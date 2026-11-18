// Throwaway spike driver: load an engine-sim script, hold the engine at a list of rpm/throttle
// points through the dyno (our Swift model would own the numbers; engine-sim only makes the
// sound), pull the audio the way a real-time callback would, and report the cost.
//
//   esim_render <main.mr> <out.wav> <label> <segments>
//   segments = "rpm:throttle:seconds,rpm:throttle:seconds,..."
//
// Run it with the working directory set to the engine-sim assets folder, like the app does.
#include "compiler.h"
#include "simulator.h"
#include "units.h"

#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <fstream>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include <sys/resource.h>
#include <unistd.h>

namespace {

struct Segment {
    double rpm;
    double throttle;
    double seconds;
};

std::vector<Segment> parseSegments(const std::string &text) {
    std::vector<Segment> out;
    std::stringstream all(text);
    std::string item;
    while (std::getline(all, item, ',')) {
        Segment s{0, 0, 0};
        if (std::sscanf(item.c_str(), "%lf:%lf:%lf", &s.rpm, &s.throttle, &s.seconds) == 3) out.push_back(s);
    }
    return out;
}

// The impulse responses are plain 16-bit PCM WAV files; take the first channel.
bool readWav16(const std::string &path, std::vector<int16_t> *samples) {
    std::ifstream f(path, std::ios::binary);
    if (!f) return false;
    char riff[12];
    f.read(riff, 12);
    if (std::memcmp(riff, "RIFF", 4) != 0 || std::memcmp(riff + 8, "WAVE", 4) != 0) return false;
    int channels = 1;
    int bits = 16;
    while (f) {
        char id[4];
        uint32_t size = 0;
        f.read(id, 4);
        f.read(reinterpret_cast<char *>(&size), 4);
        if (!f) break;
        if (std::memcmp(id, "fmt ", 4) == 0) {
            std::vector<char> fmt(size);
            f.read(fmt.data(), size);
            channels = *reinterpret_cast<uint16_t *>(&fmt[2]);
            bits = *reinterpret_cast<uint16_t *>(&fmt[14]);
        } else if (std::memcmp(id, "data", 4) == 0) {
            if (bits != 16) return false;
            const size_t frames = size / (2 * channels);
            std::vector<int16_t> raw(frames * channels);
            f.read(reinterpret_cast<char *>(raw.data()), frames * channels * 2);
            samples->resize(frames);
            for (size_t i = 0; i < frames; ++i) (*samples)[i] = raw[i * channels];
            return true;
        } else {
            f.seekg(size + (size & 1), std::ios::cur);
        }
    }
    return false;
}

void writeWav(const std::string &path, const std::vector<int16_t> &pcm) {
    std::ofstream f(path, std::ios::binary);
    const uint32_t dataBytes = static_cast<uint32_t>(pcm.size() * 2);
    const uint32_t riffSize = 36 + dataBytes;
    const uint32_t fmtSize = 16, rate = 44100, byteRate = 44100 * 2;
    const uint16_t pcmFormat = 1, channels = 1, align = 2, bits = 16;
    f.write("RIFF", 4);
    f.write(reinterpret_cast<const char *>(&riffSize), 4);
    f.write("WAVEfmt ", 8);
    f.write(reinterpret_cast<const char *>(&fmtSize), 4);
    f.write(reinterpret_cast<const char *>(&pcmFormat), 2);
    f.write(reinterpret_cast<const char *>(&channels), 2);
    f.write(reinterpret_cast<const char *>(&rate), 4);
    f.write(reinterpret_cast<const char *>(&byteRate), 4);
    f.write(reinterpret_cast<const char *>(&align), 2);
    f.write(reinterpret_cast<const char *>(&bits), 2);
    f.write("data", 4);
    f.write(reinterpret_cast<const char *>(&dataBytes), 4);
    f.write(reinterpret_cast<const char *>(pcm.data()), dataBytes);
}

double wallSeconds() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

} // namespace

