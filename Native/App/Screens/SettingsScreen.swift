import PistonForgeKit
import SwiftUI

/// Units, controls, sound, haptics, quality, and a reset that can be undone.
struct SettingsScreen: View {
    @Binding var settings: PistonForgeKit.Settings
    var preview = false
    var onReset: () -> Void = {}

    var body: some View {
        Form {
            if preview {
                Section { PreviewTag(rules: "Rules: native rows, reset walled off at the bottom with undo, no 'are you sure'") }
            }
            Section("Units") {
                Picker("Units", selection: $settings.units) {
                    Text("Metric (km/h, Nm)").tag(PistonForgeKit.Settings.Units.metric)
                    Text("Imperial (mph, lb-ft)").tag(PistonForgeKit.Settings.Units.imperial)
                }
                .pickerStyle(.menu)
            }
            Section {
                Picker("Steering", selection: $settings.steering) {
                    Text("Tilt the phone").tag(PistonForgeKit.Settings.Steering.tilt)
                    Text("On-screen buttons").tag(PistonForgeKit.Settings.Steering.touch)
                }
                .pickerStyle(.menu)
                Picker("Gears", selection: $settings.gears) {
                    Text("Automatic").tag(PistonForgeKit.Settings.Gears.automatic)
                    Text("Paddles").tag(PistonForgeKit.Settings.Gears.paddles)
                }
                .pickerStyle(.menu)
            } header: { Text("Driving") } footer: {
                Text("Used when driving arrives in the next update.")
            }
            Section {
                Toggle("Engine sound", isOn: $settings.sound)
                Toggle("Haptics", isOn: $settings.haptics)
                Picker("3D quality", selection: $settings.quality) {
                    Text("Low (cooler, longer battery)").tag(PistonForgeKit.Settings.Quality.low)
                    Text("Medium").tag(PistonForgeKit.Settings.Quality.medium)
                    Text("High").tag(PistonForgeKit.Settings.Quality.high)
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.settings")
    }
}
