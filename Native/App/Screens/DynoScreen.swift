import Charts
import PistonForgeKit
import SwiftUI

/// Which way the dyno is used: sweep the whole rev range, or hold one steady point.
enum DynoMode: String, CaseIterable, Identifiable {
    case pull, hold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pull: "Pull"
        case .hold: "Hold"
        }
    }

    var note: String {
        switch self {
        case .pull:
            "Full throttle through the rev range. The brake lets the engine climb at about 400 rpm/s and records a point every 100 rpm."
        case .hold:
            "Full throttle at one rpm. The brake holds the engine there so you can read a steady point."
        }
    }
}

/// Crank figures or what reaches the wheels.
enum DynoBasis: String, CaseIterable, Identifiable {
    case crank, wheels

    var id: String { rawValue }

    var title: String {
        switch self {
        case .crank: "Crank"
        case .wheels: "Wheels"
        }
    }

    /// `DynoRun` sheds 15% through the drivetrain by default. `DynoResult` does not carry the
    /// loss it used, so every result on this screen is read against the kit default.
    /// TODO(ws09): read the run's own `drivetrainLoss` once `DynoResult` carries it.
    static let drivetrainLoss = 0.15

    var factor: Double { self == .crank ? 1 : 1 - Self.drivetrainLoss }

    func power(_ crankHp: Double) -> Double { crankHp * factor }
    func torque(_ crankNm: Double) -> Double { crankNm * factor }

    var powerUnit: String { self == .crank ? "hp" : "whp" }
    var axisLabel: String { self == .crank ? "hp / Nm" : "whp / Nm at the wheels" }

    var note: String {
        switch self {
        case .crank: "What the engine makes on the dyno brake."
        case .wheels: "The same run after \(Int(Self.drivetrainLoss * 100))% drivetrain loss."
        }
    }
}

/// The dyno: hold a steady rpm or sweep a full pull, read crank or wheel figures, and keep a
/// log of what this engine has run.
struct DynoScreen: View {
    let build: EngineBuild
    let current: DynoResult?
    let last: DynoResult?
    let isPulling: Bool
    var preview = false
    var onPull: () -> Void = {}

    @State private var mode = DynoMode.pull
    @State private var basis = DynoBasis.crank
    @State private var hold = DynoHold()
    @State private var log: [DynoLogEntry] = []
    @State private var didLoadLog = false

    /// `DynoRun` starts its sweep here and nothing on `DynoResult` says so.
    /// TODO(ws09): take the start rpm from the result once the kit exposes it.
    private let pullStartRpm = 2000.0

