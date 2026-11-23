import Foundation
import Testing
@testable import PistonForgeKit

/// 240 steps a second, the step the drive model is tested at.
private let physicsStepS = 1.0 / 240

private func setup(_ body: CarBody, compound: Tyre.Compound = .sport, widthMm: Double = 225) -> CarSetup {
    CarSetup(body: body, gearbox: .auto8, finalDrive: 3.55, tyre: Tyre(compound: compound, widthMm: widthMm))
}

/// A mass that includes a plausible engine, so the tests use the same total the simulator does.
private func roadMass(_ body: CarBody, engineKg: Double = 300) -> Double {
    body.spec.massKg + engineKg
}

private func muscleSim() -> DriveSim {
    let car = CarSetup(
        body: .muscle, gearbox: .auto8, finalDrive: 3.55,
        tyre: Tyre(compound: .sport, widthMm: 255)
    )
    return DriveSim(build: EngineBuild.starter(.v8Cross), car: car, mode: .sport, automatic: true)
}

/// Steps a sim on full throttle until it reaches `target` m/s, or gives up.
private func reach(_ sim: inout DriveSim, _ target: Double) {
    var steps = 0
    while sim.state.speedMps < target && steps < 4800 {
        _ = sim.step(dt: physicsStepS, input: DriveInput(throttle: 1))
        steps += 1
    }
}

// MARK: - Straight-line behaviour is untouched

@Test func steeringDefaultsToStraightAhead() {
    #expect(DriveInput(throttle: 1).steering == 0)
    #expect(DriveInput(throttle: 1, brake: 0.5, steering: 0.25).steering == 0.25)
}

@Test func aStraightRunReportsNoLateralState() {
    var sim = muscleSim()
    reach(&sim, 20)
    for _ in 0..<240 {
        _ = sim.step(dt: physicsStepS, input: DriveInput(throttle: 1))
    }
    let cornering = sim.state.cornering
    #expect(cornering.lateralAccelMps2 == 0)
    #expect(cornering.yawRateRadPerS == 0)
    #expect(cornering.cornerRadiusM == nil)
    #expect(cornering.scrubForceN == 0)
    #expect(cornering.gripLimited == false)
    #expect(cornering.frontUse == 0 && cornering.rearUse == 0)
    #expect(sim.state.braking == .none)
}

@Test func aSteeringInputOfZeroChangesNothingAtAll() {
    // Two identical cars, one driven with the default input and one with an explicit zero
    // steering angle. Every state value has to match, which is the guard that the cornering
    // and braking terms collapse to nothing when the wheel is straight.
    var implicit = muscleSim()
    var explicit = muscleSim()
    for _ in 0..<720 {
        let first = implicit.step(dt: physicsStepS, input: DriveInput(throttle: 1))
        let second = explicit.step(dt: physicsStepS, input: DriveInput(throttle: 1, steering: 0))
        #expect(first == second)
        #expect(first.cornering.lateralAccelMps2 == 0)
    }
    #expect(implicit.state.distanceM == explicit.state.distanceM)
    #expect(implicit.state.speedMps == explicit.state.speedMps)
}

// MARK: - Lateral grip limit

@Test func lateralLimitRisesWithCompoundGrip() {
    let compounds: [Tyre.Compound] = [.street, .sport, .semiSlick]
    for body in CarBody.allCases {
        let mass = roadMass(body)
        var previous = 0.0
        for compound in compounds {
            let limit = VehicleDynamics.lateralLimit(
                car: setup(body, compound: compound), massKg: mass
            ).accelMps2
            #expect(limit > previous, "\(body) \(compound)")
            previous = limit
        }
        // A drag radial is built to go straight, so it corners worse than a street tyre even
        // though it is the grippiest compound off the line.
        let drag = VehicleDynamics.lateralLimit(
            car: setup(body, compound: .dragRadial), massKg: mass
        ).accelMps2
        let street = VehicleDynamics.lateralLimit(
            car: setup(body, compound: .street), massKg: mass
        ).accelMps2
        #expect(drag < street, "\(body)")
    }
}

