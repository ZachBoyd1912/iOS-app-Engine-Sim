import Testing
@testable import PistonForgeKit

/// Gaps between consecutive firing events in crank degrees, wrapping at 720.
private func gaps(_ spec: LayoutSpec) -> [Double] {
    let angles = spec.firingAngles
    return angles.indices.map { index in
        let next = index + 1 < angles.count ? angles[index + 1] : angles[0] + 720
        return next - angles[index]
    }
}

private func banks(_ spec: LayoutSpec) -> [Int] {
    spec.firingOrder.map { spec.bankOf[$0 - 1] }
}

@Test(arguments: EngineLayout.allCases)
func allLayoutsFireEveryCylinderOnce(layout: EngineLayout) {
    let spec = layout.spec
    #expect(spec.cylinders > 0)
    #expect(Set(spec.firingOrder) == Set(1...max(spec.cylinders, 1)))
    #expect(spec.firingOrder.count == spec.cylinders)
    #expect(spec.firingAngles.count == spec.cylinders)
    #expect(spec.bankOf.count == spec.cylinders)
    #expect(spec.crankPins.count == spec.cylinders)
    #expect(spec.firingAngles.allSatisfy { $0 >= 0 && $0 < 720 })
    #expect(spec.bankOf.allSatisfy { $0 >= 0 && $0 < spec.banks })
}

@Test(arguments: [EngineLayout.i3, .i4, .i6, .v6_60, .v8Cross, .v8Flat, .v10, .v12, .w16])
func evenFireIntervals(layout: EngineLayout) {
    let spec = layout.spec
    let expected = 720 / Double(spec.cylinders)
    #expect(!spec.firingAngles.isEmpty)
    for gap in gaps(spec) {
        #expect(abs(gap - expected) < 0.001, "\(layout): gap \(gap), expected \(expected)")
    }
}

@Test func v6_90IsOddFire() {
    let found = gaps(EngineLayout.v6_90.spec)
    #expect(found.count == 6)
    for (index, gap) in found.enumerated() {
        #expect(abs(gap - (index.isMultiple(of: 2) ? 90 : 150)) < 0.001, "gap \(index) is \(gap)")
    }
}

@Test func flatPlaneAlternatesBanks() {
    let sequence = banks(EngineLayout.v8Flat.spec)
    #expect(sequence.count == 8)
    for index in sequence.indices {
        #expect(sequence[index] != sequence[(index + 1) % sequence.count])
    }
}

@Test func crossPlaneBankPattern() {
    let spec = EngineLayout.v8Cross.spec
    #expect(spec.bankOf == [0, 1, 0, 1, 0, 1, 0, 1])
    // L,R,R,L,R,L,L,R
    #expect(banks(spec) == [0, 1, 1, 0, 1, 0, 0, 1])
}

@Test func knownOrders() {
    #expect(EngineLayout.i4.spec.firingOrder == [1, 3, 4, 2])
    #expect(EngineLayout.i6.spec.firingOrder == [1, 5, 3, 6, 2, 4])
    #expect(EngineLayout.v8Cross.spec.firingOrder == [1, 8, 4, 3, 6, 5, 7, 2])
    let flat = EngineLayout.v8Flat.spec
    #expect(flat.firingOrder == [1, 8, 2, 7, 4, 5, 3, 6])
    #expect(flat.bankOf == [0, 0, 0, 0, 1, 1, 1, 1])
    #expect(banks(flat) == [0, 1, 0, 1, 0, 1, 0, 1])
}

@Test func w16Generic() {
    let name = EngineLayout.w16.spec.name
    #expect(!name.isEmpty)
    for word in ["Bugatti", "VW", "Volkswagen"] {
        #expect(!name.localizedCaseInsensitiveContains(word))
    }
}

@Test func bankAngles() {
    #expect(EngineLayout.i4.spec.banks == 1)
    #expect(EngineLayout.v6_60.spec.bankAngle == 60)
    #expect(EngineLayout.v6_90.spec.bankAngle == 90)
    #expect(EngineLayout.v10.spec.bankAngle == 72)
    #expect(EngineLayout.v12.spec.bankAngle == 60)
    #expect(EngineLayout.w16.spec.banks == 4)
}
