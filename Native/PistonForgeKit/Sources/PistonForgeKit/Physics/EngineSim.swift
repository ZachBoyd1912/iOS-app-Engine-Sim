import Foundation

/// The engine at one moment, for the screens, the sound and the dyno.
public struct EngineState: Equatable, Sendable {
    public var rpm = 0.0
    /// Crank angle in degrees, 0..<720 (one full four-stroke cycle).
    public var crankAngle = 0.0
    /// Torque at the crank, Nm (negative while it drags).
    public var torqueNm = 0.0
    public var powerHp = 0.0
    public var boostPsi = 0.0
    public var afr = 0.0
    public var targetAfr = 0.0
    public var knockIndex = 0.0
    public var egtC = 0.0
    public var injectorDuty = 0.0
    public var oilPressureBar = 0.0
    public var oilTempC = 85.0
    public var iatC = 25.0
    public var loadKpa = 0.0
    public var timingDeg = 0.0
    public var throttle = 0.0
    /// 1 is a fresh engine, 0 is broken.
    public var health = 1.0
    public var failure: Failure?
    public var warnings: [Warning] = []
    public var nitrousActive = false
    public var limiterActive = false
    public var isRunning = false

    public init() {}
}

/// The running engine: integrates crank speed at a fixed 480 Hz from torque, inertia and the
/// external load, with idle control, the rev limiter, turbo spool, closed-loop fuel and damage.
public final class EngineSim {
    /// Internal integration rate, Hz.
    public static let stepRate = 480.0

    public private(set) var build: EngineBuild
    public private(set) var isRunning = false
    /// Warnings about the build itself (tune, fuel system, MAF), plus those from the last step.
    public private(set) var warnings: [Warning] = []
    /// The latest state.
    public private(set) var state = EngineState()
    /// The player's nitrous arming switch.
    public var nitrousArmed = false
    public var idleTargetRpm: Double { 850 }

    private var rpm = 0.0
    private var crank = 0.0
    private var turbo = TurboState()
    private var trim = 0.0
    private var idleIntegral = 0.0
    private var cutting = false
    private var damage = DamageModel()
    private var failure: Failure?
    private var oilTemp = 85.0
    private var buildWarnings: [Warning] = []

    public init(build: EngineBuild) {
        self.build = build.sanitized()
        buildWarnings = Self.checkBuild(self.build)
        warnings = buildWarnings
        state = snapshot(point: nil, boost: 0, throttle: 0, torque: 0, live: [])
    }

    /// Swaps in new parts or a new tune. The tune is never silently rewritten: if it is now
    /// more aggressive than the parts can take, `.mapOutOfDate` appears in `warnings` before
    /// the next step, and the tune screen offers the auto-base tune.
    public func setBuild(_ newBuild: EngineBuild) {
        build = newBuild.sanitized()
        buildWarnings = Self.checkBuild(build)
        warnings = buildWarnings
        state.warnings = warnings
        trim = 0
    }

    public func start() {
        guard failure == nil else { return }
        isRunning = true
        rpm = max(rpm, idleTargetRpm * 0.9)
        idleIntegral = 0
    }

    public func stop() {
        isRunning = false
    }

    /// Fixes everything, free.
    public func repair() {
        damage = DamageModel()
        failure = nil
        oilTemp = 85
        state.health = 1
        state.failure = nil
    }

    /// Advances by `dt` seconds (clamped to 0...0.1 so a long pause never jumps the engine)
    /// at `throttle` (0...1) against an external `load` torque in Nm (the dyno's or the car's;
    /// 0 when free revving).
    @discardableResult
    public func step(dt: Double, throttle: Double, load: Double) -> EngineState {
        let span = bounded(dt, 0...0.1)
        let pedal = bounded(throttle, 0...1)
        let resistance = bounded(load, 0...100_000)
        let count = Int((span * Self.stepRate).rounded(.up))
        guard count > 0 else { return state }
        let h = span / Double(count)
        for _ in 0..<count {
            substep(h: h, pedal: pedal, resistance: resistance)
        }
        return state
    }

    // MARK: - Integration

    /// Rotating inertia of the crank, flywheel and reciprocating parts, kg·m².
    public var inertiaKgM2: Double {
        0.08 + 0.012 * Double(build.layout.spec.cylinders) + 0.000_03 * build.displacementCc
    }

    /// Pumping loss against a closed throttle, Nm: what makes engine braking.
    private func pumpingNm(throttle: Double) -> Double {
        0.8 * (1 - throttle) * 100_000 * build.displacementCc / 1_000_000 / (4 * Double.pi)
    }