@Test func lateralLimitFallsAsTheSameTyresCarryMoreWeight() {
    // Tyre friction falls with load, so doubling the mass does not double the lateral force:
    // the acceleration the car can hold goes down (slightly).
    for body in CarBody.allCases {
        let light = VehicleDynamics.lateralLimit(
            car: setup(body), massKg: roadMass(body)
        ).accelMps2
        let heavy = VehicleDynamics.lateralLimit(
            car: setup(body), massKg: roadMass(body) * 2
        ).accelMps2
        #expect(heavy < light, "\(body)")
        #expect(heavy > light * 0.7, "\(body)")
    }
}

@Test func lateralLimitIsInTheGripRangeOfTheTyres() {
    for body in CarBody.allCases {
        for compound in Tyre.Compound.allCases {
            let limit = VehicleDynamics.lateralLimit(
                car: setup(body, compound: compound), massKg: roadMass(body)
            ).accelMps2
            let mu = VehicleDynamics.lateralMu(compound)
            #expect(limit > mu * VehicleDynamics.gravity * 0.6, "\(body) \(compound)")
            #expect(limit < mu * VehicleDynamics.gravity * 1.2, "\(body) \(compound)")
        }
    }
}

@Test func frontHeavyBodiesUndersteerAndTheMidEngineCarOversteers() {
    let hatch = VehicleDynamics.lateralLimit(
        car: setup(.hatch), massKg: roadMass(.hatch, engineKg: 180)
    )
    #expect(hatch.balance == .understeer)
    #expect(hatch.frontAxleMps2 < hatch.rearAxleMps2)

    let midEngine = VehicleDynamics.lateralLimit(
        car: setup(.super_), massKg: roadMass(.super_, engineKg: 450)
    )
    #expect(midEngine.balance == .oversteer)
    #expect(midEngine.rearAxleMps2 < midEngine.frontAxleMps2)
}

@Test func theDrivenAxleLosesGripWhileCornering() {
    // Friction ellipse: with the tyre already working sideways it cannot also give its full
    // straight-line force.
    let grip = VehicleDynamics.axleLongitudinalGripN(
        loadN: 6000, lateralN: 0, muLong: 1.1, muLat: 1.1
    )
    #expect(grip == 6600)
    let cornering = VehicleDynamics.axleLongitudinalGripN(
        loadN: 6000, lateralN: 3300, muLong: 1.1, muLat: 1.1
    )
    #expect(cornering < grip)
    #expect(cornering > 0)
    let saturated = VehicleDynamics.axleLongitudinalGripN(
        loadN: 6000, lateralN: 6600, muLong: 1.1, muLat: 1.1
    )
    #expect(saturated == 0)
}

// MARK: - Cornering geometry

@Test func theRadiusGrowsWithSpeedForAFixedSteeringAngle() {
    let car = setup(.coupe)
    var previous = 0.0
    for speed in [8.0, 12.0, 16.0, 20.0] {
        let corner = VehicleDynamics.cornering(
            speedMps: speed, steering: 0.15, car: car, massKg: roadMass(.coupe)
        )
        #expect(!corner.gripLimited, "\(speed)")
        let radius = corner.cornerRadiusM ?? 0
        #expect(radius > previous, "\(speed)")
        #expect(radius > car.body.spec.wheelbaseM)
        previous = radius
    }
}

@Test func moreSteeringTightensTheRadiusUntilTheTyresSaturate() {
    let car = setup(.hatch)
    let mass = roadMass(.hatch, engineKg: 180)
    let light = VehicleDynamics.cornering(speedMps: 11.1, steering: 0.2, car: car, massKg: mass)
    let firm = VehicleDynamics.cornering(speedMps: 11.1, steering: 0.4, car: car, massKg: mass)
    let limit = VehicleDynamics.cornering(speedMps: 11.1, steering: 0.7, car: car, massKg: mass)
    let more = VehicleDynamics.cornering(speedMps: 11.1, steering: 1.0, car: car, massKg: mass)

    #expect((light.cornerRadiusM ?? 0) > (firm.cornerRadiusM ?? 0))
    #expect((firm.cornerRadiusM ?? 0) > (limit.cornerRadiusM ?? 0))
    // Past the limit more lock cannot help: the radius is set by grip, not by steering.
    #expect(limit.gripLimited)
    #expect(more.gripLimited)
    #expect(abs((limit.cornerRadiusM ?? 0) - (more.cornerRadiusM ?? 0)) < 0.001)
}

