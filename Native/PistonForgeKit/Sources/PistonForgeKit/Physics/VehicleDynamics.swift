import Foundation

/// Pure vehicle dynamics for the Drive experience.
///
/// Specified by `VehicleDynamicsTests`; implemented to make those tests green.
/// Conventions: SI units. Speed m/s, distance m, angle radians, force N.
/// `gravity` defaults to 9.80665.
///
/// The closed-form helpers at the top answer one question each and take their constants as
/// arguments. The model below them (`CarHandling`, `CorneringState`, `BrakingState`,
/// `lateralLimit`, `cornering`, `braking`, `stoppingDistance`) is what `DriveSim` runs: it adds
/// axle loads, load-sensitive tyre friction, an understeer gradient and a friction circle, so
/// the car has a different limit on each axle and when it is braking or on the power.
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

    // MARK: - The model DriveSim runs
    //
    // Everything from here down is the full cornering and braking model. The closed forms above
    // assume one friction coefficient for the whole car; the model below splits the car into two
    // axles with their own loads, their own share of the lateral force and their own friction,
    // which is what produces understeer, oversteer, power-on understeer and trail-braking.
    //
    // Sources, all recorded in `docs/research/raw/cars-tyres-modes-2.md`:
    // - peak tyre friction per compound: §2.1 to §2.2 (Wong 1993 via HPWizard, Bosch 1996);
    // - sliding friction as a fraction of peak: §2.1 gives 0.80 to 0.90 peak against 0.75
    //   sliding on dry asphalt, so a locked tyre keeps 0.85 of its peak force;
    // - rolling resistance and air density: §2.3 and the values `DriveSim` already had;
    // - longitudinal weight transfer `dW = m * a * h / L`: §3.4 (Wikipedia, Weight transfer);
    // - steady-state cornering, understeer gradient, characteristic and critical speed:
    //   Milliken & Milliken, "Race Car Vehicle Dynamics" (1995) ch. 5; Gillespie,
    //   "Fundamentals of Vehicle Dynamics" (1992) ch. 6.

    /// Gravity, m/s². The value `DriveSim` has always used, so the straight-line model is
    /// unchanged. The closed-form helpers above keep 9.80665 as their own default.
    public static let gravity = 9.81
    /// Air density, kg/m³. The same value `DriveSim` has always used.
    public static let airDensity = 1.2
    /// Rolling resistance coefficient. The same value `DriveSim` has always used.
    public static let rollingCoefficient = 0.012
    /// Brake force the pedal asks for at full travel, as a multiple of weight (1.1 g). The
    /// tyres, not this number, decide how much of it the car can use.
    public static let brakeCommandDecel = 1.1
    /// How fast tyre friction falls as load rises, as the exponent of `Fz / reference`.
    /// A real tyre loses about 5 to 15 percent of its friction coefficient when its load
    /// doubles; 0.15 puts that at the top of the band. The research file has no measured
    /// coefficient for this (it is marked NS), so the exponent is game-tuned.
    public static let tyreLoadSensitivity = 0.15
    /// Load at which a tyre makes its peak friction coefficient, N. A typical passenger tyre
    /// is rated around 4 to 5 kN; the research file has no per-tyre load, so this is a
    /// game-tuned reference.
    public static let tyreReferenceLoadN = 4000.0
    /// A tyre that has lost grip slides with this share of its peak force. Dry asphalt peak is
    /// 0.80 to 0.90 against 0.75 sliding (research file §2.1, Wong 1993), so 0.75 / 0.85 is
    /// about 0.88; 0.85 is used here and also covers the loss on the unloaded inner tyre.
    public static let slidingGripFraction = 0.85
    /// Extra slip angle at the grip limit, as a fraction of the linear estimate. The linear
    /// bicycle model gives 5 to 7 degrees at the limit; real tyres go a little past that
    /// before they let go, so the scrub force is raised by this share squared at saturation.
    public static let limitScrubRise = 0.4
    /// Two axles within this share of each other count as balanced.
    static let neutralBand = 0.01
    /// Fixed-point passes for the load-transfer loops. Four is within 0.001 m/s² of converged
    /// for the lateral limit and six within 0.001 m/s² for braking; both are deterministic.
    static let lateralPasses = 4
    static let brakingPasses = 6

    /// Peak dry friction coefficient in the direction the tyre rolls. These are the numbers
    /// `DriveSim` has always used, moved here so there is one table.
    public static func longitudinalMu(_ compound: Tyre.Compound) -> Double {
        switch compound {
        case .street: 1.0
        case .sport: 1.1
        case .semiSlick: 1.3
        case .dragRadial: 1.5
        }
    }

    /// Peak dry friction coefficient sideways. Street, sport and semi-slick tyres are close to
    /// symmetric. A drag radial is not: its soft, thin-walled construction and large
    /// longitudinal contact patch give it far less lateral grip than it has off the line, so it
    /// is the one compound whose two coefficients differ.
    public static func lateralMu(_ compound: Tyre.Compound) -> Double {
        switch compound {
        case .street: 1.0
        case .sport: 1.1
        case .semiSlick: 1.3
        case .dragRadial: 0.9
        }
    }

    /// Friction coefficient a tyre makes at `loadN`, with load sensitivity: friction falls as
    /// the tyre is pressed harder. Kept within 0.6 to 1.25 times `mu0` so a near-zero or huge
    /// load cannot produce a silly number.
    public static func peakMu(_ mu0: Double, loadN: Double) -> Double {
        guard loadN > 0, mu0 > 0, loadN.isFinite, mu0.isFinite else { return 0 }
        let ratio = loadN / tyreReferenceLoadN
        let mu = mu0 * pow(ratio, -tyreLoadSensitivity)
        return min(max(mu, 0.6 * mu0), 1.25 * mu0)
    }

    /// Lateral force one axle can hold, N: the sum of its two tyres, each with its own load
    /// and therefore its own friction coefficient. `transferN` is the load moved from the
    /// inside tyre to the outside one by body roll.
    public static func axleLateralCapacityN(mu0: Double, axleLoadN: Double, transferN: Double) -> Double {
        guard axleLoadN > 0 else { return 0 }
        let half = axleLoadN / 2
        let outer = max(0, half + transferN)
        let inner = max(0, half - transferN)
        return peakMu(mu0, loadN: outer) * outer + peakMu(mu0, loadN: inner) * inner
    }

    /// Longitudinal force left on an axle once it is already using `lateralN` sideways, N.
    /// This is the friction ellipse:
    /// `(Fx / (muLong * Fz))^2 + (Fy / (muLat * Fz))^2 <= 1`.
    ///
    /// With no lateral force the result is exactly `muLong * loadN`, which is what the
    /// straight-line model has always used, so a car that is not steering keeps its old
    /// behaviour bit for bit.
    ///
    /// Load sensitivity is deliberately not applied here: the straight-line grip is unchanged
    /// from the original model, and applying it would move every existing acceleration and
    /// quarter-mile number.
    public static func axleLongitudinalGripN(
        loadN: Double, lateralN: Double, muLong: Double, muLat: Double
    ) -> Double {
        guard loadN > 0, muLong > 0, muLat > 0 else { return 0 }
        let lateralCapacity = muLat * loadN
        let used = min(1, abs(lateralN) / lateralCapacity)
        return muLong * loadN * (1 - used * used).squareRoot()
    }

    /// Which axle saturates first, from the two axle limits.
    public static func balance(front: Double, rear: Double) -> CorneringBalance {
        let lower = min(front, rear)
        guard lower > 0, front.isFinite, rear.isFinite else { return .neutral }
        let spread = abs(front - rear) / lower
        if spread < neutralBand { return .neutral }
        return front < rear ? .understeer : .oversteer
    }

    /// The most lateral acceleration the tyres can hold, from the axle loads and the friction
    /// each axle makes at those loads. `longitudinalAccelMps2` moves load between the axles
    /// first, so a car on the throttle or the brakes has a different limit.
    ///
    /// Each axle's limit is the lateral acceleration at which the *car's* demand uses up that
    /// axle's capacity, `capacity / (mass * axleShare)`, and the car is held by the lower of
    /// the two. Lateral load transfer is split between the axles by their static weight share,
    /// standing in for roll stiffness distribution, which the catalogue does not carry.
    public static func lateralLimit(
        car: CarSetup, massKg: Double, longitudinalAccelMps2: Double = 0
    ) -> LateralLimit {
        let body = car.body.spec
        let handling = car.body.handling
        let mu = lateralMu(car.tyre.compound)
        let mass = max(1, massKg)
        let weight = mass * gravity
        let frontShare = min(max(body.frontWeight, 0.05), 0.95)
        let rearShare = 1 - frontShare
        let transfer = mass * longitudinalAccelMps2 * body.cgHeightM / body.wheelbaseM
        let frontLoad = max(0, weight * frontShare + transfer)
        let rearLoad = max(0, weight * rearShare - transfer)

        var frontLimit = mu * gravity
        var rearLimit = mu * gravity
        for _ in 0..<lateralPasses {
            // The lateral force the whole car is carrying, which is what moves load sideways.
            let sideways = mass * min(frontLimit, rearLimit) * body.cgHeightM / handling.trackM
            let frontCapacity = axleLateralCapacityN(
                mu0: mu, axleLoadN: frontLoad, transferN: sideways * frontShare
            )
            let rearCapacity = axleLateralCapacityN(
                mu0: mu, axleLoadN: rearLoad, transferN: sideways * rearShare
            )
            frontLimit = frontCapacity / (mass * frontShare)
            rearLimit = rearCapacity / (mass * rearShare)
        }
        return LateralLimit(
            accelMps2: min(frontLimit, rearLimit),
            frontAxleMps2: frontLimit,
            rearAxleMps2: rearLimit,
            frontLoadN: frontLoad,
            rearLoadN: rearLoad
        )
    }

    /// Steady-state cornering for one step.
    ///
    /// The steering angle is the road-wheel angle, and the steady-state bicycle model gives
    /// `delta = L/R + K * a_y`. With `a_y = v^2 / R` that solves to
    ///
    ///     a_y = v^2 * delta / (L + K * v^2)        R = (L + K * v^2) / delta
    ///
    /// so for a fixed steering angle the radius grows with the square of speed (an
    /// understeering car needs more lock to hold a radius as it goes faster) and the requested
    /// lateral acceleration is capped by `lateralLimit`. Above the critical speed of an
    /// oversteering car the linear solution runs away; the denominator is held at 5 percent of
    /// the wheelbase there and the grip limit does the rest, which is a documented stand-in for
    /// the spin the real car would enter.
    ///
    /// `scrubForceN` is the drag the slip angles themselves make:
    /// `F = m * a_y^2 / g * (f/cf + (1-f)/cr)`, raised near the limit (see `limitScrubRise`).
    public static func cornering(
        speedMps: Double,
        steering: Double,
        car: CarSetup,
        massKg: Double,
        longitudinalAccelMps2: Double = 0
    ) -> CorneringState {
        let handling = car.body.handling
        let mass = max(1, massKg)
        let speed = bounded(speedMps, 0...200, or: 0)
        let steer = bounded(steering, -1...1, or: 0)
        let angle = steer * handling.maxRoadWheelAngleRad
        let limit = lateralLimit(car: car, massKg: mass, longitudinalAccelMps2: longitudinalAccelMps2)

        guard steer != 0, speed > 0 else {
            return CorneringState(
                steeringAngleRad: angle, lateralAccelMps2: 0, yawRateRadPerS: 0,
                cornerRadiusM: nil, lateralLimitMps2: limit.accelMps2,
                frontLimitMps2: limit.frontAxleMps2, rearLimitMps2: limit.rearAxleMps2,
                balance: limit.balance, gripLimited: false, frontUse: 0, rearUse: 0,
                scrubForceN: 0
            )
        }

        let denominator = max(
            handling.wheelbaseM + handling.understeerGradient * speed * speed,
            0.05 * handling.wheelbaseM
        )
        let demand = speed * speed * angle / denominator
        let capped = min(max(demand, -limit.accelMps2), limit.accelMps2)
        let yawRate = capped / speed
        let radius = abs(capped) > 0 ? speed * speed / abs(capped) : nil

        let body = car.body.spec
        let frontShare = min(max(body.frontWeight, 0.05), 0.95)
        let slipFactor = frontShare / handling.frontCorneringStiffness
            + (1 - frontShare) / handling.rearCorneringStiffness
        let saturation = limit.accelMps2 > 0 ? min(1, abs(capped) / limit.accelMps2) : 0
        let scrub = mass * capped * capped / gravity * slipFactor
            * (1 + limitScrubRise * saturation * saturation)

        return CorneringState(
            steeringAngleRad: angle,
            lateralAccelMps2: capped,
            yawRateRadPerS: yawRate,
            cornerRadiusM: radius,
            lateralLimitMps2: limit.accelMps2,
            frontLimitMps2: limit.frontAxleMps2,
            rearLimitMps2: limit.rearAxleMps2,
            balance: limit.balance,
            gripLimited: abs(demand) > limit.accelMps2,
            frontUse: limit.frontAxleMps2 > 0 ? min(1, abs(capped) / limit.frontAxleMps2) : 0,
            rearUse: limit.rearAxleMps2 > 0 ? min(1, abs(capped) / limit.rearAxleMps2) : 0,
            scrubForceN: scrub
        )
    }

    /// Brake force at the tyres for one step.
    ///
    /// The pedal asks for `pedal * 1.1 * weight` of deceleration and the force is split front
    /// and rear by a fixed bias. Each axle is then capped by the longitudinal force left after
    /// its share of the lateral force (the friction ellipse), so a car that is cornering cannot
    /// also brake at full force, and one that is braking hard transfers load forward, which
    /// changes both axle loads.
    ///
    /// There is no proportioning valve, ABS or EBD. The fixed bias is set for about 1 g of
    /// deceleration, so at higher pedal the rear axle asks for more than the load left on it,
    /// locks, and contributes only its sliding friction (`slidingGripFraction`). That is why
    /// the achieved deceleration plateaus near 0.9 to 1.0 g. It is the behaviour of a
    /// fixed-bias system, not of a car with EBD, and is the main braking assumption here.
    public static func braking(
        pedal: Double,
        speedMps: Double,
        car: CarSetup,
        massKg: Double,
        lateralAccelMps2: Double = 0
    ) -> BrakingState {
        let request = bounded(pedal, 0...1, or: 0) * brakeCommandDecel
        guard request > 0 else { return .none }

        let body = car.body.spec
        let handling = car.body.handling
        let mass = max(1, massKg)
        let weight = mass * gravity
        let speed = bounded(speedMps, 0...200, or: 0)
        let frontShare = min(max(body.frontWeight, 0.05), 0.95)
        let rearShare = 1 - frontShare
        let muLong = longitudinalMu(car.tyre.compound)
        let muLat = lateralMu(car.tyre.compound)
        let lateral = mass * bounded(lateralAccelMps2, -100...100, or: 0)
        let lateralFront = abs(lateral * frontShare)
        let lateralRear = abs(lateral * rearShare)
        let demand = request * weight
        let frontDemand = handling.brakeBiasFront * demand
        let rearDemand = (1 - handling.brakeBiasFront) * demand
        let drag = 0.5 * airDensity * body.cdA * speed * speed
        let rolling = speed > 0.01 ? rollingCoefficient * weight : 0

        var frontLoad = weight * frontShare
        var rearLoad = weight * rearShare
        var frontForce = frontDemand
        var rearForce = rearDemand
        var frontLocked = false
        var rearLocked = false
        var decel = 0.0

        for _ in 0..<brakingPasses {
            // Weight transfer follows the deceleration the whole car is making, so the loads
            // are solved by fixed-point iteration rather than from one guessed value.
            let transfer = mass * decel * body.cgHeightM / body.wheelbaseM
            frontLoad = max(0, weight * frontShare + transfer)
            rearLoad = max(0, weight * rearShare - transfer)
            let frontCapacity = axleLongitudinalGripN(
                loadN: frontLoad, lateralN: lateralFront, muLong: muLong, muLat: muLat
            )
            let rearCapacity = axleLongitudinalGripN(
                loadN: rearLoad, lateralN: lateralRear, muLong: muLong, muLat: muLat
            )
            frontLocked = frontDemand > frontCapacity
            rearLocked = rearDemand > rearCapacity
            frontForce = frontLocked ? slidingGripFraction * frontCapacity : frontDemand
            rearForce = rearLocked ? slidingGripFraction * rearCapacity : rearDemand
            decel = (frontForce + rearForce + drag + rolling) / mass
        }

        return BrakingState(
            totalForceN: frontForce + rearForce,
            frontForceN: frontForce,
            rearForceN: rearForce,
            frontLoadN: frontLoad,
            rearLoadN: rearLoad,
            frontLocked: frontLocked,
            rearLocked: rearLocked,
            decelMps2: (frontForce + rearForce) / mass
        )
    }

    /// Distance and time a full-pedal stop takes from `speedMps`, holding `steering`.
    ///
    /// Integrates the same brake, drag, rolling and tyre-scrub equations as a drive step at
    /// 240 steps a second, so the figure matches what the car model does. Engine braking is not
    /// included: this is the tyre-limited answer, and a car left in gear stops sooner.
    public static func stoppingDistance(
        fromSpeedMps speedMps: Double,
        car: CarSetup,
        massKg: Double,
        steering: Double = 0
    ) -> BrakingDistance {
        let step = 1.0 / 240
        let mass = max(1, massKg)
        var speed = bounded(speedMps, 0...200, or: 0)
        guard speed > 0 else { return BrakingDistance(distanceM: 0, timeS: 0) }
        let weight = mass * gravity
        var distance = 0.0
        var time = 0.0
        while speed > 0.05 && time < 60 {
            let corner = cornering(speedMps: speed, steering: steering, car: car, massKg: mass)
            let brakes = braking(
                pedal: 1, speedMps: speed, car: car, massKg: mass,
                lateralAccelMps2: corner.lateralAccelMps2
            )
            let drag = 0.5 * airDensity * car.body.spec.cdA * speed * speed
            let rolling = rollingCoefficient * weight
            let decel = (brakes.totalForceN + drag + rolling + corner.scrubForceN) / mass
            let next = max(0, speed - decel * step)
            distance += 0.5 * (speed + next) * step
            speed = next
            time += step
        }
        return BrakingDistance(distanceM: distance, timeS: time)
    }
}

