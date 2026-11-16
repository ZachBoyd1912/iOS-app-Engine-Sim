import Testing
@testable import PistonForgeKit

private let inductions: [Induction] = [.natural]
    + TurboSize.allCases.map { Induction.turbo($0) }
    + SuperchargerKind.allCases.map { Induction.supercharger($0, pulley: 1) }

/// A build with this induction and fuel, its fuel system sized to match, on the auto-base map.
private func tuned(_ layout: EngineLayout, _ induction: Induction, _ fuel: Fuel) -> EngineBuild {
    var build = EngineBuild.starter(layout)
    build.induction = induction
    build.fuel = fuel
    build = build.withFuelSystemSized()
    build.ecu = ECUMap.autoBase(for: build)
    return build
}

private func fullLoad(_ build: EngineBuild, rpm: Double, nitrous: Bool = false) -> OperatingPoint {
    let boost = steadyBoostPsi(build, rpm: rpm, throttle: 1, target: build.ecu.boostTargetPsi)
    return operatingPoint(build, rpm: rpm, throttle: 1, boostPsi: boost, nitrousArmed: nitrous, closedLoopTrim: 0)
}

/// The same build with every ignition cell set to `degrees`.
private func flatTiming(_ build: EngineBuild, _ degrees: Double) -> EngineBuild {
    var copy = build
    copy.ecu.ignitionTable = copy.ecu.ignitionTable.map { $0.map { _ in degrees } }
    return copy
}

@Test(arguments: EngineLayout.allCases)
func autoBaseIsSafeForEveryCombination(layout: EngineLayout) {
    for induction in inductions {
        for fuel in Fuel.allCases {
            let build = tuned(layout, induction, fuel)
            let safe = fuel.spec.safeAfr
            for rpm in stride(from: 1500.0, through: build.ecu.revLimit, by: 250) {
                let point = fullLoad(build, rpm: rpm)
                let tag = "\(layout) \(induction) \(fuel) \(rpm) rpm"
                #expect(point.combustion.knockIndex < 1, "\(tag): knock \(point.combustion.knockIndex)")
                #expect(safe.contains(point.combustion.afr), "\(tag): AFR \(point.combustion.afr)")
                #expect(point.combustion.egtC < 950, "\(tag): EGT \(point.combustion.egtC)")
                #expect(point.brakeHp.isFinite && point.brakeHp > 0, "\(tag): \(point.brakeHp) hp")
            }
        }
    }
}

@Test func autoBaseCapsTurboToTheFuelSystem() {
    var stock = EngineBuild.starter(.i4)
    stock.induction = .turbo(.large)
    let capped = ECUMap.autoBase(for: stock)
    let sized = ECUMap.autoBase(for: stock.withFuelSystemSized())
    #expect(capped.boostTargetPsi < sized.boostTargetPsi)
    let needs = fuelSystemNeeds(stock, boostPsi: capped.boostTargetPsi)
    #expect(needs.injectorCcMin <= stock.parts.injectorCcMin + 0.5)
}

@Test func timingPastMbtLosesTorque() {
    var build = EngineBuild.starter(.i4)
    build.fuel = .race
    build.sensors.knock = false
    let rpm = 4000.0
    let air = airflowGps(build, rpm: rpm, throttle: 1, boostPsi: 0, chargeTempC: 25)
    let mbt = mbtDegrees(build, rpm: rpm, loadKpa: loadKpa(build, rpm: rpm, airflowGps: air))
    let atMbt = operatingPoint(flatTiming(build, mbt), rpm: rpm, throttle: 1, boostPsi: 0, nitrousArmed: false, closedLoopTrim: 0)
    let past = operatingPoint(flatTiming(build, mbt + 15), rpm: rpm, throttle: 1, boostPsi: 0, nitrousArmed: false, closedLoopTrim: 0)
    let short = operatingPoint(flatTiming(build, mbt - 15), rpm: rpm, throttle: 1, boostPsi: 0, nitrousArmed: false, closedLoopTrim: 0)
    #expect(past.combustion.torqueNm < atMbt.combustion.torqueNm)
    #expect(short.combustion.torqueNm < atMbt.combustion.torqueNm)
    #expect(short.combustion.egtC > atMbt.combustion.egtC, "late timing heats the exhaust")
}

