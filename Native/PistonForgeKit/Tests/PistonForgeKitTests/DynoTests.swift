import Foundation
import Testing
@testable import PistonForgeKit

/// Golden fixtures exported from the old TypeScript game (`PistonForge/tests/export-fixtures.test.ts`).
/// They are plausibility references, not exact targets: the native model fixes the old game's
/// bugs on purpose. Old layout ids are mapped to the new layouts here.
struct GoldenFile: Decodable {
    struct Case: Decodable {
        struct Parts: Decodable {
            let head, cams, intake, exhaust, internals, valves, gasket, intercooler: Int
        }
        struct Engine: Decodable {
            let layout: String
            let bore: Double
            let stroke: Double
            let compression: Double
            let induction: String
            let fuel: String
            let parts: Parts
        }
        struct Input: Decodable { let engine: Engine }
        struct Spec: Decodable {
            let displacementCc: Double
            let cylinders: Int
        }
        struct Dyno: Decodable { let peakHp: Double }
        let name: String
        let input: Input
        let spec: Spec
        let dyno: Dyno
    }
    let cases: [Case]

    static func load() throws -> GoldenFile {
        let url = try #require(Bundle.module.url(forResource: "sim-golden", withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder().decode(GoldenFile.self, from: Data(contentsOf: url))
    }

    /// Old game layout id to the new layout; nil where the new game has no equivalent.
    static func layout(forOldId id: String) -> EngineLayout? {
        switch id {
        case "i3": .i3
        case "i4": .i4
        case "i6": .i6
        case "v6": .v6_60
        case "v8": .v8Cross
        case "v12": .v12
        default: nil
        }
    }

    /// The nearest native build to an old-game engine, fuel system sized, on the auto-base tune.
    static func build(from engine: Case.Engine) -> EngineBuild? {
        guard let layout = layout(forOldId: engine.layout) else { return nil }
        var build = EngineBuild.starter(layout)
        build.bore = engine.bore
        build.stroke = engine.stroke
        build.compression = engine.compression
        build.induction = switch engine.induction {
        case "turboS": .turbo(.small)
        case "turboM": .turbo(.medium)
        case "turboL": .turbo(.large)
        case "twinTurbo": .turbo(.twin)
        default: .natural
        }
        build.fuel = switch engine.fuel {
        case "p98": .pump98
        case "e85": .e85
        case "race": .race
        default: .pump95
        }
        let parts = engine.parts
        build.parts.head = parts.head
        build.parts.cams = parts.cams
        build.parts.intake = parts.intake
        build.parts.exhaust = parts.exhaust
        build.parts.internals = parts.internals
        build.parts.valves = parts.valves
        build.parts.gasket = parts.gasket
        build.parts.intercooler = parts.intercooler
        build = build.sanitized().withFuelSystemSized()
        build.ecu = ECUMap.autoBase(for: build)
        return build
    }
}

@Test func fixturesLoad() throws {
    let golden = try GoldenFile.load()
    #expect(golden.cases.count >= 18)
}

@Test func displacementMatchesTypeScript() throws {
    var checked = 0
    for item in try GoldenFile.load().cases {
        guard let layout = GoldenFile.layout(forOldId: item.input.engine.layout) else { continue }
        let engine = item.input.engine
        #expect(layout.spec.cylinders == item.spec.cylinders, "\(item.name): layout mapping")
        let swift = Double.pi / 4 * engine.bore * engine.bore * engine.stroke * Double(layout.spec.cylinders) / 1000
        // The TS spec rounds to whole cc.
        #expect(abs(swift.rounded() - item.spec.displacementCc) <= 1, "\(item.name): \(swift) vs \(item.spec.displacementCc)")
        checked += 1
    }
    #expect(checked >= 15)
}

@Test func plausibleAgainstOldGame() throws {
    let wanted = ["preset-street", "preset-turbo", "preset-bigblock"]
    let cases = try GoldenFile.load().cases.filter { wanted.contains($0.name) }
    #expect(cases.count == 3)
    for item in cases {
        let build = try #require(GoldenFile.build(from: item.input.engine))
        let result = runDynoToEnd(build)
        #expect(result.failure == nil, "\(item.name) failed: \(String(describing: result.failure))")
        let ratio = result.peakHp / item.dyno.peakHp
        #expect(ratio >= 0.55 && ratio <= 1.45, "\(item.name): \(result.peakHp) hp vs old \(item.dyno.peakHp)")
    }
}

