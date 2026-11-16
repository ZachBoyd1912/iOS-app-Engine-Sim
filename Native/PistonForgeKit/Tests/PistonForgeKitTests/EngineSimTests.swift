import Testing
@testable import PistonForgeKit

private let frame = 1.0 / 60

/// Revs freely to `rpm`, then holds it there by loading the crank with the engine's own torque.
/// Returns the last state; `each` sees every state on the way.
@discardableResult
private func hold(_ sim: EngineSim, rpm: Double, throttle: Double, seconds: Double, each: (EngineState) -> Void = { _ in }) -> EngineState {
    var state = sim.step(dt: frame, throttle: throttle, load: 0)
    var climbing = 0
    while state.rpm < rpm, climbing < 600, sim.isRunning {
        state = sim.step(dt: frame, throttle: throttle, load: 0)
        each(state)
        climbing += 1
    }
    for _ in 0..<Int(seconds / frame) {
        // Brake harder above the target, less below it.
        let load = max(0, state.torqueNm + (state.rpm - rpm) * 0.5)
        state = sim.step(dt: frame, throttle: throttle, load: load)
        each(state)
    }
    return state
}

@Test(arguments: [EngineLayout.i3, .i4, .v8Cross, .w16])
func idlesStable(layout: EngineLayout) {
    let sim = EngineSim(build: EngineBuild.starter(layout))
    sim.start()
    #expect(sim.isRunning)
    var state = sim.step(dt: frame, throttle: 0, load: 0)
    let firstAngle = state.crankAngle
    var moved = false
    for _ in 0..<Int(5 / frame) {
        state = sim.step(dt: frame, throttle: 0, load: 0)
        if state.crankAngle != firstAngle { moved = true }
    }
    #expect(abs(state.rpm - sim.idleTargetRpm) <= 80, "\(layout) idles at \(state.rpm)")
    #expect(moved)
    #expect(state.failure == nil)
}

@Test(arguments: [EngineLayout.i3, .v8Flat, .w16])
func limiterCaps(layout: EngineLayout) {
    let sim = EngineSim(build: EngineBuild.starter(layout))
    sim.start()
    var highest = 0.0
    for _ in 0..<Int(6 / frame) {
        highest = max(highest, sim.step(dt: frame, throttle: 1, load: 0).rpm)
    }
    #expect(highest > sim.build.ecu.revLimit - 200, "\(layout) reached \(highest)")
    #expect(highest <= sim.build.ecu.revLimit + 150, "\(layout) overshot to \(highest)")
}

@Test func leanRunCausesFailureWithCause() {
    var build = EngineBuild.starter(.i4)
    build.induction = .turbo(.medium)
    build = build.withFuelSystemSized()
    build.ecu = ECUMap.autoBase(for: build)
    build.ecu.afrTable = build.ecu.afrTable.map { $0.map { _ in 16 } }
    let sim = EngineSim(build: build)
    sim.start()
    var failure: Failure?
    hold(sim, rpm: 5000, throttle: 1, seconds: 3) { state in
        if failure == nil { failure = state.failure }
    }
    #expect(failure == .leanMelt)
    #expect(!(failure?.explanation ?? "").isEmpty)
    #expect(!sim.isRunning, "a failed engine stops")
    sim.start()
    #expect(!sim.isRunning, "and will not restart until repaired")
    sim.repair()
    #expect(sim.step(dt: frame, throttle: 0, load: 0).health == 1)
    sim.start()
    #expect(sim.isRunning)
}

@Test func hugeDtIsClamped() {
    let a = EngineSim(build: EngineBuild.starter(.v8Cross))
    let b = EngineSim(build: EngineBuild.starter(.v8Cross))
    a.start()
    b.start()
    let before = a.step(dt: frame, throttle: 0.5, load: 0).rpm
    _ = b.step(dt: frame, throttle: 0.5, load: 0)
    let huge = a.step(dt: 30, throttle: 1, load: 0).rpm
    let tenth = b.step(dt: 0.1, throttle: 1, load: 0).rpm
    #expect(abs((huge - before) - (tenth - before)) < 0.001, "30 s step moved \(huge - before), 0.1 s moved \(tenth - before)")
    for bad in [Double.nan, .infinity, -5] {
        let state = a.step(dt: bad, throttle: bad, load: bad)
        #expect(state.rpm.isFinite && state.torqueNm.isFinite && state.crankAngle.isFinite)
    }
}

