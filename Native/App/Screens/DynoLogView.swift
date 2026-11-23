import PistonForgeKit
import SwiftUI

/// One finished run, kept so a build can be compared with itself.
///
/// A pull is summarised from its `DynoResult` (peaks, worst AFR, most boost and so on) and a
/// held point from the single engine state it was saved at. Samples are not kept: the log is
/// for comparing numbers, the chart shows the run in progress.
struct DynoLogEntry: Codable, Equatable, Identifiable, Sendable {
    enum Kind: String, Codable, Sendable {
        case pull, hold
    }

    var id = UUID()
    var engineID: UUID
    var engineName: String
    var date = Date()
    var kind: Kind
    /// The rpm a hold was taken at; nil for a pull.
    var targetRpm: Double?
    var peakHp: Double
    var peakTorqueNm: Double
    var peakPowerRpm: Double
    var peakTorqueRpm: Double
    var revLimit: Double
    var sampleCount: Int
    var maxBoostPsi: Double?
    var minAfr: Double?
    var maxKnock: Double?
    var maxEgtC: Double?
    var failure: Failure?

    init(pull result: DynoResult, build: EngineBuild) {
        engineID = build.id
        engineName = build.name
        kind = .pull
        peakHp = result.peakHp
        peakTorqueNm = result.peakTorqueNm
        peakPowerRpm = result.peakHpRpm
        peakTorqueRpm = result.peakTorqueRpm
        revLimit = build.ecu.revLimit
        sampleCount = result.samples.count
        maxBoostPsi = result.samples.map(\.boostPsi).max()
        minAfr = result.samples.map(\.afr).filter { $0 > 0 }.min()
        maxKnock = result.samples.map(\.knockIndex).max()
        maxEgtC = result.samples.map(\.egtC).max()
        failure = result.failure
    }

    init(hold state: EngineState, build: EngineBuild, targetRpm: Double) {
        engineID = build.id
        engineName = build.name
        kind = .hold
        self.targetRpm = targetRpm
        peakHp = state.powerHp
        peakTorqueNm = state.torqueNm
        peakPowerRpm = state.rpm
        peakTorqueRpm = state.rpm
        revLimit = build.ecu.revLimit
        sampleCount = 1
        maxBoostPsi = state.boostPsi
        minAfr = state.afr > 0 ? state.afr : nil
        maxKnock = state.knockIndex
        maxEgtC = state.egtC
        failure = state.failure
    }
}

/// The log's home. It lives beside the screen, not in `GameStore`, until the game owns a
/// per-build run history.
/// TODO(ws09): move the log into `SaveFile` so it follows the build across devices.
enum DynoLogStore {
    static let key = "dyno.log.v1"
    static let perEngineLimit = 24
    static let totalLimit = 60

    static func load() -> [DynoLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        let decoded = (try? JSONDecoder().decode([DynoLogEntry].self, from: data)) ?? []
        return decoded.sorted { $0.date > $1.date }
    }

