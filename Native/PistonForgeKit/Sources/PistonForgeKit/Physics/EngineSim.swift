import Foundation

/// The engine at one moment, for the screens, the sound and the dyno.
public struct EngineState: Equatable, Sendable {
    public var rpm = 0.0
    /// Crank angle in degrees, 0..<720 (one full four-stroke cycle).
    public var crankAngle = 0.0
    /// Torque at the crank, Nm (negative while it drags).
    public var torqueNm = 0.0
    public var powerHp = 0.0
    public var boostPsi = 0.0
    public var afr = 0.0
    public var targetAfr = 0.0
    public var knockIndex = 0.0
    public var egtC = 0.0
    public var injectorDuty = 0.0
    public var oilPressureBar = 0.0
    public var oilTempC = 85.0
    public var iatC = 25.0
    public var loadKpa = 0.0
    public var timingDeg = 0.0
    public var throttle = 0.0
    /// 1 is a fresh engine, 0 is broken.
    public var health = 1.0
    public var failure: Failure?
    public var warnings: [Warning] = []
    public var nitrousActive = false
    public var limiterActive = false
    public var isRunning = false

    public init() {}
}

/// The running engine: integrates crank speed at a fixed 480 Hz from torque, inertia and the
/// external load, with idle control, the rev limiter, turbo spool, closed-loop fuel and damage.
public final class EngineSim {
    public private(set) var build: EngineBuild
    public private(set) var isRunning = false
    public private(set) var warnings: [Warning] = []
    public var nitrousArmed = false
    public var idleTargetRpm: Double { 850 }

    public init(build: EngineBuild) {
        self.build = build.sanitized()
    }

    // RED stubs: replaced by the implementation in the next commit.
    public func setBuild(_ newBuild: EngineBuild) { build = newBuild.sanitized() }
    public func step(dt: Double, throttle: Double, load: Double) -> EngineState { EngineState() }
    public func start() {}
    public func stop() {}
    public func repair() {}
}
