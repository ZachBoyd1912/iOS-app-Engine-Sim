import Foundation

public enum Drivetrain: String, Codable, CaseIterable, Sendable {
    case fwd, rwd, awd
}

/// Fixed facts about a car body.
public struct CarSpec: Sendable {
    public let name: String
    public let drivetrain: Drivetrain
    /// Kerb mass without the engine's extra weight, kg.
    public let massKg: Double
    /// Inside size of the engine bay, mm.
    public let bayMm: (length: Double, width: Double, height: Double)
    public let wheelbaseM: Double
    public let cgHeightM: Double
    /// Share of the weight on the front axle.
    public let frontWeight: Double
    /// Drag coefficient times frontal area, m².
    public let cdA: Double
}

/// Our own five car bodies; none is based on a real car.
public enum CarBody: String, Codable, CaseIterable, Sendable {
    case hatch, coupe, muscle, pickup, super_

    public var spec: CarSpec {
        switch self {
        case .hatch:
            CarSpec(name: "Pocket Hatch", drivetrain: .fwd, massKg: 1050, bayMm: (720, 760, 700), wheelbaseM: 2.5, cgHeightM: 0.52, frontWeight: 0.62, cdA: 0.68)
        case .coupe:
            CarSpec(name: "Grand Coupe", drivetrain: .rwd, massKg: 1350, bayMm: (950, 950, 700), wheelbaseM: 2.7, cgHeightM: 0.48, frontWeight: 0.52, cdA: 0.62)
        case .muscle:
            CarSpec(name: "Muscle", drivetrain: .rwd, massKg: 1550, bayMm: (900, 1050, 820), wheelbaseM: 2.85, cgHeightM: 0.53, frontWeight: 0.56, cdA: 0.78)
        case .pickup:
            CarSpec(name: "Pickup", drivetrain: .rwd, massKg: 1850, bayMm: (1000, 1100, 900), wheelbaseM: 3.3, cgHeightM: 0.7, frontWeight: 0.55, cdA: 1.1)
        case .super_:
            CarSpec(name: "Mid-engine Super", drivetrain: .awd, massKg: 1400, bayMm: (1000, 1400, 720), wheelbaseM: 2.7, cgHeightM: 0.42, frontWeight: 0.42, cdA: 0.58)
        }
    }
}

public enum Gearbox: String, Codable, CaseIterable, Sendable {
    case m5, m6, seq6, auto8
}

public struct Tyre: Codable, Equatable, Sendable {
    public enum Compound: String, Codable, CaseIterable, Sendable {
        case street, sport, semiSlick, dragRadial
    }

    public var compound: Compound
    public var widthMm: Double

    public init(compound: Compound, widthMm: Double) {
        self.compound = compound
        self.widthMm = widthMm
    }
}

/// The car the engine goes into.
public struct CarSetup: Codable, Equatable, Sendable {
    public var body: CarBody
    public var gearbox: Gearbox
    public var finalDrive: Double
    public var tyre: Tyre

    public init(body: CarBody, gearbox: Gearbox, finalDrive: Double, tyre: Tyre) {
        self.body = body
        self.gearbox = gearbox
        self.finalDrive = finalDrive
        self.tyre = tyre
    }
}
