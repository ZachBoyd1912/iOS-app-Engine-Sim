import Foundation
import Testing
@testable import PistonForgeKit

/// Golden fixtures exported from the TypeScript sim (`PistonForge/tests/export-fixtures.test.ts`).
/// They are plausibility references, not exact targets: the native model fixes the old game's
/// bugs on purpose. Layout ids from the old game are mapped to the new layouts here.
struct GoldenFile: Decodable {
    struct Case: Decodable {
        struct Engine: Decodable {
            let layout: String
            let bore: Double
            let stroke: Double
        }
        struct Input: Decodable { let engine: Engine }
        struct Spec: Decodable { let displacementCc: Double }
        let name: String
        let input: Input
        let spec: Spec
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
        let swift = Double.pi / 4 * engine.bore * engine.bore * engine.stroke * Double(layout.spec.cylinders) / 1000
        // The TS spec rounds to whole cc.
        #expect(abs(swift.rounded() - item.spec.displacementCc) <= 1, "\(item.name): \(swift) vs \(item.spec.displacementCc)")
        checked += 1
    }
    #expect(checked >= 15)
}
