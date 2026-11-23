import XCTest
@testable import PistonForgeKit

/// Specification for the researched engine catalogue. Written before the data exists:
/// against the empty stub these fail, which is the point.
///
/// The invariants exist because the source research explicitly refuses to invent firing
/// orders. A catalogue that quietly fills them in would be lying to the player and to the
/// sound model, so the tests enforce the honesty.
final class EngineCatalogTests: XCTestCase {

    func testCatalogueHasEveryResearchedRow() {
        XCTAssertEqual(EngineCatalog.all.count, 83)
    }

    func testIdsAreUniqueAndPadded() {
        let ids = EngineCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "ids must be unique")
        for id in ids {
            XCTAssertEqual(id.count, 2, "id \(id) should be two characters, e.g. 07")
            XCTAssertNotNil(Int(id), "id \(id) should be numeric")
        }
    }

    func testNamesAreNeverEmpty() {
        for entry in EngineCatalog.all {
            XCTAssertFalse(entry.name.trimmingCharacters(in: .whitespaces).isEmpty,
                           "entry \(entry.id) has no name")
        }
    }

    func testCylinderCountIsPositiveExceptForRotaries() {
        for entry in EngineCatalog.all {
            if entry.layout.lowercased().contains("rotary") { continue }
            XCTAssertGreaterThan(entry.cylinders, 0, "entry \(entry.id) has no cylinders")
        }
    }

    func testUnsourcedRowsCarryNoFiringOrder() {
        for entry in EngineCatalog.all where entry.firingSource == .unsourced {
            XCTAssertNil(entry.firingOrder,
                         "entry \(entry.id) is marked unsourced but carries \(entry.firingOrder ?? "")")
        }
    }

    func testSourcedRowsActuallyHaveAnOrder() {
        for entry in EngineCatalog.all where entry.firingSource == .sourced {
            XCTAssertNotNil(entry.firingOrder, "entry \(entry.id) claims a source but has no order")
        }
    }

    func testDerivedRowsActuallyHaveAnOrder() {
        for entry in EngineCatalog.all where entry.firingSource == .derived {
            XCTAssertNotNil(entry.firingOrder, "entry \(entry.id) is derived but has no order")
        }
    }

    func testSingleCylinderIsNotApplicableRatherThanUnsourced() {
        let singles = EngineCatalog.all.filter { $0.cylinders == 1 }
        XCTAssertFalse(singles.isEmpty, "the catalogue should contain single-cylinder engines")
        for entry in singles {
            XCTAssertEqual(entry.firingSource, .notApplicable,
                           "entry \(entry.id) is a single and should be notApplicable, not \(entry.firingSource)")
        }
    }

    func testDisplacementsArePlausibleWhenPresent() {
        for entry in EngineCatalog.all {
            guard let cc = entry.displacementCc else { continue }
            XCTAssertGreaterThan(cc, 20, "entry \(entry.id) displacement \(cc) cc is implausibly small")
            XCTAssertLessThan(cc, 30_000, "entry \(entry.id) displacement \(cc) cc is implausibly large")
        }
    }

    func testEveryRowCitesASource() {
        for entry in EngineCatalog.all {
            XCTAssertFalse(entry.sources.trimmingCharacters(in: .whitespaces).isEmpty,
                           "entry \(entry.id) cites no source")
        }
    }

    func testProvenanceIsSpreadRatherThanAllOneBucket() {
        let counts = EngineCatalogEntry.FiringSource.allCases.map { source in
            EngineCatalog.all.filter { $0.firingSource == source }.count
        }
        XCTAssertGreaterThan(counts.reduce(0, +), 0)
        // The research found real orders for some rows and none for others; a catalogue that
        // claims one bucket for everything has been filled in by guesswork.
        XCTAssertGreaterThan(counts.filter { $0 > 0 }.count, 1,
                             "provenance should not be a single bucket")
    }
}
