import Foundation

/// Everything about the engine at one rpm, throttle and boost: the single chain that the tests,
/// the auto-base tune, the running simulation and the dyno all share.
public struct OperatingPoint: Equatable, Sendable {
    public let rpm: Double
    public let throttle: Double
    public let boostPsi: Double
    public let chargeTempC: Double
    public let airflowGps: Double
    public let loadKpa: Double
    public let fuel: FuelResult
    public let combustion: CombustionResult
    public let nitrousActive: Bool
    /// Friction torque, Nm.
    public let frictionNm: Double
    /// Supercharger drive torque, Nm.
    public let parasiticNm: Double
    /// Torque at the crank after friction and accessory drag, Nm (negative when it drags).
    public let brakeTorqueNm: Double

    /// Power at the crank, hp.
    public var brakeHp: Double { brakeTorqueNm * rpm * 2 * Double.pi / 60 / 745.7 }
}

/// Friction torque from mean friction pressure, which rises with rpm, Nm.
func frictionTorqueNm(_ b: EngineBuild, rpm: Double) -> Double {
    let krpm = bounded(rpm, 0...30_000) / 1000
    let fmepBar = 0.4 + 0.12 * krpm + 0.025 * krpm * krpm
    return fmepBar * 100_000 * b.displacementCc / 1_000_000 / (4 * Double.pi)
}

/// Runs the chain: charge temperature, airflow, load, the map's AFR target, fuel delivery
/// (with dry-nitrous enrichment), combustion, then friction and supercharger drag.
///
/// `nitrousArmed` is the player's arming switch; the kit sprays only if it is also enabled and
/// within its rpm and throttle window.
public func operatingPoint(
    _ b: EngineBuild, rpm: Double, throttle: Double, boostPsi: Double, nitrousArmed: Bool,
    closedLoopTrim: Double, ambientC: Double = 25
) -> OperatingPoint {
    let speed = bounded(rpm, 0...30_000)
    let pedal = bounded(throttle, 0...1)
    let boost = bounded(boostPsi, 0...60)
    let heat = chargeTempC(b, boostPsi: boost, ambientC: ambientC)
    let air = airflowGps(b, rpm: speed, throttle: pedal, boostPsi: boost, chargeTempC: heat)
    let load = loadKpa(b, rpm: speed, airflowGps: air)
    let target = b.ecu.value(\.afrTable, rpm: speed, loadKpa: load)

    let spraying = nitrousArmed && nitrousCanSpray(b, rpm: speed, throttle: pedal)
    var enrichment = 0.0
    if spraying, let kit = b.nitrous {
        enrichment = dryNitrousFuelGps(b, kit: kit) * bounded(b.ecu.nitrousEnrichment, 0...1.5)
    }
    let fuel = deliverFuel(
        b, strategy: b.ecu.strategy, airflowGps: air, rpm: speed, targetAfr: target,
        closedLoopTrim: closedLoopTrim, extraFuelGps: enrichment
    )
    let burn = combust(b, rpm: speed, airflowGps: air, fuel: fuel, boostPsi: boost, iatC: heat, nitrousActive: spraying)

    let friction = frictionTorqueNm(b, rpm: speed)
    let omega = speed * 2 * Double.pi / 60
    let parasitic = omega > 1 ? parasiticLossHp(b, rpm: speed, boost: boost) * 745.7 / omega : 0
    return OperatingPoint(
        rpm: speed, throttle: pedal, boostPsi: boost, chargeTempC: heat, airflowGps: air, loadKpa: load,
        fuel: fuel, combustion: burn, nitrousActive: spraying,
        frictionNm: friction, parasiticNm: parasitic, brakeTorqueNm: burn.torqueNm - friction - parasitic
    )
}

/// Injector size (cc/min per cylinder, at 80% duty) and pump size (L/h, at 85% load) needed to
/// fuel `b` at redline, wide open, on `boostPsi`, including a dry nitrous kit's fuel.
public func fuelSystemNeeds(_ b: EngineBuild, boostPsi: Double) -> (injectorCcMin: Double, pumpLph: Double) {
    let spec = b.fuel.spec
    let rpm = b.mechanicalRedline
    let boost = bounded(boostPsi, 0...60)
    let air = airflowGps(b, rpm: rpm, throttle: 1, boostPsi: boost, chargeTempC: chargeTempC(b, boostPsi: boost))
    let load = loadKpa(b, rpm: rpm, airflowGps: air)
    var fuel = air / (ECUMap.baseLambda(loadKpa: load) * spec.stoichAfr)
    if let kit = b.nitrous { fuel += dryNitrousFuelGps(b, kit: kit) }
    let cylinders = Double(b.layout.spec.cylinders)
    return (fuel / 0.8 / cylinders / spec.density * 60, fuel / 0.85 / spec.density * 3.6)
}

extension EngineBuild {
    /// The same build with injectors and pump sized for what it will make: the turbo's
    /// knock-limited boost, a supercharger's boost at redline, or none. Sizes round up to
    /// 10 cc/min and 5 L/h, within the parts' ranges.
    public func withFuelSystemSized() -> EngineBuild {
        var build = self
        let boost: Double = switch induction {
        case .natural: 0
        case .turbo: ECUMap.knockLimitedBoost(for: self)
        case .supercharger: steadyBoostPsi(self, rpm: mechanicalRedline, throttle: 1, target: 0)
        }
        let needs = fuelSystemNeeds(self, boostPsi: boost)
        build.parts.injectorCcMin = min(max((needs.injectorCcMin / 10).rounded(.up) * 10, PartChoices.injectorRange.lowerBound), PartChoices.injectorRange.upperBound)
        build.parts.pumpLph = min(max((needs.pumpLph / 5).rounded(.up) * 5, PartChoices.pumpRange.lowerBound), PartChoices.pumpRange.upperBound)
        return build
    }
}
