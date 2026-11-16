import PistonForgeKit
import SwiftUI

/// Home: the engine in 3D, its live readings, start/stop and the rev slider.
struct EngineScreen: View {
    let build: EngineBuild
    let state: EngineState
    let warnings: [Warning]
    @Binding var throttle: Double
    var preview = false
    var onStartStop: () -> Void = {}
    var onSelectPart: (PartGroup) -> Void = { _ in }
    var onOpenGarage: () -> Void = {}
    var onOpenSettings: () -> Void = {}

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            EngineViewport(build: build, state: state, onSelect: onSelectPart)
                .ignoresSafeArea(edges: .horizontal)
            VStack(spacing: Theme.Space.m) {
                header
                if preview { PreviewTag(rules: "Rules: one accent (Start), status = icon + word, 44 pt targets, persistent banner for warnings") }
                WarningBanner(warnings: warnings)
                Spacer(minLength: 0)
                controls
            }
            .padding(.horizontal, Theme.Space.l)
            .padding(.vertical, Theme.Space.s)
        }
        .accessibilityIdentifier("screen.engine")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Theme.Space.m) {
            Button(action: onOpenGarage) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(build.name)
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .accessibilityIdentifier("label.engineName")
                    Text("\(build.layout.spec.name) · \(build.induction.displayName) · \(Int(build.displacementCc.rounded())) cc")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, minHeight: Theme.hitTarget, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens your saved engines")
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: Theme.hitTarget, height: Theme.hitTarget)
                    .background(Theme.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var controls: some View {
        VStack(spacing: Theme.Space.m) {
            HStack(spacing: Theme.Space.m) {
                Readout(label: "Engine speed", value: "\(Int(state.rpm.rounded()))", unit: "rpm")
                    .accessibilityIdentifier("label.rpm")
                Readout(label: "Power", value: "\(Int(max(state.powerHp, 0).rounded()))", unit: "hp")
                Readout(label: "Air-fuel", value: state.afr > 0 ? String(format: "%.1f", state.afr) : "–", unit: "AFR", status: afrStatus)
                Readout(label: "Boost", value: String(format: "%.1f", state.boostPsi), unit: "psi")
            }
            if state.isRunning {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    Text("Rev: \(Int((throttle * 100).rounded()))% throttle")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Slider(value: $throttle, in: 0...1)
                        .tint(Theme.accent)
                        .frame(minHeight: Theme.hitTarget)
                        .accessibilityLabel("Throttle")
                        .accessibilityIdentifier("slider.throttle")
                }
            }
            PrimaryButton(title: state.isRunning ? "Stop engine" : "Start engine", systemImage: state.isRunning ? "stop.fill" : "power", action: onStartStop)
                .accessibilityIdentifier("button.start")
        }
        .padding(Theme.Space.l)
        .background(Theme.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: Theme.Radius.l))
    }

    private var afrStatus: Status? {
        guard state.isRunning, state.afr > 0, state.loadKpa > 90 else { return nil }
        return build.fuel.spec.safeAfr.contains(state.afr) ? .good : .bad
    }
}
