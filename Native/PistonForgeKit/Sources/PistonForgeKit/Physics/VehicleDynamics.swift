import Foundation

/// Pure vehicle dynamics for the Drive experience.
///
/// This file is deliberately a stub. Every function traps, so a missing implementation
/// shows up as a failing test rather than a plausible-looking number.
/// `VehicleDynamicsTests` is the specification; implement until it is green.
///
/// Conventions: SI units. Speed m/s, distance m, angle radians, force N.
/// `gravity` defaults to 9.80665.
public enum VehicleDynamics {

    /// Peak lateral acceleration the tyres can hold, in m/s²: μ·g.
    public static func lateralGripAcceleration(friction: Double, gravity: Double = 9.80665) -> Double {
        fatalError("VehicleDynamics.lateralGripAcceleration is unimplemented")
    }

    /// Steady-state cornering radius from steering geometry alone (no slip), in metres:
    /// R = wheelbase / tan(steerAngle). Zero steer means straight ahead, so `.infinity`.
    public static func geometricCorneringRadius(wheelbase: Double, steerAngle: Double) -> Double {
        fatalError("VehicleDynamics.geometricCorneringRadius is unimplemented")
    }

    /// Fastest speed the car can hold on `radius` without exceeding lateral grip, in m/s:
    /// v = sqrt(μ·g·R).
    public static func maxCorneringSpeed(radius: Double, friction: Double,
                                         gravity: Double = 9.80665) -> Double {
        fatalError("VehicleDynamics.maxCorneringSpeed is unimplemented")
    }

    /// Radius the car actually holds at `speed`: the larger of what the steering asks for
    /// and what grip allows (v²/(μ·g)). A car cannot corner tighter than its tyres permit.
    public static func achievableCorneringRadius(speed: Double, wheelbase: Double, steerAngle: Double,
                                                 friction: Double, gravity: Double = 9.80665) -> Double {
        fatalError("VehicleDynamics.achievableCorneringRadius is unimplemented")
    }

    /// Stopping distance under constant braking, in metres: v² / (2·μ·g·decelerationG).
    public static func brakingDistance(speed: Double, friction: Double,
                                       decelerationG: Double = 1.0, gravity: Double = 9.80665) -> Double {
        fatalError("VehicleDynamics.brakingDistance is unimplemented")
    }
}
