# Piston Forge Stage 1 (Engine, Dyno, Sound) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship stage 1 of the native game as an installable `.ipa`. The app opens on an assembled 3D engine with every layout and part. It has a full tune screen, a live dyno, generated engine sound and a car screen with fitment.

**Architecture:**
- **`Native/PistonForgeKit`** is a pure-Swift package with no UIKit, SwiftUI, RealityKit or AVFoundation. It holds the engine model, the dyno, sound synthesis, cars and saving, and is tested with `swift test` on Linux.
- **`Native/App`** is SwiftUI plus RealityKit. It reads the package's state, draws it, plays the synthesised samples through `AVAudioSourceNode`, and drives haptics.
- **No Mac.** Every compile and test runs on GitHub Actions. Package tests run on Linux on every push to the work branch; the macOS app job runs on demand and on `main`.

**Tech Stack:** Swift 6 (language mode 6), Swift Testing, SwiftUI, RealityKit (non-AR `RealityView`), Swift Charts, AVFoundation (`AVAudioEngine`, `AVAudioSourceNode`), Core Haptics, XCUITest, XcodeGen 2.46, Xcode 26 on `macos-26`, `swift:6.1` container on Linux.

**Spec:** `docs/superpowers/specs/2026-11-16-piston-forge-native-design.md` (approved 16/11/2026). Research: `docs/research/2026-11-16-*.md`.

## Global Constraints

- iOS 18.0 minimum; iPhone and iPad (`TARGETED_DEVICE_FAMILY "1,2"`); bundle ID `ie.zbautomations.pistonforge`.
- PistonForgeKit imports Foundation only. It must build and pass on Linux (`swift:6.1`).
- No Mac locally and no Swift toolchain on the PC. The only proof of a compile is a green CI run; never claim a task done without one.
- Theme: dark only, dark grey, never black (`#202326`-ish base). Hues are low-opacity warm orange and cool blue in the background. One accent (orange). Tokens live in `Theme.swift`; there are no other hard-coded colours.
- ZB UX standard, iOS-adapted:
  - Hit areas ≥ 44 pt; status always uses an icon and a word, never colour alone.
  - Dynamic Type works; Reduce Motion is respected.
  - Previews are Simulator screenshots at iPhone 6.3", iPad 13" and landscape phone.
  - `performAccessibilityAudit` passes on every screen.
- Stage 1 has every layout at once:
  - I3, I4, I6 (added by Zach 16/11/2026), V6 60° (even fire), V6 90° (odd fire, 90/150), V8 cross-plane, V8 flat-plane, V10 72°, V12 60°, W16 (generic, even 45°, our own firing order, no manufacturer claim).
  - Induction: NA, turbo, and Roots, twin-screw and centrifugal superchargers.
  - Nitrous: dry and wet kits, 50–300 hp shots.
  - Sensors: MAF, MAP, IAT, wideband O2, knock, EGT, oil pressure and temperature.
- No career, money or unlocks. Repairs are free.
- Audio session `.playback`: sound plays with the ringer switch on silent, with no background audio. Sound stops when the app leaves the foreground.
- 60 fps target on iPhone 13. Physics runs at a fixed rate separate from rendering. Moving 3D parts are updated by one RealityKit `System`; static parts are merged into few meshes.
- 3D models are built in code only. No downloaded, bought or AI-generated assets; no real brands or car designs.
- No tracking and no data collected. `PrivacyInfo.xcprivacy` declares only UserDefaults (`CA92.1`), and only if UserDefaults is used.
- Never run `pnpm build` on the PC. The web game in `PistonForge/` is deleted in Task 14, not before.
- Every commit adds a `CHANGELOG.md` entry at line 2:
  - Fresh `TZ=Europe/Dublin date` timestamp; model `claude-opus-5-5` (confirmed).
  - Completion figure from `docs/roadmap.md`.
  - Commit trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Work branch `native-stage-1`; merged to `main` in Task 14.
- **Task loop (no local compiler):** write the tests and the code for a task together, then make
  one commit + push per task and read the CI result. Compile-fix follow-up commits on the same
  task are expected; they share that task's changelog entry (amend the entry, not a new one),
  approved by Zach 16/11/2026. A task is done only when its CI run is green.

## Review Focus

1. **Extreme combinations** (W16, maximum boost, smallest injectors, nitrous 300 at low rpm, smallest bore with longest stroke) must never produce NaN or infinity anywhere: dyno, sound or UI. They lean out, knock and break, with a stated cause. Pinned by Task 7's `everyCombinationStaysFinite`.
2. **A corrupt, empty or newer-version save file** must not crash or wipe data. The app falls back to the backup, then to defaults, and keeps a newer file untouched. Pinned in Task 9.
3. **The app leaving the foreground while the engine runs or a dyno pull is in progress:**
   - Audio stops and the simulation pauses.
   - On return, nothing has jumped: no huge `dt` step.
   - Pinned in Task 8 (`hugeDtIsClamped`) and in Task 13's UI test.
