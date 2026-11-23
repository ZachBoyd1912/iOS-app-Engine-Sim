import Foundation
import PistonForgeKit
import SwiftUI

/// The ECU: limits, boost, strategy, nitrous, and the fuel and ignition tables.
///
/// The tables are editable. Tap a cell and change it in the bar along the bottom of the screen, or
/// hold a cell and drag across its neighbours to paint them with the same value. Every change is
/// written straight into `build`, so `EngineSim` (and with it the warnings, the dyno and the
/// sound) sees it at once.
struct TuneScreen: View {
    @Binding var build: EngineBuild
    let warnings: [Warning]
    var preview = false
    var onAutoTune: () -> Void = {}

    @State private var table = Table.ignition
    @State private var selection: SelectedCell?
    /// The text in the value field, kept apart from the table so a half-typed number is never
    /// written into the tune.
    @State private var entry = ""
    /// The value a paint stroke spreads across every cell it touches; nil when no stroke is running.
    @State private var brush: Double?
    @State private var paintedCell: SelectedCell?
    @FocusState private var entryFocused: Bool

    /// Cells grow with the text so a number never clips; 44 pt is the touch floor either way.
    @ScaledMetric(relativeTo: .caption2) private var cellSide: CGFloat = 44
    /// Height of the rpm header and of the "kPa" corner above the load labels.
    @ScaledMetric(relativeTo: .caption2) private var headerHeight: CGFloat = 24

    private static let cellSpacing: CGFloat = 2
    private static let gridSpace = "tune.grid"

    /// A cell in the table: `row` indexes the load axis, `column` the rpm axis.
    struct SelectedCell: Equatable {
        var row: Int
        var column: Int
    }

    enum Table: String, CaseIterable {
        case ignition = "Ignition timing"
        case fuel = "Air-fuel ratio"

        /// The range `ECUMap.sanitized` keeps, so a cell can never be set outside the model's world.
        var range: ClosedRange<Double> {
            switch self {
            case .ignition: (-10.0)...50.0
            case .fuel: 6.0...20.0
            }
        }

        /// The smallest change worth showing: whole degrees of timing, a tenth of an AFR point.
        var step: Double {
            switch self {
            case .ignition: 1
            case .fuel: 0.1
            }
        }

        var format: String {
            switch self {
            case .ignition: "%.0f"
            case .fuel: "%.1f"
            }
        }

        var unit: String {
            switch self {
            case .ignition: "degrees before top dead centre"
            case .fuel: "to one"
            }
        }

