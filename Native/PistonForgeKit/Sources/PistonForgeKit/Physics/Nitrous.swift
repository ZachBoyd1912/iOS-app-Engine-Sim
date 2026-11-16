import Foundation

/// Air-equivalent oxygen per rated horsepower of shot, g/s. Calibrated so a shot adds about
/// its rated power on a matching tune.
let nitrousAirPerHp = 0.70

/// What a spraying kit adds regardless of conditions: oxygen (as air-equivalent g/s) and, for
/// a wet kit, its own fuel at λ 0.8.
func nitrousCharge(_ b: EngineBuild, kit: NitrousKit) -> (oxygenGps: Double, addedFuelGps: Double) {
    let oxygen = bounded(kit.shotHp, NitrousKit.shotRange, or: 100) * nitrousAirPerHp
    let fuel = kit.kind == .wet ? oxygen / (b.fuel.spec.stoichAfr * 0.8) : 0
    return (oxygen, fuel)
}

/// Fuel a dry kit needs the ECU to add through the injectors while it sprays, g/s.
func dryNitrousFuelGps(_ b: EngineBuild, kit: NitrousKit) -> Double {
    kit.kind == .dry ? nitrousCharge(b, kit: kit).oxygenGps / (b.fuel.spec.stoichAfr * 0.8) : 0
}

/// Oxygen (as air-equivalent g/s) and wet-kit fuel the nitrous adds right now. Nothing unless
/// the kit is enabled, the rpm is at or above its arming rpm, and the throttle is inside the
/// map's nitrous window.
public func nitrousExtra(_ b: EngineBuild, rpm: Double, throttle: Double) -> (oxygenGps: Double, addedFuelGps: Double) {
    guard nitrousCanSpray(b, rpm: rpm, throttle: throttle), let kit = b.nitrous else { return (0, 0) }
    return nitrousCharge(b, kit: kit)
}

func nitrousCanSpray(_ b: EngineBuild, rpm: Double, throttle: Double) -> Bool {
    guard let kit = b.nitrous, kit.enabled else { return false }
    let speed = bounded(rpm, 0...30_000)
    let pedal = bounded(throttle, 0...1)
    return speed >= bounded(kit.armRpm, NitrousKit.armRpmRange, or: 3000) && b.ecu.nitrousWindow.contains(pedal)
}
