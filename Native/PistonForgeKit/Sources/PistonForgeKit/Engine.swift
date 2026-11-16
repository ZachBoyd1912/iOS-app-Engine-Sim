import Foundation

/// Engine layouts. Raw values match the save format and the golden fixtures.
public enum EngineLayout: String, Codable, Sendable, CaseIterable {
    case i3, i4, i6, v6, v8, v10, v12, flat4, rotary2, rotary3

    public var cylinders: Int {
        switch self {
        case .i3: 3
        case .i4, .flat4: 4
        case .i6, .v6: 6
        case .v8: 8
        case .v10: 10
        case .v12: 12
        case .rotary2: 2
        case .rotary3: 3
        }
    }

    public var rotors: Int {
        switch self {
        case .rotary2: 2
        case .rotary3: 3
        default: 0
        }
    }

    public var isRotary: Bool { rotors > 0 }
}

/// The parts of an engine build that the model reads. Ported from the TypeScript sim
/// (`src/sim/types.ts` EngineConfig); more fields arrive as more of the model is ported.
public struct EngineConfig: Codable, Sendable, Equatable {
    public var layout: EngineLayout
    public var name: String
    /// Bore in mm (for a rotary: rotor width proxy, see `displacementCc`).
    public var bore: Double
    /// Stroke in mm (for a rotary: eccentric proxy).
    public var stroke: Double
    public var compression: Double

    public init(layout: EngineLayout, name: String, bore: Double, stroke: Double, compression: Double) {
        self.layout = layout
        self.name = name
        self.bore = bore
        self.stroke = stroke
        self.compression = compression
    }
}

public enum EngineModel {
    /// Reference rotary chamber: 654 cc per rotor at bore 80, stroke 75.
    static let rotaryChamberCc = 654.0
    static let rotaryReferenceBore = 80.0
    static let rotaryReferenceStroke = 75.0

    /// Swept volume in cc. Pistons: pi/4 x bore^2 x stroke x cylinders.
    /// Rotaries scale the reference chamber linearly with bore and by the square of stroke.
    public static func displacementCc(_ config: EngineConfig) -> Double {
        let layout = config.layout
        if layout.isRotary {
            return rotaryChamberCc * Double(layout.rotors)
                * (config.bore / rotaryReferenceBore)
                * pow(config.stroke / rotaryReferenceStroke, 2)
        }
        return Double.pi / 4 * config.bore * config.bore * config.stroke * Double(layout.cylinders) / 1000
    }
}
