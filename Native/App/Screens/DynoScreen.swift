import Charts
import PistonForgeKit
import SwiftUI

/// The dyno: a pull draws power and torque live, with the last pull behind it and the
/// air-fuel, boost, knock and exhaust traces underneath.
struct DynoScreen: View {
    let build: EngineBuild
    let current: DynoResult?
    let last: DynoResult?
    let isPulling: Bool
    var preview = false
    var onPull: () -> Void = {}

    private struct Point: Identifiable {
        let id: Int
        let rpm: Double
        let value: Double
        let series: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                if preview { PreviewTag(rules: "Rules: one accent (Start pull), figures in tabular digits, failure explained in words with a next step") }
                peaks
                if let failure = current?.failure {
                    Card {
                        StatusLabel(status: .bad, text: failure.title)
                        Text(failure.explanation)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .accessibilityIdentifier("card.failure")
                }
                Card("Power and torque") {
                    powerChart
                        .frame(height: 240)
                        .accessibilityIdentifier("chart.dyno")
                    legend
                }
                Card("What the engine was doing") {
                    trace("Air-fuel ratio", unit: "AFR", values: \.afr)
                    trace("Boost", unit: "psi", values: \.boostPsi)
                    trace("Knock", unit: "index (1 = detonation)", values: \.knockIndex)
                    trace("Exhaust temperature", unit: "°C", values: \.egtC)
                }
                PrimaryButton(title: isPulling ? "Pulling…" : "Start pull", systemImage: "gauge.with.dots.needle.67percent", action: onPull)
                    .accessibilityIdentifier("button.pull")
            }
            .padding(Theme.Space.l)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Dyno")
        .accessibilityIdentifier("screen.dyno")
    }

    private var peaks: some View {
        HStack(spacing: Theme.Space.m) {
            Readout(label: "Peak power", value: current.map { "\(Int($0.peakHp.rounded()))" } ?? "–", unit: "hp")
                .accessibilityIdentifier("label.peakHp")
            Readout(label: "At the wheels", value: current.map { "\(Int(($0.peakHp * 0.85).rounded()))" } ?? "–", unit: "whp")
            Readout(label: "Peak torque", value: current.map { "\(Int($0.peakTorqueNm.rounded()))" } ?? "–", unit: "Nm")
        }
        .padding(Theme.Space.l)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private var points: [Point] {
        var out: [Point] = []
        func add(_ result: DynoResult?, prefix: String) {
            guard let result else { return }
            for sample in result.samples {
                out.append(Point(id: out.count, rpm: sample.rpm, value: sample.powerHp, series: "\(prefix)power"))
                out.append(Point(id: out.count, rpm: sample.rpm, value: sample.torqueNm, series: "\(prefix)torque"))
            }
        }
        add(last, prefix: "Last pull ")
        add(current, prefix: "This pull ")
        return out
    }

    private var powerChart: some View {
        Chart(points) { point in
            LineMark(x: .value("rpm", point.rpm), y: .value("Value", point.value))
                .foregroundStyle(by: .value("Series", point.series))
                .lineStyle(StrokeStyle(lineWidth: point.series.hasPrefix("Last") ? 1.5 : 2.5, dash: point.series.hasPrefix("Last") ? [5, 4] : []))
        }
        .chartForegroundStyleScale([
            "This pull power": Theme.power,
            "This pull torque": Theme.torque,
            "Last pull power": Theme.lastPull,
            "Last pull torque": Theme.lastPull,
        ])
        .chartLegend(.hidden)
        .chartXAxisLabel("rpm")
        .chartYAxisLabel("hp / Nm")
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            legendRow(color: Theme.power, dashed: false, text: "Power, this pull (hp)")
            legendRow(color: Theme.torque, dashed: false, text: "Torque, this pull (Nm)")
            if last != nil { legendRow(color: Theme.lastPull, dashed: true, text: "Last pull (dashed)") }
        }
    }

    private func legendRow(color: Color, dashed: Bool, text: String) -> some View {
        HStack(spacing: Theme.Space.s) {
            Capsule()
                .stroke(color, style: StrokeStyle(lineWidth: 3, dash: dashed ? [4, 3] : []))
                .frame(width: 22, height: 3)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func trace(_ title: String, unit: String, values: KeyPath<DynoSample, Double>) -> some View {
        let samples = current?.samples ?? []
        let peak = samples.map { $0[keyPath: values] }.max() ?? 0
        return VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack {
                Text(title).font(.subheadline).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("max \(peak, specifier: "%.1f") \(unit)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
            Chart(Array(samples.enumerated()), id: \.offset) { item in
                LineMark(x: .value("rpm", item.element.rpm), y: .value(title, item.element[keyPath: values]))
                    .foregroundStyle(Theme.accent)
            }
            .chartXAxis(.hidden)
            .frame(height: 60)
            .accessibilityLabel("\(title) trace, highest \(String(format: "%.1f", peak)) \(unit)")
        }
    }
}
