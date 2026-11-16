import Testing
@testable import PistonForgeKit

private func with(_ layout: EngineLayout, _ induction: Induction) -> EngineBuild {
    var build = EngineBuild.starter(layout)
    build.induction = induction
    return build
}

/// Runs the turbo at a fixed rpm and throttle for `seconds` and returns the final boost.
private func spool(_ build: EngineBuild, rpm: Double, seconds: Double, target: Double, turbo: inout TurboState) -> Double {
    var boost = 0.0
    let dt = 0.01
    for _ in 0..<Int((seconds / dt).rounded()) {
        boost = boostPsi(build, rpm: rpm, throttle: 1, turbo: &turbo, dt: dt, target: target)
    }
    return boost
}

@Test(arguments: EngineLayout.allCases)
func veIsBoundedAndPeaks(layout: EngineLayout) {
    for cams in 0...PartChoices.maxLevel {
        var build = EngineBuild.starter(layout)
        build.parts.cams = cams
        build.parts.head = cams
        let redline = build.mechanicalRedline
        var best = (rpm: 0.0, ve: 0.0)
        for rpm in stride(from: 1000.0, through: redline, by: 250) {
            let ve = volumetricEfficiency(build, rpm: rpm)
            #expect(ve >= 0.35 && ve <= 1.15, "\(layout) cams \(cams) at \(rpm): \(ve)")
            if ve > best.ve { best = (rpm, ve) }
        }
        #expect(best.rpm > 1000 && best.rpm < redline, "\(layout) cams \(cams): peak at \(best.rpm), redline \(redline)")
    }
}

@Test func biggerCamsMovePeakUp() {
    var mild = EngineBuild.starter(.i4)
    var wild = mild
    mild.parts.cams = 0
    wild.parts.cams = 3
    let peak = { (build: EngineBuild) in
        stride(from: 1000.0, through: build.mechanicalRedline, by: 50).max { volumetricEfficiency(build, rpm: $0) < volumetricEfficiency(build, rpm: $1) } ?? 0
    }
    #expect(peak(wild) > peak(mild))
    #expect(volumetricEfficiency(wild, rpm: 2000) < volumetricEfficiency(mild, rpm: 2000))
}

@Test func turboLags() {
    let build = with(.i4, .turbo(.medium))
    var turbo = TurboState()
    let early = spool(build, rpm: 2500, seconds: 0.1, target: 15, turbo: &turbo)
    var fresh = TurboState()
    let late = spool(build, rpm: 2500, seconds: 3, target: 15, turbo: &fresh)
    #expect(late > 0)
    #expect(early < 0.5 * late, "after 0.1 s \(early) psi, after 3 s \(late) psi")
}

@Test func largeTurboSpoolsLater() {
    var small = TurboState()
    var large = TurboState()
    let smallBoost = spool(with(.i4, .turbo(.small)), rpm: 3000, seconds: 10, target: 30, turbo: &small)
    let largeBoost = spool(with(.i4, .turbo(.large)), rpm: 3000, seconds: 10, target: 30, turbo: &large)
    #expect(smallBoost > largeBoost, "small \(smallBoost) psi, large \(largeBoost) psi")
}

@Test func rootsIsFlat() {
    let build = with(.v8Cross, .supercharger(.roots, pulley: 1))
    var turbo = TurboState()
    let low = boostPsi(build, rpm: 2500, throttle: 1, turbo: &turbo, dt: 0.01, target: 0)
    let high = boostPsi(build, rpm: 6000, throttle: 1, turbo: &turbo, dt: 0.01, target: 0)
    #expect(high > 0)
    #expect(low >= 0.7 * high, "2500: \(low), 6000: \(high)")
}

@Test func centrifugalRisesWithRpm() {
    let build = with(.v8Cross, .supercharger(.centrifugal, pulley: 1))
    var turbo = TurboState()
    let low = boostPsi(build, rpm: 2500, throttle: 1, turbo: &turbo, dt: 0.01, target: 0)
    let high = boostPsi(build, rpm: 6500, throttle: 1, turbo: &turbo, dt: 0.01, target: 0)
    #expect(high > 0)
    #expect(low < 0.35 * high, "2500: \(low), 6500: \(high)")
}

@Test func smallerPulleyMakesMoreBoost() {
    var turbo = TurboState()
    let stock = boostPsi(with(.v8Cross, .supercharger(.twinScrew, pulley: 1)), rpm: 5000, throttle: 1, turbo: &turbo, dt: 0.01, target: 0)
    let fast = boostPsi(with(.v8Cross, .supercharger(.twinScrew, pulley: 1.3)), rpm: 5000, throttle: 1, turbo: &turbo, dt: 0.01, target: 0)
    #expect(fast > stock)
}

@Test func superchargerCostsPower() {
    for kind in SuperchargerKind.allCases {
        let build = with(.v8Cross, .supercharger(kind, pulley: 1))
        var turbo = TurboState()
        let boost = boostPsi(build, rpm: 5000, throttle: 1, turbo: &turbo, dt: 0.01, target: 0)
        #expect(parasiticLossHp(build, rpm: 5000, boost: boost) > 0, "\(kind)")
    }
    #expect(parasiticLossHp(EngineBuild.starter(.v8Cross), rpm: 5000, boost: 0) == 0)
}

@Test func wastegateHoldsTarget() {
    var turbo = TurboState()
    let boost = spool(with(.i4, .turbo(.small)), rpm: 6000, seconds: 5, target: 12, turbo: &turbo)
    #expect(abs(boost - 12) <= 1, "boost \(boost) psi, target 12")
}

@Test func naturalMakesNoBoost() {
    var turbo = TurboState()
    #expect(boostPsi(EngineBuild.starter(.i6), rpm: 6000, throttle: 1, turbo: &turbo, dt: 0.01, target: 20) == 0)
}

@Test func nonFiniteInputsStayFinite() {
    let build = with(.w16, .turbo(.twin))
    var turbo = TurboState()
    for value in [Double.nan, .infinity, -.infinity] {
        let boost = boostPsi(build, rpm: value, throttle: value, turbo: &turbo, dt: value, target: value)
        #expect(boost.isFinite)
        #expect(turbo.shaftSpeed.isFinite)
        #expect(volumetricEfficiency(build, rpm: value).isFinite)
        #expect(parasiticLossHp(build, rpm: value, boost: value).isFinite)
    }
}
