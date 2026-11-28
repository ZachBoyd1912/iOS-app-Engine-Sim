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

/// Fuel the ECU delivers for `airflowGps` of real air.
///
/// The ECU fuels for the air it *measures*: the MAF reading (clipped past its maximum) or a
/// speed-density estimate, which guesses 8% low without a MAP sensor because it cannot see
/// manifold pressure. A wideband applies `closedLoopTrim` (limited to ±25%); without one the
/// trim is ignored. Injectors deliver what is asked up to 85% duty, then flatten out toward
/// 92%; the pump caps the rest. The actual AFR is the real air over the fuel delivered.
/// `extraFuelGps` is fuel the ECU adds on top through the injectors (dry-nitrous enrichment).
public func deliverFuel(
    _ b: EngineBuild, strategy: FuelStrategy, airflowGps: Double, rpm: Double, targetAfr: Double,
    closedLoopTrim: Double, extraFuelGps: Double = 0
) -> FuelResult {
    let spec = b.fuel.spec
    let air = bounded(airflowGps, 0...5000)
    let target = bounded(targetAfr, 5...25, or: spec.stoichAfr * 0.85)

    var measured = air * (b.sensors.map ? 1 : 0.92)
    var clipped = false
    if strategy == .maf, b.sensors.maf != nil {
        let reading = mafReading(b, airflowGps: air)
        measured = reading.gps
        clipped = reading.clipped
    }

    let trim = b.sensors.wideband ? bounded(closedLoopTrim, -0.25...0.25) : 0
    let wanted = measured / target * (1 + trim) + bounded(extraFuelGps, 0...500)

    let injectorCapacity = b.parts.injectorCcMin * Double(b.layout.spec.cylinders) * spec.density / 60
    let duty = injectorCapacity > 0 ? wanted / injectorCapacity : 1
    var delivered = duty <= 0.85
        ? wanted
        : injectorCapacity * (0.85 + 0.07 * (1 - exp(-(duty - 0.85) / 0.07)))

    let pumpCapacity = b.parts.pumpLph * spec.density / 3.6
    let pumpLimited = delivered > pumpCapacity
    delivered = min(delivered, pumpCapacity)

    let actual: Double = if delivered > 1e-6 {
        min(air / delivered, 30)
    } else {
        air > 0 ? 30 : target
    }
    return FuelResult(
        commandedAfr: target,
        actualAfr: actual,
        injectorDuty: bounded(duty, 0...1, or: 1),
        pumpLimited: pumpLimited,
        mafClipped: clipped,
        deliveredFuelGps: delivered
    )
}
