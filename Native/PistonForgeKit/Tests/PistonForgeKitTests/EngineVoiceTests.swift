import Foundation
import Testing
@testable import PistonForgeKit

private let rate = 44_100.0

private func params(_ layout: EngineLayout, rpm: Double, boost: Double = 0, induction: Induction = .natural, nitrous: Bool = false) -> VoiceParams {
    VoiceParams(rpm: rpm, load: 0.6, boostPsi: boost, throttle: 0.6, nitrous: nitrous, induction: induction, layout: layout, exhaustLevel: 1)
}

/// Renders `seconds` of sound after `preroll` seconds settling, with steady parameters.
private func render(_ voice: EngineVoice, _ p: VoiceParams, seconds: Double, preroll: Double = 0.2) -> [Float] {
    var settle = [Float](repeating: 0, count: Int(rate * preroll))
    settle.withUnsafeMutableBufferPointer { voice.render(p, frames: $0.count, into: $0.baseAddress!) }
    var out = [Float](repeating: 0, count: Int(rate * seconds))
    out.withUnsafeMutableBufferPointer { buffer in
        var offset = 0
        while offset < buffer.count {
            let block = min(512, buffer.count - offset)
            voice.render(p, frames: block, into: buffer.baseAddress! + offset)
            offset += block
        }
    }
    return out
}

private func rms(_ samples: [Float]) -> Double {
    (samples.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(max(samples.count, 1))).squareRoot()
}

/// Power at `frequency` by the Goertzel algorithm.
private func power(_ samples: [Float], at frequency: Double) -> Double {
    let coefficient = 2 * cos(2 * Double.pi * frequency / rate)
    var s1 = 0.0
    var s2 = 0.0
    for sample in samples {
        let s0 = Double(sample) + coefficient * s1 - s2
        s2 = s1
        s1 = s0
    }
    return s1 * s1 + s2 * s2 - coefficient * s1 * s2
}

@Test(arguments: EngineLayout.allCases)
func outputBoundedAndFinite(layout: EngineLayout) {
    let voice = EngineVoice(sampleRate: rate)
    let redline = EngineBuild.starter(layout).mechanicalRedline
    var buffer = [Float](repeating: 0, count: 441)
    var worst: Float = 0
    var finite = true
    for step in 0..<200 {
        let rpm = 900 + (redline - 900) * Double(step) / 199
        let p = VoiceParams(rpm: rpm, load: 1.8, boostPsi: 30, throttle: 1, nitrous: true, induction: .turbo(.twin), layout: layout, exhaustLevel: 3)
        buffer.withUnsafeMutableBufferPointer { voice.render(p, frames: $0.count, into: $0.baseAddress!) }
        for sample in buffer {
            if !sample.isFinite { finite = false }
            worst = max(worst, abs(sample))
        }
    }
    #expect(finite, "\(layout)")
    #expect(worst <= 1, "\(layout) peaked at \(worst)")
    #expect(worst > 0.05, "\(layout) is audible")
}

@Test func pulseRateMatchesFiring() {
    let samples = render(EngineVoice(sampleRate: rate), params(.i4, rpm: 3000), seconds: 0.5)
    // Autocorrelation between 2.5 ms and 15 ms of lag (400 Hz down to 67 Hz).
    var best = (lag: 0, value: -Double.infinity)
    for lag in Int(rate * 0.0025)...Int(rate * 0.015) {
        var sum = 0.0
        for index in 0..<(samples.count - lag) { sum += Double(samples[index]) * Double(samples[index + lag]) }
        if sum > best.value { best = (lag, sum) }
    }
    let frequency = rate / Double(best.lag)
    #expect(abs(frequency - 100) / 100 < 0.05, "dominant pulse at \(frequency) Hz, expected 100")
}

@Test func flatVsCrossPlaneDiffer() {
    let voice = EngineVoice(sampleRate: rate)
    func gaps(_ layout: EngineLayout) -> [Double] {
        let times = voice.firingTimes(layout: layout, rpm: 3000, duration: 0.2, bank: 0)
        return zip(times, times.dropFirst()).map { $1 - $0 }
    }
    let flat = gaps(.v8Flat)
    let cross = gaps(.v8Cross)
    #expect(flat.count >= 6 && cross.count >= 6)
    let flatSpread = (flat.max() ?? 0) - (flat.min() ?? 0)
    let crossSpread = (cross.max() ?? 0) - (cross.min() ?? 0)
    #expect(flatSpread < 1e-9, "flat-plane bank fires evenly")
    #expect(crossSpread > 0.004, "cross-plane bank fires unevenly: spread \(crossSpread) s")
    // At 3000 rpm one bank of a flat-plane V8 fires every 180° = 10 ms.
    #expect(abs((flat.first ?? 0) - 0.01) < 1e-9)
}

@Test func silenceWhenStopped() {
    let samples = render(EngineVoice(sampleRate: rate), VoiceParams(rpm: 0, load: 0, boostPsi: 0, throttle: 0, nitrous: false, induction: .turbo(.large), layout: .v12, exhaustLevel: 2), seconds: 0.5)
    #expect(rms(samples) < 0.001)
}