        var explanation: String {
            switch self {
            case .ignition: "Spark advance. More timing makes more torque until the engine knocks."
            case .fuel: "Target air-fuel ratio. A lower number is richer, which cools the charge."
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                if preview { PreviewTag(rules: "Rules: one accent (Auto-tune), tables show numbers not colour alone, 44 pt cells, persistent banner") }
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
                    Text("Rows are load (kPa, 101 is full throttle without boost); columns are rpm. Tap a cell to change it.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Hold a cell for half a second, then drag across its neighbours to paint them the same value.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Theme.Space.l)
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { cellEditor }
        .onChange(of: selection) { _, cell in
            guard let cell, let value = valueAt(cell) else { return }
            entry = format(value)
        }
        .onChange(of: table) { _, _ in
            brush = nil
            paintedCell = nil
            entryFocused = false
            guard let cell = selection else { return }
            if let value = valueAt(cell) {
                entry = format(value)
            } else {
                selection = nil
            }
        }
        .onChange(of: build.ecu) { _, _ in
            // Auto-tune (or a save reload) replaces the map under the editor; keep the field honest
            // without stealing a number the player is half-way through typing.
            guard let cell = selection, !entryFocused, let value = valueAt(cell) else { return }
            entry = format(value)
        }
        .navigationTitle("Tune")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.tune")
    }

    // MARK: - The table

    private var tableGrid: some View {
        let values = table == .ignition ? build.ecu.ignitionTable : build.ecu.afrTable
        let rows = build.ecu.loadAxis.indices
        let columns = build.ecu.rpmAxis.indices
        let shaped = values.count == rows.count && values.allSatisfy { $0.count == columns.count }
        let low = shaped ? (values.flatMap { $0 }.min() ?? 0) : 0
        let high = shaped ? (values.flatMap { $0 }.max() ?? 1) : 1
        return Group {
            if shaped {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(alignment: .top, spacing: Self.cellSpacing) {
                        VStack(spacing: Self.cellSpacing) {
                            Text("kPa")
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                                .frame(width: cellSide, height: headerHeight)
                                .accessibilityHidden(true)
                            ForEach(rows.reversed(), id: \.self) { row in
                                axisLabel(loadText(row))
                            }
                        }
                        VStack(alignment: .leading, spacing: Self.cellSpacing) {
                            HStack(spacing: Self.cellSpacing) {
                                ForEach(columns, id: \.self) { column in
                                    axisLabel(rpmText(column), height: headerHeight)
                                }
                            }
                            .accessibilityHidden(true)
                            VStack(spacing: Self.cellSpacing) {
                                ForEach(rows.reversed(), id: \.self) { row in
                                    HStack(spacing: Self.cellSpacing) {
                                        ForEach(columns, id: \.self) { column in
                                            cellButton(
                                                SelectedCell(row: row, column: column),
                                                value: values[row][column], low: low, high: high
                                            )
                                        }
                                    }
                                }
                            }
                            .coordinateSpace(.named(Self.gridSpace))
                            .simultaneousGesture(paintGesture)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("\(table.rawValue) table, \(rows.count) load rows by \(columns.count) rpm columns, from \(format(low)) to \(format(high))")
                .accessibilityIdentifier("grid.table")
            } else {
                Text("This table is malformed. Run Auto-tune to put a safe map back in.")
                    .font(.footnote)
                    .foregroundStyle(Theme.warnInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("label.tableMalformed")
            }
        }
    }

    private func axisLabel(_ text: String, height: CGFloat? = nil) -> some View {
        Text(text)
            .font(.caption2.monospacedDigit())
            .foregroundStyle(Theme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: cellSide, height: height ?? cellSide)
            .accessibilityHidden(true)
    }

    private func cellButton(_ cell: SelectedCell, value: Double, low: Double, high: Double) -> some View {
        let share = high > low ? (value - low) / (high - low) : 0.5
        let chosen = selection == cell
        return Button {
            if let previous = selection, previous != cell { commitEntry(previous) }
            brush = nil
            paintedCell = nil
            selection = cell
            entry = format(value)
        } label: {
            Text(format(value))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: cellSide, height: cellSide)
                .background(Theme.accent.opacity(0.12 + 0.45 * share), in: RoundedRectangle(cornerRadius: 4))
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Theme.accent, lineWidth: 2)
                        .opacity(chosen ? 1 : 0)
                }
                .contentShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Load \(loadText(cell.row)) kPa, \(rpmText(cell.column)) rpm")
        .accessibilityValue("\(format(value)) \(table.unit)")
        .accessibilityHint("Selects the cell so it can be changed below")
        .accessibilityAddTraits(chosen ? AccessibilityTraits.isSelected : [])
        .accessibilityIdentifier("cell.table.\(cell.row).\(cell.column)")
    }

    /// Long press, then drag: paints every cell the finger crosses. A tap still belongs to the cell,
    /// so selecting and scrolling are never taken away from the player.
    private var paintGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.gridSpace)))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                guard let drag else { return }
                paint(at: drag.location)
            }
            .onEnded { _ in
                brush = nil
                paintedCell = nil
            }
    }

    private func paint(at point: CGPoint) {
        let rows = build.ecu.loadAxis.count
        let columns = build.ecu.rpmAxis.count
        let pitch = cellSide + Self.cellSpacing
        let column = Int(point.x / pitch)
        let fromTop = Int(point.y / pitch)
        guard (0..<columns).contains(column), (0..<rows).contains(fromTop) else { return }
        // The table is drawn top row = highest load, so the load index runs the other way.
        let cell = SelectedCell(row: rows - 1 - fromTop, column: column)
        guard cell != paintedCell else { return }
        paintedCell = cell
        selection = cell
        if brush == nil { brush = valueAt(cell) }
        if let brush { write(brush, at: cell) }
    }

    // MARK: - The cell editor

    @ViewBuilder private var cellEditor: some View {
        if let cell = selection, let value = valueAt(cell) {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                HStack(alignment: .top, spacing: Theme.Space.s) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Load \(loadText(cell.row)) kPa · \(rpmText(cell.column)) rpm")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(table.explanation)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: Theme.Space.s)
                    Button {
                        commitEntry(cell)
                        entryFocused = false
                        brush = nil
                        paintedCell = nil
                        selection = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: Theme.hitTarget, height: Theme.hitTarget)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close the cell editor")
                    .accessibilityIdentifier("button.cellDone")
                }
                HStack(spacing: Theme.Space.s) {
                    stepButton("Less", systemImage: "minus", identifier: "button.cellLess", delta: -table.step, cell: cell)
                    TextField("Value", text: $entry)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                        .focused($entryFocused)
                        .submitLabel(.done)
                        .onSubmit { commitEntry(cell) }
                        .onChange(of: entryFocused) { _, focused in
                            if !focused { commitEntry(cell) }
                        }
                        .frame(maxWidth: 128, minHeight: Theme.hitTarget)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.s))
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.Radius.s).strokeBorder(Theme.separator)
                        }
                        .accessibilityLabel("Value at load \(loadText(cell.row)) kPa, \(rpmText(cell.column)) rpm")
                        .accessibilityValue("\(format(value)) \(table.unit)")
                        .accessibilityIdentifier("field.cellValue")
                    stepButton("More", systemImage: "plus", identifier: "button.cellMore", delta: table.step, cell: cell)
                }
                Slider(
                    value: Binding(get: { valueAt(cell) ?? value }, set: { write($0, at: cell) }),
                    in: table.range,
                    step: table.step
                ) {
                    Text("Value")
                } minimumValueLabel: {
                    Text(format(table.range.lowerBound))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                } maximumValueLabel: {
                    Text(format(table.range.upperBound))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
                .tint(Theme.accent)
                .frame(minHeight: Theme.hitTarget)
                .accessibilityLabel("\(table.rawValue) at load \(loadText(cell.row)) kPa, \(rpmText(cell.column)) rpm")
                .accessibilityValue("\(format(value)) \(table.unit)")
                .accessibilityIdentifier("slider.cellValue")
            }
            .padding(Theme.Space.m)
            .background(Theme.surfaceRaised)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.separator).frame(height: 1)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("panel.cellEditor")
        }
    }

    private func stepButton(_ title: String, systemImage: String, identifier: String, delta: Double, cell: SelectedCell) -> some View {
        Button {
            // Take whatever is in the field first, so a typed number is stepped from, not lost.
            commitEntry(cell)
            guard let current = valueAt(cell) else { return }
            write(current + delta, at: cell)
        } label: {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Theme.hitTarget, height: Theme.hitTarget)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.s))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
    }

    // MARK: - Reading and writing cells

    private func valueAt(_ cell: SelectedCell) -> Double? {
        let values = table == .ignition ? build.ecu.ignitionTable : build.ecu.afrTable
        guard values.indices.contains(cell.row), values[cell.row].indices.contains(cell.column) else { return nil }
        return values[cell.row][cell.column]
    }

    /// Writes a cell as a plain tune change: snapped to the table's step, held inside the range the
    /// model accepts, and dropped when it would not move. The binding is `GameStore.build`, so the
    /// engine, the warnings and the save all pick it up.
    private func write(_ raw: Double, at cell: SelectedCell) {
        guard raw.isFinite, let current = valueAt(cell) else { return }
        let clamped = min(max(raw, table.range.lowerBound), table.range.upperBound)
        let value = (clamped / table.step).rounded() * table.step
        guard abs(current - value) > table.step / 20 else { return }
        switch table {
        case .ignition:
            guard build.ecu.ignitionTable.indices.contains(cell.row),
                  build.ecu.ignitionTable[cell.row].indices.contains(cell.column) else { return }
            build.ecu.ignitionTable[cell.row][cell.column] = value
        case .fuel:
            guard build.ecu.afrTable.indices.contains(cell.row),
                  build.ecu.afrTable[cell.row].indices.contains(cell.column) else { return }
            build.ecu.afrTable[cell.row][cell.column] = value
        }
        if selection == cell { entry = format(value) }
    }

    /// Takes whatever is in the field, writes it if it is a number, then puts the canonical value back
    /// so a rejected entry never sits there looking accepted.
    private func commitEntry(_ cell: SelectedCell) {
        let typed = entry.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if let parsed = Double(typed), parsed.isFinite {
            write(parsed, at: cell)
        }
        if let value = valueAt(cell) {
            entry = format(value)
        }
    }

    private func format(_ value: Double) -> String {
        String(format: table.format, value)
    }

    private func loadText(_ row: Int) -> String {
        guard build.ecu.loadAxis.indices.contains(row) else { return "?" }
        return Int(build.ecu.loadAxis[row]).formatted()
    }

    private func rpmText(_ column: Int) -> String {
        guard build.ecu.rpmAxis.indices.contains(column) else { return "?" }
        return Int(build.ecu.rpmAxis[column]).formatted()
    }

    // MARK: - The other controls

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