4. **Installing an engine that does not fit the chosen car** is refused with the blocking dimension and the millimetres over. Switching to a car the current engine does not fit is allowed only with that warning. Pinned in Task 9.
5. **Changing a part on a tuned engine:**
   - The map must not silently seize the engine. A part change that moves airflow by more than 5% re-bases the fuel table, or shows a "map out of date" warning before the next pull.
   - The old game's bug (`stale-map-cams-2` and `-3` fixtures) must not come back.
   - Pinned in Task 6 (`partChangeNeverSilentlySeizes`).

---

### Task 0: Work branch and split CI

**Files:**
- Modify: `.github/workflows/native.yml`
- Modify: `Native/project.yml` (add the UI test target `PistonForgeUITests`, sources `UITests/`, with a scheme that tests it)
- Create: `Native/UITests/SmokeUITests.swift`

**Interfaces:**
- Produces:
  - A `sim-tests` job that runs on every push to any branch touching `Native/PistonForgeKit/**` or the workflow.
  - An `app` job that runs on `workflow_dispatch` and on pushes to `main` touching `Native/**`. It builds, runs the UI tests on an iPhone and an iPad simulator, exports screenshots from the `.xcresult` with `xcrun xcresulttool export attachments`, and builds the unsigned `.ipa`.

- [ ] **Step 1:** `git switch -c native-stage-1`.
- [ ] **Step 2: Write `SmokeUITests.testLaunches`.** It launches the app, asserts that a static text containing "Piston Forge" exists within 20 s, and attaches a screenshot named `smoke-<device>` with `.keepAlways`.
- [ ] **Step 3: Edit the workflow as above.** The app job picks the newest available iPhone 17-class and iPad Pro 13-inch simulators by name from `xcrun simctl list -j`. It compiles first (`xcodebuild build-for-testing` once, so a compile error fails in minutes), then runs `xcodebuild test-without-building -destination id=<udid> -resultBundlePath build/<device>.xcresult` on each simulator from that one build, exports attachments to `shots/<device>/`, and uploads `shots/` and the `.ipa` as artifacts. One macOS job per run (minutes are rounded up per job).
- [ ] **Step 4:** Push, then run `gh workflow run native.yml --ref native-stage-1`.
  - Expected: `sim-tests: success`, `app: success`.
  - The artifact contains `smoke-iphone*.png` and `smoke-ipad*.png`. Open both and look at them.
- [ ] **Step 5:** Commit with a changelog entry.

### Task 1: Engine layouts with firing data

**Files:**
- Create: `Native/PistonForgeKit/Sources/PistonForgeKit/Catalog/Layouts.swift`
- Replace: `Native/PistonForgeKit/Sources/PistonForgeKit/Engine.swift` (its `EngineLayout` moves here). The fixture test stops decoding `EngineConfig`; it decodes `layout` as a `String` and maps old ids in the test file (`i3→.i3, i4→.i4, i6→.i6, v6→.v6_60, v8→.v8Cross, v12→.v12`), skipping cases with no match (`v10` old geometry, `flat4`, rotaries)
- Test: `Native/PistonForgeKit/Tests/PistonForgeKitTests/LayoutTests.swift`

**Interfaces:**
- Produces:
  - `enum EngineLayout: String, Codable, CaseIterable, Sendable { case i3, i4, i6, v6_60, v6_90, v8Cross, v8Flat, v10, v12, w16 }`
  - `struct LayoutSpec: Sendable { let name: String; let cylinders: Int; let banks: Int; let bankAngle: Double; let firingOrder: [Int]; let firingAngles: [Double]; let bankOf: [Int]; let crankPins: [Double] }`
    - `firingAngles` are crank degrees in 0..<720, one per firing event in order.
    - `bankOf[cyl-1]` is 0-based.
  - `extension EngineLayout { var spec: LayoutSpec }`

