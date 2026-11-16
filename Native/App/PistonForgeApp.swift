import PistonForgeKit
import SwiftUI

@main
struct PistonForgeApp: App {
    @State private var driver: EngineDriver
    private let route: LaunchRoute

    init() {
        Engine3D.register()
        let route = LaunchRoute.parse()
        self.route = route
        _driver = State(initialValue: EngineDriver(build: route.build()))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if route.preview {
                    PreviewRoot(screen: route.screen)
                } else {
                    EngineHomeView(driver: driver)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Runs the engine simulation on the main actor about 60 times a second.
@Observable
@MainActor
final class EngineDriver {
    let build: EngineBuild
    private(set) var state = EngineState()
    private let sim: EngineSim

    init(build: EngineBuild) {
        let clean = build.sanitized()
        self.build = clean
        sim = EngineSim(build: clean)
        sim.start()
        state = sim.state
    }

    /// Steps the engine with real elapsed time until the task is cancelled (the view goes away).
    func run() async {
        let clock = ContinuousClock()
        var last = clock.now
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(16))
            let now = clock.now
            let elapsed = last.duration(to: now).components
            last = now
            let seconds = Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
            state = sim.step(dt: seconds, throttle: 0, load: 0)
        }
    }
}

/// Stage 1 so far: the engine idling in 3D. The full screens arrive after the previews.
struct EngineHomeView: View {
    let driver: EngineDriver
    @State private var selected: PartGroup?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            EngineViewport(build: driver.build, state: driver.state) { selected = $0 }
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 4) {
                Text("Piston Forge")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(driver.build.name)
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                    .accessibilityIdentifier("label.engineName")
                Text("\(Int(driver.state.rpm.rounded())) rpm")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityIdentifier("label.rpm")
                if let selected {
                    Text(selected.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .accessibilityIdentifier("label.selectedPart")
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("screen.engine")
        .task { await driver.run() }
    }
}
