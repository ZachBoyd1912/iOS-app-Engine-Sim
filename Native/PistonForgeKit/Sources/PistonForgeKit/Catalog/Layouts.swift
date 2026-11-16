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
    /// Crank phase of each cylinder: the crank angle (degrees, 0..<360) at which it reaches top
    /// dead centre, indexed by cylinder number - 1. The 3D crank and pistons are posed from it.
    public let crankPins: [Double]
}

extension EngineLayout {
    /// Built once; the simulation reads it hundreds of times a second.
    private static let table: [EngineLayout: LayoutSpec] = Dictionary(uniqueKeysWithValues: allCases.map { ($0, $0.makeSpec()) })

    public var spec: LayoutSpec { Self.table[self] ?? makeSpec() }

    private func makeSpec() -> LayoutSpec {
        switch self {
        case .i3:
            LayoutSpec.make(name: "Inline 3", bankAngle: 0, order: [1, 2, 3], gaps: [240], bank: { _ in 0 })
        case .i4:
            LayoutSpec.make(name: "Inline 4", bankAngle: 0, order: [1, 3, 4, 2], gaps: [180], bank: { _ in 0 })
        case .i6:
            LayoutSpec.make(name: "Inline 6", bankAngle: 0, order: [1, 5, 3, 6, 2, 4], gaps: [120], bank: { _ in 0 })
        case .v6_60:
            // Odd cylinders left, even right; even fire every 120 degrees.
            LayoutSpec.make(name: "V6 60°", bankAngle: 60, order: [1, 2, 3, 4, 5, 6], gaps: [120], bank: { ($0 - 1) % 2 })
        case .v6_90:
            // Odd-fire 90-degree V6 on offset (split) pins: intervals alternate 90 and 150.
            LayoutSpec.make(name: "V6 90° odd-fire", bankAngle: 90, order: [1, 6, 5, 4, 3, 2], gaps: [90, 150], bank: { ($0 - 1) % 2 })
        case .v8Cross:
            // Odd cylinders left, even right. Bank sequence L,R,R,L,R,L,L,R gives the burble.
            LayoutSpec.make(name: "V8 cross-plane", bankAngle: 90, order: [1, 8, 4, 3, 6, 5, 7, 2], gaps: [90], bank: { ($0 - 1) % 2 })
        case .v8Flat:
            // Cylinders 1-4 left, 5-8 right; firing strictly alternates banks.
            LayoutSpec.make(name: "V8 flat-plane", bankAngle: 90, order: [1, 8, 2, 7, 4, 5, 3, 6], gaps: [90], bank: { $0 <= 4 ? 0 : 1 })
        case .v10:
            // L1-R1-L5-R5-L2-R2-L3-R3-L4-R4 with left = 1-5 and right = 6-10, every 72 degrees.
            LayoutSpec.make(name: "V10 72°", bankAngle: 72, order: [1, 6, 5, 10, 2, 7, 3, 8, 4, 9], gaps: [72], bank: { $0 <= 5 ? 0 : 1 })
        case .v12:
            // Cylinders 1-6 left, 7-12 right; every 60 degrees, alternating banks.
            LayoutSpec.make(name: "V12 60°", bankAngle: 60, order: [1, 7, 5, 11, 3, 9, 6, 12, 2, 8, 4, 10], gaps: [60], bank: { $0 <= 6 ? 0 : 1 })
        case .w16:
            // Our own generic W16: four banks of four (1-4, 5-8, 9-12, 13-16), even 45-degree
            // fire, each bank running an inline-four 1-3-4-2 sequence, banks taken 0,2,1,3.
            LayoutSpec.make(
                name: "W16 four-bank",
                bankAngle: 90,
                order: [1, 9, 5, 13, 3, 11, 7, 15, 4, 12, 8, 16, 2, 10, 6, 14],
                gaps: [45],
                bank: { ($0 - 1) / 4 }
            )
        }
    }
}

extension LayoutSpec {
    /// Builds a spec from a firing order and a repeating pattern of firing gaps.
    /// `bank` maps a 1-based cylinder number to its 0-based bank.
    static func make(name: String, bankAngle: Double, order: [Int], gaps: [Double], bank: (Int) -> Int) -> LayoutSpec {
        let count = order.count
        var angles: [Double] = []
        var angle = 0.0
        for index in 0..<count {
            angles.append(angle)
            angle += gaps[index % gaps.count]
        }
        let bankOf = (1...count).map(bank)
        var pins = Array(repeating: 0.0, count: count)
        for (index, cylinder) in order.enumerated() {
            pins[cylinder - 1] = angles[index].truncatingRemainder(dividingBy: 360)
        }
        return LayoutSpec(
            name: name,
            cylinders: count,
            banks: (bankOf.max() ?? 0) + 1,
            bankAngle: bankAngle,
            firingOrder: order,
            firingAngles: angles,
            bankOf: bankOf,
            crankPins: pins
        )
    }
}