- [ ] **Step 1: Write the tests** (one `@Test` each):
  - `allLayoutsFireEveryCylinderOnce`: for every layout, `Set(firingOrder) == Set(1...cylinders)` and `firingAngles.count == cylinders`.
  - `evenFireIntervals`: for i3, i4, i6, v6_60, v8Cross, v8Flat, v10, v12 and w16, consecutive gaps (wrapping at 720) all equal `720 / cylinders` within 0.001.
  - `v6_90IsOddFire`: the gaps alternate 90 and 150.
  - `flatPlaneAlternatesBanks`: for v8Flat, the `bankOf` of consecutive firings always differs.
  - `crossPlaneBankPattern`: v8Cross uses odd cylinders left (bank 0) and even right (bank 1); the bank sequence of `[1,8,4,3,6,5,7,2]` is exactly L,R,R,L,R,L,L,R.
  - `knownOrders`: i4 `[1,3,4,2]`; i6 `[1,5,3,6,2,4]`; v8Cross `[1,8,4,3,6,5,7,2]`; v8Flat `[1,8,2,7,4,5,3,6]` (with banks 1-4 left and 5-8 right, so it alternates L,R,L,R...).
  - `w16Generic`: `name` contains no manufacturer word ("Bugatti", "VW", "Volkswagen").
- [ ] **Step 2: Implement `Layouts.swift`.** Use the orders from the test, and from `docs/research/2026-11-16-engines.md` for the rest:
  - V10: R1-L5-R5-L2-R2-L3-R3-L4-R4-L1, 72° intervals.
  - V12: 1-7-5-11-3-9-6-12-2-8-4-10 at 60°.
  - W16: your own even 45° order alternating the four banks.
- [ ] **Step 3:** Commit with the changelog entry, push. Expected: `sim-tests: success`.

### Task 2: Parts catalogue and the engine build

**Files:**
- Create: `Sources/PistonForgeKit/Catalog/Parts.swift`, `Sources/PistonForgeKit/Model/EngineBuild.swift`
- Test: `Tests/PistonForgeKitTests/EngineBuildTests.swift`

**Interfaces:**
- Consumes: `EngineLayout`, `LayoutSpec` (Task 1).
- Produces:
  - `enum Induction: Codable, Equatable, Sendable { case natural; case turbo(TurboSize); case supercharger(SuperchargerKind, pulley: Double) }`
    - `TurboSize: small, medium, large, twin`.
    - `SuperchargerKind: roots, twinScrew, centrifugal`.
  - `enum Fuel: String, Codable { case pump95, pump98, e85, race }`
  - `struct NitrousKit: Codable, Equatable { var kind: Kind /* dry, wet */; var shotHp: Double /* 50...300 */; var armRpm: Double; var enabled: Bool }`
  - `struct SensorSet: Codable, Equatable { var maf: MafSize? /* nil = speed-density only */; var map: Bool; var iat: Bool; var wideband: Bool; var knock: Bool; var egt: Bool; var oil: Bool }`
  - `struct PartChoices: Codable, Equatable { head, cams, intake, exhaust, internals, valves, gasket, intercooler: Int; injectorCcMin: Double; pumpLph: Double }`
  - `struct EngineBuild: Codable, Equatable, Identifiable { id: UUID; name: String; layout: EngineLayout; bore: Double; stroke: Double; compression: Double; rodRatio: Double; induction: Induction; fuel: Fuel; parts: PartChoices; sensors: SensorSet; nitrous: NitrousKit?; ecu: ECUMap }`
    - `ECUMap` is defined in Task 5. Until then, use a placeholder `struct ECUMap: Codable, Equatable {}` in its final file `Model/ECUMap.swift`.
  - `EngineBuild.starter(_ layout: EngineLayout) -> EngineBuild`: a sensible stock build per layout.
  - `func sanitized() -> EngineBuild` clamps bore 60–110 mm, stroke 50–110 mm, compression 7.5–14, rodRatio 1.4–2.1, injector 150–2400 cc/min and pump 150–1000 L/h.
  - `var displacementCc: Double`, `var meanPistonSpeedAtRedline: Double`, `var mechanicalRedline: Double`, `var envelopeMm: (length: Double, width: Double, height: Double)`.
- [ ] **Step 1: Write the tests:**
  - `starterForEveryLayoutIsSane`: displacement 600–9000 cc; redline 5000–10000.
  - `sanitizeClamps`.
  - `codableRoundTrip` for a build with a turbo, nitrous and every sensor.
  - `displacementMatchesFormula`: π/4·b²·s·n/1000.
  - `envelopeGrowsWithCylinders`: the V12 is longer than the I4 at the same bore and stroke.
- [ ] **Step 2:** Implement, commit with the changelog entry, push. Expected: `sim-tests: success` (fix-up commits until green).

### Task 3: Breathing and induction

**Files:**
- Create: `Sources/PistonForgeKit/Physics/Breathing.swift`, `Physics/Induction.swift`
- Test: `Tests/PistonForgeKitTests/InductionTests.swift`

**Interfaces:**
- Consumes: `EngineBuild`.
- Produces:
  - `func volumetricEfficiency(_ b: EngineBuild, rpm: Double) -> Double`
  - `struct TurboState: Sendable { var shaftSpeed: Double /* 0...1 */ }`
  - `func boostPsi(_ b: EngineBuild, rpm: Double, throttle: Double, turbo: inout TurboState, dt: Double, target: Double) -> Double`
  - `func parasiticLossHp(_ b: EngineBuild, rpm: Double, boost: Double) -> Double`
