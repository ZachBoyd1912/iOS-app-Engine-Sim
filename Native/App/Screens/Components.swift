import PistonForgeKit
import SwiftUI

/// Good, caution or bad: always shown as icon + word + colour, never colour alone.
@MainActor
enum Status {
    case good, caution, bad

    var icon: String {
        switch self {
        case .good: "checkmark.circle.fill"
        case .caution: "exclamationmark.triangle.fill"
        case .bad: "xmark.octagon.fill"
        }
    }

    var mark: Color {
        switch self {
        case .good: Theme.goodMark
        case .caution: Theme.warnMark
        case .bad: Theme.badMark
        }
    }

    var ink: Color {
        switch self {
        case .good: Theme.goodInk
        case .caution: Theme.warnInk
        case .bad: Theme.badInk
        }
    }
}

struct StatusLabel: View {
    let status: Status
    let text: String

    var body: some View {
        Label {
            Text(text).foregroundStyle(status.ink)
        } icon: {
            Image(systemName: status.icon).foregroundStyle(status.mark)
        }
        .font(.subheadline.weight(.semibold))
    }
}

/// The "PREVIEW · sample data" marker every preview screen carries.
struct PreviewTag: View {
    let rules: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("PREVIEW · sample data")
                .font(.caption.weight(.heavy))
                .foregroundStyle(Theme.accent)
            Text(rules)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("label.preview")
    }
}

/// The one accent-filled action on a screen.
struct PrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundStyle(Theme.onAccent)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
        .buttonStyle(.plain)
    }
}

/// A quieter action next to the primary one.
struct SecondaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Theme.hitTarget)
                .foregroundStyle(Theme.textPrimary)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
        .buttonStyle(.plain)
    }
}

/// One live reading: a label, a big tabular number and its unit.
struct Readout: View {
    let label: String
    let value: String
    let unit: String
    var status: Status?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                if let status {
                    Image(systemName: status.icon)
                        .font(.caption)
                        .foregroundStyle(status.mark)
                }
                Text(value)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Persistent notice for warnings that hold until the build or tune changes.
struct WarningBanner: View {
    let warnings: [Warning]

    var body: some View {
        if !warnings.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                ForEach(warnings, id: \.self) { warning in
                    StatusLabel(status: severity(warning), text: warning.message)
                }
            }
            .padding(Theme.Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.m))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Theme.warnMark).frame(width: 4)
            }
            .accessibilityIdentifier("banner.warnings")
        }
    }

    private func severity(_ warning: Warning) -> Status {
        switch warning {
        case .knocking, .runningLean, .overBoost, .overRev, .hotExhaust, .oilPressureLow, .boostTooHighForFuel: .bad
        default: .caution
        }
    }
}

/// A rounded card on the first surface layer.
struct Card<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .padding(Theme.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
    }
}

extension Induction {
    var displayName: String {
        switch self {
        case .natural: "Naturally aspirated"
        case .turbo(let size):
            switch size {
            case .small: "Small turbo"
            case .medium: "Medium turbo"
            case .large: "Large turbo"
            case .twin: "Twin turbo"
            }
        case .supercharger(let kind, _):
            switch kind {
            case .roots: "Roots blower"
            case .twinScrew: "Twin-screw blower"
            case .centrifugal: "Centrifugal blower"
            }
        }
    }
}

extension Failure {
    /// A short headline for what broke.
    var title: String {
        switch self {
        case .leanMelt: "Melted a piston (ran lean)"
        case .detonation: "Cracked a piston (detonation)"
        case .overBoost: "Blew the head gasket (too much boost)"
        case .overRev: "Bent the valves (over-revved)"
        case .oilStarvation: "Spun a bearing (oil too hot)"
        }
    }
}