@Test func aGripLimitedCornerHoldsTheLateralLimit() {
    let car = setup(.muscle)
    let mass = roadMass(.muscle, engineKg: 537)
    let corner = VehicleDynamics.cornering(speedMps: 40, steering: 1, car: car, massKg: mass)
    #expect(corner.gripLimited)
    #expect(abs(corner.lateralAccelMps2 - corner.lateralLimitMps2) < 1e-9)
    #expect(max(corner.frontUse, corner.rearUse) > 0.999)
    #expect(max(corner.frontUse, corner.rearUse) <= 1.0)
    let radius = corner.cornerRadiusM ?? 0
    #expect(radius > car.body.spec.wheelbaseM)
    #expect(radius < 500)
}

@Test func yawRateIsLateralAccelerationOverSpeed() {
    let car = setup(.coupe)
    let mass = roadMass(.coupe)
    for speed in [10.0, 18.0, 26.0] {
        let corner = VehicleDynamics.cornering(
            speedMps: speed, steering: 0.3, car: car, massKg: mass
        )
        #expect(abs(corner.lateralAccelMps2 - speed * corner.yawRateRadPerS) < 1e-9, "\(speed)")
    }
}

@Test func aLeftTurnAndARightTurnMirrorEachOther() {
    let car = setup(.coupe)
    let mass = roadMass(.coupe)
    let left = VehicleDynamics.cornering(speedMps: 20, steering: 0.4, car: car, massKg: mass)
    let right = VehicleDynamics.cornering(speedMps: 20, steering: -0.4, car: car, massKg: mass)
    #expect(left.lateralAccelMps2 > 0)
    #expect(right.lateralAccelMps2 < 0)
    #expect(abs(left.lateralAccelMps2 + right.lateralAccelMps2) < 1e-9)
    #expect(abs(left.yawRateRadPerS + right.yawRateRadPerS) < 1e-9)
    #expect(abs((left.cornerRadiusM ?? 0) - (right.cornerRadiusM ?? 0)) < 1e-9)
}

@Test func steeringAngleIsReportedInDegrees() {
    let car = setup(.muscle)
    let corner = VehicleDynamics.cornering(
        speedMps: 10, steering: 0.5, car: car, massKg: roadMass(.muscle, engineKg: 537)
    )
    let lock = car.body.handling.maxRoadWheelAngleRad
    #expect(abs(corner.steeringAngleRad - lock * 0.5) < 1e-12)
    #expect(corner.steeringAngleDeg > 10 && corner.steeringAngleDeg < 20)
    #expect(abs(corner.steeringAngleDeg - corner.steeringAngleRad * 180 / .pi) < 1e-12)
}

@Test func scrubDragIsZeroStraightAndGrowsWithLateralForce() {
    let car = setup(.hatch)
    let mass = roadMass(.hatch, engineKg: 180)
    let straight = VehicleDynamics.cornering(speedMps: 15, steering: 0, car: car, massKg: mass)
    #expect(straight.scrubForceN == 0)
    var previous = 0.0
    for steering in [0.1, 0.2, 0.3] {
        let corner = VehicleDynamics.cornering(
            speedMps: 15, steering: steering, car: car, massKg: mass
        )
        #expect(corner.scrubForceN > previous, "\(steering)")
        previous = corner.scrubForceN
    }
    // Even at the limit, slip-angle drag stays under a fifth of the car's weight.
    #expect(previous < mass * VehicleDynamics.gravity * 0.2)
}

@Test func corneringBleedsSpeed() {
    var straight = muscleSim()
    reach(&straight, 20)
    var turning = straight
    for _ in 0..<240 {
        _ = straight.step(dt: physicsStepS, input: DriveInput(throttle: 0))
        _ = turning.step(dt: physicsStepS, input: DriveInput(throttle: 0, steering: 0.6))
    }
    #expect(turning.state.speedMps < straight.state.speedMps)
    #expect(turning.state.cornering.lateralAccelMps2 != 0)
    #expect(turning.state.cornering.cornerRadiusM != nil)
    #expect(turning.state.cornering.scrubForceN > 0)
}

@Test func theDriveSimReportsCorneringStateOnceSteeringIsUsed() {
    var sim = muscleSim()
    reach(&sim, 15)
    let state = sim.step(dt: physicsStepS, input: DriveInput(throttle: 0, steering: 0.5))
    #expect(state.cornering.steeringAngleRad != 0)
    #expect(state.cornering.lateralLimitMps2 > 0)
    #expect(state.cornering.lateralLimitG > 0.5)
    #expect(state.cornering.cornerRadiusM != nil)
    #expect(state.cornering.balance == VehicleDynamics.balance(
        front: state.cornering.frontLimitMps2, rear: state.cornering.rearLimitMps2
    ))
}