/// Which axle runs out of lateral grip first in a steady corner.
public enum CorneringBalance: String, Sendable, Equatable, CaseIterable {
    /// The two axles reach their limit within a percent of each other.
    case neutral
    /// The front tyres saturate first: for a given steering angle the car asks for a tighter
    /// radius than it can hold, so it runs wide as speed rises.
    case understeer
    /// The rear tyres saturate first: the rear of the car is past its limit before the front,
    /// which is the condition that leads to a spin.
    case oversteer
}

/// The handling numbers one body needs for the bicycle model: steering lock, track, axle
/// cornering stiffness and brake bias. Pure value type, derived from the body's `CarSpec`
/// plus the game-tuned constants in `init`.
public struct CarHandling: Sendable, Equatable {
    /// Wheelbase, m. Copied from `CarSpec` so the derived speeds need no lookup.
    public let wheelbaseM: Double
    /// Track width, m. The research file (`docs/research/raw/cars-tyres-modes-2.md` §1.1)
    /// records track as not sourced for every body type, so these are game-tuned to the
    /// published class dimensions of each body.
    public let trackM: Double
    /// Road-wheel angle at full lock, rad. Full lock sets the low-speed turning circle:
    /// radius = wheelbase / tan(lock).
    public let maxRoadWheelAngleRad: Double
    /// Front axle cornering stiffness per newton of axle load, per radian. A tyre's cornering
    /// stiffness is quoted as `C_alpha / Fz` and is typically 0.15 to 0.25 per degree, which is
    /// 9 to 14 per radian; these sit in that band and are game-tuned within it.
    /// Source for the band: Milliken & Milliken, "Race Car Vehicle Dynamics" (1995), ch. 5,
    /// and Gillespie, "Fundamentals of Vehicle Dynamics" (1992), ch. 6.
    public let frontCorneringStiffness: Double
    /// Rear axle cornering stiffness per newton of axle load, per radian. See
    /// `frontCorneringStiffness`.
    public let rearCorneringStiffness: Double
    /// Share of the brake force applied by the front axle. Game-tuned to the axle loads a
    /// production car is set up for; there is no proportioning valve or EBD in this model, so
    /// the rear axle is over-braked at high deceleration (see `VehicleDynamics.braking`).
    public let brakeBiasFront: Double

