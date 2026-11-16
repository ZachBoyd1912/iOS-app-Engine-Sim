import Foundation

/// Ways an engine breaks. Each stops the engine until it is repaired (repairs are free).
public enum Failure: String, Codable, CaseIterable, Sendable {
    case leanMelt, detonation, overBoost, overRev, oilStarvation

    /// What happened, in plain words, shown after the pull.
    public var explanation: String {
        switch self {
        case .leanMelt:
            "Too little fuel for the air under load. The mixture burnt hot and lean and melted a piston. Richen the fuel table, or fit bigger injectors or a bigger pump."
        case .detonation:
            "The fuel exploded instead of burning (knock) until a piston cracked. Take timing out, lower the boost, use higher octane fuel, or fit a knock sensor."
        case .overBoost:
            "More boost than the head gasket can hold. It blew. Lower the boost target or fit a stronger gasket."
        case .overRev:
            "Revved past what the valves and rods can take. Lower the rev limit, or fit stronger valves and internals."
        case .oilStarvation:
            "The oil got too hot and thin to protect the bearings, and one spun. Give it a rest between hard pulls."
        }
    }
}

/// Things the driver should know about right now, or about the build.
public enum Warning: String, Codable, CaseIterable, Sendable {
    /// The tune is more aggressive than is safe for the current parts.
    case mapOutOfDate
    /// The injectors or pump cannot fuel the boost this build will make.
    case fuelSystemTooSmall
    /// The MAF reads less air than the engine takes.
    case mafClipping
    case knocking, runningLean, overBoost, overRev, hotExhaust, oilPressureLow
    /// The tune reads a MAF sensor that is not fitted.
    case mafMissing
    /// A supercharger makes more boost than the fuel, compression or gasket can take, whatever the tune.
    case boostTooHighForFuel

    public var message: String {
        switch self {
        case .mapOutOfDate: "Tune is more aggressive than these parts can take"
        case .fuelSystemTooSmall: "Injectors or pump too small for this boost"
        case .mafClipping: "MAF sensor maxed out: engine running lean"
        case .knocking: "Knock detected"
        case .runningLean: "Running lean under load"
        case .overBoost: "Boost above the head gasket's limit"
        case .overRev: "Over-revving"
        case .hotExhaust: "Exhaust too hot"
        case .oilPressureLow: "Oil pressure low"
        case .mafMissing: "Tune reads a MAF sensor that is not fitted"
        case .boostTooHighForFuel: "Blower boost too high for this engine: fit a bigger pulley, better fuel or a stronger gasket"
        }
    }
}

/// Wear that builds up while abuse continues. Any kind reaching 1 breaks the engine.
struct DamageModel: Equatable, Sendable {
    var lean = 0.0
    var knock = 0.0
    var boost = 0.0
    var rev = 0.0
    var oil = 0.0
}
