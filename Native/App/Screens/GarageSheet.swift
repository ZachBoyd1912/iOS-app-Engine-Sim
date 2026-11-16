import PistonForgeKit
import SwiftUI

/// The saved engines: pick one, duplicate it, or delete it (with undo).
struct GarageSheet: View {
    let builds: [EngineBuild]
    let selected: UUID?
    var preview = false
    var onSelect: (UUID) -> Void = { _ in }
    var onDuplicate: (UUID) -> Void = { _ in }
    var onDelete: (UUID) -> Void = { _ in }

    var body: some View {
        List {
            if preview {
                Section { PreviewTag(rules: "Rules: whole row is the target, swipe to delete with undo, duplicate never destroys") }
            }
            Section {
                ForEach(builds) { build in
                    Button { onSelect(build.id) } label: {
                        HStack(spacing: Theme.Space.m) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(build.name).foregroundStyle(Theme.textPrimary)
                                Text("\(build.layout.spec.name) · \(build.induction.displayName)")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            if build.id == selected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                                    .accessibilityLabel("In use")
                            }
                        }
                        .frame(minHeight: Theme.hitTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) { onDelete(build.id) } label: { Label("Delete", systemImage: "trash") }
                        Button { onDuplicate(build.id) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    }
                    .contextMenu {
                        Button { onDuplicate(build.id) } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                        Button(role: .destructive) { onDelete(build.id) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            } header: { Text("Your engines") } footer: {
                Text("Swipe left on an engine to duplicate or delete it. A deleted engine can be brought back for 10 seconds.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Garage")
        .accessibilityIdentifier("screen.garage")
    }
}
