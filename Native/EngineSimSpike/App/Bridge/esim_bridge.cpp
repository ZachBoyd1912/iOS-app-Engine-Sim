// Spike: runs engine-sim on its own thread at real-time pace and hands audio to the app's render
// callback. One engine at a time; stopping tears everything down so another can be loaded.
#include "esim_bridge.h"

#include "compiler.h"
#include "simulator.h"
#include "units.h"

#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <string>
#include <thread>
#include <vector>

#include <unistd.h>

namespace {

struct Session {
    Engine *engine = nullptr;
    Vehicle *vehicle = nullptr;
    Transmission *transmission = nullptr;
    Simulator *sim = nullptr;
    std::thread thread;
};

Session g;
std::atomic<bool> g_running{false};
std::atomic<double> g_throttle{0.2};
std::atomic<int> g_hold{0};
std::atomic<double> g_holdRpm{3000};
std::atomic<bool> g_crank{false};
std::atomic<long> g_underruns{0};
std::atomic<long> g_frames{0};
std::atomic<double> g_rpm{0};
std::atomic<double> g_frameMs{0};
std::atomic<double> g_torque{0};
std::atomic<int> g_cylinders{0};

bool readWav16(const std::string &path, std::vector<int16_t> *samples) {
    std::ifstream f(path, std::ios::binary);
    if (!f) return false;
    char riff[12];
    f.read(riff, 12);
    if (std::memcmp(riff, "RIFF", 4) != 0 || std::memcmp(riff + 8, "WAVE", 4) != 0) return false;
    int channels = 1, bits = 16;
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

void setError(char *err, int len, const std::string &message) {
    if (err != nullptr && len > 0) std::snprintf(err, static_cast<size_t>(len), "%s", message.c_str());
}

void simLoop() {
    using clock = std::chrono::steady_clock;
    const double dt = 1.0 / 60.0;
    auto next = clock::now();
    auto crankStart = clock::now();
    bool cranking = false;
    double avgMs = 0;

    while (g_running.load()) {
        Simulator *sim = g.sim;
        Engine *engine = g.engine;

        if (g_hold.load()) {
            sim->m_dyno.m_enabled = true;
            sim->m_dyno.m_hold = true;
            sim->m_dyno.m_rotationSpeed = units::rpm(g_holdRpm.load());
        } else {
            sim->m_dyno.m_enabled = false;
            sim->m_dyno.m_hold = false;
        }
        engine->setSpeedControl(g_throttle.load());

        if (g_crank.exchange(false)) {
            cranking = true;
            crankStart = clock::now();
        }
        if (cranking) {
            const double seconds = std::chrono::duration<double>(clock::now() - crankStart).count();
            sim->m_starterMotor.m_enabled = true;
            if ((engine->getRpm() > 650 && seconds > 0.6) || seconds > 5.0) {
                cranking = false;
                sim->m_starterMotor.m_enabled = false;
            }
        } else {
            sim->m_starterMotor.m_enabled = false;
        }

        const auto t0 = clock::now();
        sim->startFrame(dt);
        while (sim->simulateStep()) {
        }
        sim->endFrame();
        const double ms = std::chrono::duration<double, std::milli>(clock::now() - t0).count();
        avgMs = avgMs * 0.95 + ms * 0.05;

        g_frameMs.store(avgMs);
        g_rpm.store(engine->getRpm());
        g_torque.store(sim->getFilteredDynoTorque());
        g_frames.fetch_add(1);

        next += std::chrono::microseconds(16667);
        const auto now = clock::now();
        if (next < now) next = now; // fell behind: do not try to catch up in a burst
        std::this_thread::sleep_until(next);
    }
}

} // namespace

extern "C" {

int esim_start(const char *assetsDir, const char *mainScript, char *err, int errLen) {
    esim_stop();
    if (chdir(assetsDir) != 0) {
        setError(err, errLen, std::string("cannot enter ") + assetsDir);
        return 1;
    }

    es_script::Compiler compiler;
    compiler.initialize();
    if (!compiler.compile(mainScript)) {
        std::string log;
        std::ifstream f("error_log.log");
        if (f) log.assign(std::istreambuf_iterator<char>(f), std::istreambuf_iterator<char>());
        compiler.destroy();
        setError(err, errLen, "script did not compile: " + log.substr(0, 300));
        return 2;
    }
    const es_script::Compiler::Output out = compiler.execute();
    g.engine = out.engine;
    g.vehicle = out.vehicle;
    g.transmission = out.transmission;
    compiler.destroy();
    if (g.engine == nullptr) {
        setError(err, errLen, "script produced no engine");
        return 3;
    }
    if (g.vehicle == nullptr) {
        Vehicle::Parameters p;
        p.mass = units::mass(1597, units::kg);
        p.diffRatio = 3.42;
        p.tireRadius = units::distance(10, units::inch);
        p.dragCoefficient = 0.25;
        p.crossSectionArea = units::distance(6.0, units::foot) * units::distance(6.0, units::foot);
        p.rollingResistance = 2000.0;
        g.vehicle = new Vehicle;
        g.vehicle->initialize(p);
    }
    if (g.transmission == nullptr) {
        static const double ratios[] = {2.97, 2.07, 1.43, 1.00, 0.84, 0.56};
        Transmission::Parameters p;
        p.GearCount = 6;
        p.GearRatios = ratios;
        p.MaxClutchTorque = units::torque(1000.0, units::ft_lb);
        g.transmission = new Transmission;
        g.transmission->initialize(p);
    }

    g.sim = g.engine->createSimulator(g.vehicle, g.transmission);
    g.engine->calculateDisplacement();
    g.sim->setSimulationFrequency(static_cast<int>(g.engine->getSimulationFrequency()));
    Synthesizer::AudioParameters audio = g.sim->synthesizer().getAudioParameters();
    audio.inputSampleNoise = static_cast<float>(g.engine->getInitialJitter());
    audio.airNoise = static_cast<float>(g.engine->getInitialNoise());
    audio.dF_F_mix = static_cast<float>(g.engine->getInitialHighFrequencyGain());
    g.sim->synthesizer().setAudioParameters(audio);

    for (int i = 0; i < g.engine->getExhaustSystemCount(); ++i) {
        ImpulseResponse *response = g.engine->getExhaustSystem(i)->getImpulseResponse();
        std::vector<int16_t> pcm;
        if (!readWav16(response->getFilename(), &pcm)) {
            setError(err, errLen, "cannot read impulse response " + response->getFilename());
            return 4;
        }
        g.sim->synthesizer().initializeImpulseResponse(
            pcm.data(), static_cast<unsigned int>(pcm.size()), response->getVolume(), i);
    }

    g.engine->getIgnitionModule()->m_enabled = true;
    g_cylinders.store(g.engine->getCylinderCount());
    g_underruns.store(0);
    g_frames.store(0);
    g_rpm.store(0);
    g.sim->startAudioRenderingThread();
    g_running.store(true);
    g.thread = std::thread(simLoop);
    return 0;
}

void esim_stop(void) {
    if (!g_running.exchange(false) && g.sim == nullptr) return;
    if (g.thread.joinable()) g.thread.join();
    if (g.sim != nullptr) {
        g.sim->releaseSimulation();
        delete g.sim;
        g.sim = nullptr;
    }
    if (g.vehicle != nullptr) {
        delete g.vehicle;
        g.vehicle = nullptr;
    }
    if (g.transmission != nullptr) {
        delete g.transmission;
        g.transmission = nullptr;
    }
    if (g.engine != nullptr) {
        g.engine->destroy();
        delete g.engine;
        g.engine = nullptr;
    }
}

void esim_set(double throttle, int holdMode, double holdRpm) {
    g_throttle.store(throttle < 0 ? 0 : (throttle > 1 ? 1 : throttle));
    g_hold.store(holdMode);
    g_holdRpm.store(holdRpm);
}

void esim_crank(void) { g_crank.store(true); }

void esim_read(float *out, int frames) {
    static std::vector<int16_t> scratch;
    if (static_cast<int>(scratch.size()) < frames) scratch.resize(static_cast<size_t>(frames));
    int got = 0;
    if (g_running.load() && g.sim != nullptr) got = g.sim->readAudioOutput(frames, scratch.data());
    if (got < frames) g_underruns.fetch_add(1);
    const float gain = 0.6f / 32768.0f;
    for (int i = 0; i < frames; ++i) out[i] = i < got ? scratch[static_cast<size_t>(i)] * gain : 0.0f;
}

void esim_stats_get(esim_stats *s) {
    s->rpm = g_rpm.load();
    s->frame_ms = g_frameMs.load();
    s->load_percent = g_frameMs.load() / (1000.0 / 60.0) * 100.0;
    s->underruns = g_underruns.load();
    s->frames = g_frames.load();
    s->dyno_torque = g_torque.load();
    s->cylinders = g_cylinders.load();
    s->running = g_running.load() ? 1 : 0;
}

} // extern "C"