int main(int argc, char **argv) {
    if (argc < 5) {
        std::fprintf(stderr, "usage: esim_render <main.mr> <out.wav> <label> <rpm:throttle:seconds,...>\n");
        return 1;
    }
    // The iOS simulator's process runner cannot set a working directory, so allow it by variable.
    if (const char *dir = std::getenv("ES_ASSETS")) {
        if (chdir(dir) != 0) {
            std::fprintf(stderr, "cannot chdir to %s\n", dir);
            return 1;
        }
    }
    const std::string script = argv[1], outPath = argv[2], label = argv[3];
    const bool freeMode = std::string(argv[4]) == "free";
    const std::vector<Segment> segments = freeMode ? std::vector<Segment>{} : parseSegments(argv[4]);
    if (!freeMode && segments.empty()) {
        std::fprintf(stderr, "no segments parsed from '%s'\n", argv[4]);
        return 1;
    }

    // ---- load the engine script ----------------------------------------------------------
    const double t0 = wallSeconds();
    es_script::Compiler compiler;
    compiler.initialize();
    if (!compiler.compile(script)) {
        std::fprintf(stderr, "COMPILE FAILED: %s (see error_log.log)\n", script.c_str());
        return 2;
    }
    const es_script::Compiler::Output out = compiler.execute();
    Engine *engine = out.engine;
    Vehicle *vehicle = out.vehicle;
    Transmission *transmission = out.transmission;
    compiler.destroy();
    if (engine == nullptr) {
        std::fprintf(stderr, "script produced no engine\n");
        return 3;
    }
    if (vehicle == nullptr) {
        Vehicle::Parameters p;
        p.mass = units::mass(1597, units::kg);
        p.diffRatio = 3.42;
        p.tireRadius = units::distance(10, units::inch);
        p.dragCoefficient = 0.25;
        p.crossSectionArea = units::distance(6.0, units::foot) * units::distance(6.0, units::foot);
        p.rollingResistance = 2000.0;
        vehicle = new Vehicle;
        vehicle->initialize(p);
    }
    if (transmission == nullptr) {
        static const double ratios[] = {2.97, 2.07, 1.43, 1.00, 0.84, 0.56};
        Transmission::Parameters p;
        p.GearCount = 6;
        p.GearRatios = ratios;
        p.MaxClutchTorque = units::torque(1000.0, units::ft_lb);
        transmission = new Transmission;
        transmission->initialize(p);
    }

    Simulator *sim = engine->createSimulator(vehicle, transmission);
    engine->calculateDisplacement();
    sim->setSimulationFrequency(static_cast<int>(engine->getSimulationFrequency()));

    Synthesizer::AudioParameters audio = sim->synthesizer().getAudioParameters();
    audio.inputSampleNoise = static_cast<float>(engine->getInitialJitter());
    audio.airNoise = static_cast<float>(engine->getInitialNoise());
    audio.dF_F_mix = static_cast<float>(engine->getInitialHighFrequencyGain());
    sim->synthesizer().setAudioParameters(audio);

    for (int i = 0; i < engine->getExhaustSystemCount(); ++i) {
        ImpulseResponse *response = engine->getExhaustSystem(i)->getImpulseResponse();
        std::vector<int16_t> pcm;
        if (!readWav16(response->getFilename(), &pcm)) {
            std::fprintf(stderr, "cannot read impulse response '%s'\n", response->getFilename().c_str());
            return 4;
        }
        sim->synthesizer().initializeImpulseResponse(
            pcm.data(), static_cast<unsigned int>(pcm.size()), response->getVolume(), i);
    }
    sim->startAudioRenderingThread();
    const double loadSeconds = wallSeconds() - t0;

    engine->getIgnitionModule()->m_enabled = true;

    if (freeMode) {
        // Free-run check: crank it, then full throttle. An engine whose firing order, cams and bank
        // offsets are consistent revs up on its own; a mis-timed one stalls or never gets going.
        const double frameDt = 1.0 / 60.0;
        std::vector<int16_t> pcm;
        std::vector<int16_t> chunk(735);
        double maxRpm = 0, rpmAt3 = 0;
        sim->m_dyno.m_enabled = false;
        sim->m_dyno.m_hold = false;
        for (int f = 0; f < 60 * 10; ++f) {
            const double t = f / 60.0;
            const double rpm = engine->getRpm();
            sim->m_starterMotor.m_enabled = t < 3.0 && rpm < 700;
            engine->setSpeedControl(t < 3.0 ? 0.35 : 1.0);
            sim->startFrame(frameDt);
            while (sim->simulateStep()) {
            }
            sim->endFrame();
            int got = 0;
            const double waitStart = wallSeconds();
            while (got < 735 && wallSeconds() - waitStart < 0.05) {
                std::vector<int16_t> part(735 - got);
                const int n = sim->readAudioOutput(735 - got, part.data());
                for (int i = 0; i < n; ++i) chunk[got + i] = part[i];
                got += n;
                if (got < 735) std::this_thread::sleep_for(std::chrono::microseconds(200));
            }
            for (int i = got; i < 735; ++i) chunk[i] = 0;
            pcm.insert(pcm.end(), chunk.begin(), chunk.end());
            maxRpm = std::max(maxRpm, engine->getRpm());
            if (f == 60 * 3) rpmAt3 = engine->getRpm();
        }
        const double finalRpm = engine->getRpm();
        const bool pass = maxRpm > 1500;
        std::printf("FREERUN %s: cylinders %d, rpm at 3 s %.0f, max %.0f, final %.0f -> %s\n", label.c_str(),
                    engine->getCylinderCount(), rpmAt3, maxRpm, finalRpm, pass ? "PASS" : "FAIL");
        writeWav(outPath, pcm);
        std::fflush(stdout);
        std::_Exit(pass ? 0 : 5);
    }

    sim->m_dyno.m_enabled = true;
    sim->m_dyno.m_hold = true;

    std::printf("ENGINE %s: %d cylinders, %d exhaust systems, sim %d Hz, load %.2f s\n", label.c_str(),
                engine->getCylinderCount(), engine->getExhaustSystemCount(), sim->getSimulationFrequency(),
                loadSeconds);

    // ---- drive it like a real-time audio callback would ----------------------------------
    const double frameDt = 1.0 / 60.0;
    const int framesPerBlock = 735; // 44100 / 60
    std::vector<int16_t> all;
    std::vector<int16_t> block(framesPerBlock);
    int underruns = 0;
    const std::clock_t cpuStart = std::clock();
    const double wallStart = wallSeconds();

    for (const Segment &seg : segments) {
        sim->m_dyno.m_rotationSpeed = units::rpm(seg.rpm);
        engine->setSpeedControl(seg.throttle);
        const int frames = static_cast<int>(seg.seconds * 60.0);
        double rpmSum = 0, torqueSum = 0;
        int counted = 0;
        const double segStart = wallSeconds();
        for (int f = 0; f < frames; ++f) {
            sim->startFrame(frameDt);
            while (sim->simulateStep()) {
            }
            sim->endFrame();

            int got = 0;
            const double waitStart = wallSeconds();
            while (got < framesPerBlock) {
                std::vector<int16_t> part(framesPerBlock - got);
                const int n = sim->readAudioOutput(framesPerBlock - got, part.data());
                for (int i = 0; i < n; ++i) block[got + i] = part[i];
                got += n;
                if (got < framesPerBlock) {
                    if (wallSeconds() - waitStart > 0.050) break; // a 50 ms stall would be audible
                    std::this_thread::sleep_for(std::chrono::microseconds(200));
                }
            }
            if (got < framesPerBlock) {
                ++underruns;
                for (int i = got; i < framesPerBlock; ++i) block[i] = 0;
            }
            all.insert(all.end(), block.begin(), block.end());

            if (f > frames / 2) { // second half of each point, after the engine has settled
                rpmSum += engine->getRpm();
                torqueSum += sim->getFilteredDynoTorque();
                ++counted;
            }
        }
        const double segWall = wallSeconds() - segStart;
        std::printf("  point %5.0f rpm throttle %.2f for %.1f s: wall %.2f s (%.2fx real time), "
                    "held %.0f rpm, dyno torque %.0f Nm\n",
                    seg.rpm, seg.throttle, seg.seconds, segWall, seg.seconds / segWall,
                    counted ? rpmSum / counted : 0.0, counted ? torqueSum / counted : 0.0);
    }

    const double wall = wallSeconds() - wallStart;
    const double cpu = static_cast<double>(std::clock() - cpuStart) / CLOCKS_PER_SEC;
    const double audioSeconds = static_cast<double>(all.size()) / 44100.0;
    struct rusage usage;
    getrusage(RUSAGE_SELF, &usage);
    double peakMB = usage.ru_maxrss / 1024.0; // Linux reports KB
#ifdef __APPLE__
    peakMB = usage.ru_maxrss / (1024.0 * 1024.0); // macOS reports bytes
#endif
    std::printf("RESULT %s audio %.1f s, wall %.2f s, real-time factor %.2fx, cpu %.2f s (%.2f cores), "
                "underruns %d, peak memory %.0f MB\n",
                label.c_str(), audioSeconds, wall, audioSeconds / wall, cpu, cpu / wall, underruns, peakMB);

    writeWav(outPath, all);
    std::fflush(stdout);
    std::_Exit(0); // skip teardown: the spike only needs the numbers and the audio
}
