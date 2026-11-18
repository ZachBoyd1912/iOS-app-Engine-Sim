import AVFoundation
import Foundation
import PistonForgeKit
import UIKit

/// Plays the engine through engine-sim. Our model owns the numbers (rpm, throttle, limiter); this
/// class only tells engine-sim what the engine is doing and plays what comes back.
@Observable
@MainActor
final class SoundEngine {
    private(set) var isLoaded = false
    private(set) var isLoading = false
    private(set) var message = ""
    private(set) var loadPercent = 0.0
    private(set) var dropouts = 0
    private(set) var thermal = "cool"

    var enabled = true {
        didSet { esim_set_volume(enabled ? volume : 0) }
    }
    var volume: Float = 0.6 {
        didSet { esim_set_volume(enabled ? volume : 0) }
    }

    private let audio = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private var loadedKey = ""
    private var poller: Timer?

    private var assetsPath: String {
        (Bundle.main.resourceURL ?? URL(fileURLWithPath: "/")).appendingPathComponent("engine/assets").path
    }

    private var esPath: String {
        (Bundle.main.resourceURL ?? URL(fileURLWithPath: "/")).appendingPathComponent("engine/es").path
    }

    /// Loads (or reloads) the engine's sound. Safe to call again with the same settings.
    func load(build: EngineBuild, exhaust: ExhaustPreset, limiter: LimiterStyle) async {
        let key = "\(build.layout.rawValue)|\(Int(build.bore * 10))|\(Int(build.stroke * 10))|\(exhaust.rawValue)|\(limiter.rawValue)"
        if key == loadedKey, isLoaded { return }
        isLoading = true
        message = "Loading engine sound…"
        unload()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            message = "Sound unavailable: \(error.localizedDescription)"
            isLoading = false
            return
        }

        let package = EngineSimScript.package(for: build, exhaust: exhaust, limiter: limiter)
        let workDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("engine-sim-work", isDirectory: true)
        let assets = assetsPath
        let es = esPath
        let result: (Int32, String) = await Task.detached(priority: .userInitiated) { () -> (Int32, String) in
            do {
                try? FileManager.default.removeItem(at: workDirectory)
                try FileManager.default.createDirectory(at: workDirectory, withIntermediateDirectories: true)
                for (name, bytes) in package.files {
                    var data = Data(bytes)
                    if name.hasSuffix(".mr"), var text = String(data: data, encoding: .utf8) {
                        text = text.replacingOccurrences(of: "../es/sound-library", with: es + "/sound-library")
                        data = Data(text.utf8)
                    }
                    try data.write(to: workDirectory.appendingPathComponent(name))
                }
            } catch {
                return (Int32(90), "could not write engine files: \(error.localizedDescription)")
            }
            var err = [CChar](repeating: 0, count: 512)
            let script = workDirectory.appendingPathComponent(package.mainScript).path
            let code = esim_start(assets, script, &err, 512)
            return (code, String(cString: err))
        }.value

        if result.0 != 0 {
            message = "Engine sound failed to load (\(result.0)): \(result.1)"
            isLoading = false
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
        esim_set_volume(enabled ? volume : 0)
        do {
            try audio.start()
        } catch {
            message = "Audio engine failed: \(error.localizedDescription)"
            esim_stop()
            isLoading = false
            return
        }
        loadedKey = key
        isLoaded = true
        isLoading = false
        message = ""
        poller?.invalidate()
        poller = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    func unload() {
        poller?.invalidate()
        poller = nil
        if audio.isRunning { audio.pause() }
        esim_stop()
        isLoaded = false
        loadedKey = ""
    }

    /// Tell engine-sim what the engine is doing. `ignition` false cuts the spark (stopped, or
    /// the rev limiter's cut); the held rpm is our model's.
    func drive(rpm: Double, throttle: Double, ignition: Bool) {
        guard isLoaded else { return }
        esim_set(throttle, 1, max(rpm, 0))
        esim_set_ignition(ignition ? 1 : 0)
    }

    private func poll() {
        var stats = esim_stats()
        esim_stats_get(&stats)
        loadPercent = stats.load_percent
        dropouts = Int(stats.underruns)
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermal = "cool"
        case .fair: thermal = "warm"
        case .serious: thermal = "hot"
        case .critical: thermal = "very hot"
        @unknown default: thermal = "unknown"
        }
    }
}
