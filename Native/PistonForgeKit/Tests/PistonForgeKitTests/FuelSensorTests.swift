import Testing
@testable import PistonForgeKit

private func target(_ fuel: Fuel) -> Double { fuel.spec.stoichAfr * 0.85 }

@Test func airflowFollowsRpmBoostAndHeat() {
    let build = EngineBuild.starter(.i4)
    let base = airflowGps(build, rpm: 4000, throttle: 1, boostPsi: 0, chargeTempC: 25)
    #expect(base > 30 && base < 150, "2.0 at 4000 rpm: \(base) g/s")
    #expect(airflowGps(build, rpm: 4000, throttle: 1, boostPsi: 14.7, chargeTempC: 25) > 1.8 * base)
    #expect(airflowGps(build, rpm: 4000, throttle: 1, boostPsi: 0, chargeTempC: 90) < base)
    #expect(airflowGps(build, rpm: 4000, throttle: 0, boostPsi: 0, chargeTempC: 25) < 0.2 * base)
}

@Test func smallInjectorsLeanOutAtTop() {
    var build = EngineBuild.starter(.i4)
    build.induction = .turbo(.medium)
    build.parts.injectorCcMin = 300
    build.parts.pumpLph = 1000
    let air = airflowGps(build, rpm: 7000, throttle: 1, boostPsi: 25, chargeTempC: 60)
    let afr = target(build.fuel)
    let result = deliverFuel(build, strategy: .speedDensity, airflowGps: air, rpm: 7000, targetAfr: afr, closedLoopTrim: 0)
    #expect(result.injectorDuty > 0.85, "duty \(result.injectorDuty)")
    #expect(result.actualAfr > result.commandedAfr + 1.0, "commanded \(result.commandedAfr), actual \(result.actualAfr)")
}

@Test func mafClipsAndLeans() {
    var build = EngineBuild.starter(.v8Cross)
    build.sensors.maf = .small
    build.parts.injectorCcMin = 2400
    build.parts.pumpLph = 1000
    let reading = mafReading(build, airflowGps: 300)
    #expect(reading.clipped)
    #expect(reading.gps == MafSize.small.maxGps)
    let afr = target(build.fuel)
    let maf = deliverFuel(build, strategy: .maf, airflowGps: 300, rpm: 6000, targetAfr: afr, closedLoopTrim: 0)
    #expect(maf.mafClipped)
    #expect(maf.actualAfr > afr + 0.5, "MAF strategy: \(maf.actualAfr) vs target \(afr)")
    let sd = deliverFuel(build, strategy: .speedDensity, airflowGps: 300, rpm: 6000, targetAfr: afr, closedLoopTrim: 0)
    #expect(sd.actualAfr <= afr + 0.05, "speed-density: \(sd.actualAfr) vs target \(afr)")
    #expect(!mafReading(build, airflowGps: 150).clipped)
}

@Test func widebandCorrects() {
    var build = EngineBuild.starter(.i6)
    build.sensors.map = false // speed-density without a MAP sensor guesses low and runs lean
    build.parts.injectorCcMin = 2400
    build.parts.pumpLph = 1000
    let afr = target(build.fuel)
    build.sensors.wideband = false
    let open = deliverFuel(build, strategy: .speedDensity, airflowGps: 150, rpm: 5000, targetAfr: afr, closedLoopTrim: 0.05)
    let openNoTrim = deliverFuel(build, strategy: .speedDensity, airflowGps: 150, rpm: 5000, targetAfr: afr, closedLoopTrim: 0)
    #expect(open.actualAfr > afr, "no MAP sensor should run lean")
    #expect(abs(open.actualAfr - openNoTrim.actualAfr) < 0.0001, "without a wideband the trim is ignored")
    build.sensors.wideband = true
    let closed = deliverFuel(build, strategy: .speedDensity, airflowGps: 150, rpm: 5000, targetAfr: afr, closedLoopTrim: 0.05)
    #expect(abs(closed.actualAfr - afr) < abs(open.actualAfr - afr))
}

@Test func pumpLimits() {
    var build = EngineBuild.starter(.v8Cross)
    build.parts.injectorCcMin = 2400
    build.parts.pumpLph = 150
    // About 900 hp of air.
    let result = deliverFuel(build, strategy: .speedDensity, airflowGps: 680, rpm: 6500, targetAfr: 12, closedLoopTrim: 0)
    #expect(result.pumpLimited)
    #expect(result.actualAfr > 12.5)
    build.parts.pumpLph = 1000
    #expect(!deliverFuel(build, strategy: .speedDensity, airflowGps: 680, rpm: 6500, targetAfr: 12, closedLoopTrim: 0).pumpLimited)
}

@Test func e85NeedsMoreFuel() {
    var build = EngineBuild.starter(.v8Cross)
    build.parts.injectorCcMin = 2400
    build.parts.pumpLph = 1000
    build.fuel = .pump98
    let petrol = deliverFuel(build, strategy: .speedDensity, airflowGps: 300, rpm: 5000, targetAfr: target(.pump98), closedLoopTrim: 0)
    build.fuel = .e85
    let ethanol = deliverFuel(build, strategy: .speedDensity, airflowGps: 300, rpm: 5000, targetAfr: target(.e85), closedLoopTrim: 0)
    let ratio = ethanol.deliveredFuelGps / petrol.deliveredFuelGps
    #expect(ratio >= 1.35 && ratio <= 1.51, "E85 / pump98 fuel mass: \(ratio)")
}

@Test func fuelNeverProducesNonNumbers() {
    var build = EngineBuild.starter(.w16)
    build.parts.injectorCcMin = 150
    for air in [0, 1e-9, 5000, Double.nan, .infinity] {
        for trim in [0, Double.nan, 9] {
            let result = deliverFuel(build, strategy: .maf, airflowGps: air, rpm: 6000, targetAfr: 12, closedLoopTrim: trim)
            for value in [result.commandedAfr, result.actualAfr, result.injectorDuty, result.deliveredFuelGps] {
                #expect(value.isFinite, "air \(air) trim \(trim)")
            }
        }
    }
}
