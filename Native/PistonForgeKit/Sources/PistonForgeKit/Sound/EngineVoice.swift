import Foundation

/// What the sound needs to know about the engine right now.
public struct VoiceParams: Equatable, Sendable {
    public var rpm: Double
    /// Engine load: 1 is wide open without boost, more on boost.
    public var load: Double
    public var boostPsi: Double
    public var throttle: Double
    public var nitrous: Bool
    public var induction: Induction
    public var layout: EngineLayout
    /// Exhaust upgrade level, 0...3: louder and lower with each step.
    public var exhaustLevel: Int

    public init(rpm: Double, load: Double, boostPsi: Double, throttle: Double, nitrous: Bool, induction: Induction, layout: EngineLayout, exhaustLevel: Int) {
        self.rpm = rpm
        self.load = load
        self.boostPsi = boostPsi
        self.throttle = throttle
        self.nitrous = nitrous
        self.induction = induction
        self.layout = layout
        self.exhaustLevel = exhaustLevel
    }

    /// The sound of `build` in `state`.
    public init(state: EngineState, build: EngineBuild) {
        self.init(
            rpm: state.rpm,
            load: bounded(state.loadKpa / 101.3, 0...3),
            boostPsi: state.boostPsi,
            throttle: state.throttle,
            nitrous: state.nitrousActive,
            induction: build.induction,
            layout: build.layout,
            exhaustLevel: build.parts.exhaust
        )
    }
}

/// Real-time engine sound synthesis.
///
/// Each cylinder firing kicks its own bank's exhaust: a low "body" resonance and a higher
/// "rasp" resonance per bank, tuned by rpm and the exhaust level. Because each bank hears only
/// its own cylinders, a cross-plane V8's uneven bank spacing gives its burble and a flat-plane
/// its even scream. Turbo and supercharger whine, intake roar and the nitrous hiss sit on top.
/// Parameters glide over about 20 ms. `render` allocates nothing, takes no locks and calls only
/// C maths functions, so it is safe on the audio thread.
public final class EngineVoice {
    struct Schedule {
        /// Crank degrees of each firing event, 0..<720.
        let angles: [Double]
        /// Bank of each firing event.
        let banks: [Int]
        let bankCount: Int
    }

    static let maxBanks = 4

    public let sampleRate: Double
    private let schedules: [EngineLayout: Schedule]
    private let glide: Double

    private var phase = 0.0
    private var rpm = 0.0
    private var load = 0.0
    private var throttle = 0.0
    private var boost = 0.0
    private var nitrous = 0.0
    private var excite: [Double]
    private var body1: [Double]
    private var body2: [Double]
    private var rasp1: [Double]
    private var rasp2: [Double]
    private var whinePhase = 0.0
    private var noiseState: UInt32 = 22_222
    private var roar = 0.0
    private var hissLow = 0.0
    /// Samples the non-number guard had to silence (should stay 0; tests check it).
    private(set) var nonFiniteSamples = 0

    public init(sampleRate: Double) {
        self.sampleRate = sampleRate > 0 && sampleRate.isFinite ? sampleRate : 44_100
        glide = 1 - exp(-1 / (0.02 * self.sampleRate))
        var table: [EngineLayout: Schedule] = [:]
        for layout in EngineLayout.allCases {
            let spec = layout.spec
            table[layout] = Schedule(
                angles: spec.firingAngles,
                banks: spec.firingOrder.map { spec.bankOf[$0 - 1] },
                bankCount: min(spec.banks, Self.maxBanks)
            )
        }
        schedules = table
        // Each buffer is allocated on its own here, so the audio thread never triggers a
        // copy-on-write when it first writes to one.
        excite = Array(repeating: 0, count: Self.maxBanks)
        body1 = Array(repeating: 0, count: Self.maxBanks)
        body2 = Array(repeating: 0, count: Self.maxBanks)
        rasp1 = Array(repeating: 0, count: Self.maxBanks)
        rasp2 = Array(repeating: 0, count: Self.maxBanks)
    }

    /// Times (seconds from crank angle 0) at which `bank`'s cylinders fire at a steady `rpm`.
    func firingTimes(layout: EngineLayout, rpm: Double, duration: Double, bank: Int) -> [Double] {
        guard let schedule = schedules[layout], rpm > 0 else { return [] }
        let degreesPerSecond = rpm / 60 * 360
        var times: [Double] = []
        var cycle = 0.0
        while cycle / degreesPerSecond < duration {
            for (angle, owner) in zip(schedule.angles, schedule.banks) where owner == bank {
                let time = (angle + cycle) / degreesPerSecond
                if time < duration { times.append(time) }
            }
            cycle += 720
        }
        return times.sorted()
    }