    public init(body: CarBody) {
        let spec = body.spec
        self.wheelbaseM = spec.wheelbaseM
        switch body {
        case .hatch:
            // Nose-heavy front-wheel drive: strong understeer, 4.4 m lock-to-lock radius.
            self.trackM = 1.50
            self.maxRoadWheelAngleRad = 0.52
            self.frontCorneringStiffness = 9.0
            self.rearCorneringStiffness = 12.5
            self.brakeBiasFront = 0.66
        case .coupe:
            // Balanced rear-wheel drive: close to neutral, long characteristic speed.
            self.trackM = 1.56
            self.maxRoadWheelAngleRad = 0.50
            self.frontCorneringStiffness = 10.0
            self.rearCorneringStiffness = 11.8
            self.brakeBiasFront = 0.64
        case .muscle:
            // Heavy nose and a short rear: mild understeer, the widest lock of the rear-drives.
            self.trackM = 1.60
            self.maxRoadWheelAngleRad = 0.48
            self.frontCorneringStiffness = 9.5
            self.rearCorneringStiffness = 12.3
            self.brakeBiasFront = 0.62
        case .pickup:
            // Tall centre of gravity and soft, load-biased tyres: the most understeery body.
            self.trackM = 1.70
            self.maxRoadWheelAngleRad = 0.55
            self.frontCorneringStiffness = 8.5
            self.rearCorneringStiffness = 13.0
            self.brakeBiasFront = 0.65
        case .super_:
            // Mid-engine: the rear axle is the stiffer one, so the car oversteers above its
            // critical speed.
            self.trackM = 1.63
            self.maxRoadWheelAngleRad = 0.46
            self.frontCorneringStiffness = 10.5
            self.rearCorneringStiffness = 9.4
            self.brakeBiasFront = 0.60
        }
    }

