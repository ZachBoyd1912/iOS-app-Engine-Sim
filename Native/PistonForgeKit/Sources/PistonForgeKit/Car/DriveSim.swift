import Foundation

/// One step's input. Pedals are 0...1. A shift flag counts only on its rising edge (false to
/// true between two steps), so holding a button does not shift again. Steering is -1...1, full
/// right to full left, and maps to the body's road-wheel lock.
public struct DriveInput: Sendable, Equatable {
    public var throttle: Double
    public var brake: Double
    public var manualShiftUp: Bool
    public var manualShiftDown: Bool
    public var launchControl: Bool
    /// Steering wheel position, -1 (full right) to 1 (full left). 0 is straight ahead and
    /// leaves the longitudinal model exactly as it was before cornering existed.
    public var steering: Double

    public init(
        throttle: Double = 0, brake: Double = 0, manualShiftUp: Bool = false,
        manualShiftDown: Bool = false, launchControl: Bool = false, steering: Double = 0
    ) {
        self.throttle = throttle
        self.brake = brake
        self.manualShiftUp = manualShiftUp
        self.manualShiftDown = manualShiftDown
        self.launchControl = launchControl
        self.steering = steering
    }
}

/// What the car is doing after a step.
public struct DriveState: Sendable, Equatable {
    public var time: Double
    public var distanceM: Double
    public var speedMps: Double
    /// Engine speed in rpm. For the electric drive, motor speed.
    public var rpm: Double
    /// 1-based gear. Neutral and reverse are not modelled, so this is never 0 or below.
    public var gear: Int
    public var shifting: Bool
    /// Share of the demanded drive force that the tyres cannot hold, 0...1.
    public var wheelSlip: Double
    /// Drive force at the tyres, N. Negative under engine braking.
    public var driveForceN: Double
    public var accelG: Double
    /// Clutch locked (manual, dual-clutch), converter locked up (automatic), or always true.
    public var clutchEngaged: Bool
    public var limiterActive: Bool
    /// Steering, lateral grip, yaw and tyre scrub for this step.
    public var cornering: CorneringState
    /// Brake force split, axle loads and lock state for this step.
    public var braking: BrakingState

    public var speedKph: Double { speedMps * 3.6 }
    public var speedMph: Double { speedMps * DriveState.mphPerMps }

    static let mphPerMps = 2.2369362920544
}

/// Longitudinal and lateral model of one car. Engine torque comes from the build's dyno pull
/// and goes through the gearbox and final drive to the driven tyres, limited by grip and weight
/// transfer. Steering adds a bicycle-model cornering limit, a friction circle on the driven
/// tyres and tyre scrub; with no steering the longitudinal model is exactly what it always was.
/// Deterministic: the same inputs always give the same states.
public struct DriveSim: Sendable {
    static let idleRpm = 900.0
    /// Engine speed a launch holds with launch control, as a share of redline.
    static let launchHoldFraction = 0.55
    /// Without launch control the engine revs up from idle at this rate until it reaches the hold speed.
    static let launchRampRpmPerS = 2500.0
    /// A slipping clutch passes at most this many times the peak engine torque.
    static let clutchCapFactor = 1.6
    /// Engine braking at zero pedal, as a share of the wide-open torque at that speed.
    static let engineBrakeFraction = 0.12
    /// Road and brake constants now live in `VehicleDynamics`, which the lateral and braking
    /// model shares. The values are unchanged.
    static let gravity = VehicleDynamics.gravity
    static let airDensity = VehicleDynamics.airDensity
    static let rollingCoefficient = VehicleDynamics.rollingCoefficient
    /// Brake force at full pedal, as a multiple of weight. Capped by grip.
    static let brakeDecel = VehicleDynamics.brakeCommandDecel
    /// All-wheel drive uses the whole weight, with this efficiency factor on its grip (from the brief).
    static let awdGripFactor = 0.85
    /// Engine mass estimate, kg per litre of displacement.
    static let engineKgPerLitre = 90.0
    /// Motor speed limit and the speed where power starts to fall, for the electric drive.
    static let electricMaxRpm = 16000.0
    static let electricBaseRpm = 4800.0

    public let mode: DriveMode
    public let automatic: Bool
    public let gearbox: Gearbox

