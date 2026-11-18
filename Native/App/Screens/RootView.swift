import PistonForgeKit
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case engine, tune, dyno, garage, drive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .engine: "Engine"
        case .tune: "Tune"
        case .dyno: "Dyno"
        case .garage: "Garage"
        case .drive: "Drive"
        }
    }

    var icon: String {
        switch self {
        case .engine: "engine.combustion.fill"
        case .tune: "slider.horizontal.3"
        case .dyno: "gauge.with.dots.needle.67percent"
        case .garage: "wrench.and.screwdriver.fill"
        case .drive: "steeringwheel"
        }
    }
}

/// The live app: five tabs over one `GameStore`.
struct RootView: View {
    @State private var game = GameStore()
    @State private var tab = AppTab.engine
    @State private var garageSection = GarageSection.parts

    var body: some View {
        TabView(selection: $tab) {
            engineTab
                .tabItem { Label("Engine", systemImage: AppTab.engine.icon) }
                .tag(AppTab.engine)
            tuneTab
                .tabItem { Label("Tune", systemImage: AppTab.tune.icon) }
                .tag(AppTab.tune)
            dynoTab
                .tabItem { Label("Dyno", systemImage: AppTab.dyno.icon) }
                .tag(AppTab.dyno)
            GarageTab(game: game, section: $garageSection)
                .tabItem { Label("Garage", systemImage: AppTab.garage.icon) }
                .tag(AppTab.garage)
            DriveTab(game: game)
                .tabItem { Label("Drive", systemImage: AppTab.drive.icon) }
                .tag(AppTab.drive)
        }
        .tint(Theme.accent)
        .preferredColorScheme(.dark)
        .task { await game.run() }
        .task { game.loadSoundIfNeeded() }
        .onChange(of: game.save.settings.sound) { _, on in game.sound.enabled = on }
    }

    private var buildBinding: Binding<EngineBuild> {
        Binding(get: { game.build }, set: { game.build = $0 })
    }

    private var engineTab: some View {
        NavigationStack {
            EngineScreen(
                build: game.build,
                state: game.state,
                warnings: game.state.warnings,
                throttle: Binding(get: { game.throttle }, set: { game.throttle = $0 }),
                onStartStop: { game.toggleEngine() },
                onSelectPart: { _ in
                    garageSection = .parts
                    tab = .garage
                },
                onOpenGarage: {
                    garageSection = .engines
                    tab = .garage
                },
                onOpenSettings: {
                    garageSection = .settings
                    tab = .garage
                },
                accessory: { AnyView(SoundPanel(game: game)) }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var tuneTab: some View {
        NavigationStack {
            TuneScreen(build: buildBinding, warnings: game.state.warnings, onAutoTune: { game.autoTune() })
        }
    }

    private var dynoTab: some View {
        NavigationStack {
            DynoScreen(
                build: game.build,
                current: game.currentPull,
                last: game.lastPull,
                isPulling: game.isPulling,
                onPull: { game.startPull() }
            )
        }
    }
}

enum GarageSection: String, CaseIterable, Identifiable {
    case parts, engines, car, settings
    var id: String { rawValue }

    var title: String {
        switch self {
        case .parts: "Parts"
        case .engines: "Engines"
        case .car: "Car"
        case .settings: "Settings"
        }
    }
}

struct GarageTab: View {
    let game: GameStore
    @Binding var section: GarageSection

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Garage section", selection: $section) {
                    ForEach(GarageSection.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(Theme.Space.l)
                content
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Garage")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder private var content: some View {
        switch section {
        case .parts:
            PartsScreen(build: Binding(get: { game.build }, set: { game.build = $0 }))
        case .engines:
            EnginesList(game: game)
        case .car:
            CarScreen(
                build: game.build,
                car: Binding(get: { game.save.car }, set: { game.save.car = $0 })
            )
        case .settings:
            SettingsScreen(
                settings: Binding(get: { game.save.settings }, set: { game.save.settings = $0 }),
                onReset: { game.save = SaveFile.defaults() }
            )
        }
    }
}

/// Saved engines plus every engine layout to add.
struct EnginesList: View {
    let game: GameStore

    var body: some View {
        List {
            Section("Your engines") {
                ForEach(game.save.builds) { build in
                    Button { game.select(build.id) } label: {
                        HStack(spacing: Theme.Space.m) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(build.name).foregroundStyle(Theme.textPrimary)
                                Text("\(build.layout.spec.name) · \(build.induction.displayName) · \(Int(build.displacementCc.rounded())) cc")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            if build.id == game.save.selectedBuild {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent)
                            }
                        }
                        .frame(minHeight: Theme.hitTarget)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) { game.delete(build.id) }
                    }
                    .swipeActions(edge: .leading) {
                        Button("Duplicate") { game.duplicate(build.id) }.tint(Theme.accent)
                    }
                }
            }
            Section("Add an engine") {
                ForEach(EngineLayout.allCases, id: \.rawValue) { layout in
                    Button { game.addEngine(layout) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(layout.spec.name).foregroundStyle(Theme.textPrimary)
                                Text("\(layout.spec.cylinders) cylinders · fires \(layout.spec.firingOrder.map(String.init).joined(separator: "-"))")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                        }
                        .frame(minHeight: Theme.hitTarget)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

/// Exhaust, rev limiter and sound status, shown on the Engine screen.
struct SoundPanel: View {
    let game: GameStore

    var body: some View {
        @Bindable var game = game
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            HStack {
                Text("Exhaust").font(.caption).foregroundStyle(Theme.textSecondary)
                Spacer()
                Picker("Exhaust", selection: $game.exhaust) {
                    ForEach(ExhaustPreset.allCases, id: \.rawValue) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
                .frame(minHeight: Theme.hitTarget)
            }
            HStack {
                Text("Rev limiter").font(.caption).foregroundStyle(Theme.textSecondary)
                Spacer()
                Picker("Rev limiter", selection: $game.limiter) {
                    ForEach(LimiterStyle.allCases, id: \.rawValue) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
                .frame(minHeight: Theme.hitTarget)
            }
            HStack {
                Text("Pops on lift-off").font(.caption).foregroundStyle(Theme.textSecondary)
                Spacer()
                Picker("Pops on lift-off", selection: $game.pops) {
                    ForEach(PopsLevel.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
                .frame(minHeight: Theme.hitTarget)
            }
            HStack(spacing: Theme.Space.s) {
                Image(systemName: game.sound.isLoaded ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundStyle(game.sound.isLoaded ? Theme.goodMark : Theme.warnMark)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(Theme.Space.m)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private var statusText: String {
        let sound = game.sound
        if sound.isLoading { return "Loading engine sound…" }
        if !sound.message.isEmpty { return sound.message }
        if sound.isLoaded {
            return "Sound load \(Int(sound.loadPercent.rounded()))% of a frame · dropouts \(sound.dropouts) · phone \(sound.thermal)"
        }
        return "Sound not loaded"
    }
}
