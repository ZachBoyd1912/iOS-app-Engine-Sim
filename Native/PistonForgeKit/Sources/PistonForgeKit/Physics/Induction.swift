import Foundation

/// The turbo's moving state between simulation steps.
public struct TurboState: Equatable, Sendable {
    /// Shaft speed as a fraction of full spool, 0...1.
    public var shaftSpeed: Double

    public init(shaftSpeed: Double = 0) {
        self.shaftSpeed = shaftSpeed
    }
}

/// Boost pressure in psi for this step. Turbos spool over time toward the wastegate target;
/// superchargers are belt-driven, so their boost follows rpm at once and ignores the target.
public func boostPsi(_ b: EngineBuild, rpm: Double, throttle: Double, turbo: inout TurboState, dt: Double, target: Double) -> Double {
    0 // RED stub
}

/// Crank power a supercharger takes to drive, in hp. Turbos and NA engines take none.
public func parasiticLossHp(_ b: EngineBuild, rpm: Double, boost: Double) -> Double {
    0 // RED stub
}
