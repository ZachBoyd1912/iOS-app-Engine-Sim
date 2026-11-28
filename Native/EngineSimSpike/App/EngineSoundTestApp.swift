import AVFoundation
import SwiftUI
import UIKit

// Throwaway phone test for engine-sim's sound (spike/engine-sim-ios). Not Piston Forge, not shipped.
// It answers three questions on a real phone: how does it sound, does the processor keep up, and
// does the phone get hot.

struct EngineChoice: Identifiable, Hashable {
    let id: String
    let name: String
    let script: String
    let maxRpm: Double
}

let engineChoices: [EngineChoice] = [
    .init(id: "flat4", name: "Flat-4", script: "main_01_subaru_ej25_eh.mr", maxRpm: 7000),
    .init(id: "v8", name: "V8", script: "main_08_ferrari_f136_v8.mr", maxRpm: 9000),
    .init(id: "v10", name: "V10", script: "main_10_lfa_v10.mr", maxRpm: 9500),
    .init(id: "v12", name: "V12", script: "main_12_ferrari_412_t2.mr", maxRpm: 13000),
]

@Observable
@MainActor
final class SoundLab {
    var choice = engineChoices[1]
    var running = false
    var message = "Pick an engine and press Start."
    var throttle = 0.2
    var holdMode = false
    var holdRpm = 3000.0
    var stats = esim_stats()
    var cpuCores = 0.0
    var thermal = "nominal"
    var batteryStart: Float = -1
    var batteryNow: Float = -1
    var startedAt = Date()
    var worstLoad = 0.0

    private let audio = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private var timer: Timer?

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    private func assetsPath() -> String {
        (Bundle.main.resourceURL ?? URL(fileURLWithPath: "/")).appendingPathComponent("engine/assets").path
    }

    func start() {
        stop()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            message = "Audio session failed: \(error.localizedDescription)"
            return
        }
        var err = [CChar](repeating: 0, count: 512)
        let code = esim_start(assetsPath(), choice.script, &err, 512)
        if code != 0 {
            message = "Engine failed to load (\(code)): \(String(cString: err))"
            return
        }
        if source == nil {
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!
            let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
                let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
                if let data = buffers[0].mData?.assumingMemoryBound(to: Float.self) {
                    esim_read(data, Int32(frameCount))
                }
                return noErr
            }
            source = node
            audio.attach(node)
            audio.connect(node, to: audio.mainMixerNode, format: format)
        }
        apply()
        do {
            try audio.start()
        } catch {
            message = "Audio engine failed: \(error.localizedDescription)"
            esim_stop()
            return
        }
        running = true
        worstLoad = 0
        startedAt = Date()
        batteryStart = UIDevice.current.batteryLevel
        UIApplication.shared.isIdleTimerDisabled = true
        message = holdMode ? "Holding \(Int(holdRpm)) rpm." : "Press Crank to start the engine."
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if running || audio.isRunning {
            audio.pause()
        }
        esim_stop()
        running = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func apply() {
        esim_set(throttle, holdMode ? 1 : 0, holdRpm)
    }

    func crank() {
        esim_crank()
    }

    private func poll() {
        var s = esim_stats()
        esim_stats_get(&s)
        stats = s
        worstLoad = max(worstLoad, s.load_percent)
        cpuCores = Self.processCPU() / 100.0
        batteryNow = UIDevice.current.batteryLevel
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermal = "nominal (cool)"
        case .fair: thermal = "fair (warming)"
        case .serious: thermal = "SERIOUS (hot)"
        case .critical: thermal = "CRITICAL (very hot)"
        @unknown default: thermal = "unknown"
        }
    }

    var elapsed: String {
        let seconds = Int(Date().timeIntervalSince(startedAt))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    var battery: String {
        if batteryStart < 0 || batteryNow < 0 { return "n/a" }
        return "\(Int(batteryStart * 100))% -> \(Int(batteryNow * 100))%"
    }

    /// Percent of one core used by this app across all threads (200 = two cores flat out).
    static func processCPU() -> Double {
        var threads: thread_act_array_t?
        var count = mach_msg_type_number_t(0)
        guard task_threads(mach_task_self_, &threads, &count) == KERN_SUCCESS, let list = threads else { return 0 }
        var total = 0.0
        for i in 0..<Int(count) {
            var info = thread_basic_info()
            var infoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            let result = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                    thread_info(list[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                }
            }
            if result == KERN_SUCCESS, info.flags & TH_FLAGS_IDLE == 0 {
                total += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: list), vm_size_t(count) * vm_size_t(MemoryLayout<thread_t>.stride))
        return total
    }
}

struct ContentView: View {
    @State private var lab = SoundLab()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Engine sound test").font(.title.bold())
                Text("Throwaway test of the engine-sim sound on this phone. Turn the volume up and the silent switch does not matter.")
                    .font(.footnote).foregroundStyle(.secondary)

                Picker("Engine", selection: $lab.choice) {
                    ForEach(engineChoices) { Text($0.name).tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(lab.running)

                HStack(spacing: 12) {
                    Button(lab.running ? "Stop" : "Start") {
                        lab.running ? lab.stop() : lab.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(minHeight: 44)
                    Button("Crank") { lab.crank() }
                        .buttonStyle(.bordered)
                        .frame(minHeight: 44)
                        .disabled(!lab.running || lab.holdMode)
                }

                Toggle("Hold a set rpm (dyno holds it)", isOn: $lab.holdMode)
                    .onChange(of: lab.holdMode) { _, _ in lab.apply() }

                VStack(alignment: .leading) {
                    Text("Throttle \(Int(lab.throttle * 100))%")
                    Slider(value: $lab.throttle, in: 0...1)
                        .onChange(of: lab.throttle) { _, _ in lab.apply() }
                }
                VStack(alignment: .leading) {
                    Text("Hold rpm \(Int(lab.holdRpm))")
                    Slider(value: $lab.holdRpm, in: 600...lab.choice.maxRpm)
                        .onChange(of: lab.holdRpm) { _, _ in lab.apply() }
                }

                Text(lab.message).font(.callout)

                Group {
                    row("Engine speed", String(format: "%.0f rpm", lab.stats.rpm))
                    row("Cylinders", "\(lab.stats.cylinders)")
                    row("Physics load", String(format: "%.0f%% of a frame (worst %.0f%%)", lab.stats.load_percent, lab.worstLoad))
                    row("App CPU", String(format: "%.2f cores", lab.cpuCores))
                    row("Audio dropouts", "\(lab.stats.underruns)")
                    row("Phone heat", lab.thermal)
                    row("Battery", "\(lab.battery) in \(lab.elapsed)")
                }
                .font(.system(.body, design: .monospaced))
            }
            .padding(16)
        }
    }

    private func row(_ name: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(name).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
    }
}

@main
struct EngineSoundTestApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
