import Foundation

/// Valve-train kinematics for a four-stroke engine.
///
/// Deliberately pure: the 3D layer only consumes these numbers, so the timing can be tested
/// on Linux in seconds instead of by looking at a phone. `ValveTrainKinematicsTests` is the
/// specification; this file traps until it is satisfied.
public enum ValveTrainKinematics {

    /// Camshaft angle for a crank angle. A four-stroke cam turns at half crank speed.
    public static func camAngle(crankAngle: Double) -> Double {
        fatalError("ValveTrainKinematics.camAngle is unimplemented")
    }

    /// Normalised valve lift in 0...1 for a cam event.
    /// - Parameters:
    ///   - camAngle: current cam angle, degrees.
    ///   - eventCentre: cam angle at which the valve is fully open, degrees.
    ///   - duration: total cam degrees the valve is off its seat (> 0).
    /// - Returns: 0 outside the window, 1 at the centre, raised-cosine in between.
    public static func normalisedLift(camAngle: Double, eventCentre: Double, duration: Double) -> Double {
        fatalError("ValveTrainKinematics.normalisedLift is unimplemented")
    }

    /// Crank angles at which each cylinder reaches its firing TDC, in firing order.
    /// Even spacing for a four-stroke: 720 / cylinderCount.
    public static func firingAngles(cylinderCount: Int) -> [Double] {
        fatalError("ValveTrainKinematics.firingAngles is unimplemented")
    }

    /// Cam-angle centre of a cylinder's intake event, given that cylinder's crank offset.
    /// The cam runs at half speed, so the cam event sits at half the crank offset.
    public static func eventCentre(crankOffset: Double) -> Double {
        fatalError("ValveTrainKinematics.eventCentre is unimplemented")
    }
}