    /// Classic understeer gradient K, rad per m/s² of lateral acceleration. Positive means
    /// understeer. From the steady-state bicycle model:
    /// `delta = L/R + K * a_y` with `K = (1/cf - 1/cr) / g`, where cf and cr are the axle
    /// cornering stiffnesses above. Milliken & Milliken ch. 5, Gillespie ch. 6.
    public var understeerGradient: Double {
        ((1 / frontCorneringStiffness) - (1 / rearCorneringStiffness)) / VehicleDynamics.gravity
    }

    /// The same gradient in the units the literature quotes, degrees per g.
    public var understeerGradientDegPerG: Double {
        understeerGradient * VehicleDynamics.gravity * 180 / Double.pi
    }

    /// Speed at which a given steering angle needs twice the Ackermann angle to hold the same
    /// radius, m/s. Only an understeering car (positive gradient) has one.
    public var characteristicSpeedMps: Double? {
        let gradient = understeerGradient
        guard gradient > 0 else { return nil }
        return (wheelbaseM / gradient).squareRoot()
    }

    /// Speed above which the linear bicycle model has no steady-state solution, m/s. Only an
    /// oversteering car (negative gradient) has one: beyond it the rear slip angle grows
    /// without bound and the car spins.
    public var criticalSpeedMps: Double? {
        let gradient = understeerGradient
        guard gradient < 0 else { return nil }
        return (-wheelbaseM / gradient).squareRoot()
    }

