import Foundation

/// Valve-train kinematics for a four-stroke engine.
///
/// Deliberately pure: the 3D layer only consumes these numbers, so the timing can be tested
/// on Linux in seconds instead of by looking at a phone. `ValveTrainKinematicsTests` is the
/// specification.
public enum ValveTrainKinematics {

    /// One four-stroke cycle in crank degrees (two crank revolutions = one cam cycle).
    private static let crankCycle = 720.0

    /// Camshaft angle for a crank angle. A four-stroke cam turns at half crank speed.
    /// The result is normalised to one cam *cycle* (720 cam degrees = two crank revolutions),
    /// so 720 crank → 360 cam and 1440 crank → 0.
    public static func camAngle(crankAngle: Double) -> Double {
        var crank = crankAngle.truncatingRemainder(dividingBy: crankCycle * 2)
        if crank < 0 { crank += crankCycle * 2 }
        return crank / 2
    }

    /// Normalised valve lift in 0...1 for a cam event.
    /// - Parameters:
    ///   - camAngle: current cam angle, degrees.
    ///   - eventCentre: cam angle at which the valve is fully open, degrees.
    ///   - duration: total cam degrees the valve is off its seat (> 0).
    /// - Returns: 0 outside the window, 1 at the centre, raised-cosine in between.
    public static func normalisedLift(camAngle: Double, eventCentre: Double, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        let half = duration / 2

        // Shortest signed distance from the event centre, within one 720° cam cycle.
        var delta = (camAngle - eventCentre).truncatingRemainder(dividingBy: 720)
        if delta < -360 { delta += 720 }
        if delta > 360 { delta -= 720 }

        guard abs(delta) < half else { return 0 }
        let phase = (delta + half) / duration          // 0...1 across the event
        return (1 - cos(2 * Double.pi * phase)) / 2
    }

    /// Crank angles at which each cylinder reaches its firing TDC, in firing order.
    /// Even spacing for a four-stroke: 720 / cylinderCount.
    public static func firingAngles(cylinderCount: Int) -> [Double] {
        guard cylinderCount > 0 else { return [] }
        let spacing = 720.0 / Double(cylinderCount)
        return (0..<cylinderCount).map { Double($0) * spacing }
    }

    /// Cam-angle centre of a cylinder's event, given that cylinder's crank offset.
    /// The cam runs at half speed, so the event sits at half the offset.
    public static func eventCentre(crankOffset: Double) -> Double {
        camAngle(crankAngle: crankOffset)
    }
}