    private let kind: GearboxSpec.Kind
    private let ratios: [Double]
    private let shiftTimeS: Double
    private let stallRpm: Double
    private let lockupGear: Int
    private let maxInputTorqueNm: Double
    private let cvtRange: ClosedRange<Double>
    /// Final drive ratio. 1 for the electric drive, which uses its single ratio alone.
    private let finalDrive: Double
    private let massKg: Double
    private let cdA: Double
    private let drivetrain: Drivetrain
    private let frontWeight: Double
    private let wheelbaseM: Double
    private let cgHeightM: Double
    private let wheelRadiusM: Double
    private let gripMu: Double
    /// Peak grip sideways. Differs from `gripMu` only for a drag radial.
    private let lateralGripMu: Double
    private let driveEfficiency: Double
    /// The car as set up, kept for the cornering and braking model.
    private let carSetup: CarSetup
    /// Dyno pull as (rpm, Nm) pairs in rpm order, 100 rpm apart from the dyno's start speed.
    private let curveRpm: [Double]
    private let curveNm: [Double]
    private let peakNm: Double
    /// Rev limit for the engine; motor limit for the electric drive.
    private let redlineRpm: Double
    private let shiftsGears: Bool
    private let autoShifts: Bool
    private let gearCount: Int

    private var gearIndex: Int
    private var shiftTimer: Double
    private var clutchLocked: Bool
    private var launchClock: Double
    private var lastAccel: Double
    /// Seconds since the last gear change; stops the box hunting up and down.
    private var shiftAge: Double
    private var prevShiftUp: Bool
    private var prevShiftDown: Bool

    public private(set) var state: DriveState

    /// Runs the build's dyno pull once to get its torque curve. The car is set up from `car`.
    public init(build: EngineBuild, car: CarSetup, mode: DriveMode, automatic: Bool) {
        let clean = build.sanitized()
        let gearboxSpec = car.gearbox.spec
        let body = car.body.spec
        let dyno = runDynoToEnd(clean)

        var rpms: [Double] = []
        var torques: [Double] = []
        for sample in dyno.samples where sample.rpm.isFinite && sample.torqueNm.isFinite {
            rpms.append(sample.rpm)
            torques.append(max(0, sample.torqueNm))
        }
        let peak = torques.max() ?? 0

        let electric = gearboxSpec.kind == .direct
        let redline: Double
        if electric {
            redline = DriveSim.electricMaxRpm
        } else {
            redline = min(clean.ecu.revLimit, clean.mechanicalRedline)
        }

        let shifts = gearboxSpec.kind != .cvt && gearboxSpec.kind != .direct
        let auto = shifts && (automatic || gearboxSpec.kind == .torqueConverter || gearboxSpec.kind == .dualClutch)

        let widthMm = bounded(car.tyre.widthMm, 100...400, or: 225)
        let radius = 0.32 + 0.0001 * (widthMm - 200)

        let grip = VehicleDynamics.longitudinalMu(car.tyre.compound)
        let lateralGrip = VehicleDynamics.lateralMu(car.tyre.compound)

        let efficiency: Double
        switch gearboxSpec.kind {
        case .cvt: efficiency = 0.88
        case .direct: efficiency = 0.95
        default: efficiency = 0.90
        }

        let engineMass = DriveSim.engineKgPerLitre * clean.displacementCc / 1000

        self.mode = mode
        self.automatic = automatic
        self.gearbox = car.gearbox
        self.kind = gearboxSpec.kind
        self.ratios = gearboxSpec.ratios
        self.shiftTimeS = gearboxSpec.shiftTimeS
        self.stallRpm = gearboxSpec.stallRpm
        self.lockupGear = gearboxSpec.lockupGear
        self.maxInputTorqueNm = gearboxSpec.maxInputTorqueNm
        self.cvtRange = gearboxSpec.cvtRatioRange ?? (0.4...2.6)
        self.finalDrive = electric ? 1.0 : bounded(car.finalDrive, 1...8, or: 3.55)
        self.massKg = body.massKg + engineMass
        self.cdA = body.cdA
        self.drivetrain = body.drivetrain
        self.frontWeight = body.frontWeight
        self.wheelbaseM = body.wheelbaseM
        self.cgHeightM = body.cgHeightM
        self.wheelRadiusM = radius
        self.gripMu = grip
        self.lateralGripMu = lateralGrip
        self.driveEfficiency = efficiency
        self.carSetup = car
        self.curveRpm = rpms
        self.curveNm = torques
        self.peakNm = peak
        self.redlineRpm = redline
        self.shiftsGears = shifts
        self.autoShifts = auto
        self.gearCount = shifts ? gearboxSpec.ratios.count : 1

        self.gearIndex = 1
        self.shiftTimer = 0
        self.clutchLocked = false
        self.launchClock = 0
        self.lastAccel = 0
        self.shiftAge = 10
        self.prevShiftUp = false
        self.prevShiftDown = false
        self.state = DriveState(
            time: 0, distanceM: 0, speedMps: 0, rpm: DriveSim.idleRpm, gear: 1, shifting: false,
            wheelSlip: 0, driveForceN: 0, accelG: 0, clutchEngaged: false, limiterActive: false,
            cornering: .straight, braking: .none
        )
    }