- [ ] **Step 1: Write the tests:**
  - `veIsBoundedAndPeaks`: for every starter at 1000…redline in 250 rpm steps, VE is in 0.35–1.15, with one peak below redline.
  - `turboLags`: from 0 at 2500 rpm full throttle, boost after 0.1 s is < 50% of its value after 3 s.
  - `largeTurboSpoolsLater`: at 3000 rpm steady state, small boost > large boost.
  - `rootsIsFlat`: Roots boost at 2500 is ≥ 70% of boost at 6000.
  - `centrifugalRisesWithRpm`: centrifugal boost at 2500 is < 35% of boost at 6500.
  - `superchargerCostsPower`: `parasiticLossHp > 0` for a supercharger; it is 0 for NA.
  - `wastegateHoldsTarget`: steady turbo boost is within 1 psi of the target.
- [ ] **Step 2:** Implement, commit with the changelog entry, push. Expected: `sim-tests: success` (fix-up commits until green).

### Task 4: Fuel delivery and sensors

**Files:**
- Create: `Sources/PistonForgeKit/Physics/Fuel.swift`, `Physics/Sensors.swift`
- Test: `Tests/PistonForgeKitTests/FuelSensorTests.swift`

**Interfaces:**
- Consumes: `EngineBuild`; airflow in g/s from Task 3.
- Produces:
  - `struct FuelResult { let commandedAfr: Double; let actualAfr: Double; let injectorDuty: Double; let pumpLimited: Bool; let mafClipped: Bool }`
  - `enum FuelStrategy: String, Codable, Sendable { case maf, speedDensity }` (lives in `Fuel.swift`; `ECUMap.strategy` in Task 5 uses it)
  - `func deliverFuel(_ b: EngineBuild, strategy: FuelStrategy, airflowGps: Double, rpm: Double, targetAfr: Double, closedLoopTrim: Double) -> FuelResult`
  - `func mafReading(_ b: EngineBuild, airflowGps: Double) -> (gps: Double, clipped: Bool)`
- [ ] **Step 1: Write the tests:**
  - `smallInjectorsLeanOutAtTop`: a 300 cc/min I4 turbo at 25 psi and 7000 rpm has duty > 0.85 and an actual AFR more than 1.0 leaner than commanded.
  - `mafClipsAndLeans`: when airflow exceeds the MAF maximum, `clipped` is true. With strategy MAF, the actual AFR is leaner than the target. With `.speedDensity` it is not.
  - `widebandCorrects`: with the wideband present, a closed-loop trim of +5% moves the AFR toward the target. Without it, the trim is ignored.
  - `pumpLimits`: a pump at 150 L/h on a 900 hp demand sets `pumpLimited`.
  - `e85NeedsMoreFuel`: for the same air, E85 needs about 1.35–1.5× the fuel mass of pump98.
- [ ] **Step 2:** Implement, commit with the changelog entry, push. Expected: `sim-tests: success` (fix-up commits until green).

### Task 5: ECU map, combustion, knock and nitrous

**Files:**
- Create: `Sources/PistonForgeKit/Model/ECUMap.swift` (replaces the placeholder), `Physics/Combustion.swift`, `Physics/Nitrous.swift`
- Test: `Tests/PistonForgeKitTests/CombustionTests.swift`

**Interfaces:**
- Consumes: Tasks 2–4.
- Produces:
  - `struct ECUMap: Codable, Equatable`:
    - Fields: `rpmAxis: [Double]` (16 values), `loadAxis: [Double]` (12 kPa values, 20–300); `afrTable: [[Double]]` and `ignitionTable: [[Double]]` (12×16 each); `boostTargetPsi`, `revLimit`, `launchRpm`; `strategy: FuelStrategy`; `nitrousWindow: ClosedRange<Double>`.
    - `static func autoBase(for: EngineBuild) -> ECUMap`
    - `func value(_ table: KeyPath<ECUMap, [[Double]]>, rpm: Double, loadKpa: Double) -> Double` (bilinear, clamped at the edges).
  - `struct CombustionResult { torqueNm, knockIndex /* 0...2, ≥1 = detonation */, egtC, timingDeg, mbtDeg: Double }`
  - `func combust(_ b: EngineBuild, rpm: Double, airflowGps: Double, fuel: FuelResult, boostPsi: Double, iatC: Double, nitrousActive: Bool) -> CombustionResult`
  - `func nitrousExtra(_ b: EngineBuild, rpm: Double, throttle: Double) -> (oxygenGps: Double, addedFuelGps: Double)`