    private func noise() -> Double {
        noiseState = 1_664_525 &* noiseState &+ 1_013_904_223
        return Double(noiseState) / 2_147_483_648 - 1
    }

    private func reset() {
        for bank in 0..<Self.maxBanks {
            body1[bank] = 0
            body2[bank] = 0
            rasp1[bank] = 0
            rasp2[bank] = 0
        }
        roar = 0
        hissLow = 0
    }

    public func render(_ params: VoiceParams, frames: Int, into buffer: UnsafeMutablePointer<Float>) {
        guard frames > 0 else { return }
        guard let schedule = schedules[params.layout] else {
            for index in 0..<frames { buffer[index] = 0 }
            return
        }
        let targetRpm = bounded(params.rpm, 0...15_000)
        let targetLoad = bounded(params.load, 0...3)
        let targetThrottle = bounded(params.throttle, 0...1)
        let targetBoost = bounded(params.boostPsi, 0...60)
        let targetNitrous = params.nitrous ? 1.0 : 0.0
        let exhaust = Double(min(max(params.exhaustLevel, 0), 3))
        let rate = sampleRate

        for index in 0..<frames {
            rpm += (targetRpm - rpm) * glide
            load += (targetLoad - load) * glide
            throttle += (targetThrottle - throttle) * glide
            boost += (targetBoost - boost) * glide
            nitrous += (targetNitrous - nitrous) * glide

            // Advance the crank and kick each bank whose cylinder fired in this sample.
            let previous = phase
            phase += rpm / 60 * 360 / rate
            for bank in 0..<Self.maxBanks { excite[bank] = 0 }
            if rpm > 30 {
                let strength = (0.25 + 0.55 * min(load, 2)) * (0.6 + 0.4 * throttle)
                for event in 0..<schedule.angles.count {
                    let angle = schedule.angles[event] > previous ? schedule.angles[event] : schedule.angles[event] + 720
                    if previous < angle && angle <= phase { excite[schedule.banks[event]] += strength }
                }
            }
            if phase >= 720 { phase -= 720 }

            var total = 0.0
            for bank in 0..<schedule.bankCount {
                let spread = Double(bank)
                let bodyHz = (70 + 25 * exhaust + rpm * 0.012) * (1 + 0.06 * spread)
                let raspHz = (420 + 90 * exhaust + rpm * 0.05) * (1 + 0.04 * spread)
                total += resonate(&body1[bank], &body2[bank], hz: bodyHz, decay: 0.006, input: excite[bank], rate: rate)
                total += 0.35 * resonate(&rasp1[bank], &rasp2[bank], hz: raspHz, decay: 0.0018, input: excite[bank], rate: rate)
            }

            switch params.induction {
            case .natural:
                break
            case .turbo:
                whinePhase += (2500 + boost * 250) / rate
                total += 0.05 * min(boost / 15, 1.5) * sin(2 * Double.pi * whinePhase)
            case .supercharger(let kind, let pulley):
                let ratio: Double = switch kind {
                case .roots: 35
                case .twinScrew: 45
                case .centrifugal: 90
                }
                whinePhase += rpm / 60 * ratio * bounded(pulley, SuperchargerKind.pulleyRange, or: 1) / rate
                total += 0.035 * (0.3 + 0.7 * throttle) * min(rpm / 6000, 1.2) * sin(2 * Double.pi * whinePhase)
            }
            if whinePhase > 1 { whinePhase -= whinePhase.rounded(.down) }

            let random = noise()
            roar += (random - roar) * 0.2
            total += roar * 0.02 * throttle * min(rpm / 6000, 1.2)
            hissLow += (random - hissLow) * 0.05
            total += (random - hissLow) * 0.05 * nitrous * (rpm > 30 ? 1 : 0)

            var sample = tanh(0.6 * total)
            if !sample.isFinite {
                reset()
                sample = 0
                nonFiniteSamples += 1
            }
            buffer[index] = Float(sample)
        }
    }

    /// One step of a two-pole resonator normalised so a unit kick peaks near 1.
    @inline(__always)
    private func resonate(_ y1: inout Double, _ y2: inout Double, hz: Double, decay: Double, input: Double, rate: Double) -> Double {
        let omega = 2 * Double.pi * min(hz, rate * 0.45) / rate
        let radius = exp(-1 / (decay * rate))
        let y = 2 * radius * cos(omega) * y1 - radius * radius * y2 + sin(omega) * input
        y2 = y1
        y1 = y
        return y
    }
}