    /// Advances the car by `dt` seconds (at most 0.1 is used) and returns the new state.
    public mutating func step(dt: Double, input: DriveInput) -> DriveState {
        let h = bounded(dt, 0.0...0.1, or: 0)
        guard h > 0 else { return state }
        let pedal = bounded(input.throttle, 0...1, or: 0)
        let brake = bounded(input.brake, 0...1, or: 0)
        let steer = bounded(input.steering, -1...1, or: 0)
        let hold = input.launchControl || kind == .dualClutch
        shiftAge += h

        let upEdge = input.manualShiftUp && !prevShiftUp
        let downEdge = input.manualShiftDown && !prevShiftDown
        prevShiftUp = input.manualShiftUp
        prevShiftDown = input.manualShiftDown

        if shiftTimer > 0 {
            shiftTimer = max(0, shiftTimer - h)
        }

        let speed = state.speedMps
        let wheelRpm = speed / wheelRadiusM * 60 / (2 * Double.pi)

        // Gear changes. A shift in progress blocks the next one.
        if shiftTimer <= 0 {
            if autoShifts {
                autoShift(pedal: pedal, wheelRpm: wheelRpm, hold: hold)
            } else if shiftsGears {
                if upEdge && gearIndex < gearCount {
                    startShift(to: gearIndex + 1)
                } else if downEdge && gearIndex > 1 {
                    startShift(to: gearIndex - 1)
                }
            }
        }

        // Clutch launch: the clutch locks once the wheels have caught up with the held engine speed.
        if usesClutch {
            if speed < 0.1 && gearIndex == 1 {
                clutchLocked = false
                launchClock = 0
            }
            if !clutchLocked {
                let lockRpm = wheelRpm * totalRatio(wheelRpm: wheelRpm, pedal: pedal)
                if lockRpm >= slipTargetRpm(hold: hold) {
                    clutchLocked = true
                } else {
                    launchClock += h
                }
            }
        }

        let rpm = engineRpm(pedal: pedal, hold: hold, wheelRpm: wheelRpm)
        let shifting = shiftTimer > 0

        // Engine torque: wide-open curve times the pedal map, with engine braking off the pedal.
        let throttle = pow(pedal, mode.throttleExponent)
        let fullNm = wotTorque(rpm: rpm)
        let driven = fullNm * throttle
        let braking = DriveSim.engineBrakeFraction * fullNm * (1 - throttle)
        var engineNm = driven - braking
        var limiterActive = false
        if rpm >= redlineRpm && engineNm > 0 {
            engineNm = 0
            limiterActive = true
        }
        if engineNm > 0 {
            engineNm *= mode.torqueLimitFraction
        }
        engineNm = min(engineNm, maxInputTorqueNm)
        if usesClutch && !clutchLocked {
            engineNm = min(engineNm, DriveSim.clutchCapFactor * peakNm)
        }

        // Wheel torque, then the force the driven tyres are asked for.
        let total = totalRatio(wheelRpm: wheelRpm, pedal: pedal)
        let wheelNm = engineNm * total * driveEfficiency
        let demandN = shifting ? 0.0 : wheelNm / wheelRadiusM

        // Lateral state from the steering angle. With no steering this is all exactly zero and
        // none of the terms below move: the straight-line model is unchanged.
        let cornering = VehicleDynamics.cornering(
            speedMps: speed, steering: steer, car: carSetup, massKg: massKg,
            longitudinalAccelMps2: lastAccel
        )
        let lateralN = massKg * cornering.lateralAccelMps2

        // Grip from the load on the driven axle. Acceleration moves weight to the rear.
        let weight = massKg * DriveSim.gravity
        let transfer = massKg * lastAccel * cgHeightM / wheelbaseM
        let frontLoad = max(0, weight * frontWeight - transfer)
        let rearLoad = max(0, weight * (1 - frontWeight) + transfer)
        var drivenLoad = weight
        var gripFactor = 1.0
        switch drivetrain {
        case .rwd: drivenLoad = rearLoad
        case .fwd: drivenLoad = frontLoad
        case .awd: gripFactor = DriveSim.awdGripFactor
        }
        drivenLoad = max(0, drivenLoad)

        // Friction circle: the lateral force the driven axle is carrying leaves less for drive.
        let gripN: Double
        if lateralN == 0 {
            gripN = gripMu * gripFactor * drivenLoad
        } else {
            switch drivetrain {
            case .rwd:
                gripN = VehicleDynamics.axleLongitudinalGripN(
                    loadN: rearLoad, lateralN: lateralN * (1 - frontWeight),
                    muLong: gripMu, muLat: lateralGripMu
                )
            case .fwd:
                gripN = VehicleDynamics.axleLongitudinalGripN(
                    loadN: frontLoad, lateralN: lateralN * frontWeight,
                    muLong: gripMu, muLat: lateralGripMu
                )
            case .awd:
                let front = VehicleDynamics.axleLongitudinalGripN(
                    loadN: frontLoad, lateralN: lateralN * frontWeight,
                    muLong: gripMu, muLat: lateralGripMu
                )
                let rear = VehicleDynamics.axleLongitudinalGripN(
                    loadN: rearLoad, lateralN: lateralN * (1 - frontWeight),
                    muLong: gripMu, muLat: lateralGripMu
                )
                gripN = DriveSim.awdGripFactor * (front + rear)
            }
        }

        let tractive = min(max(demandN, -gripN), gripN)
        var slip = 0.0
        if demandN > gripN {
            slip = 1 - gripN / demandN
        }

        // Resistance: brakes, drag, rolling and the drag the slip angles make.
        let brakes = VehicleDynamics.braking(
            pedal: brake, speedMps: speed, car: carSetup, massKg: massKg,
            lateralAccelMps2: cornering.lateralAccelMps2
        )
        let drag = 0.5 * DriveSim.airDensity * cdA * speed * speed
        let rolling = speed > 0.01 ? DriveSim.rollingCoefficient * weight : 0.0
        let net = tractive - drag - rolling - brakes.totalForceN - cornering.scrubForceN

        var newSpeed = speed + net / massKg * h
        if newSpeed < 0 {
            newSpeed = 0
        }
        let accel = (newSpeed - speed) / h
        let distance = state.distanceM + 0.5 * (speed + newSpeed) * h
        lastAccel = accel

        let next = DriveState(
            time: state.time + h,
            distanceM: distance,
            speedMps: newSpeed,
            rpm: rpm,
            gear: gearIndex,
            shifting: shifting,
            wheelSlip: slip,
            driveForceN: tractive,
            accelG: accel / DriveSim.gravity,
            clutchEngaged: engagedNow(),
            limiterActive: limiterActive,
            cornering: cornering,
            braking: brakes
        )
        state = next
        return next
    }

