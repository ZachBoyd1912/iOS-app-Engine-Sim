import XCTest
@testable import PistonForgeKit

/// Specification for `ValveTrainKinematics`, written before the implementation.
///
/// Geometry note: one four-stroke cycle is 720 camshaft degrees (two crank revolutions).
/// A cam event centred at 240 with duration 240 therefore opens at 120 and closes at 360.
final class ValveTrainKinematicsTests: XCTestCase {

    private let eps = 1e-9

    // MARK: cam speed

    func testCamTurnsAtHalfCrankSpeed() {
        XCTAssertEqual(ValveTrainKinematics.camAngle(crankAngle: 720), 360, accuracy: eps)
        XCTAssertEqual(ValveTrainKinematics.camAngle(crankAngle: 90), 45, accuracy: eps)
    }

    func testCamCycleRepeatsEveryTwoCrankRevolutions() {
        // 1440 crank degrees is one full cam cycle: same cam angle as zero.
        XCTAssertEqual(ValveTrainKinematics.camAngle(crankAngle: 1440),
                       ValveTrainKinematics.camAngle(crankAngle: 0), accuracy: eps)
    }

    // MARK: lift profile

    func testValveIsFullyOpenAtTheEventCentre() {
        let lift = ValveTrainKinematics.normalisedLift(camAngle: 240, eventCentre: 240, duration: 240)
        XCTAssertEqual(lift, 1, accuracy: eps)
    }

    func testValveIsShutOutsideTheWindow() {
        // Window is 120..360 cam degrees.
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 0, eventCentre: 240, duration: 240), 0, accuracy: eps)
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 100, eventCentre: 240, duration: 240), 0, accuracy: eps)
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 400, eventCentre: 240, duration: 240), 0, accuracy: eps)
    }

    func testValveIsShutExactlyAtTheWindowEdges() {
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 120, eventCentre: 240, duration: 240), 0, accuracy: eps)
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 360, eventCentre: 240, duration: 240), 0, accuracy: eps)
    }

    func testLiftIsHalfWayAtTheQuarterPointsOfARaisedCosine() {
        // Raised cosine over the window: a quarter of the way in is 0.5.
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 180, eventCentre: 240, duration: 240), 0.5, accuracy: 1e-6)
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 300, eventCentre: 240, duration: 240), 0.5, accuracy: 1e-6)
    }

    func testLiftIsSymmetricAboutTheCentre() {
        let before = ValveTrainKinematics.normalisedLift(camAngle: 200, eventCentre: 240, duration: 240)
        let after = ValveTrainKinematics.normalisedLift(camAngle: 280, eventCentre: 240, duration: 240)
        XCTAssertEqual(before, after, accuracy: 1e-9)
    }

    func testLiftIsNeverNegativeOrAboveOne() {
        for angle in stride(from: 0.0, through: 720.0, by: 7.0) {
            let lift = ValveTrainKinematics.normalisedLift(camAngle: angle, eventCentre: 240, duration: 240)
            XCTAssertGreaterThanOrEqual(lift, 0)
            XCTAssertLessThanOrEqual(lift, 1)
        }
    }

    func testLiftRepeatsEveryCamCycle() {
        let now = ValveTrainKinematics.normalisedLift(camAngle: 300, eventCentre: 240, duration: 240)
        let nextCycle = ValveTrainKinematics.normalisedLift(camAngle: 300 + 720, eventCentre: 240, duration: 240)
        XCTAssertEqual(now, nextCycle, accuracy: 1e-9)
    }

    func testZeroDurationMeansNoLift() {
        XCTAssertEqual(ValveTrainKinematics.normalisedLift(camAngle: 240, eventCentre: 240, duration: 0), 0, accuracy: eps)
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
        XCTAssertEqual(v8.last ?? .nan, 630, accuracy: eps)
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
