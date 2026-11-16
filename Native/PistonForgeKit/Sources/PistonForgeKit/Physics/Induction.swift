import Foundation

/// The turbo's moving state between simulation steps.
public struct TurboState: Equatable, Sendable {
    /// Shaft speed as a fraction of full spool, 0...1.
    public var shaftSpeed: Double

    public init(shaftSpeed: Double = 0) {
        self.shaftSpeed = shaftSpeed
    }
}

extension TurboSize {
    /// Exhaust flow it needs to spool, in litre x thousand-rpm (displacement x rpm / 1000).
    var flowCapacity: Double {
        switch self {
        case .small: 7
        case .medium: 11
        case .large: 16
        case .twin: 13
        }
    }

    /// Most boost the compressor can make, psi.
    var maxPsi: Double {
        switch self {
        case .small: 18
        case .medium: 24
        case .large: 32
        case .twin: 30
        }
    }

    /// Spool time constant in seconds: bigger turbines are slower.
    var spoolSeconds: Double { 0.35 + 0.08 * flowCapacity }
}

extension SuperchargerKind {
    /// Boost at redline on the stock pulley, psi.
    var redlinePsi: Double {
        switch self {
        case .roots: 8
        case .twinScrew: 10
        case .centrifugal: 14
        }
    }

    /// Crank hp it takes per psi, per litre, per thousand rpm.
    var dragFactor: Double {
        switch self {
        case .roots: 0.2
        case .twinScrew: 0.15
        case .centrifugal: 0.11
        }
    }
}

/// Shaft speed (0...1) a turbo settles at for this rpm and throttle.
func turboSteadyShaft(_ b: EngineBuild, size: TurboSize, rpm: Double, throttle: Double) -> Double {
    // Exhaust flow drives the turbine; a closed throttle leaves a trickle.
    let flow = b.displacementCc / 1000 * bounded(rpm, 0...30_000) / 1000 * (0.2 + 0.8 * bounded(throttle, 0...1))
    return smoothstep(0.25 * size.flowCapacity, 0.6 * size.flowCapacity, flow)
}

/// Boost a supercharger makes at this rpm and throttle, psi.
func superchargerBoostPsi(_ b: EngineBuild, kind: SuperchargerKind, pulley: Double, rpm: Double, throttle: Double) -> Double {
    let fraction = bounded(bounded(rpm, 0...30_000) / b.mechanicalRedline, 0...1.2)
    let drive = bounded(pulley, SuperchargerKind.pulleyRange, or: 1)
    let shape: Double = switch kind {
    case .roots: 0.75 + 0.25 * fraction
    case .twinScrew: 0.8 + 0.2 * fraction
    case .centrifugal: fraction * fraction
    }
    // The bypass valve opens at part throttle.
    let bypass = bounded(bounded(throttle, 0...1) * 1.2 - 0.2, 0...1)
    return kind.redlinePsi * drive * drive * shape * bypass
}

/// Boost once everything has settled at this rpm and throttle (no turbo lag), psi.
/// Used by the auto-base tune and the tune screen's boost curve.
public func steadyBoostPsi(_ b: EngineBuild, rpm: Double, throttle: Double, target: Double) -> Double {
    switch b.induction {
    case .natural:
        return 0
    case .turbo(let size):
        return min(bounded(target, 0...size.maxPsi), size.maxPsi * turboSteadyShaft(b, size: size, rpm: rpm, throttle: throttle))
    case .supercharger(let kind, let pulley):
        return superchargerBoostPsi(b, kind: kind, pulley: pulley, rpm: rpm, throttle: throttle)
    }
}

/// Boost pressure in psi for this step. Turbos spool over time toward the wastegate target;
/// superchargers are belt-driven, so their boost follows rpm at once and ignores the target.
public func boostPsi(_ b: EngineBuild, rpm: Double, throttle: Double, turbo: inout TurboState, dt: Double, target: Double) -> Double {
    switch b.induction {
    case .natural:
        turbo.shaftSpeed = 0
        return 0

    case .turbo(let size):
        let steady = turboSteadyShaft(b, size: size, rpm: rpm, throttle: throttle)
        let step = bounded(dt, 0...0.1)
        let current = bounded(turbo.shaftSpeed, 0...1)
        turbo.shaftSpeed = current + (steady - current) * (1 - exp(-step / size.spoolSeconds))
        // The wastegate opens at the target; below it the compressor gives what the shaft allows.
        let wanted = bounded(target, 0...size.maxPsi)
        return min(wanted, size.maxPsi * turbo.shaftSpeed)

    case .supercharger(let kind, let pulley):
        turbo.shaftSpeed = 0
        return superchargerBoostPsi(b, kind: kind, pulley: pulley, rpm: rpm, throttle: throttle)
    }
}

/// Intake charge temperature after compression and the intercooler, °C.
/// Compression heats the charge about 6.1 °C per psi; each intercooler level removes a share.
public func chargeTempC(_ b: EngineBuild, boostPsi: Double, ambientC: Double = 25) -> Double {
    let level = min(max(b.parts.intercooler, 0), PartChoices.intercoolerCooling.count - 1)
    let cooling = PartChoices.intercoolerCooling[level]
    return bounded(ambientC, -40...60, or: 25) + bounded(boostPsi, 0...60) * 6.1 * (1 - cooling)
}

/// Crank power a supercharger takes to drive, in hp. Turbos and NA engines take none here;
/// a turbine's cost shows up as exhaust back-pressure in the volumetric efficiency.
public func parasiticLossHp(_ b: EngineBuild, rpm: Double, boost: Double) -> Double {
    guard case .supercharger(let kind, _) = b.induction else { return 0 }
    let speed = bounded(rpm, 0...30_000)
    let pressure = bounded(boost, 0...60)
    // A spinning blower costs a little even with no boost.
    return kind.dragFactor * (pressure + 1) * b.displacementCc / 1000 * speed / 1000
}
