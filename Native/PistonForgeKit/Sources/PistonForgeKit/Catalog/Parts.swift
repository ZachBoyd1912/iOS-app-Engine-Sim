import Foundation

/// Turbocharger sizes. Bigger turbos make more boost, later in the rev range.
public enum TurboSize: String, Codable, CaseIterable, Sendable {
    case small, medium, large, twin
}

/// Supercharger types, each with its own boost-versus-rpm shape.
public enum SuperchargerKind: String, Codable, CaseIterable, Sendable {
    case roots, twinScrew, centrifugal

    /// Pulley drive ratio relative to stock: a smaller pulley (higher number) spins it faster.
    public static let pulleyRange: ClosedRange<Double> = 0.8...1.4
}

/// How air gets into the engine.
public enum Induction: Codable, Equatable, Sendable {
    case natural
    case turbo(TurboSize)
    case supercharger(SuperchargerKind, pulley: Double)

    public var isForced: Bool { self != .natural }
}

/// Fuel grades. Each changes stoichiometry, knock resistance and how much has to flow.
public enum Fuel: String, Codable, CaseIterable, Sendable {
    case pump95, pump98, e85, race
}

/// Fixed properties of a fuel.
public struct FuelSpec: Sendable {
    public let name: String
    /// Stoichiometric air-fuel ratio by mass.
    public let stoichAfr: Double
    /// Rich and lean limits for full-load running, as AFR.
    public let safeAfr: ClosedRange<Double>
    /// Density in g/cc.
    public let density: Double
    /// Effective octane; higher allows more timing and boost before knock.
    public let octane: Double
    /// Energy released by burning it, kJ per gram (MJ/kg).
    public let heatKJPerGram: Double
}

extension Fuel {
    public var spec: FuelSpec {
        switch self {
        case .pump95: FuelSpec(name: "Pump 95", stoichAfr: 14.7, safeAfr: 11.0...13.2, density: 0.745, octane: 95, heatKJPerGram: 43)
        case .pump98: FuelSpec(name: "Pump 98", stoichAfr: 14.7, safeAfr: 11.0...13.2, density: 0.75, octane: 98, heatKJPerGram: 43)
        case .e85: FuelSpec(name: "E85", stoichAfr: 9.8, safeAfr: 7.3...8.8, density: 0.785, octane: 105, heatKJPerGram: 29.2)
        case .race: FuelSpec(name: "Race fuel", stoichAfr: 14.6, safeAfr: 10.9...13.1, density: 0.72, octane: 110, heatKJPerGram: 44)
        }
    }
}

/// A nitrous oxide kit.
public struct NitrousKit: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        /// Nitrous only: the ECU must add the fuel through the injectors.
        case dry
        /// Nitrous and its own fuel through a nozzle.
        case wet
    }

    public static let shotRange: ClosedRange<Double> = 50...300
    public static let armRpmRange: ClosedRange<Double> = 1500...9000

    public var kind: Kind
    /// Rated extra power in hp.
    public var shotHp: Double
    /// The kit only sprays above this rpm.
    public var armRpm: Double
    public var enabled: Bool

    public init(kind: Kind, shotHp: Double, armRpm: Double, enabled: Bool) {
        self.kind = kind
        self.shotHp = shotHp
        self.armRpm = armRpm
        self.enabled = enabled
    }
}

/// Mass airflow sensor sizes. Past its maximum the reading clips.
public enum MafSize: String, Codable, CaseIterable, Sendable {
    case small, medium, large, xl

    /// Highest airflow it can read, in g/s.
    public var maxGps: Double {
        switch self {
        case .small: 200
        case .medium: 350
        case .large: 550
        case .xl: 800
        }
    }
}

/// The sensors fitted. Each gives the ECU information or protection; removing it removes that.
public struct SensorSet: Codable, Equatable, Sendable {
    /// Mass airflow sensor; nil means the engine can only run speed-density.
    public var maf: MafSize?
    /// Manifold pressure sensor.
    public var map: Bool
    /// Intake air temperature sensor.
    public var iat: Bool
    /// Wideband oxygen sensor: closed-loop fuel correction under load.
    public var wideband: Bool
    /// Knock sensor: pulls timing when detonation starts.
    public var knock: Bool
    /// Exhaust gas temperature probe.
    public var egt: Bool
    /// Oil pressure and temperature senders.
    public var oil: Bool

    public init(maf: MafSize?, map: Bool, iat: Bool, wideband: Bool, knock: Bool, egt: Bool, oil: Bool) {
        self.maf = maf
        self.map = map
        self.iat = iat
        self.wideband = wideband
        self.knock = knock
        self.egt = egt
        self.oil = oil
    }
}

/// Upgrade levels for the hard parts. 0 is stock; `PartChoices.maxLevel` is full race.
public struct PartChoices: Codable, Equatable, Sendable {
    public static let maxLevel = 3
    public static let levelNames = ["Stock", "Street", "Sport", "Race"]
    public static let injectorRange: ClosedRange<Double> = 150...2400
    public static let pumpRange: ClosedRange<Double> = 150...1000
    /// Boost each head gasket level holds before it starts to fail, psi.
    public static let gasketBoostLimitPsi: [Double] = [18, 26, 40, 40]
    /// Share of compression heat each intercooler level removes (0 = none fitted).
    public static let intercoolerCooling: [Double] = [0, 0.55, 0.7, 0.82]

    public var head: Int
    public var cams: Int
    public var intake: Int
    public var exhaust: Int
    /// Rods, pistons and crank: raise the safe piston speed and cylinder pressure.
    public var internals: Int
    /// Valves and springs: stop valve float at high rpm.
    public var valves: Int
    /// Head gasket: how much boost and cylinder pressure it holds.
    public var gasket: Int
    /// 0 means no intercooler.
    public var intercooler: Int
    /// Injector size per cylinder, cc/min.
    public var injectorCcMin: Double
    /// Fuel pump capacity, L/h.
    public var pumpLph: Double

    public init(
        head: Int = 0, cams: Int = 0, intake: Int = 0, exhaust: Int = 0, internals: Int = 0,
        valves: Int = 0, gasket: Int = 0, intercooler: Int = 0, injectorCcMin: Double, pumpLph: Double
    ) {
        self.head = head
        self.cams = cams
        self.intake = intake
        self.exhaust = exhaust
        self.internals = internals
        self.valves = valves
        self.gasket = gasket
        self.intercooler = intercooler
        self.injectorCcMin = injectorCcMin
        self.pumpLph = pumpLph
    }
}
