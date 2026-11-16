import Foundation
import Testing
@testable import PistonForgeKit

/// Pins the findings of the subagent review of Tasks 3-9 (16/11/2026).

private func temporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("pf-review-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

@Test func invertedNitrousWindowIsCorruptNotACrash() throws {
    var file = SaveFile.defaults()
    file.builds = [EngineBuild.starter(.i4)]
    file.selectedBuild = file.builds[0].id
    let encoded = try JSONEncoder().encode(file)
    var text = try #require(String(data: encoded, encoding: .utf8))
    text = text.replacingOccurrences(of: "\"nitrousWindow\":[0.9,1]", with: "\"nitrousWindow\":[1,0.2]")
    #expect(text.contains("\"nitrousWindow\":[1,0.2]"))
    let directory = try temporaryDirectory()
    try Data(text.utf8).write(to: directory.appendingPathComponent("save.json"))
    let (_, status) = SaveStore(directory: directory).load()
    #expect(status == .corruptReset)
}

@Test func failedEncodeNeverLosesTheNewerSave() throws {
    let directory = try temporaryDirectory()
    let main = directory.appendingPathComponent("save.json")
    let future = Data(#"{"version": 99}"#.utf8)
    try future.write(to: main)
    let store = SaveStore(directory: directory)
    var (file, _) = store.load()
    file.builds[0].bore = .nan // JSON cannot hold NaN, so encoding throws
    #expect(throws: (any Error).self) { try store.save(file) }
    #expect(try Data(contentsOf: main) == future, "the newer save is still where it was")
}

@Test func existingNewerSideFileIsNeverOverwritten() throws {
    let directory = try temporaryDirectory()
    let side = directory.appendingPathComponent("save.newer.json")
    let older = Data(#"{"version": 50}"#.utf8)
    try older.write(to: side)
    let future = Data(#"{"version": 99}"#.utf8)
    try future.write(to: directory.appendingPathComponent("save.json"))
    let store = SaveStore(directory: directory)
    let (file, _) = store.load()
    try store.save(file)
    #expect(try Data(contentsOf: side) == older)
    let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
    let kept = try names.filter { $0.hasPrefix("save.newer") }.map { try Data(contentsOf: directory.appendingPathComponent($0)) }
    #expect(kept.contains(future), "the second newer save is kept under another name: \(names)")
}

@Test func mafStrategyWithoutAMafWarns() {
    var build = EngineBuild.starter(.i4)
    build.sensors.maf = nil
    build.ecu.strategy = .maf
    let warnings = EngineSim(build: build).warnings
    #expect(warnings.contains(.mafMissing))
    #expect(!warnings.contains(.mafClipping))
}

@Test func limiterIsNotOverRev() {
    let sim = EngineSim(build: EngineBuild.starter(.i4))
    sim.start()
    var sawLimiter = false
    for _ in 0..<240 {
        let state = sim.step(dt: 1.0 / 60, throttle: 1, load: 0)
        if state.limiterActive {
            sawLimiter = true
            #expect(!state.warnings.contains(.overRev))
        }
    }
    #expect(sawLimiter)
}

@Test func fitmentOfANonNumberBuildDoesNotTrap() {
    var build = EngineBuild.starter(.v8Cross)
    build.bore = .infinity
    build.stroke = .nan
    if case .blocked(_, let over) = fitment(build, in: .muscle) {
        #expect(over >= 0)
    }
}

@Test func superchargerBoostBeyondTheFuelWarns() {
    var build = EngineBuild.starter(.v8Flat) // 11:1 on pump 95
    build.induction = .supercharger(.centrifugal, pulley: SuperchargerKind.pulleyRange.upperBound)
    build = build.withFuelSystemSized()
    build.ecu = ECUMap.autoBase(for: build)
    #expect(EngineSim(build: build).warnings.contains(.boostTooHighForFuel))
    build.induction = .supercharger(.roots, pulley: SuperchargerKind.pulleyRange.lowerBound)
    build.fuel = .race
    build = build.withFuelSystemSized()
    build.ecu = ECUMap.autoBase(for: build)
    #expect(!EngineSim(build: build).warnings.contains(.boostTooHighForFuel))
}

private let sensorSets: [SensorSet] = [
    SensorSet(maf: nil, map: true, iat: true, wideband: false, knock: true, egt: false, oil: true),
    SensorSet(maf: .small, map: false, iat: false, wideband: false, knock: false, egt: false, oil: false),
    SensorSet(maf: .xl, map: true, iat: true, wideband: true, knock: true, egt: true, oil: true),
]

/// The auto-base tune is safe, or the build already carries a warning that says why not.
@Test(arguments: EngineLayout.allCases)
func everyCombinationIsSafeOrWarned(layout: EngineLayout) {
    let inductions: [Induction] = [.natural, .turbo(.large)]
        + SuperchargerKind.allCases.flatMap { [Induction.supercharger($0, pulley: 0.8), .supercharger($0, pulley: 1.4)] }
    for induction in inductions {
        for sensors in sensorSets {
            for fuel in [Fuel.pump95, .e85] {
                var build = EngineBuild.starter(layout)
                build.induction = induction
                build.fuel = fuel
                build.sensors = sensors
                build = build.withFuelSystemSized()
                build.ecu = ECUMap.autoBase(for: build)
                let warned = !EngineSim(build: build).warnings.isEmpty
                var unsafe = false
                for rpm in stride(from: 1500.0, through: build.ecu.revLimit, by: 500) {
                    let boost = steadyBoostPsi(build, rpm: rpm, throttle: 1, target: build.ecu.boostTargetPsi)
                    let point = operatingPoint(build, rpm: rpm, throttle: 1, boostPsi: boost, nitrousArmed: false, closedLoopTrim: 0)
                    if point.combustion.knockIndex >= 1 || !fuel.spec.safeAfr.contains(point.combustion.afr) || point.combustion.egtC >= 950 {
                        unsafe = true
                    }
                }
                #expect(!unsafe || warned, "\(layout) \(induction) \(fuel) \(sensors): unsafe with no warning")
            }
        }
    }
}

@Test func voiceNeverHitsTheNonNumberGuard() {
    let voice = EngineVoice(sampleRate: 44_100)
    var buffer = [Float](repeating: 0, count: 4410)
    for layout in EngineLayout.allCases {
        let p = VoiceParams(rpm: 9000, load: 3, boostPsi: 60, throttle: 1, nitrous: true, induction: .supercharger(.centrifugal, pulley: 1.4), layout: layout, exhaustLevel: 3)
        buffer.withUnsafeMutableBufferPointer { voice.render(p, frames: $0.count, into: $0.baseAddress!) }
    }
    #expect(voice.nonFiniteSamples == 0)
}
