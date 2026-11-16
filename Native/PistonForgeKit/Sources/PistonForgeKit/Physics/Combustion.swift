import Foundation

/// The outcome of burning one moment's air and fuel.
public struct CombustionResult: Equatable, Sendable {
    /// Indicated (gross) torque before friction and accessory drag, Nm.
    public let torqueNm: Double
    /// 0...2; 1 or more is detonation.
    public let knockIndex: Double
    /// Exhaust gas temperature, °C.
    public let egtC: Double
    /// Timing actually used after any knock-sensor retard, degrees before TDC.
    public let timingDeg: Double
    /// Timing for best torque at this point, degrees before TDC.
    public let mbtDeg: Double
    /// Air-fuel ratio in the cylinder, counting oxygen from nitrous and fuel from a wet kit.
    public let afr: Double
    /// Timing the map asked for (after nitrous retard), before any knock-sensor retard.
    public let mapTimingDeg: Double
}

/// Engine load as a manifold pressure, kPa: 101.3 at wide-open throttle without boost, more
/// with boost, less at part throttle. The tune tables are looked up on this.
public func loadKpa(_ b: EngineBuild, rpm: Double, airflowGps: Double) -> Double {
    let reference = intakeAirGps(b, rpm: rpm, throttle: 1, boostPsi: 0, chargeTempC: 25)
    guard reference > 1e-9 else { return 0 }
    return bounded(101.3 * airflowGps / reference, 0...600)
}

/// Spark timing for best torque (MBT), degrees: more with rpm and bigger cams, less with boost.
public func mbtDegrees(_ b: EngineBuild, rpm: Double, loadKpa: Double) -> Double {
    let fraction = min(bounded(rpm, 0...30_000) / b.mechanicalRedline, 1)
    let boosted = max(0, bounded(loadKpa, 0...600) - 100)
    return bounded(18 + 14 * fraction + Double(b.parts.cams) - boosted * 0.04, 10...40, or: 20)
}

/// Most timing the engine takes before it starts to knock, degrees. Higher octane and rpm
/// raise it; compression, boost, charge heat and nitrous lower it.
public func knockLimitDegrees(_ b: EngineBuild, rpm: Double, loadKpa: Double, iatC: Double, nitrousHpPerCylinder: Double) -> Double {
    let fraction = min(bounded(rpm, 0...30_000) / b.mechanicalRedline, 1)
    let limit = 12 + (b.fuel.spec.octane - 90)
        + 14 * fraction
        - (b.compression - 10) * 2.5
        - max(0, bounded(loadKpa, 0...600) - 100) * 0.09
        - max(0, bounded(iatC, -40...300, or: 25) - 30) * 0.08
        - bounded(nitrousHpPerCylinder, 0...100) * 0.4
    return bounded(limit, -30...60)
}

/// Indicated thermal efficiency from the compression ratio (an Otto-cycle shape, scaled).
func thermalEfficiency(_ b: EngineBuild) -> Double {
    0.8 * (1 - pow(bounded(b.compression, EngineBuild.compressionRange, or: 10), -0.3))
}

/// Burns the delivered fuel in the measured air at the map's timing.
///
/// Only fuel that has oxygen to burn makes power; past MBT either way loses torque; much richer
/// than λ 0.82 bogs. Knock comes from timing past the knock limit, a lean mixture under load,
/// and very hot intake air. With a knock sensor fitted, the ECU pulls up to 12° once the knock
/// index passes 0.5. A nitrous shot adds oxygen (and fuel from a wet kit) and lowers the knock
/// limit; the map's nitrous retard applies while it sprays.
public func combust(_ b: EngineBuild, rpm: Double, airflowGps: Double, fuel: FuelResult, boostPsi: Double, iatC: Double, nitrousActive: Bool) -> CombustionResult {
    let speed = bounded(rpm, 0...30_000)
    let air = bounded(airflowGps, 0...5000)
    let iat = bounded(iatC, -40...300, or: 25)
    let spec = b.fuel.spec
    let load = loadKpa(b, rpm: speed, airflowGps: air)

    var nitrousAir = 0.0
    var nitrousFuel = 0.0
    var nitrousPerCylinder = 0.0
    if nitrousActive, let kit = b.nitrous {
        let charge = nitrousCharge(b, kit: kit)
        nitrousAir = charge.oxygenGps
        nitrousFuel = charge.addedFuelGps
        nitrousPerCylinder = kit.shotHp / Double(b.layout.spec.cylinders)
    }
    let totalAir = air + nitrousAir
    let totalFuel = bounded(fuel.deliveredFuelGps, 0...500) + nitrousFuel
    let lambda = totalFuel > 1e-9 ? min(totalAir / totalFuel / spec.stoichAfr, 3) : 3

    let mbt = mbtDegrees(b, rpm: speed, loadKpa: load)
    let limit = knockLimitDegrees(b, rpm: speed, loadKpa: load, iatC: iat, nitrousHpPerCylinder: nitrousPerCylinder)
    let retard = nitrousActive ? bounded(b.ecu.nitrousRetardDeg, 0...30) : 0
    let mapTiming = bounded(b.ecu.value(\.ignitionTable, rpm: speed, loadKpa: load), -10...50) - retard

    func knock(_ timing: Double) -> Double {
        let spark = max(0, (timing - limit + 3) / 7)
        let lean = max(0, lambda - 0.92) * 8 * min(load / 100, 2.5)
        let heat = max(0, iat - 80) * 0.01
        return bounded(spark + lean + heat, 0...2)
    }
    var timing = mapTiming
    var knockIndex = knock(timing)
    if b.sensors.knock, knockIndex > 0.5 {
        timing -= min(12, (knockIndex - 0.5) * 16)
        knockIndex = knock(timing)
    }

    let burnt = min(totalFuel, totalAir / spec.stoichAfr)
    let offMbt = timing - mbt
    let efficiency = max(0, thermalEfficiency(b) * (1 - 0.0005 * offMbt * offMbt) * (1 - max(0, 0.82 - lambda) * 0.9))
    let powerW = burnt * spec.heatKJPerGram * efficiency * 1000
    let omega = speed * 2 * Double.pi / 60
    let torque = omega > 1 ? powerW / omega : 0

    let egt = 400 + 250 * min(speed / b.mechanicalRedline, 1)
        + 1.2 * max(0, load - 100)
        + 900 * max(0, lambda - 0.86)
        + 4 * max(0, mbt - timing)
        - 600 * max(0, 0.86 - lambda)
    return CombustionResult(
        torqueNm: torque,
        knockIndex: knockIndex,
        egtC: bounded(egt, 0...1400),
        timingDeg: timing,
        mbtDeg: mbt,
        afr: lambda * spec.stoichAfr,
        mapTimingDeg: mapTiming
    )
}
