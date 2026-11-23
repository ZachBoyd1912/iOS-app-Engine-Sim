import Foundation

/// Pure vehicle dynamics for the Drive experience.
///
/// Specified by `VehicleDynamicsTests`; implemented to make those tests green.
/// Conventions: SI units. Speed m/s, distance m, angle radians, force N.
/// `gravity` defaults to 9.80665.
public enum VehicleDynamics {

    /// Peak lateral acceleration the tyres can hold, in m/s²: μ·g.
    public static func lateralGripAcceleration(friction: Double, gravity: Double = 9.80665) -> Double {
        friction * gravity
    }

    /// Steady-state cornering radius from steering geometry alone (no slip), in metres:
    /// R = wheelbase / tan(steerAngle). Zero steer means straight ahead, so `.infinity`.
    public static func geometricCorneringRadius(wheelbase: Double, steerAngle: Double) -> Double {
        // Exact zero is the straight-ahead case; tiny angles are left to the maths.
        steerAngle == 0 ? .infinity : wheelbase / tan(steerAngle)
    }

    /// Fastest speed the car can hold on `radius` without exceeding lateral grip, in m/s:
    /// v = sqrt(μ·g·R).
    public static func maxCorneringSpeed(radius: Double, friction: Double,
                                         gravity: Double = 9.80665) -> Double {
        (friction * gravity * radius).squareRoot()
    }

    /// Radius the car actually holds at `speed`: the larger of what the steering asks for
    /// and what grip allows (v²/(μ·g)). A car cannot corner tighter than its tyres permit.
    public static func achievableCorneringRadius(speed: Double, wheelbase: Double, steerAngle: Double,
                                                 friction: Double, gravity: Double = 9.80665) -> Double {
        let geometric = geometricCorneringRadius(wheelbase: wheelbase, steerAngle: steerAngle)
        guard friction > 0, gravity > 0 else { return .infinity }
        let gripLimited = speed * speed / (friction * gravity)
        return max(geometric, gripLimited)
    }

    /// Stopping distance under constant braking, in metres: v² / (2·μ·g·decelerationG).
    public static func brakingDistance(speed: Double, friction: Double,
                                       decelerationG: Double = 1.0, gravity: Double = 9.80665) -> Double {
        let denominator = 2 * friction * gravity * decelerationG
        guard denominator > 0 else { return .infinity }
        return speed * speed / denominator
    }
}
