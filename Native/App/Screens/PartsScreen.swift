import PistonForgeKit
import SwiftUI

/// Every part, grouped by system. Each choice says in plain words what it changes.
struct PartsScreen: View {
    @Binding var build: EngineBuild
    var preview = false

    private static let inductionChoices: [(String, Induction)] = [
        ("Naturally aspirated", .natural),
        ("Small turbo", .turbo(.small)), ("Medium turbo", .turbo(.medium)),
        ("Large turbo", .turbo(.large)), ("Twin turbo", .turbo(.twin)),
        ("Roots blower", .supercharger(.roots, pulley: 1)),
        ("Twin-screw blower", .supercharger(.twinScrew, pulley: 1)),
        ("Centrifugal blower", .supercharger(.centrifugal, pulley: 1)),
    ]

    var body: some View {
        Form {
            if preview {
                Section { PreviewTag(rules: "Rules: grouped by system, label above / effect below, native 44 pt rows") }
            }
            Section {
                level("Rods, pistons, crank", \.internals, effect: "Each step allows a higher safe rpm and more cylinder pressure.")
                stepper("Compression", value: $build.compression, range: EngineBuild.compressionRange, step: 0.5, format: "%.1f:1",
                        effect: "Higher makes more power per drop of fuel but knocks sooner on boost.")
                stepper("Bore", value: $build.bore, range: EngineBuild.boreRange, step: 1, format: "%.0f mm", effect: "Wider cylinders: more capacity, a longer engine.")
                stepper("Stroke", value: $build.stroke, range: EngineBuild.strokeRange, step: 1, format: "%.0f mm", effect: "Longer stroke: more torque, a lower safe redline.")
            } header: { Text("Block and crank") }
            Section {
                level("Cylinder head", \.head, effect: "Better ports let more air in at every rpm.")
                level("Camshafts", \.cams, effect: "Bigger cams move the power up the rev range and cost low-down pull.")
                level("Valves and springs", \.valves, effect: "Stop the valves floating when you rev past redline.")
            } header: { Text("Head and cams") }
            Section {
                Picker("Induction", selection: inductionBinding) {
                    ForEach(Self.inductionChoices, id: \.0) { choice in
                        Text(choice.0).tag(choice.0)
                    }
                }
                .pickerStyle(.menu)
                if case .supercharger(let kind, let pulley) = build.induction {
                    stepper("Blower pulley", value: Binding(
                        get: { pulley },
                        set: { build.induction = .supercharger(kind, pulley: $0) }
                    ), range: SuperchargerKind.pulleyRange, step: 0.05, format: "%.2f×", effect: "A smaller pulley spins the blower faster for more boost.")
                }
                level("Intercooler", \.intercooler, effect: "Cools the boosted air: denser, and less likely to knock.", names: ["None", "Small", "Large", "Water-to-air"])
                level("Head gasket", \.gasket, effect: "Holds more boost before it blows.", names: ["Stock", "Multi-layer", "Copper-ringed", "Copper-ringed"])
                level("Intake", \.intake, effect: "Freer intake: more air at high rpm.")
                level("Exhaust", \.exhaust, effect: "Freer exhaust: more power and a louder note.")
            } header: { Text("Air in and out") }
            Section {
                Picker("Fuel", selection: $build.fuel) {
                    ForEach(Fuel.allCases, id: \.self) { Text($0.spec.name).tag($0) }
                }
                .pickerStyle(.menu)
                stepper("Injectors", value: $build.parts.injectorCcMin, range: PartChoices.injectorRange, step: 10, format: "%.0f cc/min",
                        effect: "Too small and the engine runs lean at the top end.")
                stepper("Fuel pump", value: $build.parts.pumpLph, range: PartChoices.pumpRange, step: 10, format: "%.0f L/h",
                        effect: "Has to keep up with every injector at once.")
            } header: { Text("Fuel") }
            Section {
                Picker("Mass airflow sensor", selection: Binding(get: { build.sensors.maf?.rawValue ?? "none" }, set: { build.sensors.maf = MafSize(rawValue: $0) })) {
                    Text("None (speed-density only)").tag("none")
                    ForEach(MafSize.allCases, id: \.self) { size in
                        Text("\(size.rawValue.capitalized), reads up to \(Int(size.maxGps)) g/s").tag(size.rawValue)
                    }
                }
                .pickerStyle(.menu)
                Toggle("Manifold pressure (MAP)", isOn: $build.sensors.map)
                Toggle("Intake air temperature", isOn: $build.sensors.iat)
                Toggle("Wideband oxygen", isOn: $build.sensors.wideband)
                Toggle("Knock sensor", isOn: $build.sensors.knock)
                Toggle("Exhaust temperature probe", isOn: $build.sensors.egt)
                Toggle("Oil pressure and temperature", isOn: $build.sensors.oil)
            } header: { Text("Sensors") } footer: {
                Text("Each sensor protects or corrects the engine. Remove one and you lose its warning.")
            }
            Section {
                Toggle("Nitrous kit fitted", isOn: Binding(
                    get: { build.nitrous != nil },
                    set: { build.nitrous = $0 ? NitrousKit(kind: .wet, shotHp: 100, armRpm: 3000, enabled: true) : nil }
                ))
                if let kit = build.nitrous {
                    Picker("Kit", selection: Binding(get: { kit.kind }, set: { build.nitrous?.kind = $0 })) {
                        Text("Wet (brings its own fuel)").tag(NitrousKit.Kind.wet)
                        Text("Dry (the tune adds fuel)").tag(NitrousKit.Kind.dry)
                    }
                    .pickerStyle(.menu)
                    stepper("Shot", value: Binding(get: { kit.shotHp }, set: { build.nitrous?.shotHp = $0 }), range: NitrousKit.shotRange, step: 25, format: "%.0f hp",
                            effect: "More shot needs more fuel and less timing, or it detonates.")
                    stepper("Arms at", value: Binding(get: { kit.armRpm }, set: { build.nitrous?.armRpm = $0 }), range: NitrousKit.armRpmRange, step: 250, format: "%.0f rpm",
                            effect: "Below this it never sprays.")
                }
            } header: { Text("Nitrous") }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Parts")
        .accessibilityIdentifier("screen.parts")
    }

    private var inductionBinding: Binding<String> {
        Binding(
            get: {
                Self.inductionChoices.first { choice in
                    if case .supercharger(let a, _) = choice.1, case .supercharger(let b, _) = build.induction {
                        return a == b
                    }
                    return choice.1 == build.induction
                }?.0 ?? "Naturally aspirated"
            },
            set: { name in
                if let choice = Self.inductionChoices.first(where: { $0.0 == name }) { build.induction = choice.1 }
            }
        )
    }

    private func level(_ title: String, _ path: WritableKeyPath<PartChoices, Int>, effect: String, names: [String] = PartChoices.levelNames) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Picker(title, selection: Binding(get: { build.parts[keyPath: path] }, set: { build.parts[keyPath: path] = $0 })) {
                ForEach(0...PartChoices.maxLevel, id: \.self) { level in
                    Text(names[min(level, names.count - 1)]).tag(level)
                }
            }
            .pickerStyle(.menu)
            Text(effect)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func stepper(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String, effect: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Stepper(value: value, in: range, step: step) {
                HStack {
                    Text(title)
                    Spacer()
                    Text(String(format: format, value.wrappedValue))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Text(effect)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
