import Foundation
import Testing
@testable import PistonForgeKit

/// 240 steps a second, the step the drive model is tested at.
private let driveStepS = 1.0 / 240

private func muscleSim(gearbox: Gearbox, mode: DriveMode, automatic: Bool) -> DriveSim {
    let build = EngineBuild.starter(.v8Cross)
    let car = CarSetup(body: .muscle, gearbox: gearbox, finalDrive: 3.55, tyre: Tyre(compound: .sport, widthMm: 255))
    return DriveSim(build: build, car: car, mode: mode, automatic: automatic)
}

/// Steps a run to its end, or to 200 s of car time if it never finishes.
private func finish(_ run: inout DragRun, input: DriveInput) {
    var steps = 0
    while !run.isOver && steps < 48_000 {
        _ = run.step(dt: driveStepS, input: input)
        steps += 1
    }
}

@Test(arguments: Gearbox.allCases)
func everyGearboxHasStrictlyDecreasingRatios(gearbox: Gearbox) {
    let ratios = gearbox.spec.ratios
    #expect(!ratios.isEmpty)
    var previous = Double.infinity
    for ratio in ratios {
        #expect(ratio < previous)
        previous = ratio
    }
}

@Test func gearCountsMatchTheirNames() {
    #expect(Gearbox.m5.spec.ratios.count == 5)
    #expect(Gearbox.m6.spec.ratios.count == 6)
    #expect(Gearbox.seq6.spec.ratios.count == 6)
    #expect(Gearbox.dct7.spec.ratios.count == 7)
    #expect(Gearbox.auto4.spec.ratios.count == 4)
    #expect(Gearbox.auto8.spec.ratios.count == 8)
    #expect(Gearbox.auto10.spec.ratios.count == 10)
    #expect(Gearbox.ev1.spec.ratios.count == 1)
}

@Test func sportierModesUpshiftLaterAtEveryThrottle() {
    for step in 0...10 {
        let throttle = Double(step) / 10
        let eco = DriveMode.eco.upshiftRpmFraction(throttle: throttle)
        let comfort = DriveMode.comfort.upshiftRpmFraction(throttle: throttle)
        let sport = DriveMode.sport.upshiftRpmFraction(throttle: throttle)
        let sportPlus = DriveMode.sportPlus.upshiftRpmFraction(throttle: throttle)
        #expect(eco < comfort)
        #expect(comfort < sport)
        #expect(sport < sportPlus)
    }
}

@Test func downshiftsSitBelowUpshiftsAtEveryMode() {
    for mode in DriveMode.allCases {
        for step in 0...10 {
            let throttle = Double(step) / 10
            let up = mode.upshiftRpmFraction(throttle: throttle)
            let down = mode.downshiftRpmFraction(throttle: throttle)
            #expect(down < up)
        }
    }
}

@Test func sportierModesShiftFaster() {
    #expect(DriveMode.eco.shiftSpeedScale > DriveMode.comfort.shiftSpeedScale)
    #expect(DriveMode.comfort.shiftSpeedScale > DriveMode.sport.shiftSpeedScale)
    #expect(DriveMode.sport.shiftSpeedScale > DriveMode.sportPlus.shiftSpeedScale)
}

@Test func muscleV8AutomaticSportQuarterMileIsPlausible() {
    var run = DragRun(sim: muscleSim(gearbox: .auto8, mode: .sport, automatic: true), lengthM: DragRun.quarterMileM)
    finish(&run, input: DriveInput(throttle: 1))
    let slip = run.timeslip
    let quarter = slip.quarterMileS ?? -1
    let trap = slip.quarterTrapMph ?? -1
    #expect(slip.finished)
    #expect(quarter >= 8 && quarter <= 20)
    #expect(trap >= 70 && trap <= 180)
}

