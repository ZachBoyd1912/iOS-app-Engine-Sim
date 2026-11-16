import Foundation
import Testing
@testable import PistonForgeKit

/// Golden fixtures exported from the TypeScript sim (`PistonForge/tests/export-fixtures.test.ts`).
/// Every ported formula is checked against them so the Swift game behaves like the model
/// that was played and audited, until a fix changes a number on purpose.
struct GoldenFile: Decodable {
    struct Case: Decodable {
        struct Input: Decodable { let engine: EngineConfig }
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
}

@Test func fixturesLoad() throws {
    let golden = try GoldenFile.load()
    #expect(golden.cases.count >= 18)
}

@Test func displacementMatchesTypeScript() throws {
    for item in try GoldenFile.load().cases {
        let swift = EngineModel.displacementCc(item.input.engine)
        // The TS spec rounds to whole cc.
        #expect(abs(swift.rounded() - item.spec.displacementCc) <= 1, "\(item.name): \(swift) vs \(item.spec.displacementCc)")
    }
}