- [ ] **Step 1: Write the tests:**
  - `autoBaseIsSafeForEveryCombination`: for every layout × {NA, each turbo, each supercharger} × every fuel, a sweep from 1500 to the rev limit at full load on the auto-base map has knockIndex < 1, AFR within the fuel's safe range, and EGT < 950 °C.
  - `timingPastMbtLosesTorque`.
  - `knockSensorPullsTiming`: with the knock sensor, the effective timing falls once the knock index rises toward 1; without it, it does not.
  - `nitrousAddsRoughlyTheShot`: a 100 hp wet shot on an auto-based V8 adds 80–120 hp at 5000 rpm.
  - `dryShotWithoutFuelDetonates`: a dry 200 shot with the stock injectors and the map unchanged gives knockIndex ≥ 1 or AFR leaner than 13.5.
  - `nitrousBelowArmRpmDoesNothing`.
  - `bilinearMatchesCorners`.
- [ ] **Step 2:** Implement, commit with the changelog entry, push. Expected: `sim-tests: success` (fix-up commits until green).

### Task 6: Engine simulation and damage

**Files:**
- Create: `Sources/PistonForgeKit/Physics/EngineSim.swift`, `Physics/Damage.swift`
- Test: `Tests/PistonForgeKitTests/EngineSimTests.swift`

**Interfaces:**
- Consumes: Tasks 2–5.
- Produces:
  - `struct EngineState: Sendable { rpm, crankAngle /* 0..<720 */, torqueNm, powerHp, boostPsi, afr, knockIndex, egtC, injectorDuty, oilPressureBar, health /* 0...1 */: Double; failure: Failure?; warnings: [Warning] }`
  - `enum Failure: String, Codable { case leanMelt, detonation, overBoost, overRev, oilStarvation }`, each with `var explanation: String` (plain words).
  - `final class EngineSim { init(build: EngineBuild); var build: EngineBuild { get }; func setBuild(_: EngineBuild) /* rebases or flags map, see test */; func step(dt: Double, throttle: Double, load: Double) -> EngineState; func start(); func stop(); var isRunning: Bool }`
    - `load` is the external load torque in Nm. The dyno and car pass theirs; free revving passes 0.
    - The fixed internal step is 1/480 s; `dt` is clamped to 0.1 s.
  - `func repair()` restores health 1.0 and clears the failure (free).
- [ ] **Step 1: Write the tests:**
  - `idlesStable`: started with throttle 0 for 5 s, rpm is within ±80 of the idle target and the crank angle advances.
  - `limiterCaps`: at full throttle with no load, rpm never exceeds revLimit + 150.
  - `leanRunCausesFailureWithCause`: forcing an AFR of 16 at full boost for 3 s gives failure `.leanMelt` with a non-empty explanation.
  - `hugeDtIsClamped`: `step(dt: 30)` changes rpm by no more than a 0.1 s step would.
  - `partChangeNeverSilentlySeizes`: on the starter I4, `setBuild` with cams raised two steps. Then either the AFR at 6000 full load stays within the fuel's safe range, or `warnings` contains `.mapOutOfDate` before any step. Pull at full load for 2 s: there is no failure unless that warning was present.
  - `crankAngleMatchesRpm`: over 1 s at 3000 rpm the crank turns 50 revolutions ± 2.
- [ ] **Step 2:** Implement, commit with the changelog entry, push. Expected: `sim-tests: success` (fix-up commits until green).

### Task 7: Dyno

**Files:**
- Create: `Sources/PistonForgeKit/Dyno/Dyno.swift`
- Test: `Tests/PistonForgeKitTests/DynoTests.swift`, which also replaces `GoldenFixtureTests.swift`

**Interfaces:**
- Consumes: `EngineSim`.
- Produces:
  - `struct DynoSample: Codable { rpm, torqueNm, powerHp, wheelHp, afr, boostPsi, knockIndex, egtC: Double }`
  - `struct DynoResult: Codable { samples: [DynoSample]; peakHp, peakHpRpm, peakTorqueNm, peakTorqueRpm: Double; failure: Failure? }`
  - `final class DynoRun { init(sim: EngineSim, fromRpm: Double = 2000, drivetrainLoss: Double = 0.15); func step(dt: Double) -> DynoSample?; var isFinished: Bool; var result: DynoResult? }` (a live inertia sweep at about 400 rpm/s)
  - `func runDynoToEnd(_ build: EngineBuild) -> DynoResult`
