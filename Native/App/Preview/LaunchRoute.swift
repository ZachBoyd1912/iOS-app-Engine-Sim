import Foundation
import PistonForgeKit

/// Launch arguments that open the app on a given screen and engine, for UI tests and
/// screenshots: `-screen engine -layout v8Cross -induction turbo-twin`.
struct LaunchRoute {
    var screen = "engine"
    var layout: EngineLayout = .v8Cross
    var induction: Induction = .natural
    var preview = false
    /// True when a test or screenshot named a screen or layout on the command line.
    var explicit = false

    static func parse(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> LaunchRoute {
        var route = LaunchRoute()
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        if let screen = value(after: "-screen") { route.screen = screen }
        if let layout = value(after: "-layout").flatMap(EngineLayout.init(rawValue:)) { route.layout = layout }
        if let induction = value(after: "-induction") { route.induction = Self.induction(named: induction) }
        route.preview = arguments.contains("-preview")
        route.explicit = arguments.contains("-layout") || arguments.contains("-screen")
        return route
    }

    static func induction(named name: String) -> Induction {
        switch name {
        case "turbo-small": .turbo(.small)
        case "turbo-medium": .turbo(.medium)
        case "turbo-large": .turbo(.large)
        case "turbo-twin": .turbo(.twin)
        case "roots": .supercharger(.roots, pulley: 1)
        case "twinScrew": .supercharger(.twinScrew, pulley: 1)
        case "centrifugal": .supercharger(.centrifugal, pulley: 1)
        default: .natural
        }
    }

    /// The engine this route opens on: the layout's stock engine with the induction fitted, its
    /// fuel system sized to match and the auto-base tune loaded.
    func build() -> EngineBuild {
        var build = EngineBuild.starter(layout)
        guard induction.isForced else { return build }
        build.induction = induction
        build.parts.intercooler = 1
        build = build.withFuelSystemSized()
        build.ecu = ECUMap.autoBase(for: build)
        return build
    }
}
