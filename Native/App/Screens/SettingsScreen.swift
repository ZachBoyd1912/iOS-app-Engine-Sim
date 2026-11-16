import PistonForgeKit
import SwiftUI

/// Units, controls, sound, haptics, quality, and a reset that can be undone.
struct SettingsScreen: View {
    @Binding var settings: Settings
    var preview = false
    var onReset: () -> Void = {}

    var body: some View {
        Form {
            if preview {
                Section { PreviewTag(rules: "Rules: native rows, reset walled off at the bottom with undo, no 'are you sure'") }
            }
            Section("Units") {
                Picker("Units", selection: $settings.units) {
                    Text("Metric (km/h, Nm)").tag(Settings.Units.metric)
                    Text("Imperial (mph, lb-ft)").tag(Settings.Units.imperial)
                }
                .pickerStyle(.menu)
            }
            Section {
                Picker("Steering", selection: $settings.steering) {
                    Text("Tilt the phone").tag(Settings.Steering.tilt)
                    Text("On-screen buttons").tag(Settings.Steering.touch)
                }
                .pickerStyle(.menu)
                Picker("Gears", selection: $settings.gears) {
                    Text("Automatic").tag(Settings.Gears.automatic)
                    Text("Paddles").tag(Settings.Gears.paddles)
                }
                .pickerStyle(.menu)
            } header: { Text("Driving") } footer: {
                Text("Used when driving arrives in the next update.")
            }
            Section {
                Toggle("Engine sound", isOn: $settings.sound)
                Toggle("Haptics", isOn: $settings.haptics)
                Picker("3D quality", selection: $settings.quality) {
                    Text("Low (cooler, longer battery)").tag(Settings.Quality.low)
                    Text("Medium").tag(Settings.Quality.medium)
                    Text("High").tag(Settings.Quality.high)
                }
                .pickerStyle(.menu)
            } header: { Text("Sound and feel") } footer: {
                Text("Engine sound plays even with the ringer switch on silent. Use the volume buttons or this switch to quiet it.")
            }
            Section {
                Button(role: .destructive, action: onReset) {
                    Label("Reset the garage to stock engines", systemImage: "arrow.counterclockwise")
                        .frame(minHeight: Theme.hitTarget)
                }
                .accessibilityIdentifier("button.reset")
            } header: { Text("Start over") } footer: {
                Text("Replaces your engines with the stock ones. You can undo it for 10 seconds.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .accessibilityIdentifier("screen.settings")
    }
}