- [ ] **Step 1: Write the tests:**
  - `everyCombinationStaysFinite`: every layout × every induction × {no nitrous, 300 dry} × {smallest injectors, largest}. `runDynoToEnd` returns only finite numbers and either completes or reports a failure.
  - `plausibleAgainstOldGame`: decode `Fixtures/sim-golden.json`. For `preset-street`, `preset-turbo` and `preset-bigblock`, build the nearest layout and induction from the input. Peak hp is within ±45% of the fixture: a plausibility check, not exact.
  - `wheelHpBelowCrank`.
  - `samplesAscendInRpm`.
  - `liveRunMatchesBatch`: stepping `DynoRun` at 1/60 s gives the same peak hp as `runDynoToEnd` within 2%.
- [ ] **Step 2:** Implement, commit with the changelog entry, push. Expected: `sim-tests: success` (fix-up commits until green).

### Task 8: Engine sound synthesis

**Files:**
- Create: `Sources/PistonForgeKit/Sound/EngineVoice.swift`
- Test: `Tests/PistonForgeKitTests/EngineVoiceTests.swift`

**Interfaces:**
- Consumes: `LayoutSpec` and `EngineState`.
- Produces:
  - `struct VoiceParams: Sendable { rpm, load, boostPsi, throttle: Double; nitrous: Bool; induction: Induction; layout: EngineLayout; exhaustLevel: Int }`
  - `final class EngineVoice { init(sampleRate: Double); func render(_ params: VoiceParams, frames: Int, into buffer: UnsafeMutablePointer<Float>) }`
    - No allocation, locks or Foundation calls inside `render` (real-time safe).
    - Smooth parameter changes over 20 ms.
- [ ] **Step 1: Write the tests** (render into an `[Float]` with `withUnsafeMutableBufferPointer`):
  - `outputBoundedAndFinite`: 2 s at every layout from 900 to redline; all samples are finite and in [-1, 1].
  - `pulseRateMatchesFiring`: an I4 at 3000 rpm with no induction. The dominant low frequency (autocorrelation over 0.5 s) is within 5% of 100 Hz (rpm/60 × cylinders/2).
  - `flatVsCrossPlaneDiffer`: one bank's pulse train at 3000 rpm has equal spacing for v8Flat and unequal spacing for v8Cross. Expose `func firingTimes(layout:rpm:duration:bank:) -> [Double]` as `internal` for the test.
  - `silenceWhenStopped`: rpm 0 gives an RMS < 0.001.
  - `turboAddsWhine`: energy in the 2–8 kHz band is higher with boost 15 than with boost 0.
  - `writesListeningSamples`: when env `PF_WAV_DIR` is set, writes a 6 s 16-bit mono WAV per layout (idle → redline → idle sweep, plus V8 turbo, V8 Roots, V8 nitrous) via `WavWriter.write(samples:sampleRate:to:)` (pure Swift, in `Sound/WavWriter.swift`). The `sim-tests` job sets `PF_WAV_DIR` and uploads the folder as artifact `engine-sounds`, so Zach can listen on the PC long before the app exists.
- [ ] **Step 2:** Implement, commit with the changelog entry, push. Expected: `sim-tests: success` (fix-up commits until green).

### Task 9: Cars, fitment and saving

**Files:**
- Create: `Sources/PistonForgeKit/Car/Cars.swift`, `Car/Fitment.swift`, `Save/SaveStore.swift`
- Test: `Tests/PistonForgeKitTests/CarSaveTests.swift`

**Interfaces:**
- Produces:
  - `enum CarBody: String, Codable, CaseIterable { case hatch, coupe, muscle, pickup, super_ }`, with `var spec: CarSpec` (`name`, `drivetrain: Drivetrain` (fwd/rwd/awd), `massKg`, `bayMm: (l, w, h)`, `wheelbaseM`, `cgHeightM`, `frontWeight`, `cdA`).
  - `struct CarSetup: Codable { body: CarBody; gearbox: Gearbox /* m5, m6, seq6, auto8 */; finalDrive: Double; tyre: Tyre /* street, sport, semiSlick, dragRadial; widthMm */ }`
  - `func fitment(_ e: EngineBuild, in body: CarBody) -> Fitment`, where `Fitment` is `.fits` or `.blocked(dimension: String, overMm: Int)`.
  - `struct SaveFile: Codable { version: Int; builds: [EngineBuild]; selectedBuild: UUID?; car: CarSetup; settings: Settings }`; `static let currentVersion = 1`.
  - `final class SaveStore { init(directory: URL); func load() -> (SaveFile, LoadStatus); func save(_: SaveFile) throws }`
    - `LoadStatus` is `.fresh`, `.loaded`, `.recoveredFromBackup`, `.newerVersionKept` or `.corruptReset`.
    - Writes go to `save.json` with the previous file kept as `save.bak.json`. Writes are atomic.
  - `struct Settings: Codable { units: Units; steering: Steering /* tilt, touch */; gears: Gears; sound: Bool; haptics: Bool; quality: Quality }`