// MARK: - Handling constants

@Test func everyBodyHasAPlausibleTurningCircle() {
    for body in CarBody.allCases {
        let handling = body.handling
        #expect(handling.minimumTurnRadiusM > 3.5, "\(body)")
        #expect(handling.minimumTurnRadiusM < 7.5, "\(body)")
        #expect(handling.trackM > 1.3 && handling.trackM < 1.9, "\(body)")
        #expect(handling.brakeBiasFront > 0.5 && handling.brakeBiasFront < 0.8, "\(body)")
    }
}

@Test func understeerGradientSignMatchesTheSpeedItImplies() {
    let hatch = CarBody.hatch.handling
    #expect(hatch.understeerGradient > 0)
    #expect(hatch.characteristicSpeedMps != nil)
    #expect(hatch.criticalSpeedMps == nil)
    let characteristic = hatch.characteristicSpeedMps ?? 0
    #expect(characteristic > 20 && characteristic < 60)
    #expect(hatch.understeerGradientDegPerG > 0.5 && hatch.understeerGradientDegPerG < 5)

    let midEngine = CarBody.super_.handling
    #expect(midEngine.understeerGradient < 0)
    #expect(midEngine.criticalSpeedMps != nil)
    #expect(midEngine.characteristicSpeedMps == nil)
    let critical = midEngine.criticalSpeedMps ?? 0
    #expect(critical > 30 && critical < 90)

    for body in CarBody.allCases {
        #expect(abs(body.handling.understeerGradientDegPerG) < 8, "\(body)")
    }
}

@Test func everyBodyCarriesItsOwnHandlingNumbers() {
    let tracks = CarBody.allCases.map(\.handling.trackM)
    #expect(Set(tracks).count == CarBody.allCases.count)
    #expect(CarBody.hatch.handling.brakeBiasFront > CarBody.super_.handling.brakeBiasFront)
}

// MARK: - Braking

@Test func brakingMovesLoadToTheFrontAxle() {
    let car = setup(.muscle)
    let mass = roadMass(.muscle, engineKg: 537)
    let weight = mass * VehicleDynamics.gravity
    let brakes = VehicleDynamics.braking(
        pedal: 1, speedMps: 27.78, car: car, massKg: mass
    )
    #expect(brakes.totalForceN > 0)
    #expect(brakes.frontLoadN > weight * car.body.spec.frontWeight)
    #expect(brakes.rearLoadN < weight * (1 - car.body.spec.frontWeight))
    #expect(abs(brakes.frontLoadN + brakes.rearLoadN - weight) < weight * 1e-9)
    #expect(brakes.frontForceN > brakes.rearForceN)
    #expect(abs(brakes.decelMps2 - brakes.totalForceN / mass) < 1e-9)
    #expect(brakes.decelMps2 > 5)
}

@Test func noPedalMeansNoBrakeForce() {
    let car = setup(.hatch)
    let brakes = VehicleDynamics.braking(
        pedal: 0, speedMps: 30, car: car, massKg: roadMass(.hatch, engineKg: 180)
    )
    #expect(brakes == .none)
}

@Test func betterTyresStopShorter() {
    let mass = roadMass(.muscle, engineKg: 537)
    var previous = Double.infinity
    for compound in [Tyre.Compound.street, .sport, .semiSlick] {
        let stop = VehicleDynamics.stoppingDistance(
            fromSpeedMps: 27.78, car: setup(.muscle, compound: compound), massKg: mass
        )
        #expect(stop.distanceM > 0)
        #expect(stop.distanceM < previous, "\(compound)")
        previous = stop.distanceM
    }
}

@Test func stoppingDistanceGrowsWithTheSquareOfSpeed() {
    let car = setup(.coupe)
    let mass = roadMass(.coupe)
    let slow = VehicleDynamics.stoppingDistance(fromSpeedMps: 13.89, car: car, massKg: mass)
    let fast = VehicleDynamics.stoppingDistance(fromSpeedMps: 27.78, car: car, massKg: mass)
    #expect(fast.distanceM > slow.distanceM * 3)
    #expect(fast.timeS > slow.timeS)
}

