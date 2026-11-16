import PistonForgeKit
import SwiftUI

/// Opens one screen with sample data for the previews Zach approves
/// (`-screen <name> -preview`). Controls work, but nothing is simulated or saved.
struct PreviewRoot: View {
    let screen: String

    @State private var build = SampleData.build
    @State private var car = SampleData.car
    @State private var settings = SampleData.settings
    @State private var throttle = 0.0

    var body: some View {
        NavigationStack {
            switch screen {
            case "parts":
                PartsScreen(build: $build, preview: true)
            case "tune":
                TuneScreen(build: $build, warnings: SampleData.warnings, preview: true)
            case "dyno":
                DynoScreen(build: build, current: SampleData.pull, last: SampleData.lastPull, isPulling: false, preview: true)
            case "car":
                CarScreen(build: build, car: $car, preview: true)
            case "settings":
                SettingsScreen(settings: $settings, preview: true)
            case "garage":
                GarageSheet(builds: SampleData.builds, selected: SampleData.build.id, preview: true)
            default:
                EngineScreen(build: build, state: SampleData.state, warnings: SampleData.warnings, throttle: $throttle, preview: true)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .tint(Theme.accent)
    }
}