- [ ] **Step 1: Write the tests:**
  - `w16DoesNotFitHatch` (blocked, with overMm > 0).
  - `v8FitsMuscle`.
  - `everyStarterFitsSomeCar`.
  - `saveRoundTrip` (temp directory).
  - `corruptMainUsesBackup`.
  - `corruptBothResets` (with status).
  - `newerVersionIsNotOverwritten`: given version 99 on disk, `load` returns defaults with `.newerVersionKept`. A later `save` writes to `save.json` only after moving the newer file to `save.newer.json`.
  - `emptyFileIsCorrupt`.
- [ ] **Step 2:** Implement, commit with the changelog entry, push. Expected: `sim-tests: success` (fix-up commits until green).

### Task 10: Procedural 3D engine

**Files:**
- Create in `Native/App/Engine3D/`: `EngineModelBuilder.swift`, `HoseMesh.swift`, `EngineAnimationSystem.swift`, `EngineViewport.swift`
- Create: `Native/App/Preview/LaunchRoute.swift` (first version: parses `-screen engine`, `-layout <id>`, `-induction <id>`; Task 11 extends it), `Native/App/Theme.swift`, `Native/UITests/ScreenshotUITests.swift`
- Modify: `Native/App/PistonForgeApp.swift` to show a bare `EngineViewport` with the engine idling (crank turning from `EngineSim`) in place of `LoopTestView` (deleted here)

**Interfaces:**
- Consumes: `LayoutSpec`, `EngineBuild` and `EngineState.crankAngle`.
- Produces:
  - `EngineModelBuilder.build(_ b: EngineBuild) -> Entity`: block and banks at `bankAngle`; heads; a crank with pins at `crankPins`; pistons; intake plenum; exhaust headers; a turbo with piping and intercooler, or a supercharger on top (Roots/twin-screw) or at the side (centrifugal); nitrous bottle and lines; sensors (MAF in the intake tract, MAP, O2 in the exhaust, knock on the block); fuel rail and injectors; wiring loom.
    - Static parts are merged per material.
    - Hoses use `MeshDescriptor` swept along Catmull-Rom curves.
  - `struct EngineMotionComponent: Component { var crankAngle: Double }`, plus `EngineAnimationSystem: System`, which places pistons and rotates the crank from `crankAngle`, registered at launch.
  - `EngineViewport(build:, state:)`: a `RealityView` with a virtual camera and a one-finger orbit and pinch zoom. Tapping a part's collision shape calls `onSelect(PartGroup)`.
- [ ] **Step 1:** Load the `realitykit`, `swiftui-gestures` and `swift-concurrency` skills. Implement. The orbit camera clamps its pitch to 5–80°.
- [ ] **Step 2:** In `ScreenshotUITests`, add `testEngineLayouts` launching `-screen engine -layout <id> -induction <id>` for each of the 9 layouts, with turbo on V8 cross-plane and Roots on V8 flat-plane.
- [ ] **Step 3:** Dispatch the app job. Expected: green, with 9+ engine screenshots. Open them and check the bank angle, cylinder count and visible induction for each.
- [ ] **Step 4:** Commit. Download the `.ipa` to `builds/PistonForge-engine3d-unsigned.ipa` and send it to Zach for a frame-rate check on his iPhone 13 (W16 with turbo is the heaviest case); that verdict decides the 3D detail level before more is built on it.

### Task 11: Screen previews (GATE: Zach approves before Task 12)

**Files:**
- Create in `Native/App/`:
  - `Preview/SampleData.swift`; extend `Preview/LaunchRoute.swift` to parse `-screen engine|parts|tune|dyno|car|settings` and `-preview`.
  - `Screens/EngineScreen.swift`, `PartsSheet.swift`, `TuneScreen.swift`, `DynoScreen.swift` (Swift Charts), `CarScreen.swift`, `SettingsScreen.swift`, `GarageSheet.swift`.
- Modify: `Native/UITests/ScreenshotUITests.swift`

**Interfaces:**
- Consumes: the package's model types, for sample data only. The screens take plain values and closures; there is no simulation wiring yet.
- Produces:
  - Screens taking an `@Observable` `ScreenModel` protocol, so that Task 12 swaps the sample model for the live one.
  - Accessibility identifiers `screen.<name>`, `button.start`, `button.pull`, `chart.dyno`.
