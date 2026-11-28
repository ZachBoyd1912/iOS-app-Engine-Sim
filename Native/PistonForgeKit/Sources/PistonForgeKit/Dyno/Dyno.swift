import Foundation

/// One point on a dyno sheet.
public struct DynoSample: Codable, Equatable, Sendable {
    public var rpm, torqueNm, powerHp, wheelHp, afr, boostPsi, knockIndex, egtC: Double
}

/// A finished pull.
public struct DynoResult: Codable, Equatable, Sendable {
    public var samples: [DynoSample]
    public var peakHp, peakHpRpm, peakTorqueNm, peakTorqueRpm: Double
    public var failure: Failure?
}

/// A live sweep. The engine is held at `fromRpm` at full throttle for half a second, then the
/// brake lets it climb at about 400 rpm/s to the limiter. A sample is kept every 100 rpm. The
/// pull ends at the limiter, after 60 seconds, or when the engine breaks or stalls.
public final class DynoRun {
    public static let sweepRpmPerSecond = 400.0
    public static let sampleSpacingRpm = 100.0
    static let settleSeconds = 0.5
    static let maxSeconds = 60.0

    public let sim: EngineSim
    public let fromRpm: Double
    public let drivetrainLoss: Double

    private enum Phase { case settling, sweeping, done }
    private var phase = Phase.settling
    private var settled = 0.0
    private var elapsed = 0.0
    private var samples: [DynoSample] = []
    private var nextSampleRpm: Double
    private var failure: Failure?

    public init(sim: EngineSim, fromRpm: Double = 2000, drivetrainLoss: Double = 0.15) {
        self.sim = sim
        self.fromRpm = bounded(fromRpm, 1000...6000, or: 2000)
        self.drivetrainLoss = bounded(drivetrainLoss, 0...0.5, or: 0.15)
        nextSampleRpm = self.fromRpm
        if !sim.isRunning { sim.start() }
        if !sim.isRunning {
            failure = sim.state.failure
            phase = .done
        }
    }

    public var isFinished: Bool { phase == .done }

    /// The pull so far; complete once `isFinished`.
    public var result: DynoResult? {
        guard !samples.isEmpty || isFinished else { return nil }
        let bestPower = samples.max { $0.powerHp < $1.powerHp }
        let bestTorque = samples.max { $0.torqueNm < $1.torqueNm }
        return DynoResult(
            samples: samples,
            peakHp: bestPower?.powerHp ?? 0,
            peakHpRpm: bestPower?.rpm ?? 0,
            peakTorqueNm: bestTorque?.torqueNm ?? 0,
            peakTorqueRpm: bestTorque?.rpm ?? 0,
            failure: failure
        )
    }

    /// Advances the pull by `dt` seconds; returns a sample when one was taken.
    @discardableResult
    public func step(dt: Double) -> DynoSample? {
        guard phase != .done else { return nil }
        let span = bounded(dt, 0...0.1)
        elapsed += span
        let last = sim.state
        var taken: DynoSample?

        switch phase {
        case .settling:
            // Brake harder the further the engine is above the start rpm, pulling it back over
            // about a quarter of a second whatever its size (stable at any frame rate here).
            let pull = sim.inertiaKgM2 * 2 * Double.pi / 60 / 0.25
            let load = max(0, last.torqueNm + (last.rpm - fromRpm) * pull)
            let state = sim.step(dt: span, throttle: 1, load: load)
            if state.rpm >= fromRpm - 50 { settled += span }
            if settled >= Self.settleSeconds { phase = .sweeping }
        case .sweeping:
            // Let through only the torque that accelerates the engine at the sweep rate.
            let alpha = Self.sweepRpmPerSecond * 2 * Double.pi / 60
            let load = max(0, last.torqueNm - sim.inertiaKgM2 * alpha)
            let state = sim.step(dt: span, throttle: 1, load: load)
            if state.rpm >= nextSampleRpm, state.isRunning {
                let sample = DynoSample(
                    rpm: state.rpm, torqueNm: state.torqueNm, powerHp: state.powerHp,
                    wheelHp: state.powerHp * (1 - drivetrainLoss), afr: state.afr, boostPsi: state.boostPsi,
                    knockIndex: state.knockIndex, egtC: state.egtC
                )
                samples.append(sample)
                taken = sample
                while nextSampleRpm <= state.rpm { nextSampleRpm += Self.sampleSpacingRpm }
            }
            if state.limiterActive || state.rpm >= sim.build.ecu.revLimit - 20 { phase = .done }
        case .done:
            break
        }

        let now = sim.state
        if now.failure != nil || !sim.isRunning || elapsed >= Self.maxSeconds {
            failure = now.failure
            phase = .done
        }
        return taken
    }
}

/// Runs a whole pull on a fresh engine built from `build`, with its nitrous armed if the kit
/// is enabled, stepping at 30 frames a second.
public func runDynoToEnd(_ build: EngineBuild) -> DynoResult {
    let sim = EngineSim(build: build)
    sim.nitrousArmed = build.nitrous?.enabled ?? false
    let run = DynoRun(sim: sim)
    while !run.isFinished {
        run.step(dt: 1.0 / 30)
    }
    return run.result ?? DynoResult(samples: [], peakHp: 0, peakHpRpm: 0, peakTorqueNm: 0, peakTorqueRpm: 0, failure: nil)
}