@Test func soundFadesAfterStopping() {
    let voice = EngineVoice(sampleRate: rate)
    _ = render(voice, params(.v8Cross, rpm: 4000), seconds: 0.2)
    let after = render(voice, VoiceParams(rpm: 0, load: 0, boostPsi: 0, throttle: 0, nitrous: false, induction: .natural, layout: .v8Cross, exhaustLevel: 1), seconds: 0.3, preroll: 0.5)
    #expect(rms(after) < 0.001)
}

@Test func turboAddsWhine() {
    let band = stride(from: 2000.0, through: 8000, by: 125)
    func whine(_ boost: Double) -> Double {
        let samples = render(EngineVoice(sampleRate: rate), params(.i4, rpm: 4000, boost: boost, induction: .turbo(.medium)), seconds: 0.5)
        return band.reduce(0) { $0 + power(samples, at: $1) }
    }
    #expect(whine(15) > whine(0) * 1.5)
}

@Test func louderUnderLoad() {
    let light = render(EngineVoice(sampleRate: rate), VoiceParams(rpm: 3000, load: 0.1, boostPsi: 0, throttle: 0.1, nitrous: false, induction: .natural, layout: .v6_60, exhaustLevel: 1), seconds: 0.3)
    let heavy = render(EngineVoice(sampleRate: rate), VoiceParams(rpm: 3000, load: 1, boostPsi: 0, throttle: 1, nitrous: false, induction: .natural, layout: .v6_60, exhaustLevel: 1), seconds: 0.3)
    #expect(rms(heavy) > rms(light) * 1.5)
}

@Test func paramsFromEngineState() {
    var build = EngineBuild.starter(.v10)
    build.parts.exhaust = 2
    var state = EngineState()
    state.rpm = 5000
    state.loadKpa = 101.3
    state.throttle = 1
    state.boostPsi = 0
    let p = VoiceParams(state: state, build: build)
    #expect(p.layout == .v10 && p.exhaustLevel == 2 && p.rpm == 5000)
    #expect(abs(p.load - 1) < 0.01)
}

/// Writes listening samples when `PF_WAV_DIR` is set (the Linux CI job sets it and uploads the
/// folder as the `engine-sounds` artifact): idle, a full-throttle pull to the limiter and a lift,
/// six seconds per layout, plus a turbo, a Roots blower and a nitrous V8.
@Test func writesListeningSamples() throws {
    let directory = ProcessInfo.processInfo.environment["PF_WAV_DIR"]
    var variants: [(String, EngineBuild, Bool)] = EngineLayout.allCases.map { ($0.rawValue, EngineBuild.starter($0), false) }
    var turbo = EngineBuild.starter(.v8Cross)
    turbo.induction = .turbo(.twin)
    turbo = turbo.withFuelSystemSized()
    turbo.ecu = ECUMap.autoBase(for: turbo)
    var roots = EngineBuild.starter(.v8Cross)
    roots.induction = .supercharger(.roots, pulley: 1.2)
    roots = roots.withFuelSystemSized()
    roots.ecu = ECUMap.autoBase(for: roots)
    var nitrous = EngineBuild.starter(.v8Cross)
    nitrous.nitrous = NitrousKit(kind: .wet, shotHp: 150, armRpm: 3000, enabled: true)
    nitrous.ecu = ECUMap.autoBase(for: nitrous)
    variants += [("v8Cross-turbo", turbo, false), ("v8Cross-roots", roots, false), ("v8Cross-nitrous", nitrous, true)]
    if directory == nil { variants = Array(variants.prefix(1)) }

    for (name, build, armed) in variants {
        let sim = EngineSim(build: build)
        sim.nitrousArmed = armed
        sim.start()
        let voice = EngineVoice(sampleRate: rate)
        let block = Int(rate / 100)
        var samples = [Float](repeating: 0, count: block * 600)
        samples.withUnsafeMutableBufferPointer { buffer in
            // One second of idle, then a full-throttle pull held to about 2000 rpm/s by a brake
            // (so it climbs over three seconds instead of hitting the limiter at once), then a lift.
            let alpha = 2000 * 2 * Double.pi / 60
            var last = sim.state
            for tick in 0..<600 {
                let pulling = tick >= 100 && tick < 420
                let load = pulling ? max(0, last.torqueNm - sim.inertiaKgM2 * alpha) : 0
                let state = sim.step(dt: 0.01, throttle: pulling ? 1 : 0, load: load)
                last = state
                voice.render(VoiceParams(state: state, build: build), frames: block, into: buffer.baseAddress! + tick * block)
            }
        }
        let finite = samples.allSatisfy { $0.isFinite && abs($0) <= 1 }
        #expect(finite, "\(name)")
        if let directory {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            let url = URL(fileURLWithPath: directory).appendingPathComponent("\(name).wav")
            try WavWriter.write(samples: samples, sampleRate: Int(rate), to: url)
            let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
            #expect(size == 44 + samples.count * 2)
        }
    }
}