- [ ] **Step 1:** Load the `zb-ux-standard`, `swiftui-patterns`, `swiftui-layout-components` and `swift-charts` skills, and the `artifact-design` skill if a review page is wanted. Build each screen to spec section 5.1 with sample data. Every screen carries a visible `PREVIEW` label while `-preview` is set. The engine screen uses the real `EngineViewport` from Task 10.
- [ ] **Step 2:** `ScreenshotUITests.testEveryScreen` launches each `-screen` route with `-preview`, attaches screenshots named `<screen>-<device>-<orientation>` (portrait, plus landscape on iPhone), and calls `try app.performAccessibilityAudit()` on each.
- [ ] **Step 3:** Dispatch the app job. Expected: `app: success`, with a screenshot for every screen × iPhone/iPad × orientation. Open every screenshot and check the theme, 44 pt targets, clipping and Dynamic Type.
- [ ] **Step 4:** Commit. Send Zach the screenshots (an artifact page or files) and wait for "previews approved". Record the approval in `.zb/state.json`. Fold any changes in and repeat Step 3.

### Task 12: Wire the game (after previews are approved)

**Files:**
- Create in `Native/App/`: `AppModel.swift` (`@Observable @MainActor`: save store, current build, `EngineSim`, `DynoRun?`, settings); `Audio/AudioOutput.swift`; `Platform/Haptics.swift`
- Modify: the Task 10 screens, so they take `AppModel`

**Interfaces:**
- Consumes: everything above.
- Produces:
  - `AudioOutput`:
    - `AVAudioSession` category `.playback`, mode `.default`, no mixing.
    - An `AVAudioSourceNode` whose render block calls `EngineVoice.render`. Parameters go through a lock-free single-writer struct updated at 60 Hz.
    - It stops on `scenePhase != .active` and handles interruptions.
  - `protocol HapticsDriver { func play(_ cue: HapticCue) }`, with a `CoreHapticsDriver` and a `NullHaptics` used when `CHHapticEngine.capabilitiesForHardware().supportsHaptics` is false.
  - The simulation steps on a display-linked timer (`TimelineView(.animation)` or `CADisplayLink`) with real `dt`. It pauses when not active.
- [ ] **Step 1:** Load the `swift-concurrency`, `swiftui-patterns` and `swiftui-performance` skills. Wire the following, all saved through `SaveStore`:
  - Engine screen: START/STOP and a rev slider.
  - Parts: changes are applied through `EngineSim.setBuild`.
  - Tune: edits the `ECUMap` and has the auto-base button.
  - Dyno: live `DynoRun` with an overlay of the last pull.
  - Car: fitment, gearbox and tyres.
  - Settings.
- [ ] **Step 2:** Add `GameplayUITests`:
  - `testStartRevAndPull`: start the engine; the rpm label is above 0 within 3 s. Start a pull; `chart.dyno` exists and a peak hp label appears within 30 s.
  - `testBackgroundPausesAndResumes`: run the engine, press home via `XCUIDevice.shared.press(.home)`, reactivate. The app is still running, with no crash, and the rpm label is present.
  - `testPartChangeShowsMapWarningOrRebases`: on the cams change, either the warning text or a rebased AFR is visible.
- [ ] **Step 3:** Dispatch the app job. Expected: all UI tests green and screenshots attached. Open them.
- [ ] **Step 4:** Commit.

### Task 13: Device-only checks and stage 1 build

**Files:**
- Modify: `Native/project.yml` (`MARKETING_VERSION 0.3.0`), `docs/roadmap.md`, `docs/ios-release.md`

- [ ] **Step 1:** Dispatch the app job on the branch. Expected: green. Download the `.ipa` to `builds/PistonForge-stage1-unsigned.ipa`. Confirm that `unzip -l` lists `PistonForge.app/PistonForge`, `Assets.car` and `PrivacyInfo.xcprivacy`.
- [ ] **Step 2:** Run the **advisor** over the whole branch before handing anything over.
- [ ] **Step 3:** Send Zach the `.ipa` with install steps and this checklist, which only a phone can prove: sound quality per layout; frame rate on the engine screen and dyno; heat after 5 minutes; touch orbit feel; haptics; the silent switch still playing sound.
- [ ] **Step 4:** Tick roadmap items with evidence, then commit.

### Task 14: Merge and retire the web game

**Files:**
- Delete: `PistonForge/` (the whole web game), `.github/workflows/ci.yml`, `.github/workflows/ios.yml`, `builds/PistonForge-unsigned.ipa`
- Keep: `Native/PistonForgeKit/Tests/PistonForgeKitTests/Fixtures/sim-golden.json`, `docs/research/`, `docs/legal/`
- Modify: `README.md` (root; create if missing), `docs/record.md`, memory files

- [ ] **Step 1:** Grep for references to `PistonForge/` paths in `docs/` and the workflows, and update or remove them.
- [ ] **Step 2:** Merge `native-stage-1` into `main` and push. Expected: `native.yml` runs on `main` and goes green, with both jobs.
- [ ] **Step 3:** Commit with a changelog entry. Write the vault Session-Log row. Update the memory and its mirror.