@Test func knockSensorPullsTiming() {
    let advanced = flatTiming(EngineBuild.starter(.i4), 40)
    let with = operatingPoint(advanced, rpm: 4000, throttle: 1, boostPsi: 0, nitrousArmed: false, closedLoopTrim: 0)
    #expect(with.combustion.mapTimingDeg == 40)
    #expect(with.combustion.timingDeg < 40)
    var blind = advanced
    blind.sensors.knock = false
    let without = operatingPoint(blind, rpm: 4000, throttle: 1, boostPsi: 0, nitrousArmed: false, closedLoopTrim: 0)
    #expect(without.combustion.timingDeg == 40)
    #expect(without.combustion.knockIndex > with.combustion.knockIndex)
    #expect(without.combustion.knockIndex >= 1)
}

@Test func nitrousAddsRoughlyTheShot() {
    var build = EngineBuild.starter(.v8Cross)
    build.nitrous = NitrousKit(kind: .wet, shotHp: 100, armRpm: 3000, enabled: true)
    build.ecu = ECUMap.autoBase(for: build)
    let off = fullLoad(build, rpm: 5000)
    let on = fullLoad(build, rpm: 5000, nitrous: true)
    #expect(on.nitrousActive)
    let gain = on.brakeHp - off.brakeHp
    #expect(gain >= 80 && gain <= 120, "100 hp wet shot added \(gain) hp")
    #expect(on.combustion.knockIndex < 1)
}

@Test func dryShotWithoutFuelDetonates() {
    var build = EngineBuild.starter(.v8Cross)
    build.nitrous = NitrousKit(kind: .dry, shotHp: 200, armRpm: 3000, enabled: true) // map left as it was
    let on = fullLoad(build, rpm: 5000, nitrous: true)
    #expect(on.nitrousActive)
    #expect(on.combustion.knockIndex >= 1 || on.combustion.afr > 13.5, "knock \(on.combustion.knockIndex), AFR \(on.combustion.afr)")
}

@Test func nitrousBelowArmRpmDoesNothing() {
    var build = EngineBuild.starter(.i6)
    build.nitrous = NitrousKit(kind: .wet, shotHp: 150, armRpm: 4000, enabled: true)
    build.ecu = ECUMap.autoBase(for: build)
    let extra = nitrousExtra(build, rpm: 3500, throttle: 1)
    #expect(extra.oxygenGps == 0 && extra.addedFuelGps == 0)
    #expect(nitrousExtra(build, rpm: 4500, throttle: 1).oxygenGps > 0)
    #expect(nitrousExtra(build, rpm: 4500, throttle: 0.3).oxygenGps == 0, "outside the throttle window")
    #expect(!fullLoad(build, rpm: 3500, nitrous: true).nitrousActive)
    build.nitrous?.enabled = false
    #expect(nitrousExtra(build, rpm: 4500, throttle: 1).oxygenGps == 0)
}

@Test func bilinearMatchesCorners() {
    let map = ECUMap.autoBase(for: EngineBuild.starter(.v10))
    let (i, j) = (5, 7)
    let corner = map.value(\.afrTable, rpm: map.rpmAxis[i], loadKpa: map.loadAxis[j])
    #expect(abs(corner - map.afrTable[j][i]) < 1e-9)
    let middle = map.value(\.ignitionTable, rpm: (map.rpmAxis[i] + map.rpmAxis[i + 1]) / 2, loadKpa: (map.loadAxis[j] + map.loadAxis[j + 1]) / 2)
    let average = (map.ignitionTable[j][i] + map.ignitionTable[j][i + 1] + map.ignitionTable[j + 1][i] + map.ignitionTable[j + 1][i + 1]) / 4
    #expect(abs(middle - average) < 1e-9)
    // Clamped at the edges.
    #expect(map.value(\.afrTable, rpm: -500, loadKpa: 5) == map.afrTable[0][0])
    #expect(map.value(\.afrTable, rpm: 99_000, loadKpa: 900) == map.afrTable[11][15])
}

@Test func malformedMapIsRebuiltBySanitize() {
    var build = EngineBuild.starter(.i4)
    build.ecu.afrTable = [[12.5]]
    build.ecu.rpmAxis = []
    #expect(build.ecu.value(\.afrTable, rpm: 3000, loadKpa: 100).isNaN, "lookup never traps")
    let clean = build.sanitized()
    #expect(clean.ecu.isWellFormed)
    #expect(clean.ecu == ECUMap.autoBase(for: clean))
    var hot = EngineBuild.starter(.i4)
    hot.ecu.ignitionTable[3][4] = .nan
    #expect(!hot.ecu.isWellFormed)
    #expect(hot.sanitized().ecu.isWellFormed)
}

@Test func starterMapIsAutoBase() {
    let build = EngineBuild.starter(.v12)
    #expect(build.ecu == ECUMap.autoBase(for: build))
    #expect(build.ecu.revLimit == build.mechanicalRedline)
    #expect(build.ecu.isWellFormed)
}
