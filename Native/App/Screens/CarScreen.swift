import PistonForgeKit
import SwiftUI

/// The car the engine goes into: body (with whether the engine fits), gearbox, final drive
/// and tyres.
struct CarScreen: View {
    let build: EngineBuild
    @Binding var car: CarSetup
    var preview = false

    var body: some View {
        Form {
            if preview {
                Section { PreviewTag(rules: "Rules: fit shown as icon + word + the dimension and mm over; native 44 pt rows") }
            }
            Section {
                ForEach(CarBody.allCases, id: \.self) { carBody in
                    Button {
                        car.body = carBody
                    } label: {
                        HStack(spacing: Theme.Space.m) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(carBody.spec.name).foregroundStyle(Theme.textPrimary)
                                Text("\(carBody.spec.drivetrain.rawValue.uppercased()) · \(Int(carBody.spec.massKg)) kg")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textSecondary)
                                fitLabel(carBody)
                            }
                            Spacer()
                            if car.body == carBody {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                                    .accessibilityLabel("Selected")
                            }
                        }
                        .frame(minHeight: Theme.hitTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: { SectionTitle("Body") } footer: {
                SectionNote("An engine that doesn't fit the bay can't be installed. Pick another body or a smaller engine.")
            }
            Section {
                Picker("Gearbox", selection: $car.gearbox) {
                    ForEach(Gearbox.allCases, id: \.rawValue) { box in
                        Text(box.displayName).tag(box)
                    }
                }
                .pickerStyle(.menu)
                Stepper(value: $car.finalDrive, in: 2...5.5, step: 0.05) {
                    HStack {
                        Text("Final drive")
                        Spacer()
                        Text(String(format: "%.2f:1", car.finalDrive)).monospacedDigit().foregroundStyle(Theme.textSecondary)
                    }
                }
            } header: { SectionTitle("Gearing") } footer: {
                SectionNote("A higher final drive number pulls harder off the line and runs out of revs sooner.")
            }
            Section {
                Picker("Compound", selection: $car.tyre.compound) {
                    Text("Street").tag(Tyre.Compound.street)
                    Text("Sport").tag(Tyre.Compound.sport)
                    Text("Semi-slick").tag(Tyre.Compound.semiSlick)
                    Text("Drag radial").tag(Tyre.Compound.dragRadial)
                }
                .pickerStyle(.menu)
                Stepper(value: $car.tyre.widthMm, in: 155...355, step: 10) {
                    HStack {
                        Text("Width")
                        Spacer()
                        Text("\(Int(car.tyre.widthMm)) mm").monospacedDigit().foregroundStyle(Theme.textSecondary)
                    }
                }
            } header: { SectionTitle("Tyres") }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Car")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.car")
    }

    @ViewBuilder
    private func fitLabel(_ carBody: CarBody) -> some View {
        switch fitment(build, in: carBody) {
        case .fits:
            StatusLabel(status: .good, text: "\(build.name) fits")
        case .blocked(let dimension, let overMm):
            StatusLabel(status: .bad, text: "Too \(word(dimension)) by \(overMm) mm")
        }
    }

    private func word(_ dimension: String) -> String {
        switch dimension {
        case "length": "long"
        case "width": "wide"
        case "height": "tall"
        default: "big"
        }
    }
}
