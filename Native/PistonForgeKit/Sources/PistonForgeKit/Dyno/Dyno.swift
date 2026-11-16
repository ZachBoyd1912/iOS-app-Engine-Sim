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

/// A live inertia-style sweep. RED stub.
public final class DynoRun {
    public init(sim: EngineSim, fromRpm: Double = 2000, drivetrainLoss: Double = 0.15) {}
    public func step(dt: Double) -> DynoSample? { nil }
    public var isFinished: Bool { true }
    public var result: DynoResult? { nil }
}

/// Runs a whole pull on a fresh engine. RED stub.
public func runDynoToEnd(_ build: EngineBuild) -> DynoResult {
    DynoResult(samples: [], peakHp: 0, peakHpRpm: 0, peakTorqueNm: 0, peakTorqueRpm: 0, failure: nil)
}