@Test func fourCylinderHatchIsSlowerThanTheV8Muscle() {
    var muscle = DragRun(sim: muscleSim(gearbox: .auto8, mode: .sport, automatic: true), lengthM: DragRun.quarterMileM)
    finish(&muscle, input: DriveInput(throttle: 1))

    let hatchCar = CarSetup(body: .hatch, gearbox: .auto4, finalDrive: 3.9, tyre: Tyre(compound: .street, widthMm: 185))
    let hatchSim = DriveSim(build: EngineBuild.starter(.i4), car: hatchCar, mode: .sport, automatic: true)
    var hatch = DragRun(sim: hatchSim, lengthM: DragRun.quarterMileM)
    finish(&hatch, input: DriveInput(throttle: 1))

    let muscleTime = muscle.timeslip.quarterMileS ?? 999
    let hatchTime = hatch.timeslip.quarterMileS ?? 999
    #expect(muscleTime < 999)
    #expect(hatchTime > muscleTime)
}

@Test func fullThrottleSpeedRisesForTheFirstThreeSeconds() {
    var sim = muscleSim(gearbox: .auto8, mode: .sport, automatic: true)
    var previous = sim.state.speedMps
    var worstDrop = 0.0
    var steps = 0
    while sim.state.time < 3 && steps < 1_000 {
        let state = sim.step(dt: driveStepS, input: DriveInput(throttle: 1))
        let drop = previous - state.speedMps
        worstDrop = max(worstDrop, drop)
        previous = state.speedMps
        steps += 1
    }
    // Only the torque cut during a shift can slow the car on full throttle.
    #expect(worstDrop < 0.05)
    #expect(sim.state.speedMps > 5)
}

@Test func launchControlIsNoWorseThanOneAndAThirdSlowerSixtyFoot() {
    var withControl = DragRun(sim: muscleSim(gearbox: .m6, mode: .sport, automatic: false), lengthM: DragRun.sixtyFootM)
    finish(&withControl, input: DriveInput(throttle: 1, launchControl: true))

    var withoutControl = DragRun(sim: muscleSim(gearbox: .m6, mode: .sport, automatic: false), lengthM: DragRun.sixtyFootM)
    finish(&withoutControl, input: DriveInput(throttle: 1))

    let launched = withControl.timeslip.sixtyFootS ?? 999
    let plain = withoutControl.timeslip.sixtyFootS ?? 999
    #expect(launched < 999)
    #expect(plain < 999)
    #expect(launched <= plain * 1.3)
}

@Test func timeslipSplitsAreInOrder() {
    var run = DragRun(sim: muscleSim(gearbox: .auto8, mode: .sport, automatic: true), lengthM: DragRun.quarterMileM)
    finish(&run, input: DriveInput(throttle: 1))
    let slip = run.timeslip
    let sixty = slip.sixtyFootS ?? 999
    let threeThirty = slip.threeThirtyFootS ?? 999
    let eighth = slip.eighthMileS ?? 999
    let quarter = slip.quarterMileS ?? 999
    #expect(sixty < threeThirty)
    #expect(threeThirty < eighth)
    #expect(eighth < quarter)
}

@Test func runsAreDeterministic() {
    var first = DragRun(sim: muscleSim(gearbox: .auto8, mode: .sport, automatic: true), lengthM: DragRun.eighthMileM)
    finish(&first, input: DriveInput(throttle: 1))
    var second = DragRun(sim: muscleSim(gearbox: .auto8, mode: .sport, automatic: true), lengthM: DragRun.eighthMileM)
    finish(&second, input: DriveInput(throttle: 1))
    #expect(first.timeslip.eighthMileS == second.timeslip.eighthMileS)
    #expect(first.timeslip.eighthTrapMph == second.timeslip.eighthTrapMph)
}

@Test(arguments: Gearbox.allCases)
func everyGearboxCompletesAQuarterMile(gearbox: Gearbox) {
    var run = DragRun(sim: muscleSim(gearbox: gearbox, mode: .comfort, automatic: true), lengthM: DragRun.quarterMileM)
    finish(&run, input: DriveInput(throttle: 1))
    #expect(run.timeslip.finished)
}
