import PistonForgeKit
import SwiftUI

/// The ECU: limits, boost, strategy, nitrous, and the fuel and ignition tables.
struct TuneScreen: View {
    @Binding var build: EngineBuild
    let warnings: [Warning]
    var preview = false
    var onAutoTune: () -> Void = {}

    @State private var table = Table.ignition

    enum Table: String, CaseIterable {
        case ignition = "Ignition timing"
        case fuel = "Air-fuel ratio"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                if preview { PreviewTag(rules: "Rules: one accent (Auto-tune), tables show numbers not colour alone, persistent banner") }
                WarningBanner(warnings: warnings)
                PrimaryButton(title: "Auto-tune for these parts", systemImage: "wand.and.stars", action: onAutoTune)
                    .accessibilityIdentifier("button.autoTune")
                Card("Limits and boost") {
                    slider("Rev limit", value: $build.ecu.revLimit, range: 3000...max(build.mechanicalRedline + 1000, 3500), step: 50, unit: "rpm",
                           note: "Safe up to \(Int(build.mechanicalRedline)) rpm with these internals.")
                    slider("Launch control", value: $build.ecu.launchRpm, range: 1500...max(build.ecu.revLimit, 2000), step: 50, unit: "rpm",
                           note: "Holds the revs here on the start line.")
                    if case .turbo = build.induction {
                        slider("Boost target", value: $build.ecu.boostTargetPsi, range: 0...40, step: 0.5, unit: "psi",
                               note: "The wastegate opens here. More boost, more power, more heat.")
                    }
                }
                Card("Fuelling") {
                    Picker("Strategy", selection: $build.ecu.strategy) {
                        Text("Mass airflow (MAF)").tag(FuelStrategy.maf)
                        Text("Speed-density (MAP)").tag(FuelStrategy.speedDensity)
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: Theme.hitTarget)
                    Text("MAF reads the air directly but tops out; speed-density works out the air from manifold pressure.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                if build.nitrous != nil {
                    Card("Nitrous") {
                        slider("Sprays from", value: Binding(
                            get: { build.ecu.nitrousWindow.lowerBound * 100 },
                            set: { build.ecu.nitrousWindow = min($0 / 100, 1)...1 }
                        ), range: 50...100, step: 5, unit: "% throttle", note: "Only at or above this throttle.")
                        slider("Timing taken out", value: $build.ecu.nitrousRetardDeg, range: 0...20, step: 0.5, unit: "°",
                               note: "Nitrous burns fast: less timing keeps it from detonating.")
                    }
                }
                Card("Tables") {
                    Picker("Table", selection: $table) {
                        ForEach(Table.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: Theme.hitTarget)
                    tableGrid
                    Text("Rows are load (kPa, 101 is full throttle without boost); columns are rpm.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(Theme.Space.l)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Tune")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.tune")
    }

    private var tableGrid: some View {
        let values = table == .ignition ? build.ecu.ignitionTable : build.ecu.afrTable
        let low = values.flatMap { $0 }.min() ?? 0
        let high = values.flatMap { $0 }.max() ?? 1
        return ScrollView(.horizontal) {
            Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                GridRow {
                    Text("kPa").font(.caption2).foregroundStyle(Theme.textSecondary)
                    ForEach(build.ecu.rpmAxis.indices, id: \.self) { column in
                        Text("\(Int(build.ecu.rpmAxis[column] / 100) * 100)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                ForEach(build.ecu.loadAxis.indices.reversed(), id: \.self) { row in
                    GridRow {
                        Text("\(Int(build.ecu.loadAxis[row]))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Theme.textSecondary)
                        ForEach(build.ecu.rpmAxis.indices, id: \.self) { column in
                            let value = values[row][column]
                            let share = high > low ? (value - low) / (high - low) : 0.5
                            Text(table == .ignition ? String(format: "%.0f", value) : String(format: "%.1f", value))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(Theme.textPrimary)
                                .frame(width: 38, height: 26)
                                .background(Theme.accent.opacity(0.12 + 0.45 * share), in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(table.rawValue) table, \(build.ecu.loadAxis.count) load rows by \(build.ecu.rpmAxis.count) rpm columns, from \(String(format: "%.1f", low)) to \(String(format: "%.1f", high))")
        .accessibilityIdentifier("grid.table")
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack {
                Text(title).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(value.wrappedValue, specifier: step < 1 ? "%.1f" : "%.0f") \(unit)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }
            Slider(value: value, in: range, step: step)
                .tint(Theme.accent)
                .frame(minHeight: Theme.hitTarget)
                .accessibilityLabel(title)
            Text(note)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