    static func save(_ entries: [DynoLogEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Adds one run at the top and keeps the newest `perEngineLimit` for each engine and
    /// `totalLimit` overall, so the log cannot grow without bound.
    static func adding(_ entry: DynoLogEntry, to entries: [DynoLogEntry]) -> [DynoLogEntry] {
        var next = entries
        next.insert(entry, at: 0)
        var perEngine: [UUID: Int] = [:]
        var kept: [DynoLogEntry] = []
        for item in next {
            let used = perEngine[item.engineID, default: 0]
            guard used < perEngineLimit else { continue }
            perEngine[item.engineID] = used + 1
            kept.append(item)
        }
        return Array(kept.prefix(totalLimit))
    }
}

/// The last few saved runs for one engine, with a way into the full log.
struct DynoLogView: View {
    @Binding var log: [DynoLogEntry]
    let engineID: UUID
    let basis: DynoBasis
    var limit = 3

    @State private var confirmClear = false

    private var mine: [DynoLogEntry] {
        Array(log.filter { $0.engineID == engineID }.prefix(limit))
    }

    private var mineCount: Int {
        log.filter { $0.engineID == engineID }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if mineCount == 0 {
                empty
            } else {
                ForEach(Array(mine.enumerated()), id: \.offset) { pair in
                    DynoLogRow(entry: pair.element, basis: basis)
                    if pair.offset < mine.count - 1 {
                        Divider()
                            .overlay { Theme.separator }
                    }
                }
                if mineCount > limit {
                    NavigationLink {
                        DynoLogList(log: $log, basis: basis, engineID: engineID)
                    } label: {
                        HStack {
                            Text("All \(mineCount) runs")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .frame(minHeight: Theme.hitTarget)
                    }
                    .buttonStyle(.plain)
                }
                Button(role: .destructive) {
                    confirmClear = true
                } label: {
                    Text("Clear this engine's log")
                        .font(.footnote)
                        .foregroundStyle(Theme.badInk)
                        .frame(minHeight: Theme.hitTarget, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .confirmationDialog("Delete this engine's runs?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Delete \(mineCount) runs", role: .destructive) {
                log.removeAll { $0.engineID == engineID }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text("No runs saved yet")
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
            Text("Every finished pull, and any held point you save, is kept here for this engine.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: Theme.hitTarget, alignment: .leading)
    }
}

/// The full log: this engine's runs, or every engine's.
struct DynoLogList: View {
    @Binding var log: [DynoLogEntry]
    let basis: DynoBasis
    let engineID: UUID

    @State private var allEngines = false

    private var shown: [DynoLogEntry] {
        allEngines ? log : log.filter { $0.engineID == engineID }
    }

    var body: some View {
        List {
            Section {
                Toggle("Show every engine", isOn: $allEngines)
                    .tint(Theme.accent)
                    .frame(minHeight: Theme.hitTarget)
                    .listRowBackground(Theme.surface)
            }
            Section("\(shown.count) runs") {
                if shown.isEmpty {
                    Text("No runs saved yet.")
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Theme.surface)
                }
                ForEach(shown) { entry in
                    DynoLogRow(entry: entry, basis: basis, showsEngine: allEngines)
                        .listRowBackground(Theme.surface)
                }
                .onDelete(perform: delete)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Dyno log")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func delete(at offsets: IndexSet) {
        let ids = Set(offsets.map { shown[$0].id })
        log.removeAll { ids.contains($0.id) }
    }
}

/// One run, in whichever basis the dyno is reading at the moment.
struct DynoLogRow: View {
    let entry: DynoLogEntry
    let basis: DynoBasis
    var showsEngine = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.s) {
                Text(entry.kind == .pull ? "Pull" : "Hold")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                if let rpm = entry.targetRpm {
                    Text("\(Int(rpm.rounded()).formatted()) rpm")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: Theme.Space.s)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                Text(entry.sampleCount > 0 ? "\(Int(basis.power(entry.peakHp).rounded())) \(basis.powerUnit)" : "– \(basis.powerUnit)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                Text("·")
                    .foregroundStyle(Theme.textSecondary)
                Text(entry.sampleCount > 0 ? "\(Int(basis.torque(entry.peakTorqueNm).rounded())) Nm" : "– Nm")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                if entry.peakPowerRpm > 0 {
                    Text("@ \(Int(entry.peakPowerRpm.rounded()).formatted()) rpm")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            if showsEngine {
                Text(entry.engineName)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            if let failure = entry.failure {
                StatusLabel(status: .bad, text: failure.title)
            } else if let afr = entry.minAfr, let boost = entry.maxBoostPsi {
                Text("Worst AFR \(String(format: "%.1f", afr)) · most boost \(String(format: "%.1f", boost)) psi")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.vertical, Theme.Space.xs)
        .accessibilityElement(children: .combine)
    }
}