    /// Tightest radius the steering geometry allows at walking pace, m.
    public var minimumTurnRadiusM: Double {
        wheelbaseM / tan(maxRoadWheelAngleRad)
    }
}

public extension CarBody {
    /// Handling constants for this body. See `CarHandling`.
    var handling: CarHandling { CarHandling(body: self) }
}

/// What the tyres can hold laterally for one car, and how close each axle is to its share.
public struct LateralLimit: Sendable, Equatable {
    /// Lateral acceleration the car can hold, m/s². The smaller of the two axle limits.
    public let accelMps2: Double
    /// Lateral acceleration at which the front axle is fully used, m/s².
    public let frontAxleMps2: Double
    /// Lateral acceleration at which the rear axle is fully used, m/s².
    public let rearAxleMps2: Double
    /// Front axle load used for the calculation, N.
    public let frontLoadN: Double
    /// Rear axle load used for the calculation, N.
    public let rearLoadN: Double

    /// Which axle reaches its limit first.
    public var balance: CorneringBalance {
        VehicleDynamics.balance(front: frontAxleMps2, rear: rearAxleMps2)
    }
}

/// The lateral result of one step.
public struct CorneringState: Sendable, Equatable {
    /// Road-wheel angle, rad. Positive is a left turn.
    public let steeringAngleRad: Double
    /// Lateral acceleration, m/s². Positive is a left turn.
    public let lateralAccelMps2: Double
    /// Yaw rate, rad/s. Positive is counter-clockwise seen from above.
    public let yawRateRadPerS: Double
    /// Radius the car is following, m. Nil when it is going straight.
    public let cornerRadiusM: Double?
    /// Lateral acceleration the tyres can hold at this speed and load, m/s².
    public let lateralLimitMps2: Double
    public let frontLimitMps2: Double
    public let rearLimitMps2: Double
    public let balance: CorneringBalance
    /// True when the steering angle asked for more lateral acceleration than the tyres can
    /// hold, so the car is running wide of the radius the geometry alone would give.
    public let gripLimited: Bool
    /// Share of the front axle's lateral grip in use, 0...1. 1 is the limit.
    public let frontUse: Double
    /// Share of the rear axle's lateral grip in use, 0...1. 1 is the limit.
    public let rearUse: Double
    /// Drag from the tyres' slip angles, N. Zero when going straight.
    public let scrubForceN: Double

