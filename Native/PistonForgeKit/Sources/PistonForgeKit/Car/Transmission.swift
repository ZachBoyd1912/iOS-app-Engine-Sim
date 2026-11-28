import Foundation

/// The numbers one gearbox needs for the car model. The ratios are game-tuned, based on public
/// ratio data for production gearboxes of each type. They are not taken from any licensed or
/// trademarked specification.
public struct GearboxSpec: Sendable {
    public enum Kind: Sendable, Equatable {
        case manual, sequential, dualClutch, torqueConverter, cvt, direct
    }

    public let kind: Kind
    /// Forward gear ratios, first gear first. A CVT lists its two end ratios here; the
    /// continuous range is in `cvtRatioRange`.
    public let ratios: [Double]
    /// Reverse ratio. Reverse is not driven by the car model yet.
    public let reverse: Double
    /// Seconds the torque is cut during a shift, before the drive mode's shift scale.
    public let shiftTimeS: Double
    /// Torque converter stall speed in rpm, 0 for gearboxes without a converter.
    public let stallRpm: Double
    /// Gear (1-based) from which a torque converter is locked up.
    public let lockupGear: Int
    /// Largest torque the gearbox passes on, Nm.
    public let maxInputTorqueNm: Double
    /// Continuous ratio range of a CVT, nil for every other gearbox.
    public let cvtRatioRange: ClosedRange<Double>?

    public init(
        kind: Kind, ratios: [Double], reverse: Double, shiftTimeS: Double, stallRpm: Double,
        lockupGear: Int, maxInputTorqueNm: Double, cvtRatioRange: ClosedRange<Double>?
    ) {
        self.kind = kind
        self.ratios = ratios
        self.reverse = reverse
        self.shiftTimeS = shiftTimeS
        self.stallRpm = stallRpm
        self.lockupGear = lockupGear
        self.maxInputTorqueNm = maxInputTorqueNm
        self.cvtRatioRange = cvtRatioRange
    }
}

public extension Gearbox {
    /// Generic name for the menu. No brand names.
    public var displayName: String {
        switch self {
        case .m5: "5-speed manual"
        case .m6: "6-speed manual"
        case .seq6: "6-speed sequential"
        case .dct7: "7-speed dual-clutch"
        case .auto4: "4-speed automatic"
        case .auto8: "8-speed automatic"
        case .auto10: "10-speed automatic"
        case .cvt: "CVT"
        case .ev1: "Single-speed (electric)"
        }
    }

    /// Ratios and shift behaviour for this gearbox. Game-tuned, based on public ratio data.
    public var spec: GearboxSpec {
        switch self {
        case .m5:
            // Five-speed manual, Mustang T-5 style. Reverse is a placeholder (not in the brief).
            GearboxSpec(kind: .manual, ratios: [3.35, 1.93, 1.29, 1.00, 0.68], reverse: 3.09, shiftTimeS: 0.45, stallRpm: 0, lockupGear: 2, maxInputTorqueNm: 650, cvtRatioRange: nil)
        case .m6:
            // Six-speed manual, Mazda MX-5 ND style. Game-tuned, based on public ratio data.
            GearboxSpec(kind: .manual, ratios: [3.760, 2.269, 1.645, 1.257, 1.000, 0.843], reverse: 3.437, shiftTimeS: 0.45, stallRpm: 0, lockupGear: 2, maxInputTorqueNm: 700, cvtRatioRange: nil)
        case .seq6:
            // Close-ratio sequential. Reverse is a placeholder (not in the brief).
            GearboxSpec(kind: .sequential, ratios: [2.92, 2.05, 1.58, 1.28, 1.07, 0.92], reverse: 3.0, shiftTimeS: 0.08, stallRpm: 0, lockupGear: 2, maxInputTorqueNm: 800, cvtRatioRange: nil)
        case .dct7:
            // Seven-speed dual-clutch, DQ500 class. Game-tuned, based on public ratio data.
            GearboxSpec(kind: .dualClutch, ratios: [3.765, 2.273, 1.531, 1.133, 0.939, 0.795, 0.670], reverse: 3.6, shiftTimeS: 0.06, stallRpm: 0, lockupGear: 2, maxInputTorqueNm: 700, cvtRatioRange: nil)
        case .auto4:
            // Four-speed torque converter, 4L60E class. Game-tuned, based on public ratio data.
            GearboxSpec(kind: .torqueConverter, ratios: [3.059, 1.625, 1.000, 0.696], reverse: 2.294, shiftTimeS: 0.35, stallRpm: 2200, lockupGear: 2, maxInputTorqueNm: 600, cvtRatioRange: nil)
        case .auto8:
            // Eight-speed torque converter, ZF 8HP class. Game-tuned, based on public ratio data.
            GearboxSpec(kind: .torqueConverter, ratios: [4.696, 3.130, 2.104, 1.667, 1.285, 1.000, 0.839, 0.667], reverse: 3.317, shiftTimeS: 0.20, stallRpm: 2200, lockupGear: 2, maxInputTorqueNm: 800, cvtRatioRange: nil)
        case .auto10:
            // Ten-speed torque converter, 10R80 class. Game-tuned, based on public ratio data.
            GearboxSpec(kind: .torqueConverter, ratios: [4.696, 2.985, 2.146, 1.769, 1.520, 1.275, 1.000, 0.854, 0.689, 0.636], reverse: 4.866, shiftTimeS: 0.18, stallRpm: 2200, lockupGear: 2, maxInputTorqueNm: 900, cvtRatioRange: nil)
        case .cvt:
            // Continuous ratio. The ratios are the two ends of cvtRatioRange; no fixed gears.
            GearboxSpec(kind: .cvt, ratios: [2.6, 0.4], reverse: 2.6, shiftTimeS: 0, stallRpm: 0, lockupGear: 2, maxInputTorqueNm: 500, cvtRatioRange: 0.4...2.6)
        case .ev1:
            // Single reduction for an electric motor. Game-tuned: the car uses this ratio alone,
            // without a final drive.
            GearboxSpec(kind: .direct, ratios: [9.03], reverse: 9.03, shiftTimeS: 0, stallRpm: 0, lockupGear: 1, maxInputTorqueNm: 1200, cvtRatioRange: nil)
        }
    }
}
