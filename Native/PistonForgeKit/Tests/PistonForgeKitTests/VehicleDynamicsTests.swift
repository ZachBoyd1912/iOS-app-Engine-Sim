import XCTest
@testable import PistonForgeKit

/// Specification for `VehicleDynamics`. Written before the implementation exists:
/// every test below fails against the stub, which is the point.
///
/// Every constant used here is derived, not invented:
///   g = 9.80665 m/s²
///   30 m/s (108 km/h) stopping at μ = 1.0 → 900 / (2 · 9.80665 · 1.0) = 45.886 m
///   R = 2.6 / tan(0.1) = 25.946 m
final class VehicleDynamicsTests: XCTestCase {

    private let g = 9.80665
    private let eps = 1e-6

    // MARK: lateral grip

    func testLateralGripAccelerationIsFrictionTimesGravity() {
        XCTAssertEqual(VehicleDynamics.lateralGripAcceleration(friction: 1.0), g, accuracy: eps)
        XCTAssertEqual(VehicleDynamics.lateralGripAcceleration(friction: 0.5), 0.5 * g, accuracy: eps)
    }

    func testLateralGripAccelerationScalesLinearlyWithFriction() {
        let street = VehicleDynamics.lateralGripAcceleration(friction: 0.8)
        let semiSlick = VehicleDynamics.lateralGripAcceleration(friction: 1.6)
        XCTAssertEqual(semiSlick, street * 2, accuracy: eps)
    }

    func testZeroFrictionMeansNoLateralAcceleration() {
        XCTAssertEqual(VehicleDynamics.lateralGripAcceleration(friction: 0), 0, accuracy: eps)
    }

    // MARK: steering geometry

    func testZeroSteerIsStraightAhead() {
        XCTAssertEqual(VehicleDynamics.geometricCorneringRadius(wheelbase: 2.6, steerAngle: 0), .infinity)
    }

    func testGeometricRadiusFollowsWheelbaseOverTangent() {
        // 2.6 / tan(0.1) = 25.946...
        let r = VehicleDynamics.geometricCorneringRadius(wheelbase: 2.6, steerAngle: 0.1)
        XCTAssertEqual(r, 25.946, accuracy: 0.01)
    }

    func testSteeringHarderGivesATighterRadius() {
        let gentle = VehicleDynamics.geometricCorneringRadius(wheelbase: 2.6, steerAngle: 0.05)
        let hard = VehicleDynamics.geometricCorneringRadius(wheelbase: 2.6, steerAngle: 0.2)
        XCTAssertLessThan(hard, gentle)
    }

    func testLongerWheelbaseTurnsWiderForTheSameSteer() {
        let short = VehicleDynamics.geometricCorneringRadius(wheelbase: 2.3, steerAngle: 0.1)
        let long = VehicleDynamics.geometricCorneringRadius(wheelbase: 3.0, steerAngle: 0.1)
        XCTAssertGreaterThan(long, short)
    }

    // MARK: grip-limited cornering

    func testMaxCorneringSpeedIsSqrtMuGR() {
        // sqrt(1.0 · 9.80665 · 50) = 22.145...
        let v = VehicleDynamics.maxCorneringSpeed(radius: 50, friction: 1.0)
        XCTAssertEqual(v, 22.145, accuracy: 0.01)
    }

    func testMoreGripMeansMoreSpeedThroughTheSameCorner() {
        let street = VehicleDynamics.maxCorneringSpeed(radius: 50, friction: 0.8)
        let slick = VehicleDynamics.maxCorneringSpeed(radius: 50, friction: 1.6)
        XCTAssertGreaterThan(slick, street)
    }

    func testTightCornerIsSlowerThanAnOpenOne() {
        let tight = VehicleDynamics.maxCorneringSpeed(radius: 20, friction: 1.0)
        let open = VehicleDynamics.maxCorneringSpeed(radius: 80, friction: 1.0)
        XCTAssertLessThan(tight, open)
    }

    // MARK: what the car actually does

    func testAtLowSpeedTheCarFollowsTheSteering() {
        // 5 m/s in a 25.9 m radius corner needs only 5²/(25.9·g) ≈ 0.098 g: well inside 1.0.
        let r = VehicleDynamics.achievableCorneringRadius(speed: 5, wheelbase: 2.6, steerAngle: 0.1,
                                                          friction: 1.0)
        XCTAssertEqual(r, 25.946, accuracy: 0.01)
    }

    func testAtHighSpeedGripLimitsTheRadiusNotTheSteering() {
        // 40 m/s asks for 25.9 m but needs 40²/(1.0·g) = 163.2 m of radius.
        let r = VehicleDynamics.achievableCorneringRadius(speed: 40, wheelbase: 2.6, steerAngle: 0.1,
                                                          friction: 1.0)
        XCTAssertEqual(r, 163.18, accuracy: 0.05)
    }

    func testAtHighSpeedMoreGripTightensTheAchievableRadius() {
        let lowGrip = VehicleDynamics.achievableCorneringRadius(speed: 40, wheelbase: 2.6, steerAngle: 0.1,
                                                                friction: 0.8)
        let highGrip = VehicleDynamics.achievableCorneringRadius(speed: 40, wheelbase: 2.6, steerAngle: 0.1,
                                                                 friction: 1.6)
        XCTAssertLessThan(highGrip, lowGrip)
    }

    // MARK: braking

    func testStoppingDistanceFromThirtyMetresPerSecondAtOneG() {
        // 900 / (2 · 9.80665 · 1.0 · 1.0) = 45.886 m
        let d = VehicleDynamics.brakingDistance(speed: 30, friction: 1.0)
        XCTAssertEqual(d, 45.886, accuracy: 0.01)
    }

    func testStoppingDistanceScalesWithSpeedSquared() {
        let at30 = VehicleDynamics.brakingDistance(speed: 30, friction: 1.0)
        let at60 = VehicleDynamics.brakingDistance(speed: 60, friction: 1.0)
        XCTAssertEqual(at60, at30 * 4, accuracy: 0.01)
    }

    func testWeakBrakesTakeLongerToStop() {
        let strong = VehicleDynamics.brakingDistance(speed: 30, friction: 1.0, decelerationG: 1.0)
        let weak = VehicleDynamics.brakingDistance(speed: 30, friction: 1.0, decelerationG: 0.6)
        XCTAssertGreaterThan(weak, strong)
        XCTAssertEqual(weak, strong / 0.6, accuracy: 0.05)
    }

    func testStoppingFromStandstillIsZero() {
        XCTAssertEqual(VehicleDynamics.brakingDistance(speed: 0, friction: 1.0), 0, accuracy: eps)
    }

    func testSlipperySurfaceDoublesTheDistanceRelativeToHalfTheGrip() {
        let dry = VehicleDynamics.brakingDistance(speed: 30, friction: 1.0)
        let wet = VehicleDynamics.brakingDistance(speed: 30, friction: 0.5)
        XCTAssertEqual(wet, dry * 2, accuracy: 0.02)
    }
}
