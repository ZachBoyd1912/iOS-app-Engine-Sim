import Foundation
import Testing

@testable import PistonForgeKit

private func countOccurrences(of needle: String, in text: String) -> Int {
    text.components(separatedBy: needle).count - 1
}

@Test(arguments: EngineLayout.allCases)
func scriptHasOneOfEverythingPerCylinder(layout: EngineLayout) {
    let build = EngineBuild.starter(layout)
    let spec = layout.spec
    let package = EngineSimScript.package(for: build, exhaust: .sport, limiter: .normal)
    let script = package.engineScript
    #expect(countOccurrences(of: "output wire", in: script) == spec.cylinders)
    #expect(countOccurrences(of: "rod_journal rj", in: script) == spec.cylinders)
    #expect(countOccurrences(of: ".connect_wire(", in: script) == spec.cylinders)
    #expect(countOccurrences(of: ".add_cylinder(", in: script) == spec.cylinders)
    #expect(countOccurrences(of: "cylinder_bank b", in: script) >= spec.banks)
    #expect(script.contains("public node main"))
}

@Test(arguments: EngineLayout.allCases)
func ignitionAnglesAreTheLayoutsFiringAngles(layout: EngineLayout) {
    let spec = layout.spec
    let package = EngineSimScript.package(for: EngineBuild.starter(layout), exhaust: .stock, limiter: .normal)
    var found: [Double] = []
    for rawLine in package.engineScript.split(separator: "\n") {
        let line = String(rawLine)
        guard line.contains(".connect_wire(wires.wire") else { continue }
        guard let comma = line.firstIndex(of: ","), let star = line.range(of: " * units.deg") else { continue }
        let number = line[line.index(after: comma)..<star.lowerBound].trimmingCharacters(in: .whitespaces)
        if let value = Double(number) { found.append(value) }
    }
    #expect(found.count == spec.cylinders)
    for (index, angle) in spec.firingAngles.enumerated() where index < found.count {
        #expect(abs(found[index] - angle) < 0.01)
    }
}

@Test(arguments: ExhaustPreset.allCases.filter { $0.isShippable })
func generatedImpulseResponsesAreValidAndDistinct(preset: ExhaustPreset) {
    let bytes = ExhaustImpulse.wav(preset)
    #expect(bytes.count == 44 + ExhaustImpulse.length * 2)
    #expect(Array(bytes[0..<4]) == Array("RIFF".utf8))
    var peak = 0
    var sumSquares = 0.0
    for index in 0..<ExhaustImpulse.length {
        let raw = Int16(bitPattern: UInt16(bytes[44 + index * 2]) | (UInt16(bytes[45 + index * 2]) << 8))
        let value = Int(raw)
        peak = max(peak, abs(value))
        sumSquares += Double(value) * Double(value)
    }
    #expect(peak > 20_000 && peak <= 32_767)
    #expect(sumSquares > 0)
}

@Test
func presetsHaveDifferentTones() {
    let shippable = ExhaustPreset.allCases.filter { $0.isShippable }
    let files = shippable.map { ExhaustImpulse.wav($0) }
    for first in 0..<files.count {
        for second in (first + 1)..<files.count {
            #expect(files[first] != files[second], "\(shippable[first]) and \(shippable[second]) are identical")
        }
    }
}

/// Writes every layout's scripts, with both bank-offset conventions, when `PF_SCRIPT_DIR` is set.
/// The Linux CI job then loads each one in engine-sim and checks that the engine revs freely.
@Test
func writesScriptsForEngineSimWhenAsked() throws {
    guard let directory = ProcessInfo.processInfo.environment["PF_SCRIPT_DIR"] else { return }
    for (name, sign) in [("pos", 1.0), ("neg", -1.0)] {
        for layout in EngineLayout.allCases {
            let folder = URL(fileURLWithPath: directory).appendingPathComponent(name).appendingPathComponent(layout.rawValue)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for preset in [ExhaustPreset.sport, ExhaustPreset.straight, ExhaustPreset.muffled] {
                let package = EngineSimScript.package(for: EngineBuild.starter(layout), exhaust: preset, limiter: .normal, bankPhaseSign: sign)
                let scriptName = "engine_\(preset.rawValue).mr"
                try Data(package.engineScript.utf8).write(to: folder.appendingPathComponent(scriptName))
                for (file, bytes) in package.files where file.hasSuffix(".wav") {
                    try Data(bytes).write(to: folder.appendingPathComponent(file))
                }
            }
        }
    }
}