@Test func brakingWhileSteeringTakesLongerThanBrakingStraight() {
    let car = setup(.hatch)
    let mass = roadMass(.hatch, engineKg: 180)
    let straight = VehicleDynamics.stoppingDistance(
        fromSpeedMps: 27.78, car: car, massKg: mass, steering: 0
    )
    let turning = VehicleDynamics.stoppingDistance(
        fromSpeedMps: 27.78, car: car, massKg: mass, steering: 0.3
    )
    #expect(turning.distanceM > straight.distanceM * 1.2)
}

@Test func stoppingDistanceIsDeterministic() {
    let car = setup(.pickup)
    let mass = roadMass(.pickup, engineKg: 450)
    let first = VehicleDynamics.stoppingDistance(fromSpeedMps: 25, car: car, massKg: mass)
    let second = VehicleDynamics.stoppingDistance(fromSpeedMps: 25, car: car, massKg: mass)
    #expect(first == second)
    #expect(first.distanceM > 20 && first.distanceM < 90)
}

@Test func theStepModelStopsInTheSameOrderAsTheEstimator() {
    // Drive to 100 km/h, then hold the brake and measure the distance. The step adds engine
    // braking, which the tyre-only estimator does not, so the car must stop no further than it.
    var sim = muscleSim()
    reach(&sim, 27.78)
    let startSpeed = sim.state.speedMps
    let startDistance = sim.state.distanceM
    var steps = 0
    while sim.state.speedMps > 0.1 && steps < 4800 {
        _ = sim.step(dt: physicsStepS, input: DriveInput(throttle: 0, brake: 1))
        steps += 1
    }
    let stepped = sim.state.distanceM - startDistance
    let engineKg = 90 * EngineBuild.starter(.v8Cross).displacementCc / 1000
    let reference = VehicleDynamics.stoppingDistance(
        fromSpeedMps: startSpeed,
        car: setup(.muscle, compound: .sport, widthMm: 255),
        massKg: CarBody.muscle.spec.massKg + engineKg
    )
    #expect(stepped > reference.distanceM * 0.6)
    #expect(stepped < reference.distanceM * 1.05)
}

@Test func brakingHardEnoughLocksAnAxle() {
    let mass = roadMass(.muscle, engineKg: 537)
    let brakes = VehicleDynamics.braking(
        pedal: 1, speedMps: 27.78, car: setup(.muscle), massKg: mass
    )
    // Fixed bias, no EBD: at full pedal one axle always asks for more than it has.
    #expect(brakes.frontLocked || brakes.rearLocked)
    let gentle = VehicleDynamics.braking(
        pedal: 0.2, speedMps: 27.78, car: setup(.muscle), massKg: mass
    )
    #expect(!gentle.frontLocked && !gentle.rearLocked)
    #expect(gentle.totalForceN < brakes.totalForceN)
}

// MARK: - Robustness

@Test func nonsenseInputsStayFinite() {
    let car = setup(.hatch)
    let mass = roadMass(.hatch, engineKg: 180)
    for speed in [-50.0, 0, Double.nan, Double.infinity, 1e9] {
        for steering in [-10.0, 0, Double.nan, 10.0] {
            let corner = VehicleDynamics.cornering(
                speedMps: speed, steering: steering, car: car, massKg: mass
            )
            #expect(corner.lateralAccelMps2.isFinite)
            #expect(corner.yawRateRadPerS.isFinite)
            #expect(corner.scrubForceN.isFinite)
            #expect(abs(corner.lateralAccelMps2) <= corner.lateralLimitMps2 + 1e-9)

            let brakes = VehicleDynamics.braking(
                pedal: 2, speedMps: speed, car: car, massKg: mass
            )
            #expect(brakes.totalForceN.isFinite)
            #expect(brakes.totalForceN >= 0)
        }
    }
}

@Test func aZeroMassCarDoesNotDivideByZero() {
    let car = setup(.coupe)
    let corner = VehicleDynamics.cornering(speedMps: 20, steering: 0.5, car: car, massKg: 0)
    #expect(corner.lateralAccelMps2.isFinite)
    let brakes = VehicleDynamics.braking(pedal: 1, speedMps: 20, car: car, massKg: 0)
    #expect(brakes.totalForceN.isFinite)
}
