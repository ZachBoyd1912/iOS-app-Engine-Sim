import Foundation

/// Every engine layout in the game. Raw values are the save format.
public enum EngineLayout: String, Codable, CaseIterable, Sendable {
    case i3, i4, i6, v6_60, v6_90, v8Cross, v8Flat, v10, v12, w16
}

/// Static description of a layout: how many cylinders, how they sit, and when they fire.
public struct LayoutSpec: Sendable {
    public let name: String
    public let cylinders: Int
    public let banks: Int
    /// Angle between banks in degrees (0 for inline).
    public let bankAngle: Double
    /// Cylinder numbers (1-based) in firing order.
    public let firingOrder: [Int]
    /// Crank degrees (0..<720) of each firing event, in firing order.
    public let firingAngles: [Double]
    /// 0-based bank of each cylinder, indexed by cylinder number - 1.
    public let bankOf: [Int]
    /// Crank pin angle (degrees, 0..<360) of each cylinder, indexed by cylinder number - 1.
    public let crankPins: [Double]
}

extension EngineLayout {
    // RED stub: replaced by the real table in the next commit.
    public var spec: LayoutSpec {
        LayoutSpec(name: "", cylinders: 0, banks: 0, bankAngle: 0, firingOrder: [], firingAngles: [], bankOf: [], crankPins: [])
    }
}
