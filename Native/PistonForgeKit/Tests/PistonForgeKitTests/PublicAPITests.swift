import PistonForgeKit
import Testing

/// Uses only the public interface, as the app does. A missing `public` passes the other
/// (`@testable`) tests on Linux but breaks the app build on the Mac; this file catches it here.
@Test func appFacingAPIIsPublic() {
    for layout in EngineLayout.allCases {
        let spec: LayoutSpec = layout.spec
        var build = EngineBuild.starter(layout)
        build.induction = .turbo(.medium)
        build.nitrous = NitrousKit(kind: .wet, shotHp: 100, armRpm: 3000, enabled: true)
        build.sensors = SensorSet(maf: .large, map: true, iat: true, wideband: true, knock: true, egt: true, oil: true)
        build.parts = PartChoices(head: 1, cams: 1, injectorCcMin: 600, pumpLph: 400)
        build = build.withFuelSystemSized().sanitized()
        build.ecu = ECUMap.autoBase(for: build)
        var turbo = TurboState()
        let boost = boostPsi(build, rpm: 5000, throttle: 1, turbo: &turbo, dt: 0.01, target: build.ecu.boostTargetPsi)
        let point: OperatingPoint = operatingPoint(build, rpm: 5000, throttle: 1, boostPsi: boost, nitrousArmed: false, closedLoopTrim: 0)
        let fuel: FuelResult = point.fuel
        let burn: CombustionResult = point.combustion
        #expect(spec.cylinders > 0)
        #expect(fuel.injectorDuty.isFinite && burn.torqueNm.isFinite && point.brakeHp.isFinite)
        #expect(build.ecu.value(\.ignitionTable, rpm: 5000, loadKpa: point.loadKpa).isFinite)
        #expect(chargeTempC(build, boostPsi: 10) > 25)
        _ = fuelSystemNeeds(build, boostPsi: 10)
        _ = (build.displacementCc, build.envelopeMm, build.mechanicalRedline, build.meanPistonSpeedAtRedline)
        _ = (MafSize.xl.maxGps, Fuel.e85.spec.safeAfr, PartChoices.levelNames, SuperchargerKind.pulleyRange)
    }
}
