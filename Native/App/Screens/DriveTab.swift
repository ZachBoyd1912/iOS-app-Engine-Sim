import PistonForgeKit
import SwiftUI

/// The drag strip: pick the run length and drive mode, hold the gas pedal, watch the timeslip.
struct DriveTab: View {
    let game: GameStore

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if game.dragRun == nil {
                    setup
                } else {
                    run
                }
            }
            .navigationTitle("Drive")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var imperial: Bool { game.save.settings.units == .imperial }

    // MARK: Setup

    private var setup: some View {
        @Bindable var game = game
        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                Card("Your car") {
                    Text("\(game.save.car.body.spec.name) · \(game.save.car.gearbox.displayName)")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(game.build.layout.spec.name) · \(Int(game.build.displacementCc.rounded())) cc · \(game.build.induction.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Change the car, gearbox, final drive and tyres in Garage › Car.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                Card("Drive mode") {
                    Picker("Drive mode", selection: $game.driveMode) {
                        ForEach(DriveMode.allCases, id: \.rawValue) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Text(modeNote(game.driveMode))
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                    Toggle("Automatic shifting", isOn: $game.driveAutomatic)
                        .frame(minHeight: Theme.hitTarget)
                    Toggle("Launch control", isOn: $game.launchControl)
                        .frame(minHeight: Theme.hitTarget)
                }
                Card("Run length") {
                    Picker("Run length", selection: $game.dragLengthM) {
                        Text("¼ mile").tag(DragRun.quarterMileM)
                        Text("½ mile").tag(DragRun.halfMileM)
                        Text("1 mile").tag(DragRun.mileM)
                    }
                    .pickerStyle(.segmented)
                }
                PrimaryButton(title: "Go to the line", systemImage: "flag.checkered") { game.startDrag() }
                    .accessibilityIdentifier("button.drive")
            }
            .padding(Theme.Space.l)
        }
    }

    private func modeNote(_ mode: DriveMode) -> String {
        switch mode {
        case .comfort: "Smooth shifts, gentle pedal. Good all-round."
        case .eco: "Short-shifts early, soft throttle, limited torque."
        case .sport: "Holds gears longer, sharper pedal, quicker shifts."
        case .sportPlus: "Shifts near redline, very sharp pedal, loosest traction control."
        }
    }

    // MARK: Run

    private var run: some View {
        VStack(spacing: Theme.Space.m) {
            hud
            Spacer(minLength: 0)
            if game.dragFinished { slip }
            controls
        }
        .padding(Theme.Space.l)
    }

    private var hud: some View {
        let state = game.driveState
        let speed = imperial ? (state?.speedMph ?? 0) : (state?.speedKph ?? 0)
        let progress = min((state?.distanceM ?? 0) / game.dragLengthM, 1)
        return VStack(spacing: Theme.Space.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(speed.rounded()))")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
                Text(imperial ? "mph" : "km/h")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Gear")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Text(gearText(state))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }
            }
            HStack {
                Readout(label: "Engine speed", value: "\(Int((state?.rpm ?? 0).rounded()))", unit: "rpm",
                        status: (state?.limiterActive ?? false) ? .bad : nil)
                Readout(label: "Time", value: String(format: "%.2f", state?.time ?? 0), unit: "s")
            }
            ProgressView(value: progress)
                .tint(Theme.accent)
                .accessibilityLabel("Distance")
            HStack {
                Text(String(format: "%.0f m", state?.distanceM ?? 0))
                Spacer()
                if (state?.wheelSlip ?? 0) > 0.85 {
                    StatusLabel(status: .caution, text: "Wheelspin")
                }
                Spacer()
                Text(String(format: "%.0f m", game.dragLengthM))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(Theme.textSecondary)
        }
        .padding(Theme.Space.l)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private func gearText(_ state: DriveState?) -> String {
        guard let state else { return "–" }
        if state.shifting { return "·" }
        return state.gear > 0 ? "\(state.gear)" : "N"
    }

    private var slip: some View {
        let slip = game.timeslip
        return Card("Timeslip") {
            slipRow("60 ft", slip?.sixtyFootS, nil)
            slipRow("330 ft", slip?.threeThirtyFootS, nil)
            slipRow("⅛ mile", slip?.eighthMileS, slip?.eighthTrapMph)
            slipRow("¼ mile", slip?.quarterMileS, slip?.quarterTrapMph)
            if game.dragLengthM > 500 { slipRow("½ mile", slip?.halfMileS, slip?.halfTrapMph) }
            if game.dragLengthM > 1000 { slipRow("1 mile", slip?.mileS, slip?.mileTrapMph) }
            HStack {
                Text("Top speed").foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(imperial ? String(format: "%.0f mph", slip?.topSpeedMph ?? 0) : String(format: "%.0f km/h", (slip?.topSpeedMph ?? 0) * 1.609_344))
                    .monospacedDigit()
            }
            .font(.subheadline)
        }
        .accessibilityIdentifier("card.timeslip")
    }

    private func slipRow(_ name: String, _ time: Double?, _ trapMph: Double?) -> some View {
        HStack {
            Text(name).foregroundStyle(Theme.textSecondary)
            Spacer()
            if let time {
                let trap = trapMph.map { imperial ? String(format: "  %.0f mph", $0) : String(format: "  %.0f km/h", $0 * 1.609_344) } ?? ""
                Text(String(format: "%.2f s", time) + trap).monospacedDigit().foregroundStyle(Theme.textPrimary)
            } else {
                Text("–").foregroundStyle(Theme.textSecondary)
            }
        }
        .font(.subheadline)
    }

    private var controls: some View {
        VStack(spacing: Theme.Space.m) {
            if game.dragFinished {
                PrimaryButton(title: "Run again", systemImage: "arrow.counterclockwise") { game.startDrag() }
                SecondaryButton(title: "Back", systemImage: "chevron.left") { game.endDrag() }
            } else {
                if !game.driveAutomatic {
                    HStack(spacing: Theme.Space.m) {
                        SecondaryButton(title: "Down", systemImage: "minus") { game.shiftDownRequest = true }
                        SecondaryButton(title: "Up", systemImage: "plus") { game.shiftUpRequest = true }
                    }
                }
                HStack(spacing: Theme.Space.m) {
                    pedal("BRAKE", systemImage: "hand.raised.fill", tint: Theme.badMark) { game.brakePedal = $0 }
                    pedal("GAS", systemImage: "arrow.up.circle.fill", tint: Theme.accent) { game.gasPedal = $0 }
                }
            }
        }
    }

    private func pedal(_ title: String, systemImage: String, tint: Color, _ set: @escaping (Bool) -> Void) -> some View {
        VStack(spacing: Theme.Space.xs) {
            Image(systemName: systemImage).font(.title)
            Text(title).font(.headline)
        }
        .foregroundStyle(Theme.onAccent)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(tint, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in set(true) }
                .onEnded { _ in set(false) }
        )
        .accessibilityLabel(title.capitalized + " pedal")
        .accessibilityAddTraits(.isButton)
    }
}