    private struct Point: Identifiable {
        let id: Int
        let rpm: Double
        let value: Double
        let series: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                if preview { PreviewTag(rules: "Rules: one accent (the action), figures in tabular digits, failure explained in words with a next step, an empty state instead of blank charts") }
                modeCard
                actionArea
                failureCard
                if mode == .hold { holdCard }
                peaks
                chartSection
                logSection
            }
            .padding(Theme.Space.l)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Dyno")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.dyno")
        .onChange(of: current) { _, result in
            // A result only lands here once the pull has stopped; a live frame is ignored.
            guard !preview, !isPulling, let result else { return }
            log = DynoLogStore.adding(DynoLogEntry(pull: result, build: build), to: log)
        }
        .onChange(of: isPulling) { _, pulling in
            if pulling { hold.stop() }
        }
        .onChange(of: mode) { _, newMode in
            if newMode == .pull { hold.stop() }
        }
        .onChange(of: build.id) { _, _ in
            hold.stop()
            hold.clampTarget(revLimit: build.ecu.revLimit)
        }
        .onChange(of: log) { _, entries in
            guard !preview else { return }
            DynoLogStore.save(entries)
        }
        .onAppear {
            hold.clampTarget(revLimit: build.ecu.revLimit)
            // Load once: `onAppear` runs again every time the tab is reopened.
            // Previews read nothing from disk and write nothing back.
            if !preview, !didLoadLog {
                log = DynoLogStore.load()
                didLoadLog = true
            }
        }
        .onDisappear { hold.stop() }
    }

    // MARK: Mode and basis

    private var modeCard: some View {
        Card("Dyno mode") {
            Picker("Dyno mode", selection: $mode) {
                ForEach(DynoMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: Theme.hitTarget)
            .accessibilityIdentifier("picker.dynoMode")
            Text(mode.note)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .overlay { Theme.separator }

            Text("Read at")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Picker("Read at", selection: $basis) {
                ForEach(DynoBasis.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: Theme.hitTarget)
            .accessibilityIdentifier("picker.dynoBasis")
            Text(basis.note)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: The action and its progress

    private var actionArea: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s) {
            if isPulling { pullProgress }
            switch mode {
            case .pull:
                PrimaryButton(
                    title: isPulling ? "Pulling…" : "Start pull",
                    systemImage: "gauge.with.dots.needle.67percent"
                ) {
                    onPull()
                }
                .opacity(canPull ? 1 : 0.45)
                .disabled(!canPull)
                .accessibilityIdentifier("button.pull")
                if !isPulling {
                    Text("About \(pullSeconds) s from \(Int(pullStartRpm)) rpm to the limiter at \(Int(build.ecu.revLimit)) rpm.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            case .hold:
                PrimaryButton(
                    title: hold.isHolding
                        ? "Release the hold"
                        : "Hold at \(Int(hold.targetRpm.rounded()).formatted()) rpm",
                    systemImage: hold.isHolding ? "stop.circle.fill" : "pause.circle.fill"
                ) {
                    if hold.isHolding { hold.stop() } else { hold.start(build: build) }
                }
                .opacity(canHold ? 1 : 0.45)
                .disabled(!canHold)
                .accessibilityIdentifier("button.hold")
                if isPulling {
                    Text("Wait for the pull to finish before holding a point.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var pullProgress: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            if let rpm = current?.samples.last?.rpm {
                ProgressView(value: pullProgressValue)
                    .tint(Theme.accent)
                    .accessibilityLabel("Pull progress")
                    .accessibilityValue("\(Int((pullProgressValue * 100).rounded())) percent")
                HStack {
                    Text("Pulling")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(Int(rpm.rounded()).formatted()) rpm · \(Int((pullProgressValue * 100).rounded()))%")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                ProgressView()
                    .tint(Theme.accent)
                Text("Pulling: settling the engine at the start rpm…")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: Failure

    @ViewBuilder private var failureCard: some View {
        if let failure = current?.failure ?? hold.reading?.failure {
            Card {
                StatusLabel(status: .bad, text: failure.title)
                Text(failure.explanation)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Repair the engine on the Engine tab, then run another pull.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityIdentifier("card.failure")
        }
    }

    // MARK: Peaks

    private var peaks: some View {
        let result = current ?? last
        return VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack(spacing: Theme.Space.m) {
                Readout(
                    label: "Peak power",
                    value: result.map { "\(Int(basis.power($0.peakHp).rounded()))" } ?? "–",
                    unit: basis.powerUnit
                )
                .accessibilityIdentifier("label.peakHp")
                Readout(
                    label: "Peak torque",
                    value: result.map { "\(Int(basis.torque($0.peakTorqueNm).rounded()))" } ?? "–",
                    unit: "Nm"
                )
                Readout(
                    label: "Peak power at",
                    value: result.map { "\(Int($0.peakHpRpm.rounded()))" } ?? "–",
                    unit: "rpm"
                )
            }
            if current == nil, last != nil {
                Text("From the last pull. Run a new one to update.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    // MARK: Charts

    private var currentSamples: [DynoSample] { current?.samples ?? [] }

    private var hasChartData: Bool {
        !currentSamples.isEmpty || !(last?.samples.isEmpty ?? true)
    }

    @ViewBuilder private var chartSection: some View {
        if hasChartData {
            Card("Power and torque") {
                powerChart
                    .frame(height: 240)
                    .accessibilityIdentifier("chart.dyno")
                legend
                if currentSamples.isEmpty {
                    Text("Showing the last pull. The air-fuel, boost, knock and exhaust traces appear while a new pull runs.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if !currentSamples.isEmpty {
                Card("What the engine was doing") {
                    trace("Air-fuel ratio", unit: "AFR", values: \.afr)
                    trace("Boost", unit: "psi", values: \.boostPsi)
                    trace("Knock", unit: "index (1 = detonation)", values: \.knockIndex)
                    trace("Exhaust temperature", unit: "°C", values: \.egtC)
                }
            }
        } else {
            Card("Power and torque") {
                ContentUnavailableView {
                    Label(savedRunCount > 0 ? "No pull this session" : "No pull yet",
                          systemImage: "gauge.with.dots.needle.67percent")
                } description: {
                    Text(savedRunCount > 0
                         ? "Run a pull to draw it. The \(savedRunCount) saved runs for this engine are in the log below."
                         : "Run a pull to draw power and torque. The air-fuel, boost, knock and exhaust traces appear underneath.")
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .accessibilityIdentifier("state.dynoEmpty")
            }
        }
    }

    private var savedRunCount: Int {
        log.filter { $0.engineID == build.id }.count
    }

    private var points: [Point] {
        var out: [Point] = []
        func add(_ result: DynoResult?, prefix: String) {
            guard let result else { return }
            for sample in result.samples {
                let power = basis == .crank ? sample.powerHp : sample.wheelHp
                out.append(Point(id: out.count, rpm: sample.rpm, value: power, series: "\(prefix)power"))
                out.append(Point(id: out.count, rpm: sample.rpm, value: basis.torque(sample.torqueNm), series: "\(prefix)torque"))
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
                .lineStyle(style(for: point.series))
        }
        .chartForegroundStyleScale([
            "This pull power": Theme.power,
            "This pull torque": Theme.torque,
            "Last pull power": Theme.lastPull,
            "Last pull torque": Theme.lastPull,
        ])
        .chartLegend(.hidden)
        .chartXAxisLabel("rpm")
        .chartYAxisLabel(basis.axisLabel)
    }

    /// Power solid, torque dashed, the last pull a thin quiet line: the series never rely on
    /// hue alone.
    private func style(for series: String) -> StrokeStyle {
        if series.hasPrefix("Last") { return StrokeStyle(lineWidth: 1.5) }
        if series.hasSuffix("torque") { return StrokeStyle(lineWidth: 2.5, dash: [6, 3]) }
        return StrokeStyle(lineWidth: 2.5)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            if !currentSamples.isEmpty {
                legendRow(color: Theme.power, width: 3, dash: [], text: "Power, this pull (\(basis.powerUnit))")
                legendRow(color: Theme.torque, width: 3, dash: [4, 3], text: "Torque, this pull (Nm)")
            }
            if last?.samples.isEmpty == false {
                legendRow(color: Theme.lastPull, width: 1.5, dash: [], text: "Last pull (thin line)")
            }
        }
    }

    private func legendRow(color: Color, width: CGFloat, dash: [CGFloat], text: String) -> some View {
        HStack(spacing: Theme.Space.s) {
            Capsule()
                .stroke(color, style: StrokeStyle(lineWidth: width, dash: dash))
                .frame(width: 22, height: 3)
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func trace(_ title: String, unit: String, values: KeyPath<DynoSample, Double>) -> some View {
        let samples = currentSamples
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

    // MARK: Hold

    private var holdCeiling: Double { max(1200, build.ecu.revLimit - 200) }

    private var holdCard: some View {
        @Bindable var hold = hold
        return Card("Held point") {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                HStack {
                    Text("Target").foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(Int(hold.targetRpm.rounded()).formatted()) rpm")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
                Slider(value: $hold.targetRpm, in: 1000...holdCeiling, step: 100)
                    .tint(Theme.accent)
                    .frame(minHeight: Theme.hitTarget)
                    .accessibilityLabel("Held rpm")
                    .accessibilityIdentifier("slider.holdRpm")
            }

            if let reading = hold.reading {
                HStack(spacing: Theme.Space.m) {
                    Readout(
                        label: "Engine speed",
                        value: Int(reading.rpm.rounded()).formatted(),
                        unit: "rpm",
                        status: reading.limiterActive ? Status.bad : nil
                    )
                    Readout(label: "Torque", value: "\(Int(basis.torque(reading.torqueNm).rounded()))", unit: "Nm")
                    Readout(label: "Power", value: "\(Int(basis.power(reading.powerHp).rounded()))", unit: basis.powerUnit)
                }
                HStack(spacing: Theme.Space.m) {
                    Readout(label: "Air-fuel", value: String(format: "%.1f", reading.afr), unit: "AFR")
                    Readout(label: "Boost", value: String(format: "%.1f", reading.boostPsi), unit: "psi")
                    Readout(label: "Knock", value: String(format: "%.1f", reading.knockIndex), unit: "index")
                }
                HStack(spacing: Theme.Space.m) {
                    Readout(label: "Exhaust temperature", value: "\(Int(reading.egtC.rounded()))", unit: "°C")
                    Readout(label: "Oil temperature", value: "\(Int(reading.oilTempC.rounded()))", unit: "°C")
                    Readout(label: "Injector duty", value: "\(Int((reading.injectorDuty * 100).rounded()))", unit: "%")
                }
                if !hold.warnings.isEmpty {
                    WarningBanner(warnings: hold.warnings)
                }
                if !reading.isRunning, reading.failure == nil {
                    StatusLabel(status: .caution, text: "The engine stopped before it reached the target.")
                }
                SecondaryButton(title: "Save this point to the log", systemImage: "square.and.arrow.down") {
                    log = DynoLogStore.adding(
                        DynoLogEntry(hold: reading, build: build, targetRpm: hold.targetRpm),
                        to: log
                    )
                }
                .accessibilityIdentifier("button.logHold")
            } else {
                Text("Pick a target and tap Hold. The brake holds the engine there at full throttle, so every reading is a steady point rather than a sweep.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("card.hold")
    }

    // MARK: Actions' state

    private var canPull: Bool { !isPulling }

    private var canHold: Bool { !isPulling }

    private var pullProgressValue: Double {
        let top = max(build.ecu.revLimit, pullStartRpm + 1)
        let rpm = current?.samples.last?.rpm ?? pullStartRpm
        return min(max((rpm - pullStartRpm) / (top - pullStartRpm), 0), 1)
    }

    private var pullSeconds: Int {
        let span = max(build.ecu.revLimit - pullStartRpm, 0)
        return Int((span / DynoRun.sweepRpmPerSecond).rounded()) + 1
    }

    // MARK: Log

    private var logSection: some View {
        Card("Previous runs") {
            DynoLogView(log: $log, engineID: build.id, basis: basis)
        }
        .accessibilityIdentifier("card.dynoLog")
    }
}

/// A live rpm hold for the dyno screen. It owns a fresh `EngineSim` and steps it on the main
/// actor 30 times a second, servo'd to `targetRpm` exactly the way `DynoRun` settles its start
/// speed. The game's own engine and sound are left alone.
/// TODO(ws09): move this into `GameStore` so the sound and the saved engine follow a hold.
@Observable
@MainActor
private final class DynoHold {
    /// Where the brake is asked to hold, in rpm.
    var targetRpm = 3500.0
    private(set) var reading: EngineState?
    private(set) var warnings: [Warning] = []
    private(set) var isHolding = false

    private var task: Task<Void, Never>?

    func start(build: EngineBuild) {
        stop()
        clampTarget(revLimit: build.ecu.revLimit)

        let sim = EngineSim(build: build)
        sim.start()
        reading = sim.state
        warnings = sim.warnings
        isHolding = sim.isRunning
        guard sim.isRunning else { return }

        task = Task { @MainActor [weak self] in
            let servo = sim.inertiaKgM2 * 2 * Double.pi / 60 / 0.25
            while !Task.isCancelled {
                guard let self else { return }
                let target = targetRpm
                let lastFrame = sim.state
                let load = max(0, lastFrame.torqueNm + (lastFrame.rpm - target) * servo)
                let state = sim.step(dt: 1.0 / 30, throttle: 1, load: load)
                guard !Task.isCancelled else { return }
                reading = state
                warnings = sim.warnings
                if state.failure != nil || !state.isRunning {
                    isHolding = false
                    return
                }
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        reading = nil
        warnings = []
        isHolding = false
    }

    /// Keeps the target inside the engine's useful range.
    func clampTarget(revLimit: Double) {
        let ceiling = max(1200, revLimit - 200)
        targetRpm = min(max(targetRpm, 1000), ceiling)
    }
}