@Test func partChangeNeverSilentlySeizes() {
    let starter = EngineBuild.starter(.i4)
    let sim = EngineSim(build: starter)
    var changed = starter
    changed.parts.cams += 2
    sim.setBuild(changed)
    let warned = sim.warnings.contains(.mapOutOfDate)
    let point = operatingPoint(sim.build, rpm: 6000, throttle: 1, boostPsi: 0, nitrousArmed: false, closedLoopTrim: 0)
    #expect(changed.fuel.spec.safeAfr.contains(point.combustion.afr) || warned)
    sim.start()
    var failure: Failure?
    hold(sim, rpm: 6000, throttle: 1, seconds: 2) { state in
        if failure == nil { failure = state.failure }
    }
    #expect(failure == nil || warned, "failed with \(String(describing: failure)) and no warning")
}

@Test func riskierPartsOnAnOldTuneWarn() {
    let starter = EngineBuild.starter(.i4)
    let sim = EngineSim(build: starter)
    var hotter = starter
    hotter.compression = 13
    sim.setBuild(hotter)
    #expect(sim.warnings.contains(.mapOutOfDate), "the old timing is too advanced for 13:1")
    var retuned = hotter
    retuned.ecu = ECUMap.autoBase(for: hotter)
    sim.setBuild(retuned)
    #expect(!sim.warnings.contains(.mapOutOfDate))
}

@Test func blowerOnStockFuelWarns() {
    var build = EngineBuild.starter(.i4)
    build.induction = .supercharger(.centrifugal, pulley: 1.3)
    build.fuel = .e85
    let sim = EngineSim(build: build)
    #expect(sim.warnings.contains(.fuelSystemTooSmall))
    sim.setBuild(build.withFuelSystemSized())
    #expect(!sim.warnings.contains(.fuelSystemTooSmall))
}

@Test func crankAngleMatchesRpm() {
    let sim = EngineSim(build: EngineBuild.starter(.i6))
    sim.start()
    hold(sim, rpm: 3000, throttle: 0.4, seconds: 1)
    var turned = 0.0
    var last = sim.step(dt: frame, throttle: 0.4, load: 0)
    var rpmSum = 0.0
    var samples = 0
    for _ in 0..<60 {
        let load = max(0, last.torqueNm + (last.rpm - 3000) * 0.5)
        let next = sim.step(dt: frame, throttle: 0.4, load: load)
        var delta = next.crankAngle - last.crankAngle
        if delta < 0 { delta += 720 }
        turned += delta
        rpmSum += next.rpm
        samples += 1
        last = next
    }
    let averageRpm = rpmSum / Double(samples)
    #expect(abs(averageRpm - 3000) < 150, "held at \(averageRpm)")
    #expect(abs(turned / 360 - averageRpm / 60) <= 2, "turned \(turned / 360) revs at \(averageRpm) rpm")
}

@Test func stoppedEngineSpinsDown() {
    let sim = EngineSim(build: EngineBuild.starter(.v12))
    sim.start()
    hold(sim, rpm: 4000, throttle: 0.5, seconds: 0.5)
    sim.stop()
    var state = sim.step(dt: frame, throttle: 1, load: 0)
    for _ in 0..<Int(4 / frame) { state = sim.step(dt: frame, throttle: 1, load: 0) }
    #expect(state.rpm < 50)
    #expect(state.torqueNm <= 0)
}

@Test func sensorsGateWarnings() {
    var build = EngineBuild.starter(.i4)
    build.ecu.ignitionTable = build.ecu.ignitionTable.map { $0.map { _ in 40 } }
    build.sensors.knock = false
    let blind = EngineSim(build: build)
    blind.start()
    let state = hold(blind, rpm: 4000, throttle: 1, seconds: 0.2)
    #expect(state.knockIndex >= 1)
    #expect(!state.warnings.contains(.knocking), "no knock sensor, no knock warning")
    build.sensors.knock = true
    let heard = EngineSim(build: build)
    heard.start()
    var warned = false
    hold(heard, rpm: 4000, throttle: 1, seconds: 0.2) { if $0.warnings.contains(.knocking) { warned = true } }
    #expect(warned)
}
