import XCTest
@testable import PistonForgeKit

/// Specification for `ValveTrainKinematics`, written before the implementation.
/// Against the stub every test below traps, which is the point.
final class ValveTrainKinematicsTests: XCTestCase {

    private let eps = 1e-9

    // MARK: cam speed

    func testCamTurnsAtHalfCrankSpeed() {
        XCTAssertEqual(ValveTrainKinematics.camAngle(crankAngle: 720), 360, accuracy: eps)
        XCTAssertEqual(ValveTrainKinematics.camAngle(crankAngle: 90), 45, accuracy: eps)
    }

    func testCamAngleWrapsOneRevolutionPerTwoCrankRevolutions() {
        // 1440 crank degrees is two cam revolutions: same cam angle as zero.
        XCTAssertEqual(ValveTrainKinematics.camAngle(crankAngle: 1440),
                       ValveTrainKinematics.camAngle(crankAngle: 0), accuracy: eps)
    }

    // MARK: lift profile

    func testValveIsFullyOpenAtTheEventCentre() {
        let lift = ValveTrainKinematics.normalisedLift(camAngle: 110, eventCentre: 110, duration: 240)
        XCTAssertEqual(lift, 1, accuracy: eps)
    }

    func testValveIsShutOutsideTheWindow() {
        // Duration 240 means the window is centre ±120, i.e. -10..230 cam degrees.
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 250, eventCentre: 110, duration: 240), 0, accuracy: eps)
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 0, eventCentre: 110, duration: 240), 0, accuracy: eps)
    }

    func testValveIsShutExactlyAtTheWindowEdges() {
        let half = 120.0
        let centre = 110.0
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: centre - half, eventCentre: centre, duration: 240), 0, accuracy: eps)
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: centre + half, eventCentre: centre, duration: 240), 0, accuracy: eps)
    }

    func testLiftIsHalfWayAtTheQuarterPointsOfARaisedCosine() {
        // Raised cosine: lift = (1 - cos(2π·x)) / 2 where x runs 0..1 across the window.
        // At a quarter into the window that is 0.5.
        let centre = 110.0
        let lift = ValveTrainKinematics.normalisedLift(camAngle: centre - 60, eventCentre: centre, duration: 240)
        XCTAssertEqual(lift, 0.5, accuracy: 1e-6)
    }

    func testLiftIsSymmetricAboutTheCentre() {
        let centre = 110.0
        let before = ValveTrainKinematics.normalisedLift(camAngle: centre - 40, eventCentre: centre, duration: 240)
        let after = ValveTrainKinematics.normalisedLift(camAngle: centre + 40, eventCentre: centre, duration: 240)
        XCTAssertEqual(before, after, accuracy: 1e-9)
    }

    func testLiftIsNeverNegativeOrAboveOne() {
        for angle in stride(from: -360.0, through: 720.0, by: 7.0) {
            let lift = ValveTrainKinematics.normalisedLift(camAngle: angle, eventCentre: 110, duration: 240)
            XCTAssertGreaterThanOrEqual(lift, 0)
            XCTAssertLessThanOrEqual(lift, 1)
        }
    }

    func testWrapsAroundZeroDegrees() {
        // Event centred at 10 with 240 duration runs -110..130, so 350 must be inside it
        // once the angle wraps (350 == -10).
        let wrapped = ValveTrainKinematics.normalisedLift(camAngle: 350, eventCentre: 10, duration: 240)
        let equivalent = ValveTrainKinematics.normalisedLift(camAngle: -10, eventCentre: 10, duration: 240)
        XCTAssertEqual(wrapped, equivalent, accuracy: 1e-9)
    }

    func testZeroDurationMeansNoLift() {
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 110, eventCentre: 110, duration: 0), 0, accuracy: eps)
    }

    // MARK: firing

    func testFiringAnglesAreEvenlySpacedOverTwoCrankRevolutions() {
        let four = ValveTrainKinematics.firingAngles(cylinderCount: 4)
        XCTAssertEqual(four, [0, 180, 360, 540])
    }

    func testFiringAnglesForAV8AreSpacedNinetyDegrees() {
        let v8 = ValveTrainKinematics.firingAngles(cylinderCount: 8)
        XCTAssertEqual(v8.count, 8)
        XCTAssertEqual(v8[1], 90, accuracy: eps)
        XCTAssertEqual(v8.last, 630, accuracy: eps)
    }

    func testSingleCylinderFiresOncePerCycle() {
        XCTAssertEqual(ValveTrainKinematics.firingAngles(cylinderCount: 1), [0])
    }

    func testZeroCylindersIsEmptyRatherThanADivideByZero() {
        XCTAssertEqual(ValveTrainKinematics.firingAngles(cylinderCount: 0), [])
    }

    // MARK: event centre

    func testEventCentreIsHalfTheCrankOffset() {
        XCTAssertEqual(ValveTrainKinematics.eventCentre(crankOffset: 180), 90, accuracy: eps)
        XCTAssertEqual(ValveTrainKinematics.eventCentre(crankOffset: 540), 270, accuracy: eps)
    }
}