    private func substep(h: Double, pedal: Double, resistance: Double) {
        let ecu = build.ecu
        var opening = isRunning ? pedal : 0
        if isRunning {
            // Idle air control: a PI loop holding the idle target, scaled to the engine's size.
            let scale = 2000 / build.displacementCc * inertiaKgM2 / 0.188
            let error = idleTargetRpm - rpm
            let idleOpening = bounded(0.08 + 0.0013 * scale * error + idleIntegral, 0...0.3)
            if pedal < idleOpening {
                if idleOpening > 0, idleOpening < 0.3 { idleIntegral += 0.0039 * scale * error * h }
                opening = idleOpening
            }
        }

        if rpm >= ecu.revLimit { cutting = true } else if rpm < ecu.revLimit - 150 { cutting = false }
        let boost = boostPsi(build, rpm: rpm, throttle: opening, turbo: &turbo, dt: h, target: ecu.boostTargetPsi)

        var torque: Double
        var point: OperatingPoint?
        var live: [Warning] = []
        if isRunning && !cutting {
            let here = operatingPoint(build, rpm: rpm, throttle: opening, boostPsi: boost, nitrousArmed: nitrousArmed, closedLoopTrim: trim)
            point = here
            let wear = 0.7 + 0.3 * health
            torque = here.combustion.torqueNm * wear - here.frictionNm - here.parasiticNm - pumpingNm(throttle: opening)
            if build.sensors.wideband, here.fuel.commandedAfr > 0 {
                trim = bounded(trim + (here.combustion.afr / here.fuel.commandedAfr - 1) * 1.5 * h, -0.25...0.25)
            }
            live = accumulateDamage(here, h: h)
        } else {
            let friction = frictionTorqueNm(build, rpm: rpm)
            let omega = rpm * 2 * Double.pi / 60
            let drag = omega > 1 ? parasiticLossHp(build, rpm: rpm, boost: boost) * 745.7 / omega : 0
            torque = -(friction + drag + pumpingNm(throttle: isRunning ? opening : 0))
            if cutting { live.append(.overRev) }
        }

        let acceleration = (torque - resistance) / inertiaKgM2
        rpm = max(0, rpm + acceleration * h * 60 / (2 * Double.pi))
        if !isRunning && rpm < 30 { rpm = 0 }
        crank = (crank + rpm / 60 * 360 * h).truncatingRemainder(dividingBy: 720)
        if isRunning && rpm < 250 && !cutting { isRunning = false }
        oilTemp += (oilTarget(point) - oilTemp) * min(1, h / 90)

        let netTorque = point.map { $0.combustion.torqueNm * (0.7 + 0.3 * health) - $0.frictionNm - $0.parasiticNm - pumpingNm(throttle: opening) } ?? torque
        state = snapshot(point: point, boost: boost, throttle: opening, torque: netTorque, live: live)
    }

    // MARK: - Damage and warnings

    private var health: Double {
        let worst = max(damage.lean, damage.knock, damage.boost, damage.rev, damage.oil)
        return failure == nil ? bounded(1 - worst, 0...1) : 0
    }

    private func oilTarget(_ point: OperatingPoint?) -> Double {
        guard let point else { return 85 }
        return 85 + 0.2 * max(0, point.loadKpa - 40) + 12 * min(rpm / build.mechanicalRedline, 1)
    }

    private var oilPressure: Double {
        guard rpm > 0 else { return 0 }
        let thinning = 1 - max(0, oilTemp - 110) / 100
        return min(6, 1 + 0.9 * rpm / 1000) * max(thinning, 0.1)
    }

