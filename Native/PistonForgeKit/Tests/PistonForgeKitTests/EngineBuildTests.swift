import Foundation
import Testing
@testable import PistonForgeKit

@Test(arguments: EngineLayout.allCases)
func starterForEveryLayoutIsSane(layout: EngineLayout) {
    let build = EngineBuild.starter(layout)
    #expect(build.layout == layout)
    #expect(build.displacementCc >= 600 && build.displacementCc <= 9000, "\(layout): \(build.displacementCc) cc")
    #expect(build.mechanicalRedline >= 5000 && build.mechanicalRedline <= 10000, "\(layout): \(build.mechanicalRedline) rpm")
    #expect(build.sanitized() == build, "\(layout): starter is already inside the safe ranges")
    #expect(!build.name.isEmpty)
}

@Test func sanitizeClamps() {
    var build = EngineBuild.starter(.i4)
    build.bore = 10
    build.stroke = 500
    build.compression = 30
    build.rodRatio = 5
    build.parts.injectorCcMin = 10
    build.parts.pumpLph = 5000
    build.parts.cams = 99
    build.parts.intercooler = -4
    let clean = build.sanitized()
    #expect(clean.bore == 60)
    #expect(clean.stroke == 110)
    #expect(clean.compression == 14)
    #expect(clean.rodRatio == 2.1)
    #expect(clean.parts.injectorCcMin == 150)
    #expect(clean.parts.pumpLph == 1000)
    #expect(clean.parts.cams == PartChoices.maxLevel)
    #expect(clean.parts.intercooler == 0)
}

@Test func sanitizeReplacesNonFinite() {
    var build = EngineBuild.starter(.v8Cross)
    build.bore = .nan
    build.stroke = .infinity
    build.compression = -.infinity
    build.nitrous = NitrousKit(kind: .dry, shotHp: .nan, armRpm: .nan, enabled: true)
    let clean = build.sanitized()
    for value in [clean.bore, clean.stroke, clean.compression, clean.nitrous?.shotHp ?? .nan, clean.nitrous?.armRpm ?? .nan] {
        #expect(value.isFinite)
    }
    #expect(clean.displacementCc.isFinite && clean.displacementCc > 0)
    let stock = EngineBuild.starter(.v8Cross)
    #expect(clean.bore == stock.bore)
    #expect(clean.stroke == stock.stroke)
    #expect(clean.compression == stock.compression)
    #expect(clean.nitrous?.shotHp == 100)
    #expect(clean.nitrous?.armRpm == 3000)
}

@Test func sanitizeClampsNitrousAndPulley() {
    var build = EngineBuild.starter(.i4)
    build.nitrous = NitrousKit(kind: .wet, shotHp: 900, armRpm: 100, enabled: true)
    build.induction = .supercharger(.roots, pulley: 9)
    let clean = build.sanitized()
    #expect(clean.nitrous?.shotHp == 300)
    #expect(clean.nitrous?.armRpm == 1500)
    #expect(clean.induction == .supercharger(.roots, pulley: SuperchargerKind.pulleyRange.upperBound))
}

@Test func codableRoundTrip() throws {
    var build = EngineBuild.starter(.v6_90)
    build.induction = .turbo(.twin)
    build.fuel = .e85
    build.nitrous = NitrousKit(kind: .wet, shotHp: 150, armRpm: 3500, enabled: true)
    build.sensors = SensorSet(maf: .large, map: true, iat: true, wideband: true, knock: true, egt: true, oil: true)
    let data = try JSONEncoder().encode(build)
    let back = try JSONDecoder().decode(EngineBuild.self, from: data)
    #expect(back == build)
    build.induction = .supercharger(.centrifugal, pulley: 1.2)
    let blown = try JSONDecoder().decode(EngineBuild.self, from: JSONEncoder().encode(build))
    #expect(blown == build)
}

@Test func displacementMatchesFormula() {
    var build = EngineBuild.starter(.v10)
    build.bore = 92
    build.stroke = 75
    let expected = Double.pi / 4 * 92 * 92 * 75 * 10 / 1000
    #expect(abs(build.displacementCc - expected) < 0.001)
}

@Test func envelopeGrowsWithCylinders() {
    var i4 = EngineBuild.starter(.i4)
    var v12 = EngineBuild.starter(.v12)
    i4.bore = 86
    i4.stroke = 86
    v12.bore = 86
    v12.stroke = 86
    #expect(v12.envelopeMm.length > i4.envelopeMm.length)
    #expect(v12.envelopeMm.width > i4.envelopeMm.width)
    let w16 = EngineBuild.starter(.w16)
    #expect(w16.envelopeMm.width > v12.envelopeMm.width)
}

@Test func pistonSpeedFollowsStroke() {
    let build = EngineBuild.starter(.i4)
    // 86 mm stroke on stock internals: 20 m/s allows 6976 rpm, rounded down to 6950.
    #expect(build.mechanicalRedline == 6950)
    #expect(abs(build.meanPistonSpeedAtRedline - 2 * 0.086 * 6950 / 60) < 0.001)
    var longer = build
    longer.stroke = build.stroke + 10
    #expect(longer.mechanicalRedline < build.mechanicalRedline)
}