    // MARK: - Gearbox logic

    private var usesClutch: Bool {
        kind == .manual || kind == .sequential || kind == .dualClutch
    }

    /// Engine speed the launch holds while the clutch is slipping, rpm.
    private var launchHoldRpm: Double {
        DriveSim.launchHoldFraction * redlineRpm
    }

    /// Engine speed a slipping clutch holds: the launch-control hold, or a ramp up from idle.
    private func slipTargetRpm(hold: Bool) -> Double {
        if hold {
            return launchHoldRpm
        }
        let ramp = DriveSim.idleRpm + DriveSim.launchRampRpmPerS * launchClock
        return min(launchHoldRpm, ramp)
    }

    /// The CVT's wanted engine speed for this pedal, rpm.
    private func cvtTargetRpm(pedal: Double) -> Double {
        let fraction = 0.55 + 0.35 * pedal
        return fraction * redlineRpm
    }

    /// Engine turns per wheel turn, including the final drive. For a CVT, the ratio that holds
    /// its wanted speed, kept within its range. For the electric drive, its single ratio.
    private func totalRatio(wheelRpm: Double, pedal: Double) -> Double {
        if kind == .cvt {
            let target = cvtTargetRpm(pedal: pedal)
            let needed = target / max(wheelRpm, 1)
            let low = cvtRange.lowerBound * finalDrive
            let high = cvtRange.upperBound * finalDrive
            return min(max(needed, low), high)
        }
        let index = min(max(gearIndex, 1), ratios.count) - 1
        return ratios[index] * finalDrive
    }