    /// Adds this substep's wear and returns the live warnings the fitted sensors can see.
    private func accumulateDamage(_ point: OperatingPoint, h: Double) -> [Warning] {
        let burn = point.combustion
        let lambda = burn.afr / build.fuel.spec.stoichAfr
        let sensors = build.sensors
        var live: [Warning] = []

        if point.loadKpa > 90 && lambda > 0.98 {
            damage.lean += (lambda - 0.98) * point.loadKpa / 100 * 4 * h
            if sensors.wideband { live.append(.runningLean) }
        }
        if burn.egtC > 1050 { damage.lean += (burn.egtC - 1050) / 100 * h }
        if burn.knockIndex >= 1 {
            let wear = (burn.knockIndex - 0.8) * 0.6 * h
            if lambda > 0.95 { damage.lean += wear } else { damage.knock += wear }
        }
        if sensors.knock && (burn.knockIndex >= 0.8 || burn.timingDeg < burn.mapTimingDeg) { live.append(.knocking) }

        let gasket = PartChoices.gasketBoostLimitPsi[min(max(build.parts.gasket, 0), PartChoices.gasketBoostLimitPsi.count - 1)]
        if point.boostPsi > gasket {
            damage.boost += (point.boostPsi - gasket) / 5 * h
            if sensors.map { live.append(.overBoost) }
        }
        let float = build.mechanicalRedline * (1.03 + 0.03 * Double(build.parts.valves))
        if rpm > float {
            damage.rev += (rpm / float - 1) * 20 * h
            live.append(.overRev)
        }
        if oilTemp > 140 { damage.oil += (oilTemp - 140) / 20 * h }
        if sensors.oil && rpm > 2500 && oilPressure < 0.8 { live.append(.oilPressureLow) }
        if sensors.egt && burn.egtC > 950 { live.append(.hotExhaust) }
        if point.fuel.mafClipped { live.append(.mafClipping) }

        let worst: [(Double, Failure)] = [
            (damage.lean, .leanMelt), (damage.knock, .detonation), (damage.boost, .overBoost),
            (damage.rev, .overRev), (damage.oil, .oilStarvation),
        ]
        if let broken = worst.filter({ $0.0 >= 1 }).max(by: { $0.0 < $1.0 }) {
            failure = broken.1
            isRunning = false
        }
        return live
    }

    private func snapshot(point: OperatingPoint?, boost: Double, throttle: Double, torque: Double, live: [Warning]) -> EngineState {
        var next = EngineState()
        next.rpm = rpm
        next.crankAngle = crank
        next.torqueNm = torque
        next.powerHp = torque * rpm * 2 * Double.pi / 60 / 745.7
        next.boostPsi = boost
        next.throttle = throttle
        next.oilTempC = oilTemp
        next.oilPressureBar = oilPressure
        if let point {
            next.afr = point.combustion.afr
            next.targetAfr = point.fuel.commandedAfr
            next.knockIndex = point.combustion.knockIndex
            next.egtC = point.combustion.egtC
            next.injectorDuty = point.fuel.injectorDuty
            next.iatC = point.chargeTempC
            next.loadKpa = point.loadKpa
            next.timingDeg = point.combustion.timingDeg
            next.nitrousActive = point.nitrousActive
        }
        next.health = health
        next.failure = failure
        var all = buildWarnings
        for warning in live where !all.contains(warning) { all.append(warning) }
        next.warnings = all
        next.limiterActive = cutting
        next.isRunning = isRunning
        warnings = all
        return next
    }

    /// Warnings about the build that hold before it runs.
    static func checkBuild(_ b: EngineBuild) -> [Warning] {
        var found: [Warning] = []
        let safe = ECUMap.autoBase(for: b)
        let ecu = b.ecu
        var aggressive = false
        for row in 0..<ECUMap.loadCount where !aggressive {
            for column in 0..<ECUMap.rpmCount {
                let rpm = ecu.rpmAxis[column]
                let load = ecu.loadAxis[row]
                let timing = ecu.value(\.ignitionTable, rpm: rpm, loadKpa: load)
                if timing > safe.value(\.ignitionTable, rpm: rpm, loadKpa: load) + 1.5 { aggressive = true; break }
                if load >= 100 {
                    let lean = ecu.value(\.afrTable, rpm: rpm, loadKpa: load) / b.fuel.spec.stoichAfr
                    if lean > ECUMap.baseLambda(loadKpa: load) + 0.06 { aggressive = true; break }
                }
            }
        }
        if case .turbo = b.induction, ecu.boostTargetPsi > ECUMap.knockLimitedBoost(for: b) + 0.5 { aggressive = true }
        if aggressive { found.append(.mapOutOfDate) }

        let boost: Double = switch b.induction {
        case .natural: 0
        case .turbo: ecu.boostTargetPsi
        case .supercharger: steadyBoostPsi(b, rpm: b.mechanicalRedline, throttle: 1, target: 0)
        }
        let needs = fuelSystemNeeds(b, boostPsi: boost)
        if needs.injectorCcMin > b.parts.injectorCcMin + 0.5 || needs.pumpLph > b.parts.pumpLph + 0.5 {
            found.append(.fuelSystemTooSmall)
        }
        if ecu.strategy == .maf {
            let air = airflowGps(b, rpm: b.mechanicalRedline, throttle: 1, boostPsi: boost, chargeTempC: chargeTempC(b, boostPsi: boost))
            if air > (b.sensors.maf?.maxGps ?? 0) { found.append(.mafClipping) }
        }
        return found
    }
}
