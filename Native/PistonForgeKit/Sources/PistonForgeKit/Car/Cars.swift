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

    /// RED stub.
    public var spec: CarSpec {
        CarSpec(name: "", drivetrain: .rwd, massKg: 0, bayMm: (0, 0, 0), wheelbaseM: 0, cgHeightM: 0, frontWeight: 0, cdA: 0)
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