private let inductions: [Induction] = [.natural]
    + TurboSize.allCases.map { Induction.turbo($0) }
    + SuperchargerKind.allCases.map { Induction.supercharger($0, pulley: SuperchargerKind.pulleyRange.upperBound) }

@Test(arguments: EngineLayout.allCases)
func everyCombinationStaysFinite(layout: EngineLayout) {
    for induction in inductions {
        for nitrous in [nil, NitrousKit(kind: .dry, shotHp: 300, armRpm: 1500, enabled: true)] {
            for injector in [PartChoices.injectorRange.lowerBound, PartChoices.injectorRange.upperBound] {
                var build = EngineBuild.starter(layout)
                build.induction = induction
                build.nitrous = nitrous
                build.parts.injectorCcMin = injector
                build.ecu.boostTargetPsi = 45 // the most a player could ask for
                let result = runDynoToEnd(build)
                let tag = "\(layout) \(induction) nitrous \(nitrous != nil) injector \(injector)"
                #expect(!result.samples.isEmpty || result.failure != nil, "\(tag): no samples and no failure")
                for sample in result.samples {
                    let values = [sample.rpm, sample.torqueNm, sample.powerHp, sample.wheelHp, sample.afr, sample.boostPsi, sample.knockIndex, sample.egtC]
                    let finite = values.allSatisfy { $0.isFinite }
                    #expect(finite, "\(tag) at \(sample.rpm)")
                }
                let peaksFinite = [result.peakHp, result.peakHpRpm, result.peakTorqueNm, result.peakTorqueRpm].allSatisfy { $0.isFinite }
                #expect(peaksFinite, "\(tag)")
            }
        }
    }
}

@Test func wheelHpBelowCrank() {
    let result = runDynoToEnd(EngineBuild.starter(.v8Flat))
    #expect(!result.samples.isEmpty)
    for sample in result.samples where sample.powerHp > 0 {
        #expect(sample.wheelHp < sample.powerHp)
        #expect(abs(sample.wheelHp - sample.powerHp * 0.85) < 0.001)
    }
}

@Test func samplesAscendInRpm() {
    let result = runDynoToEnd(EngineBuild.starter(.i6))
    #expect(result.samples.count >= 20)
    let ascending = zip(result.samples, result.samples.dropFirst()).allSatisfy { $0.rpm < $1.rpm }
    #expect(ascending)
    let first = result.samples.first?.rpm ?? 0
    let last = result.samples.last?.rpm ?? 0
    #expect(first >= 1900 && first <= 2300, "starts near 2000: \(first)")
    #expect(last >= EngineBuild.starter(.i6).ecu.revLimit - 300, "runs to the limiter: \(last)")
}

@Test func liveRunMatchesBatch() {
    var build = EngineBuild.starter(.i4)
    build.induction = .turbo(.small)
    build = build.withFuelSystemSized()
    build.ecu = ECUMap.autoBase(for: build)
    let sim = EngineSim(build: build)
    let run = DynoRun(sim: sim)
    var steps = 0
    while !run.isFinished && steps < 60 * 120 {
        _ = run.step(dt: 1.0 / 60)
        steps += 1
    }
    let live = run.result?.peakHp ?? 0
    let batch = runDynoToEnd(build).peakHp
    #expect(live > 0)
    #expect(abs(live - batch) / batch < 0.02, "live \(live), batch \(batch)")
}

@Test func sweepRateIsAboutFourHundredRpmPerSecond() {
    let sim = EngineSim(build: EngineBuild.starter(.v10))
    let run = DynoRun(sim: sim)
    var times: [(t: Double, rpm: Double)] = []
    var t = 0.0
    while !run.isFinished && t < 60 {
        if let sample = run.step(dt: 1.0 / 60) { times.append((t, sample.rpm)) }
        t += 1.0 / 60
    }
    let rising = times.filter { $0.rpm > 3000 && $0.rpm < 6000 }
    let first = rising.first
    let last = rising.last
    #expect(first != nil && last != nil)
    if let first, let last, last.t > first.t {
        let rate = (last.rpm - first.rpm) / (last.t - first.t)
        #expect(rate > 300 && rate < 500, "sweep at \(rate) rpm/s")
    }
}
