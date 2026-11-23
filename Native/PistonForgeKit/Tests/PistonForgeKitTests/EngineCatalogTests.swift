import Testing
@testable import PistonForgeKit

/// The catalogue is research data, so these tests guard transcription and provenance, not
/// physics. They must pass while CI is blocked, so they only read the data layer.

@Test func catalogHasEveryResearchRow() {
    #expect(EngineCatalog.all.count == 83)
    #expect(EngineCatalog.all.map(\.id) == Array(1...83))
}

@Test func everyRecordedOrderFiresEachCylinderOnce() {
    for entry in EngineCatalog.all {
        guard let order = entry.firingOrder.cylinders else { continue }
        // An order only means anything against a stated cylinder count.
        guard let cylinders = entry.cylinders else {
            Issue.record("row \(entry.id) records an order but no cylinder count")
            continue
        }
        #expect(order.count == cylinders, "row \(entry.id): \(order.count) entries for \(cylinders) cylinders")
        #expect(Set(order) == Set(1...cylinders), "row \(entry.id): order \(order) is not a permutation of 1...\(cylinders)")
    }
}

@Test func playableRowsMapOntoEveryShippedLayout() {
    let mapped = EngineCatalog.playableLayouts
    #expect(mapped.count == EngineLayout.allCases.count)
    #expect(Set(mapped) == Set(EngineLayout.allCases))
}

@Test func playableRowsAgreeWithTheirLayout() {
    for entry in EngineCatalog.all {
        guard case .playable(let layout) = entry.playability else { continue }
        #expect(entry.cylinders == layout.spec.cylinders, "row \(entry.id) (\(layout.rawValue))")
    }
}

/// Records the one shipped layout whose firing order the research does not source, so a new
/// unsourced order cannot be added to the playable set without this test being updated.
@Test func onlyOnePlayableRowHasAnUnsourcedOrder() {
    let ids = EngineCatalog.all.filter { entry in
        guard case .playable = entry.playability else { return false }
        return entry.firingOrder.status == .notSourced
    }.map(\.id)
    #expect(ids == [27])
}

@Test func classificationsAccountForEveryRow() {
    #expect(
        EngineCatalog.playableCount + EngineCatalog.blockedOnGeometryCount
            + EngineCatalog.blockedOnFiringOrderCount + EngineCatalog.unsupportedArchitectureCount
            == EngineCatalog.all.count
    )
    #expect(
        EngineCatalog.sourcedOrderCount + EngineCatalog.derivedOrderCount
            + EngineCatalog.unsourcedOrderCount + EngineCatalog.notApplicableOrderCount
            == EngineCatalog.all.count
    )
}