    /// Engine speed for the current gear and clutch state, rpm.
    private func engineRpm(pedal: Double, hold: Bool, wheelRpm: Double) -> Double {
        let idle = DriveSim.idleRpm
        switch kind {
        case .manual, .sequential, .dualClutch:
            if !clutchLocked {
                return slipTargetRpm(hold: hold)
            }
            return max(idle, wheelRpm * totalRatio(wheelRpm: wheelRpm, pedal: pedal))
        case .torqueConverter:
            let derived = wheelRpm * totalRatio(wheelRpm: wheelRpm, pedal: pedal)
            if gearIndex < lockupGear {
                // Unlocked converter: the engine can run up to stall speed with the pedal down.
                let lift = idle + (stallRpm - idle) * pedal
                return max(derived, lift)
            }
            return max(idle, derived)
        case .cvt:
            let lift = idle + (0.5 * redlineRpm - idle) * pedal
            return max(lift, wheelRpm * totalRatio(wheelRpm: wheelRpm, pedal: pedal))
        case .direct:
            return wheelRpm * totalRatio(wheelRpm: wheelRpm, pedal: pedal)
        }
    }

    /// Whether the clutch or converter is locked now, for the state.
    private func engagedNow() -> Bool {
        if usesClutch {
            return clutchLocked
        }
        if kind == .torqueConverter {
            return gearIndex >= lockupGear
        }
        return true
    }

    /// Upshift when the engine is above the mode's upshift point; downshift when it is below the
    /// downshift point and the lower gear would still sit under the upshift point (no hunting).
    private mutating func autoShift(pedal: Double, wheelRpm: Double, hold: Bool) {
        let rpm = engineRpm(pedal: pedal, hold: hold, wheelRpm: wheelRpm)
        let up = mode.upshiftRpmFraction(throttle: pedal) * redlineRpm
        let down = mode.downshiftRpmFraction(throttle: pedal) * redlineRpm
        if gearIndex < gearCount && rpm >= up {
            startShift(to: gearIndex + 1)
        } else if gearIndex > 1 && rpm < down && shiftAge > 0.6 {
            let here = ratios[gearIndex - 1]
            let below = ratios[gearIndex - 2]
            let rpmBelow = rpm * below / here
            if rpmBelow < up * 0.9 {
                startShift(to: gearIndex - 1)
            }
        }
    }

    /// Changes gear and cuts torque for the shift time, scaled by the drive mode.
    private mutating func startShift(to newGear: Int) {
        gearIndex = newGear
        shiftTimer = shiftTimeS * mode.shiftSpeedScale
        shiftAge = 0
        clutchLocked = true
    }

    // MARK: - Engine torque

    /// Wide-open-throttle torque at `rpm`, Nm. For the engine, linear between dyno samples,
    /// held flat beyond the ends. For the electric drive, flat to the base speed, then falling
    /// with speed so that power stays constant.
    private func wotTorque(rpm: Double) -> Double {
        if kind == .direct {
            if rpm <= DriveSim.electricBaseRpm {
                return peakNm
            }
            return peakNm * DriveSim.electricBaseRpm / rpm
        }
        return curveTorque(rpm: rpm)
    }

    private func curveTorque(rpm: Double) -> Double {
        let count = curveRpm.count
        if count == 0 {
            return 0
        }
        if rpm <= curveRpm[0] {
            return curveNm[0]
        }
        if rpm >= curveRpm[count - 1] {
            return curveNm[count - 1]
        }
        for index in 1..<count where rpm <= curveRpm[index] {
            let low = curveRpm[index - 1]
            let high = curveRpm[index]
            let span = high - low
            if span <= 0 {
                return curveNm[index]
            }
            let fraction = (rpm - low) / span
            let lowNm = curveNm[index - 1]
            let highNm = curveNm[index]
            return lowNm + fraction * (highNm - lowNm)
        }
        return curveNm[count - 1]
    }
}
