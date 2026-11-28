import Foundation

/// How the car answers the driver: pedal map, when an automatic shifts, how fast it shifts,
/// how much torque it lets through and how much wheelspin its traction control allows.
/// All numbers are game-tuned.
public enum DriveMode: String, Codable, CaseIterable, Sendable {
    case comfort, eco, sport, sportPlus

    /// No shift point goes above this fraction of redline.
    static let maxShiftFraction = 0.97

    public var displayName: String {
        switch self {
        case .comfort: "Comfort"
        case .eco: "Eco"
        case .sport: "Sport"
        case .sportPlus: "Sport+"
        }
    }

    /// Effective throttle is pedal ^ this. Above 1 softens the pedal; below 1 sharpens it.
    public var throttleExponent: Double {
        switch self {
        case .eco: 1.6
        case .comfort: 1.2
        case .sport: 0.9
        case .sportPlus: 0.75
        }
    }

    /// Fraction of redline at which an automatic upshifts, at this pedal position (0...1).
    public func upshiftRpmFraction(throttle: Double) -> Double {
        let pedal = bounded(throttle, 0...1, or: 0)
        let raw: Double
        switch self {
        case .eco: raw = 0.40 + 0.35 * pedal
        case .comfort: raw = 0.45 + 0.40 * pedal
        case .sport: raw = 0.55 + 0.40 * pedal
        case .sportPlus: raw = 0.65 + 0.33 * pedal
        }
        return min(raw, DriveMode.maxShiftFraction)
    }

    /// Fraction of redline at which an automatic downshifts. About 55% of the upshift point,
    /// raised by 0.15 for kickdown (pedal above 85%).
    public func downshiftRpmFraction(throttle: Double) -> Double {
        let pedal = bounded(throttle, 0...1, or: 0)
        let base = 0.55 * upshiftRpmFraction(throttle: pedal)
        let kickdown = pedal > 0.85 ? 0.15 : 0.0
        return min(base + kickdown, DriveMode.maxShiftFraction)
    }

    /// Multiplies the gearbox's shift time: above 1 is a slower, smoother shift.
    public var shiftSpeedScale: Double {
        switch self {
        case .eco: 1.3
        case .comfort: 1.15
        case .sport: 0.85
        case .sportPlus: 0.7
        }
    }

    /// Share of the engine torque let through to the wheels.
    public var torqueLimitFraction: Double {
        switch self {
        case .eco: 0.75
        case .comfort, .sport, .sportPlus: 1.0
        }
    }

    /// Wheelspin, as a share of the drive force, that traction control allows before it cuts in.
    /// Exposed for the screen. The car model caps drive force at grip, so this does not change
    /// the result of a run yet.
    public var tractionControlSlipTarget: Double {
        switch self {
        case .comfort: 0.08
        case .eco: 0.06
        case .sport: 0.15
        case .sportPlus: 0.25
        }
    }
}
