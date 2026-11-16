import Foundation

/// How the ECU measures the air it fuels for.
public enum FuelStrategy: String, Codable, CaseIterable, Sendable {
    /// Reads the mass airflow sensor; clips past its maximum.
    case maf
    /// Estimates air from manifold pressure, rpm and temperature.
    case speedDensity
}

/// What happened when the ECU fuelled one moment of running.
public struct FuelResult: Equatable, Sendable {
    /// The AFR the ECU was aiming for.
    public let commandedAfr: Double
    /// The AFR the engine actually got.
    public let actualAfr: Double
    /// Injector duty cycle the ECU asked for, 0...1.
    public let injectorDuty: Double
    public let pumpLimited: Bool
    public let mafClipped: Bool
    /// Fuel actually delivered, g/s.
    public let deliveredFuelGps: Double
}

/// Fuel the ECU delivers for `airflowGps` of real air. RED stub.
public func deliverFuel(_ b: EngineBuild, strategy: FuelStrategy, airflowGps: Double, rpm: Double, targetAfr: Double, closedLoopTrim: Double) -> FuelResult {
    FuelResult(commandedAfr: 0, actualAfr: 0, injectorDuty: 0, pumpLimited: false, mafClipped: false, deliveredFuelGps: 0)
}
