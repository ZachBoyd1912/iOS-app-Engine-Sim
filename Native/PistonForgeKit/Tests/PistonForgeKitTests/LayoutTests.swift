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

@Test func allOrdersPinned() {
    #expect(EngineLayout.i3.spec.firingOrder == [1, 2, 3])
    #expect(EngineLayout.v6_60.spec.firingOrder == [1, 2, 3, 4, 5, 6])
    #expect(EngineLayout.v6_90.spec.firingOrder == [1, 6, 5, 4, 3, 2])
    #expect(EngineLayout.v10.spec.firingOrder == [1, 6, 5, 10, 2, 7, 3, 8, 4, 9])
    #expect(EngineLayout.v10.spec.bankOf == [0, 0, 0, 0, 0, 1, 1, 1, 1, 1])
    #expect(EngineLayout.v12.spec.firingOrder == [1, 7, 5, 11, 3, 9, 6, 12, 2, 8, 4, 10])
    #expect(EngineLayout.v12.spec.bankOf == [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1])
    #expect(EngineLayout.w16.spec.firingOrder == [1, 9, 5, 13, 3, 11, 7, 15, 4, 12, 8, 16, 2, 10, 6, 14])
    #expect(EngineLayout.w16.spec.bankOf == [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3])
}

@Test(arguments: EngineLayout.allCases)
func crankPhaseIsFiringAngleModulo360(layout: EngineLayout) {
    let spec = layout.spec
    for (index, cylinder) in spec.firingOrder.enumerated() {
        let expected = spec.firingAngles[index].truncatingRemainder(dividingBy: 360)
        #expect(abs(spec.crankPins[cylinder - 1] - expected) < 0.001, "\(layout) cylinder \(cylinder)")
    }
    // An I4's cylinders 1 and 4 share a crank phase, as do 2 and 3.
    if layout == .i4 {
        #expect(spec.crankPins[0] == spec.crankPins[3])
        #expect(spec.crankPins[1] == spec.crankPins[2])
        #expect(spec.crankPins[0] != spec.crankPins[1])
    }
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