    public var steeringAngleDeg: Double { steeringAngleRad * 180 / Double.pi }
    public var lateralAccelG: Double { lateralAccelMps2 / VehicleDynamics.gravity }
    public var lateralLimitG: Double { lateralLimitMps2 / VehicleDynamics.gravity }
    public var yawRateDegPerS: Double { yawRateRadPerS * 180 / Double.pi }

    /// Going straight: no lateral force, no yaw, no scrub.
    public static let straight = CorneringState(
        steeringAngleRad: 0, lateralAccelMps2: 0, yawRateRadPerS: 0, cornerRadiusM: nil,
        lateralLimitMps2: 0, frontLimitMps2: 0, rearLimitMps2: 0, balance: .neutral,
        gripLimited: false, frontUse: 0, rearUse: 0, scrubForceN: 0
    )
}

/// The braking result of one step.
public struct BrakingState: Sendable, Equatable {
    /// Brake force at the tyres, N. Always positive.
    public let totalForceN: Double
    public let frontForceN: Double
    public let rearForceN: Double
    /// Front axle load the brake force was limited by, N.
    public let frontLoadN: Double
    /// Rear axle load the brake force was limited by, N.
    public let rearLoadN: Double
    /// The demanded front force exceeded the front axle's usable grip, so the front wheels
    /// would lock.
    public let frontLocked: Bool
    /// The demanded rear force exceeded the rear axle's usable grip, so the rear wheels would
    /// lock.
    public let rearLocked: Bool
    /// Deceleration the brake force alone gives, m/s².
    public let decelMps2: Double

    /// No pedal: no brake force at all.
    public static let none = BrakingState(
        totalForceN: 0, frontForceN: 0, rearForceN: 0, frontLoadN: 0, rearLoadN: 0,
        frontLocked: false, rearLocked: false, decelMps2: 0
    )
}

/// Distance and time a full-pedal stop takes from a given speed.
public struct BrakingDistance: Sendable, Equatable {
    public let distanceM: Double
    public let timeS: Double
}
