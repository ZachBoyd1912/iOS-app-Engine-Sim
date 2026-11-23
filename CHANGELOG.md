# Changelog
## 23/11/2026 @ 03:14:38 IST - "deepseek-flash"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged. Four workstreams landed code; none is proven until CI compiles it.

**Goal:** land the first wave of workstream agents (WS1 catalogue, WS2 valve train, WS8 tune editing, WS9 dyno, WS10 vehicle physics) and let CI decide whether it compiles.

**Added**
- WS1: `PistonForgeKit/.../Catalog/EngineCatalog.swift` — 83 provenance-tagged engine rows (14 sourced firing orders, 13 derived, 46 unsourced, 10 not applicable) plus `EngineCatalogTests`. Deliberately does **not** add `EngineLayout` cases: every `allCases` test requires a firing order and starter geometry, and inventing them was out of bounds.
- WS2: valve train — `CamshaftComponent`/`ValveTrainComponent` in `EngineAnimationSystem`, `addValveTrain` geometry in `EngineModelBuilder`. Cams at half crank speed, valves moving 0.11·bore, springs compressing, rockers swinging. Driven by the existing `EngineMotionComponent`; no new timer.
- WS8: `TuneScreen` cells are editable controls (tap → inspector bar with Less/More, numeric field, slider; long-press then drag to paint), writing through the existing `@Binding build`. Cells are 44 pt and `@ScaledMetric`.
- WS9: `DynoScreen` gains Hold/Pull modes, wheel/crank toggle, `DynoLogView`, disabled and empty states.
- WS10: `VehicleDynamics.swift` — steering, lateral grip, understeer/oversteer, cornering radius, braking with weight transfer, as pure functions with tests.
- `docs/workstreams/ws01…ws10.md` — each agent's design note, file:line map and stated limits.

**Known risks carried into the build**
- Two WS2 agents ran concurrently on the same two Engine3D files and overwrote each other mid-task; the surviving version is the world-frame one, and the collision is documented at `EngineModelBuilder.swift:647`.
- WS1 reports that 6 of the 16 shipped firing orders disagree with the research (`i3`, `i8`, `v8Cross`, `v8Flat`, `v10`, `flat4`). Correcting them changes crank pose and sound, so it is left as an owner decision.
- **Nothing has been compiled**: CI was billing-blocked while these were written. This commit exists to find out.

**Files Touched:** `Native/App/Engine3D/*`, `Native/App/Screens/TuneScreen.swift`, `Native/App/Screens/DynoScreen.swift`, `Native/App/Screens/DynoLogView.swift`, `Native/PistonForgeKit/Sources/PistonForgeKit/Catalog/EngineCatalog.swift`, `.../Physics/VehicleDynamics.swift`, `.../Car/DriveSim.swift`, `Native/PistonForgeKit/Tests/.../EngineCatalogTests.swift`, `Native/project.yml`, `docs/workstreams/*`, `CHANGELOG.md`.

## 23/11/2026 @ 01:02:50 IST - "deepseek-flash"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged.

**Goal:** confirm the Game Mode fix on device and stop the tab bar covering the primary action.

**Verified on device (0.2.6, build 7):**
- The iOS warning is **gone**. `builds/device/2026-11-23/v026-clean.png` shows the header reading cleanly where the overlay used to be.
- The Metal HUD now reports **`Game Mode: On`** (it read `On` before too, but the system claimed the key was missing); frame rate 60.01 FPS, GPU 2.07 ms, `dropouts 0`, thermal `Fair`.
- The engine renders behind the HUD on the Engine screen, at the Inline 2 selection.
- The sound panel shows **no load error**, which is the first evidence that the impulse-response path fix works: a failed load would print "Engine sound failed to load (4)".

**Cause of the one visible regression.** Moving the controls into a `ScrollView` in 0.2.4 left them scrolling *under* the floating tab bar, so "Start engine" was half covered.

**Fixed**
- `EngineScreen`: 96 pt bottom padding inside the scroll content, sized to clear the tab bar, with a comment so it is not removed as arbitrary spacing.

**Also changed**
- `scripts/sideloadly-install.ps1` now terminates the app before installing. A running app makes installd stall at **89% "Installing…"** indefinitely - the 0.2.6 install hung there until `ios kill` was issued, and then completed. Without this the automation can wedge for the full timeout.

**Files Touched:** `Native/App/Screens/EngineScreen.swift`, `Native/project.yml`, `scripts/sideloadly-install.ps1`, `CHANGELOG.md`.

## 23/11/2026 @ 00:45:20 IST - "deepseek-flash"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged. This removes a system-drawn obstruction from the hero screen and closes a submission requirement; it does not complete a roadmap item.

**Goal:** find out what the giant white text over the 3D engine actually was, and remove it.

**Cause.** It was never SwiftUI and never RealityKit. Enlarging the screenshot showed the sentence:

> "…SupportsGameMode key not found in Info.plist. This key will become required to be eligible for …"

iOS 27.2 draws that warning **over the app** when a game does not declare Game Mode support. It is absent from the accessibility tree because the system, not the app, renders it - which is why every tree dump came back clean and why the string did not exist anywhere in our source. `GCSupportsGameMode` was deprecated in iOS 18.6 and replaced by `LSSupportsGameMode` (Apple: "If you don't include this key in your Info.plist, Game Mode might not turn on for your game"). The project generates its Info.plist from `INFOPLIST_KEY_*` settings, so nothing was ever declaring it.

**Fixed**
- `Native/AppInfo.plist` (new, outside `Native/App` so it is never copied in as a resource) declares `LSSupportsGameMode`, and `Native/project.yml` sets `INFOPLIST_FILE: AppInfo.plist` so Xcode merges it into the generated plist.
- First attempt used `INFOPLIST_KEY_LSSupportsGameMode`, which **silently does nothing**: 0.2.5 built and shipped, and unpacking the .ipa showed `LSSupportsGameMode: None`. `INFOPLIST_KEY_*` only covers keys Xcode knows. Caught by inspecting the built bundle rather than trusting the build being green.

**Why it matters beyond the cosmetic:** Apple states the key will become required, and without it Game Mode may not engage - which is precisely the mode that would stop background activity from stealing CPU from the simulator while a pull is running.

**Verified:** the warning is legible in `builds/device/2026-11-23/v024-engine.png`, and Apple's documentation for `LSSupportsGameMode` / deprecated `GCSupportsGameMode` confirms the key name and version. **Not verified:** that 0.2.5 no longer shows the warning - that is the next install.

**Files Touched:** `Native/project.yml`, `CHANGELOG.md`.

## 23/11/2026 @ 00:07:44 IST - "deepseek-flash"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged. Two P0 audit findings from `docs/audits/2026-11-22-ios-audit.md` are addressed; the rest remain.

**Goal:** make the Engine screen usable at every phone size and stop the 3D stage bleeding into the rest of the UI.

**Cause.** `EngineScreen` was a `ZStack` with an unframed `EngineViewport` that also applied `.ignoresSafeArea(edges: .horizontal)`, and every control sat in a fixed `VStack` with `Spacer(minLength: 0)`. Consequences the audit predicted and the device confirmed: content needs ~645 pt on a screen that offers ~598 pt after chrome, so **Start engine falls off a 4.7" phone**; the viewport had no bounds, so its layer could paint outside its area; and in landscape the header and gear button are clipped off the right edge.

**Changed**
- `EngineScreen`: the 3D stage is now a fixed 360 pt block with `.frame` + `.clipped()`, the header overlays it, and **everything actionable moved into a `ScrollView`** so Start is reachable on any device. Horizontal safe-area escape removed from the content layer.
- No behaviour, model or sound changes; purely structural, so it is safe to verify visually.

**Verified:** the pre-fix state is captured in `builds/device/2026-11-23/v023-engine.png` (Start button pinned at the bottom, panels overrunning the tab bar). **Not verified:** that 0.2.4 renders correctly — the next install and screenshot.

**Files Touched:** `Native/App/Screens/EngineScreen.swift`, `Native/project.yml`, `CHANGELOG.md`.

## 22/11/2026 @ 23:55:44 IST - "deepseek-flash"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged. This fixes a rendering defect on the app's hero screen; it does not complete a roadmap item.

**Goal:** stop the 3D engine rendering as giant clipped garbage on device (0.2.2, iPhone 13). Evidence: the Engine screen showed enormous white shapes and a giant warning glyph inside the viewport, with `dropouts 8903-10732` and "phone hot" in the sound panel. The accessibility tree contains no such text, which places the artefact inside the RealityKit scene rather than SwiftUI.

**Cause.** `HoseMesh.addTube` normalised the two end-cap tangents without checking their length:

```swift
let startTangent = simd_normalize(rings[1].0 - first.0)
let endTangent = simd_normalize(last.0 - rings[rings.count - 2].0)
```

`catmullRom` can emit consecutive duplicate samples (a control point repeated, or a degenerate span). Every hose, intake runner and exhaust pipe goes through `addTube`, so a single duplicate gives a zero-length delta, `simd_normalize` returns NaN, and the NaN lands in the **normals buffer for the whole merged mesh** - the geometry then draws as runaway shapes and the GPU burns cycles rasterising them, which also starves the audio render thread (hence the dropout counter climbing ~1000/s). `addCylinder` already guarded its axis; `addTube` did not.

**Fixed**
- `HoseMesh.addTube`: consecutive duplicate samples are dropped before rings are built, and each cap is emitted only when its delta is longer than 1e-6, so no NaN can enter the buffer. Comment records the symptom so it is not "simplified" back.

**Verified so far:** the artefact and the dropout rate were captured in `builds/device/2026-11-22/screen-engine.png` and `verify-234320-*` on 0.2.2. **Not verified:** that 0.2.3 renders a recognisable engine - that needs the next install and a fresh screenshot.

**Files Touched:** `Native/App/Engine3D/HoseMesh.swift`, `Native/project.yml`, `CHANGELOG.md`.

## 22/11/2026 @ 23:25:18 IST - "deepseek-flash"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged: this removes a crash and a broken feature, it does not finish a roadmap item. Item 23 stays open until a build is installed and verified from the phone side.

**Goal:** kill the second crash found on the device (23:04, `std::terminate` in `SoundEngine.load`'s detached task) and fix what the investigation uncovered underneath it.

**Cause (two bugs, one investigation).**
1. **No exception boundary.** `esim_bridge.cpp` had zero `try`/`catch` and no lock anywhere. engine-sim and piranha throw (`EmptyPort`, `InvalidLiteralType`, `filesystem_error`, `bad_alloc`); every throw unwound out of the `extern "C"` functions into Swift's async thunk, whose cleanup calls `__clang_call_terminate` → `std::terminate` → SIGABRT. That is the 23:04 report exactly: no engine-sim frames, because the unwinder had already popped them.
2. **Loads could overlap.** `SoundEngine.load` set `isLoading` but never checked it, and the bridge's `esim_start` began with an unlocked `esim_stop()`. Two picker changes ~300 ms apart (the debounce in `GameStore.reloadSound`) put a stop inside a start; two starts in flight both reach `g.thread = std::thread(simLoop)`, and assigning to a joinable `std::thread` is defined to call `std::terminate()` with nothing to catch.

**Fixed**
- `esim_bridge.cpp`: lifecycle `std::mutex` around start/stop; every public entry point wrapped so no C++ exception crosses the boundary (codes 5 `system_error`, 6 `std::exception`, 7 unknown); teardown inside catch handlers is itself guarded; the sim thread body is wrapped and latches a fault instead of terminating; `esim_read` no longer allocates on the audio thread (fixed 8 KiB buffer, `try`/`catch` → silence + fault); `esim_stats_get` null-checks; new `esim_fault()`.
- `esim_bridge.h`: declares `esim_fault()`.
- `SoundEngine.swift`: loads are queued on a `Task` chain so the bridge never sees two at once; `esim_fault()` is polled and surfaced as "Engine sound stopped after an internal fault" instead of a silent death.
- `SoundEngine.swift`: **impulse-response path fix.** Generated IRs are written to the caches work directory but referenced by a bare filename, and engine-sim resolves it against the read-only bundle folder. `readWav16` therefore missed and **every generated preset returned code 4** — only `.reference` could ever load. The rewrite now emits the absolute path, the same way the reference recording was already handled.

**Verified:** the crash signature was read off the device (`.ips` via `ios crash cp`), and every claim above was traced to a specific file:line by a read-only audit agent. **Not yet verified:** that 0.2.2 compiles and that the presets load and the app survives a rapid preset switch — that is the next device run.

**Files Touched:** `Native/EngineSimSpike/App/Bridge/esim_bridge.cpp`, `Native/EngineSimSpike/App/Bridge/esim_bridge.h`, `Native/App/Sound/SoundEngine.swift`, `Native/project.yml`, `CHANGELOG.md`.

## 22/11/2026 @ 22:22:42 IST - "deepseek-flash"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged. Item 23 ("unsigned .ipa produced by CI and installed on Zach's iPhone") is the one this touches, and it still cannot be ticked tonight: the CI can build the IPA but cannot deliver it, for a reason that has nothing to do with the app.

**Goal:** get a build with the audio fix onto the phone. Two failed runs showed the real blocker.

**Cause.** Run 45076156023 and 45076919133 both stopped in `sim-tests` with *"Failed to CreateArtifact: Artifact storage quota has been hit"*. Because `app` declares `needs: sim-tests`, that failure skipped the macOS job entirely — **the audio fix has never been compiled, let alone tested**. Deleting 1.4 GB of stale artifacts (91 of them, oldest first) did not help: GitHub states usage is recalculated only every 6-12 hours, so enforcement stays latched for the rest of the day. The app job was being blocked by an upload of engine-sim *test fixtures*, not by anything in the product.

**Changed**
- `.github/workflows/native.yml`: every `upload-artifact` step is now `continue-on-error: true`, so a storage-quota failure can no longer skip the macOS build. The `.ipa` is additionally published as a **release asset** on a `device-test` tag, which is not counted against Actions artifact storage, and the workflow gains `contents: write` for that one purpose. Pull it with `gh release download device-test -p "*.ipa" -D builds/device-latest --clobber`.
- The release is explicitly not user-facing: title "Device test builds", overwritten every run, notes say so.

**Verified:** the two run logs (`gh run view --log-failed`) name the quota error verbatim; the step list for 45076156023 shows `sim-tests: failure` at the two upload steps and `app: skipped`. Not yet verified: that the workflow edit runs green — that is the next dispatch.

**Files Touched:** `.github/workflows/native.yml`, `CHANGELOG.md`.

## 22/11/2026 @ 22:09:38 IST - "deepseek-flash"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged. Item 20 (performance verified on a real iPhone) and item 23 stay open — but this entry does settle the first real-device question the iOS plan has been carrying since 15/11: the app crashed on every launch, and now we know why.

**Goal:** stop Piston Forge 0.2.0 crashing on the phone. First real-device session immediately produced three identical crash reports, so the goal became "diagnose from those reports, not from guesswork".

**Cause.** All three crashes are the same: `EXC_BREAKPOINT / SIGTRAP`, faulting thread `AURemoteIO::IOThread`, stack `_dispatch_assert_queue_fail` → `dispatch_assert_queue` → `_swift_task_checkIsolatedSwift` → `closure #2 in SoundEngine.load(build:exhaust:limiter:)`. `SoundEngine` is `@MainActor`, so the `AVAudioSourceNode` render closure written inside it **inherits main-actor isolation**. Core Audio calls that block on its real-time I/O thread, Swift 6 mode inserts a dynamic isolation check on the way in, the check fails, and the process traps the first time audio is pulled. `Native/project.yml` sets `SWIFT_VERSION: "6.0"`; the engine-sim spike app has the identical closure but built in Swift 5 mode, which is exactly why it "sounded perfect" on the phone while the real app dies. This was never a signing or sideloading problem — it would crash the same way from TestFlight.

**Fixed**
- `Native/App/Sound/SoundEngine.swift`: the render block is now `private nonisolated static func render(...)`, passed as `renderBlock: Self.render` instead of an inline closure. A `nonisolated` static function carries no actor isolation, so no runtime check is inserted and the audio thread can call it. The comment records the crash signature so nobody reintroduces the closure form.

**Verified so far:** the crash reports were pulled off the device with `ios crash cp` and parsed (`EXC_BREAKPOINT`, thread, symbolicated frame). The fix itself is **not yet verified on the phone** — that needs a CI build (macOS) and a Sideloadly re-sign, which is the next step.

**Files Touched:** `Native/App/Sound/SoundEngine.swift`, `CHANGELOG.md`.

## 22/11/2026 @ 22:01:11 IST - "deepseek-flash"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged: this entry adds a testing harness, it does not finish a product feature. Item 23 ("Simulator screenshot and unsigned .ipa produced by CI and installed on Zach's iPhone") is now *half* proven — the installed app was verified on the device — but the item also covers the CI Simulator screenshot, so it stays unticked rather than being credited on a partial. Item 20 (performance on a real iPhone) stays open until numbers are actually sampled.

**Goal:** give this repo a way to install, launch, screenshot and log Piston Forge on Zach's real iPhone from this Windows PC, with no Mac and no jailbreak, so the "cannot be proven from Windows" list in `docs/ios-release.md` can finally be worked through.

**Why this shape.** Zach asked about `ipasimulator/ipasim` (IPA Sim) as a vPhone-style virtual iPhone. It is not one: it is a WinObjC-era UWP emulator whose README states "only simple applications can be emulated", it has no SwiftUI or RealityKit, and its author states he does not plan to continue it. vPhone needs Apple Silicon macOS, touchHLE only covers iPhone OS 2.x–4.x apps, and `vphone-win-port` does not run a VM yet. Since the goal was testing Piston Forge on a *real* iPhone, the harness drives the physical device over USB instead — the same binary a player installs.

**Added**
- `scripts/device.ps1` — one entry point for `status | start | stop | apps | launch | kill | install | shot | logs | report` plus pass-throughs for taps once a UI driver is signed. `shot` prints a bare absolute path so an agent can read the image back. Tunnel start is idempotent and polls until `apps --list` succeeds rather than sleeping blind.
- `.opencode/skills/ios-device/SKILL.md` — the agent-facing contract, with the traps that cost time: unsigned IPAs are rejected by `install` (Sideloadly is the signer, not go-ios), always target an explicit UDID, free-account 3-app/7-day limits, and `ios screenshot` vs `ios ui screenshot` needing different prerequisites.
- `docs/ios-device-testing.md` — runbook: verified device/tool state, daily commands, the one manual signing step, and what the harness still cannot prove (sound quality, haptic feel).

**Changed**
- `docs/ios-release.md` — the "NOT yet done: an actual install on a phone" line was stale; an install is now confirmed and the PC can drive the device, so it says so and points at the new runbook.

**Verified on the device (not inferred):**
- iPhone 13 (`iPhone14,5`), iOS 27.2 build 24B5099f, UDID `00008110-001A2D200CDB801E`.
- go-ios 1.3.2 installed; **userspace tunnel negotiates with no admin rights and no `wintun.dll`** — the kernel path was tried first and correctly refused with "needs elevated privileges", which removed two UAC steps from the plan.
- `apps` lists `ie.zbautomations.pistonforge  Piston Forge 0.2.0`; that version matches `builds/v2-latest/PistonForge-native-unsigned.ipa` (0.2.0 build 1, min iOS 18.0, arm64 `iphoneos`), so the phone is running the latest build already.
- `launch` started the process (PID 69407) and a screenshot 9 s later shows the Tune screen with the "288 hp @ 6952, 305 Nm" readout — proving the launch/screenshot loop against the real app.
- `syslog` streams (2700 lines in 8 s) and filters correctly (18/1154 matched `SpringBoard`).
- **Not verified:** taps. `ios ui status` has no driver, and the DeviceKit runner IPA is unsigned for this device (`ApplicationVerificationFailed`), so UI automation waits on one Sideloadly signing pass.

**Files Touched:** `scripts/device.ps1`, `.opencode/skills/ios-device/SKILL.md`, `docs/ios-device-testing.md`, `docs/ios-release.md`, `CHANGELOG.md`.
## 18/11/2026 @ 16:52:00 IST — "claude-sonnet-5-5"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged: this entry is research and a throwaway spike, so no roadmap item moves. Item 8 (screens to the ZB UX standard) stays open; the redesign is waiting on the design update.

**Goal:** answer Zach's 17-18/11 direction: replace the engine sound with engine-sim, find the largest engine and gearbox lists, and prove engine-sim can run on an iPhone.

**Added**
- Research (7 agents): `docs/research/raw/` holds an 83-row engine catalogue, two gearbox and car data files, a free 3D-kit survey, an engine-sim iOS feasibility report, a portrait-cockpit study, and the spike results. Why: Zach wants far more engines (RevLab has 21), many gearboxes and a Tuning-Simulator-style cockpit in portrait; no design can be approved without the real data. Honest gaps (unsourced firing orders, ratios, drive-mode numbers, frontal areas) are tagged in each file.
- Spike (branch `spike/engine-sim-ios`, not merged): `Native/EngineSimSpike/` builds engine-sim's sound core headless and a phone test app. Why: the feasibility report said "needs a spike". Cause of the many small patches: upstream is written for MSVC and the research missed that piranha needs Boost.
- `.zb/state.json`: Zach's decisions (engine-sim for sound, write our own engines and exhaust sounds, career later, portrait-first, gearbox list approved).

**Verified:** CI run 44346718049: Linux, macOS arm64 and iOS Simulator render audio; iPhone arm64 libraries and the test app build; V8/V10/V12 ran at 1.0-2.2x real time on shared runners. Not verified: sound quality, phone CPU, heat (needs Zach's phone test).

**Files Touched:** `Native/EngineSimSpike/**`, `.github/workflows/engine-sim-spike.yml`, `docs/research/raw/*`, `.zb/state.json`, `CHANGELOG.md`.

## 17/11/2026 @ 16:44:44 IST — "claude-opus-5-5"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged. Item 8 (screens to the ZB UX standard, previews approved) stays open: Zach rejected the previews.

### Goal
Record Zach's rejection of the stage 1 previews and the research he asked for: three reference games, licensable 3D engine models and real gearbox behaviour.

### Added
- **`docs/research/2026-11-17-reference-games.md`:** findings from five research subagents.
  - Covers RevLab, Engine Simulator (Muhammad Saad Ata) and Tuning Simulator (Scott Busby): listings, features, layouts, strengths and complaints.
  - Covers 3D model sources, licences, polygon budget and the heat-glow approach.
  - Gives gearbox figures for 5- and 6-speed manuals, a sequential, a 7-speed dual-clutch and an 8-speed automatic.
  - Why: Zach wants a game as deep as these, with real 3D models and real gearboxes. Store screenshots are kept privately in `builds/research/` (not committed) as reference only; our look stays our own.

### Changed
- **`.zb/state.json`:** Zach's decisions.
  - The previews are not approved, because landscape must use the width.
  - The game should be as deep as the reference games.
  - Every engine is fully modelled, with moving valves and heat glow, using internet models where licensable. This reverses the "built in code only" call.
  - Gearboxes: 5MT, 6MT, sequential, 7-speed dual-clutch and 8-speed automatic.

### Verification
- Research only; no code changed. The listings and screenshots were read directly. Unverified claims are marked in the document.

### Files Touched
- `docs/research/2026-11-17-reference-games.md` (new), `.zb/state.json`, `CHANGELOG.md`

## 16/11/2026 @ 15:53:00 IST — "claude-opus-5-5"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged. Item 8 (screens to the ZB UX standard, previews approved) stays open until Zach approves the previews.

### Goal
Stage 1 plan, Task 11: preview every screen with sample data, for Zach to approve before the game is wired up. This is the ZB UX standard adapted to native iOS, as Zach approved:
- Native SwiftUI controls instead of the web parts libraries.
- Dark only.
- Simulator screenshots on iPhone (portrait and landscape) and iPad, each checked by Xcode's accessibility audit.

### Added
- **Screens, in `Native/App/Screens/`, all on sample data:**
  - **Engine:** 3D engine, live rpm, power, AFR and boost, Start (the one accent), rev slider, warnings banner.
  - **Parts:** grouped by system; every choice says what it changes in plain words.
  - **Tune:** auto-tune, limits, boost, strategy, nitrous, and the fuel and ignition tables with their numbers.
  - **Dyno:** power and torque charts with the last pull dashed behind, AFR, boost, knock and EGT traces, crank and wheel figures, and a failure explained in words.
  - **Car:** each body shows whether the engine fits, as an icon, a word and the millimetres over; gearing; tyres.
  - **Settings:** includes a reset that can be undone.
  - **Garage:** swipe to duplicate or delete.
- **Shared components** (`Components.swift`): status as icon + word + colour, readouts in tabular digits, primary and secondary buttons at least 44 pt, cards, the PREVIEW tag.
- **Theme tokens:** surfaces, vivid status marks and inks, a 4-point spacing scale, radii, hit target.
- **`Preview/SampleData.swift`:** real model output (a dyno pull of a twin-turbo V8), not invented numbers. **`Preview/PreviewRoot.swift`:** opens one screen with `-screen <name> -preview`.
- **`ScreenshotUITests.testEveryScreen`:** every screen, portrait plus landscape on iPhone, with `performAccessibilityAudit`.

### Verification
- Pending one Mac run that covers both this task and Task 10.
- Before that run, the advisor caught three problems, now fixed:
  - **No phone build when a test failed:** the CI skipped the phone build whenever a UI test failed. It now always builds the `.ipa` and fails the job only at the end.
  - **Name clash:** `Settings` is a SwiftUI type name too, so the screen now names `PistonForgeKit.Settings`.
  - **Screen identifiers:** each screen's identifier now sits on a containing element, so it doesn't hide its children's identifiers.
- **Other CI changes:**
  - Dispatch inputs to run one UI test on one device during fix-up rounds, which saves Mac minutes.
  - The audit lists every issue in one pass.
  - The `.xcresult` is always uploaded.
  - The Simulator `.app` is kept as an artifact, for a live-streaming service if Zach picks one.
- **Runs 43901298051 and 43902770109:** GitHub never assigned a Mac ("not acquired by Runner" and "capacity constraints" on macOS arm64), twice for 15 minutes; no minutes were charged. A dispatch input now picks the runner (`macos-26`, `macos-15` or `macos-15-intel`) so a capacity shortage doesn't block the work.
- **Intel run 43908934695:** the 3D engine and all seven screens compiled first time (Xcode 16.4).
  - Six preview screens rendered.
  - The engine screens crashed inside RealityKit's own start-up (`re::Engine::init`, a divide-by-zero), read from the crash report in the test results. Intel runners have no GPU; on Apple silicon RealityKit rendered in Task 0.
  - The accessibility audit flagged contrast and Dynamic Type issues. The audit now names each element, so they can be fixed without a Mac.
- **Apple-silicon run 43922004468** (`macos-15`): the 3D engine renders on all ten layouts, iPhone and iPad.
- **That run's audit findings, now fixed:**
  - System-grey section headings and notes failed contrast, so they now use theme inks.
  - The engine screen's live readouts clipped, so they are now a 2×2 grid on an opaque panel.
  - Long titles now wrap.
- **3D fixes:**
  - The camera now sits further back, so the engine is no longer cut off.
  - The W16's banks are spread to 15° so all four show.
  - The turbo downpipes are shorter.

### Files Touched
- `Native/App/Screens/*.swift`, `Native/App/Preview/SampleData.swift`, `Native/App/Preview/PreviewRoot.swift` (new), `Native/App/Theme.swift`, `Native/App/PistonForgeApp.swift`, `Native/UITests/ScreenshotUITests.swift`, `.github/workflows/native.yml`, `CHANGELOG.md`

## 16/11/2026 @ 15:44:56 IST — "claude-opus-5-5"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`, unchanged. Item 15 (3D scenes in RealityKit) stays open until the screenshots are checked and Zach has judged the frame rate on his iPhone 13.

### Goal
Stage 1 plan, Task 10: the engine in 3D, built entirely in code from its layout and parts. The opening screen shows it idling, with the crank, pistons and rods driven by the simulation. This build then goes to Zach's iPhone 13 for a frame-rate check before more is built on it.

### Added
- **`Native/App/Engine3D/HoseMesh.swift`:** a mesh builder that merges boxes, cylinders and hoses into one mesh per part group and finish (few draws). Hoses and pipes are swept along Catmull-Rom curves with twist-free frames.
- **`Native/App/Engine3D/EngineModelBuilder.swift`:**
  - Block and banks at the layout's bank angle, cut away so the pistons show. A W16 is drawn as four banks.
  - Heads and valve covers; intake plenum and runners; exhaust headers into collectors.
  - Turbo, twin turbo and intercooler with charge piping; Roots and twin-screw blowers on top, or a centrifugal one at the side, with belts.
  - Fuel rails and injectors, the fitted sensors, the wiring loom and the nitrous kit.
  - A crankshaft whose throws point each cylinder to top dead centre at its firing phase.
  - Each part group can be tapped.
- **`Native/App/Engine3D/EngineAnimationSystem.swift`:** one RealityKit `System` that turns the crank and places every piston and rod from the crank angle, using slider-crank geometry.
- **`Native/App/Engine3D/EngineViewport.swift`:** one-finger orbit (pitch held to 5-80°), pinch zoom, tap to select a part, and a VoiceOver label and hint.
- **`Native/App/Preview/LaunchRoute.swift`:** `-screen`, `-layout` and `-induction` launch arguments for UI tests and screenshots.
- **`Native/App/Theme.swift`:** every colour as a token, including the engine finishes.
- **`Native/UITests/ScreenshotUITests.swift`:** a screenshot of every layout in 3D: twin turbo on the cross-plane V8 and the W16, a Roots blower on the flat-plane V8.

### Changed
- **`Native/App/PistonForgeApp.swift`:** opens on the cross-plane V8 idling in 3D, with its name and live rpm.

### Removed
- **`Native/App/LoopTestView.swift`**, the build-loop test screen.

### Verification
- Pending the Mac run (dispatched after the Linux fix-up run goes green).

### Files Touched
- `Native/App/Engine3D/*.swift`, `Native/App/Preview/LaunchRoute.swift`, `Native/App/Theme.swift`, `Native/UITests/ScreenshotUITests.swift` (new), `Native/App/PistonForgeApp.swift`, `Native/App/LoopTestView.swift` (deleted), `CHANGELOG.md`

## 16/11/2026 @ 15:38:11 IST — "claude-opus-5-5"

**Project completion: 17.39%**
Basis: 8 of 46 items ticked in `docs/roadmap.md`. Item 14 (save file with backup and a version-migration path, tested) is newly ticked: Task 9 went green on run 43896721518 with 86 tests. Still open: the 3D engine, the screens, wiring the game, device checks and the store.

### Goal
Act on the subagent review of Tasks 3-9. It made 13 findings: 1 marked critical, 7 important, 5 minor. Each fix gets a test that fails first.

### Added
- **`ReviewFixTests.swift`**, run red first:
  - A reversed nitrous window in a save is treated as corrupt, not a crash. The reviewer called this a crash; I believe Swift's decoder throws instead, and this test settles it.
  - A failed write never loses a newer-version save, and an existing `save.newer.json` is never overwritten.
  - A tune that reads a MAF that isn't fitted warns.
  - Hitting the rev limiter isn't reported as over-revving.
  - Fitment of a non-number build doesn't trap.
  - A supercharger making more boost than the fuel can take warns.
  - Every layout × induction (both pulley ends) × three sensor sets × two fuels is either safe on the auto-base tune or already warns why not.
  - The sound's non-number guard is never hit.
- **Warnings** `mafMissing` and `boostTooHighForFuel`, and a non-number counter in `EngineVoice`, so the tests compile.

### Changed
- **`docs/roadmap.md`:** item 14 ticked. Task 9 GREEN recorded.

### Verification
- RED: run 43898492775 crashed on the non-number fitment check: "Double value cannot be converted to Int". That confirms the trap, and a crash counts as red.
- Run 43898772518: 95 of 96 tests passed. The new sweep found four I3 and I4 builds with no knock sensor (two turbo, two Roots-blown) that knocked on the auto-base tune with no warning. A follow-up commit fixes the cause:
  - The tune guessed each cell's charge temperature as if boost were proportional to load, ignoring how a hot charge holds less air.
  - It also ignored the knock that very hot intake air adds.
  - The knock sensor had been hiding both. The tune now solves for the boost behind each load and leaves room for heat knock. The turbo boost cap and the blower warning share that same "usable timing".
- GREEN: pending.

### Fixed
- **Fitment** returns "blocked" for an unmeasurable build instead of trapping.
- **Save store:**
  - Encodes before touching any file, so a failed write changes nothing.
  - Moves newer and corrupt saves aside under numbered names, and never overwrites an earlier side file.
- **Engine sound:**
  - Each synthesis buffer is allocated on its own, so the audio thread never triggers a copy-on-write allocation.
  - Counts any sample it has to silence.
- **Build warnings:**
  - A MAF tune without a MAF now says so, instead of saying "MAF maxed out".
  - A supercharger that leaves under 8° of knock-limited timing, or comes within 2 psi of the gasket's limit, warns that the blower boost is too high.
- **Rev limiter:** hitting it no longer shows "Over-revving"; the limiter state is reported separately.
- **Tests:**
  - The part-change test checks that the cam change really moves airflow by more than 5%.
  - A new test checks that a just-big-enough fuel system warns when the cams and head are raised.

### Not changed (my rulings)
- **Nitrous window decoding:** the reviewer's crash claim is tested here rather than assumed.
- **Hand-off to the audio thread:** a lock-free parameter handoff and an `@unchecked Sendable` contract on `EngineVoice` are needed. They belong to Task 12 (`AudioOutput`) and are noted there.
- **Minor findings left as they are:**
  - EGT damage counts as lean damage.
  - The flat-plane/cross-plane test reads the firing schedule rather than the rendered sound.

### Files Touched
- `Native/PistonForgeKit/Tests/PistonForgeKitTests/ReviewFixTests.swift` (new), `EngineSimTests.swift`, `Native/PistonForgeKit/Sources/PistonForgeKit/Physics/Damage.swift`, `Physics/EngineSim.swift`, `Sound/EngineVoice.swift`, `Car/Fitment.swift`, `Save/SaveStore.swift`, `docs/roadmap.md`, `CHANGELOG.md`

## 16/11/2026 @ 15:26:27 IST — "claude-opus-5-5"

**Project completion: 15.22%**
Basis: 7 of 46 items ticked in `docs/roadmap.md`, unchanged. Item 14 (save file with backup and a version-migration path) closes when this task is green.

### Goal
Stage 1 plan, Task 9: our five original car bodies, engine-bay fitment, and the save file. The save keeps a backup, recovers from a corrupt file and never overwrites a save from a newer version of the game.

### Added
- **`CarSaveTests.swift`**, run red first:
  - A W16 doesn't fit the hatch; a V8 fits the muscle car; every starter engine fits some car.
  - A blocked fit reports the worst dimension and the millimetres over (Review Focus 4).
  - The cars are sane.
  - Save and load round-trip.
  - A corrupt save falls back to the backup; corrupt save and backup reset to defaults with that status; an empty file counts as corrupt.
  - A newer-version save is left untouched and moved aside to `save.newer.json` before the first write (Review Focus 2).
  - Loaded builds are sanitised.
  - The default save opens on an assembled engine that fits its car.
- **`Car/Cars.swift`, `Car/Fitment.swift`, `Save/SaveStore.swift`.**

### Changed
- **`.gitignore`:** ignores Sideloadly's log, which it writes into the folder it was started from.

### Verification
- RED: run 43896358156 on the stubs failed the car, fitment and save assertions (52 issues).
- GREEN: run 43896721518 passed all 86 tests.

### Added (implementation)
- **Five bodies:**
  - Pocket Hatch: front-wheel drive, 1050 kg.
  - Grand Coupe: rear-wheel drive, 1350 kg.
  - Muscle: rear-wheel drive, 1550 kg.
  - Pickup: rear-wheel drive, 1850 kg.
  - Mid-engine Super: all-wheel drive, 1400 kg.

  Engine bays are sized so the small engines fit the hatch, the sixes, V10 and V12 fit the coupe, the V8s fit the muscle car, and only the Super takes the W16.
- **Save store:** atomic writes with a backup. A corrupt file is moved to `save.corrupt.json` rather than deleted. A newer-version save is moved to `save.newer.json`. There is a place for version migrations. Loaded saves are sanitised.
- **First launch:** one stock engine of every layout, opening on the cross-plane V8 in the Muscle car.

### Files Touched
- `Native/PistonForgeKit/Sources/PistonForgeKit/Car/Cars.swift`, `Car/Fitment.swift`, `Save/SaveStore.swift` (new), `Native/PistonForgeKit/Tests/PistonForgeKitTests/CarSaveTests.swift` (new), `.gitignore`, `CHANGELOG.md`

## 16/11/2026 @ 15:21:43 IST — "claude-opus-5-5"

**Project completion: 15.22%**
Basis: 7 of 46 items ticked in `docs/roadmap.md`. Item 2 (engine simulation in PistonForgeKit, tested on Linux) is newly ticked: Tasks 1-7 are green, 65 tests including the dyno. Still open: sound, cars and saving, the 3D engine, the screens, device checks and the store.

### Goal
Stage 1 plan, Task 8: the engine sound. It is generated in real time from the firing order: one pulse per cylinder firing into its own bank's exhaust, shaped by rpm, load and exhaust, plus turbo whine, supercharger whine and the nitrous hiss. Listening files come out of the Linux CI job so Zach can hear every layout long before the app exists.

### Added
- **`EngineVoiceTests.swift`**, run red first:
  - Output stays finite and within ±1 for every layout swept to redline at full boost with nitrous.
  - An I4 at 3000 rpm pulses at 100 Hz.
  - A flat-plane V8's bank fires evenly and a cross-plane bank unevenly.
  - Silence when stopped, and the sound fades after stopping.
  - Turbo whine shows in the 2-8 kHz band; load makes it louder.
  - Voice parameters come from the engine state.
  - Listening WAVs are written when `PF_WAV_DIR` is set: idle, a full-throttle run to the limiter and a lift, six seconds per layout, plus a twin-turbo, a Roots-blown and a nitrous V8.
- **`Sound/EngineVoice.swift`**, and **`Sound/WavWriter.swift`** (16-bit mono WAV).

### Changed
- **`docs/roadmap.md`:** item 2 ticked.

### Verification
- Task 7 GREEN: run 43895061504 passed all 65 tests in 12 s.
- Task 8 RED: run 43895503974 on the stubs failed the sound assertions (18 issues).
- Before porting, a Python prototype of the synthesis (scratchpad) checked the main tests:
  - An I4 at 3000 rpm pulses at 100.0 Hz.
  - At 15 psi, turbo whine is about 400× stronger in the 2-8 kHz band.
  - A V8 at full throttle peaks below 0.7.
  - Heavy load is 4× louder than light load.
- GREEN: run 43895798734 passed all 74 tests.
- The 13 WAV files were downloaded and their loudness checked second by second: idle RMS 0.02-0.05, the pull 0.14-0.28, peaks 0.38-0.62, no clipping. A follow-up changes the listening run from a free rev, which hit the limiter in under a second, to a steady three-second pull.

### Files Touched
- `Native/PistonForgeKit/Sources/PistonForgeKit/Sound/EngineVoice.swift`, `Sound/WavWriter.swift` (new), `Native/PistonForgeKit/Tests/PistonForgeKitTests/EngineVoiceTests.swift` (new), `docs/roadmap.md`, `CHANGELOG.md`

## 16/11/2026 @ 15:15:47 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`, unchanged. Item 2 (engine simulation in PistonForgeKit) closes once the dyno is green.

### Goal
Stage 1 plan, Task 7: the dyno, a live inertia-style sweep at about 400 rpm per second from 2000 rpm to the limiter. It records torque, crank and wheel power, AFR, boost, knock and EGT, and stops with the cause if the engine breaks.

### Added
- **`DynoTests.swift`**, run red first. It replaces `GoldenFixtureTests.swift` and keeps its two tests.
  - Every layout × NA, every turbo and every supercharger (fastest pulley) × with and without a 300 hp dry shot × smallest and largest injectors, with the boost target at its maximum, gives only finite numbers. Each run either completes or reports a failure (Review Focus 1).
  - The old game's street, turbo and big-block presets land within ±45% of its dyno peaks.
  - Wheel power is 15% under crank power.
  - Samples rise in rpm from about 2000 to the limiter.
  - A live run stepped at 60 fps matches a batch run within 2%.
  - The sweep runs at about 400 rpm/s.
- **`Dyno/Dyno.swift`.**

### Removed
- **`GoldenFixtureTests.swift`**, folded into `DynoTests.swift` (its deletion landed in the previous commit).

### Verification
- Run 43894457582 did not compile. Swift Testing's `#expect` macro rejects a rethrowing call written inside it, so the checks are now computed before the `#expect`. RED: run 43894749845 on the stubs failed on the assertions (330 issues), as expected.
- GREEN: run 43895061504 passed all 65 tests in 12 s.

### Added (implementation)
- **`DynoRun`:** holds the engine at 2000 rpm at full throttle for half a second, then lets it climb at 400 rpm/s and samples every 100 rpm. It ends at the limiter, on a failure or stall, or after 60 s.
  - The holding brake scales with the engine's inertia, so it stays stable at any frame rate.
  - `EngineSim.inertiaKgM2` is now public for the dyno.

### Files Touched
- `Native/PistonForgeKit/Sources/PistonForgeKit/Dyno/Dyno.swift` (new), `Physics/EngineSim.swift`, `Native/PistonForgeKit/Tests/PistonForgeKitTests/DynoTests.swift` (new), `CHANGELOG.md`

## 16/11/2026 @ 15:10:30 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`, unchanged; item 2 (engine simulation) stays open until the dyno is in.

### Goal
Stage 1 plan, Task 6: the running engine. Crank speed from torque and inertia at a fixed 480 Hz; idle control; the rev limiter; turbo spool; closed-loop fuel; damage with plain-words causes; warnings.

### Added
- **`EngineSimTests.swift`**, run red first:
  - Idle holds within 80 rpm from an I3 to a W16.
  - The limiter caps free revving within 150 rpm.
  - A lean run on boost melts a piston, gives its cause, and won't restart until repaired.
  - A 30-second step moves the engine no more than a 0.1 s step, and bad inputs stay finite (Review Focus 3).
  - A cam change never seizes the engine without a warning (Review Focus 5 and the old game's bug).
  - Riskier parts on an old tune warn that the map is out of date.
  - A blower on a stock fuel system warns that the fuel system is too small.
  - The crank angle matches rpm; a stopped engine spins down.
  - Knock warnings need a knock sensor.
- **`Physics/Damage.swift`:** failures with explanations, warnings with messages.
- **`Physics/EngineSim.swift`:** `EngineState` and `EngineSim`.

### Verification
- RED: run 43893546445 on the stubs failed the idle, limiter, failure, warning and crank assertions (23 issues).
- Run 43893830298: 58 of 59 passed. The one failure was in the test itself: Swift Testing's `#expect` mis-read a negated optional-chain expression, although the explanation text was there. A fix-up rewrites it as a plain variable.
- GREEN: run 43894162563 passed all 57 tests. The count fell by 2 because the fixture tests move to the dyno test file in the next commit.

### Files Touched
- `Native/PistonForgeKit/Sources/PistonForgeKit/Physics/EngineSim.swift`, `Physics/Damage.swift` (new), `Native/PistonForgeKit/Tests/PistonForgeKitTests/EngineSimTests.swift` (new), `Catalog/Layouts.swift` (layout table built once, because the 480 Hz loop reads it constantly), `CHANGELOG.md`

## 16/11/2026 @ 15:01:31 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`, unchanged; item 2 (engine simulation) stays open until the whole model is in.

### Goal
Stage 1 plan, Task 5: the tune (ECU map), combustion, knock and nitrous. The engine now makes torque from its air, fuel and timing; knocks when timing, boost, heat or a lean mixture push it; and takes a nitrous shot that needs fuel and less timing.

### Added
- **`CombustionTests.swift`:**
  - The auto-base map is safe (no knock, safe AFR, EGT under 950 °C) for every layout × NA, every turbo and every supercharger × every fuel, on a matched fuel system.
  - The auto-base map caps turbo boost to the installed fuel system.
  - Timing past or short of MBT loses torque, and late timing heats the exhaust.
  - The knock sensor pulls timing; with no sensor, the engine detonates.
  - A 100 hp wet shot adds 80-120 hp; a dry shot on an unchanged map detonates or runs lean; nitrous does nothing below its arming rpm or outside its throttle window.
  - Map lookup is bilinear and clamped at the edges.
  - A malformed map from a bad save never traps and is rebuilt.
- **`PublicAPITests.swift`** uses only the public interface, as the app will. Why: a missing `public` passes on Linux but breaks the Mac build much later (advisor's catch).

### Verification
- RED: run 43891959121 failed to compile, on the missing operating-point, load, MBT, nitrous and fuel-system functions, as expected.
- Run 43892681781: the compiler timed out type-checking one long arithmetic line. A fix-up commit splits the long expressions into typed steps.
- GREEN: run 43893106111 passed all 49 tests on Linux, including the full safety matrix.

### Added (implementation)
- **`Model/ECUMap.swift`:** 16 × 12 fuel and ignition tables with a bilinear, edge-clamped lookup that never traps. It also holds the boost target, rev and launch limits, fuel strategy, nitrous throttle window, dry-kit enrichment and nitrous timing retard.
  - `autoBase(for:)`: a safe tune. λ 0.86 at full throttle, richening to 0.78 on boost.
  - Timing is MBT, or 2° under the knock limit where that is lower.
  - Turbo boost is capped by knock, the head gasket and the installed fuel system.
  - Speed-density is used when the MAF would clip.
- **`Physics/Combustion.swift`:** load, MBT, the knock limit (octane, rpm, compression, boost, charge heat, nitrous), and torque from the burnt fuel × efficiency (compression, timing vs MBT, over-rich). It also gives knock with knock-sensor retard, and EGT.
- **`Physics/Nitrous.swift`:** a shot adds about 0.7 g/s of air-equivalent oxygen per rated hp; a wet kit brings its own fuel.
- **`Physics/OperatingPoint.swift`:** one chain shared by the tests, the tune, the simulation and the dyno: charge temp → airflow → load → map → fuel → combustion → friction and supercharger drag. It also holds `fuelSystemNeeds` and `withFuelSystemSized()`.
- **`chargeTempC`** (intercooler levels) and **`steadyBoostPsi`** in `Physics/Induction.swift`. The fuel heat value, gasket boost limits and intercooler cooling are in `Catalog/Parts.swift`.

### Changed
- **`EngineBuild.starter`** now loads the auto-base tune. **`sanitized()`** validates the tune (shape, finite numbers, rising axes) and rebuilds a malformed one; it no longer builds a whole starter to find fallbacks.
- **Volumetric efficiency base raised from 0.88 to 0.93**, after calibrating against the old game in a local model. The stock I4 2.0 makes about 131 hp, the V8 6.0 about 363 hp and the W16 about 506 hp. The old game's street, turbo and big-block presets come out within about 10%.
- **`deliverFuel`** takes an optional extra fuel amount (dry-nitrous enrichment through the injectors).

### Files Touched
- `Native/PistonForgeKit/Tests/PistonForgeKitTests/CombustionTests.swift`, `PublicAPITests.swift` (new), `CHANGELOG.md`
- `Native/PistonForgeKit/Sources/PistonForgeKit/Model/ECUMap.swift`, `Physics/Combustion.swift`, `Physics/Nitrous.swift`, `Physics/OperatingPoint.swift` (new), `Physics/Induction.swift`, `Physics/Breathing.swift`, `Physics/Fuel.swift`, `Catalog/Parts.swift`, `Model/EngineBuild.swift`

## 16/11/2026 @ 14:52:04 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`, unchanged.

### Goal
Act on the subagent review of Tasks 1 and 2 (layouts and the engine build). It found no critical problems, but four tests would have passed on wrong code.

### Changed
- **`LayoutTests.swift`:**
  - Every layout's firing order is now pinned, along with the V10, V12 and W16 bank assignment. Before, a swapped V12 order would have passed.
  - The crank phase of every cylinder is checked against its firing angle. Task 10 builds the 3D crank from it.
- **`EngineBuildTests.swift`:**
  - Non-numbers must fall back to the exact stock values, not just to any finite number.
  - The I4 redline is pinned at 6950 rpm.
  - A supercharged build also round-trips through save and load.
- **`GoldenFixtureTests.swift`:** also checks the cylinder count of each mapped layout.
- **`Layouts.swift`:** a comment wrongly said the odd-fire V6 uses common crank pins; it uses offset pins.
- **Task 4 entry:** GREEN result recorded.

### Verification
- These tests pin behaviour that already exists, so they are expected to pass at once; the CI result is recorded in the next entry.

### Files Touched
- `Native/PistonForgeKit/Tests/PistonForgeKitTests/LayoutTests.swift`, `EngineBuildTests.swift`, `GoldenFixtureTests.swift`, `Native/PistonForgeKit/Sources/PistonForgeKit/Catalog/Layouts.swift`, `CHANGELOG.md`

## 16/11/2026 @ 14:49:20 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`, unchanged; item 2 (engine simulation) stays open until the whole model is in.

### Goal
Stage 1 plan, Task 4: fuel delivery and the sensors that feed it, so injector size, pump size, fuel type, the MAF limit and the wideband all change how the engine runs.

### Added
- **`FuelSensorTests.swift`**, run red first:
  - Airflow rises with rpm and boost and falls with heat and a closed throttle.
  - Small injectors run out of duty and lean out at the top.
  - A MAF past its maximum clips and leans the engine on MAF strategy, but not on speed-density.
  - A wideband's correction works only when it is fitted.
  - A small pump starves a big engine.
  - E85 needs about 1.5 times the fuel mass of pump 98.
  - No input gives a non-number (Review Focus 1).
- **`Physics/Fuel.swift`, `Physics/Sensors.swift`.**
- **`airflowGps`** in `Physics/Breathing.swift`. Why: the plan has Tasks 4 and 5 consume airflow "from Task 3", but no task defined it.
- **`FuelResult.deliveredFuelGps`**, because combustion and the E85 check need the fuel mass.

### Verification
- RED: run 43889803624 on the stubs failed the airflow, MAF, injector, wideband, pump and E85 assertions.
- GREEN: run 43890036544 passed all 36 tests on Linux.

### Files Touched
- `Native/PistonForgeKit/Sources/PistonForgeKit/Physics/Fuel.swift`, `Physics/Sensors.swift` (new), `Physics/Breathing.swift`, `Native/PistonForgeKit/Tests/PistonForgeKitTests/FuelSensorTests.swift` (new), `CHANGELOG.md`

## 16/11/2026 @ 14:46:06 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`, unchanged; item 2 (engine simulation) stays open until the whole model is in.

### Goal
Stage 1 plan, Task 3: how the engine breathes. Volumetric efficiency from the head, cams, intake and exhaust, and boost from each induction type: turbo spool with lag and a wastegate, and three supercharger shapes with their drive loss.

### Added
- **`InductionTests.swift`**, run red first:
  - VE stays in 0.35-1.15 with one peak below redline, for every layout at every cam and head level.
  - Bigger cams move the peak up and lose low-rpm fill.
  - Turbos lag, and a large turbo spools later than a small one; the wastegate holds the target.
  - A Roots blower is flat, a centrifugal one rises with rpm, and a smaller pulley makes more boost.
  - Superchargers cost crank power; NA engines make no boost.
  - NaN or infinite inputs never produce a non-number (Review Focus 1).
- **`Physics/Breathing.swift`, `Physics/Induction.swift`.**

### Verification
- RED: run 43889226392 on the stubs failed the breathing and boost assertions. The NA-no-boost and finite-input guards passed on the zero stub, as they should.
- GREEN: run 43889526201 passed all 29 tests on Linux.

### Files Touched
- `Native/PistonForgeKit/Sources/PistonForgeKit/Physics/Breathing.swift`, `Physics/Induction.swift` (new), `Native/PistonForgeKit/Tests/PistonForgeKitTests/InductionTests.swift` (new), `CHANGELOG.md`

## 16/11/2026 @ 14:39:38 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`, unchanged; item 2 (engine simulation) stays open until the whole model is in.

### Goal
Stage 1 plan, Task 2: the parts catalogue and the engine build, the one record every screen, the dyno, the sound and the save file read.

### Added
- **`Catalog/Parts.swift`:** turbo sizes, supercharger types with a pulley ratio, four fuels with stoichiometry, safe AFR range, density and octane, dry and wet nitrous kits (50-300 hp), MAF sizes with a maximum airflow, the sensor set, and part levels 0-3 (Stock, Street, Sport, Race) with injector and pump sizes.
- **`Model/EngineBuild.swift`:** the build record with a stock starter per layout, `sanitized()` and the derived geometry (displacement, mean piston speed, mechanical redline, engine envelope for car fitment).
- **`Model/ECUMap.swift`:** placeholder, filled in by Task 5.
- **`EngineBuildTests.swift`**, run red first. Beyond the plan, two tests pin the first Review Focus item: `sanitized()` replaces NaN and infinity with safe values, and clamps nitrous shot, arming rpm and supercharger pulley. Why: a corrupt save or a slider bug must never feed non-numbers into the model.

### Verification
- RED: run 43888069232 on the stubs failed on the assertions (starter sizes, sanitising, envelope), as expected.
- GREEN: run 43888893361 passed all 18 tests on Linux.

### Changed
- **`.github/workflows/native.yml`:** only the Mac job cancels an older run on the same branch. Why: a quick second push was cancelling the Linux result of the first, so a commit could go untested.

### Files Touched
- `Native/PistonForgeKit/Sources/PistonForgeKit/Catalog/Parts.swift`, `Model/EngineBuild.swift`, `Model/ECUMap.swift` (new), `Native/PistonForgeKit/Tests/PistonForgeKitTests/EngineBuildTests.swift` (new), `.github/workflows/native.yml`, `CHANGELOG.md`

## 16/11/2026 @ 14:32:12 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`, unchanged. Item 2 (engine simulation in PistonForgeKit) stays open until the whole model is in. Still open: all native game code, previews, device checks and the store.

### Goal
Stage 1 plan, Task 1: the table of engine layouts the whole game reads (cylinder count, banks, bank angle, firing order, firing angles and crank pins), for I3, I4, I6, V6 60° and 90°, V8 cross-plane and flat-plane, V10, V12 and W16.

### Added
- **`Native/PistonForgeKit/Tests/PistonForgeKitTests/LayoutTests.swift`**, written first and run red against an empty stub: every layout fires each cylinder once; even intervals for all even-fire layouts; the 90° V6 alternates 90/150; the flat-plane V8 alternates banks; the cross-plane V8 has the exact L,R,R,L,R,L,L,R pattern; known firing orders; the W16 makes no manufacturer claim; bank angles.
- **`Native/PistonForgeKit/Sources/PistonForgeKit/Catalog/Layouts.swift`:** `EngineLayout` and `LayoutSpec`.

### Changed
- **`GoldenFixtureTests.swift`:** maps the old game's layout ids to the new ones and skips the rotary, which the new game drops. Why: the fixtures stay a plausibility check without forcing the old layout list back in.
- **`Native/App/LoopTestView.swift`:** reads the cylinder count from the new table (the old `EngineConfig` is gone).

### Removed
- **`Native/PistonForgeKit/Sources/PistonForgeKit/Engine.swift`**, the temporary loop-test model, replaced by the layout table.

### Verification
- RED: run 43886763674 on the empty stub failed on the layout assertions (no compile error), as expected.
- GREEN: run 43887402282 passed all 10 tests on Linux (Swift 6.1).

### Files Touched
- `Native/PistonForgeKit/Sources/PistonForgeKit/Catalog/Layouts.swift` (new), `Native/PistonForgeKit/Tests/PistonForgeKitTests/LayoutTests.swift` (new), `Native/PistonForgeKit/Tests/PistonForgeKitTests/GoldenFixtureTests.swift`, `Native/PistonForgeKit/Sources/PistonForgeKit/Engine.swift` (deleted), `Native/App/LoopTestView.swift`, `CHANGELOG.md`

## 16/11/2026 @ 14:30:56 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`, unchanged. This commit sets up the test pipeline; item 3 (UI tests drive the real loop) and item 22 (native CI green) stay open until the game exists and its runs are green. Still open: all native game code, previews, device checks and the store.

### Goal
Stage 1 plan, Task 0: split the native CI so cheap Linux tests run on every push to the work branch, while the expensive Mac job compiles once and runs UI tests on both an iPhone and an iPad simulator, only when asked or on `main`.

### Added
- **`Native/UITests/SmokeUITests.swift`:** launches the app, waits up to 20 s for text containing "Piston Forge" and saves a screenshot named `smoke-iphone` or `smoke-ipad`. Why: with no Mac, UI test screenshots are the only way to see the screens. This is the first one, and it proves the pipeline before real screens exist.
- **`Native/ci/pick_sim.py`:** picks the newest iPhone 17-class and iPad Pro 13-inch simulator, falling back to any iPhone or iPad so a runner image change doesn't break the job.
- **`Native/ci/name_attachments.py`:** renames exported screenshots to the names the tests gave them. It works loosely, because the export format on Xcode 26 is unverified (see `docs/research/2026-11-16-uitest.md`).
- **Decisions from Zach, 16/11/2026, recorded in the spec, plan and `.zb/state.json`:**
  - The main session writes the Swift; Haiku subagents review each task.
  - Fix-up commits for a plan task share that task's changelog entry.
  - An inline six (I6) joins the stage 1 layouts.

### Changed
- **`.github/workflows/native.yml`:**
  - `sim-tests` now runs on every branch push touching `Native/` and uploads any engine sound files the tests write (from Task 8).
  - The `app` job runs only on demand or on `main`, as one job, because Mac minutes cost about ten times Linux and are rounded up per job.
  - It runs `build-for-testing` once, so a compile error fails in minutes, then `test-without-building` on each simulator, exports screenshots with `xcresulttool`, and keeps the `.xcresult` on failure for diagnosis.
- **`Native/project.yml`:** adds the `PistonForgeUITests` target to the PistonForge scheme.
- **`.gitignore`:** ignores `.superpowers/`, the plan-execution ledger.

### Verification
- Pushed to `native-stage-1`; the result of the Mac run is recorded in the next entry. Neither job has been run on this commit yet.

### Files Touched
- `.github/workflows/native.yml`, `Native/project.yml`, `Native/UITests/SmokeUITests.swift` (new), `Native/ci/pick_sim.py` (new), `Native/ci/name_attachments.py` (new)
- `docs/superpowers/specs/2026-11-16-piston-forge-native-design.md`, `docs/superpowers/plans/2026-11-16-piston-forge-stage-1.md`, `.zb/state.json`, `.gitignore`, `CHANGELOG.md`

## 16/11/2026 @ 03:18:49 IST — "claude-opus-5-5"

**Project completion: 13.04%**
Basis: 6 of 46 items ticked in `docs/roadmap.md`. Item 45 is newly ticked: Zach set the direction and approved the design document. Items 1, 2, 5, 9 and 41-46 were reworded for the approved native design. Item 46 stays open: the design document is approved, but the stage 1 screen previews are not yet. Still open: all native building, testing, device checks and the store.

### Goal
Plan the native Swift rebuild properly before any game code: agree what the game is with Zach, research the hard technical questions, write a design he approves, and turn it into a step-by-step build plan checked by the advisor.

### Added
- **`docs/superpowers/specs/2026-11-16-piston-forge-native-design.md`, approved by Zach ("design approved").** Why: Zach asked to start over through planning, preview, approval and build. Zach set each part of it across the conversation:
  - **The game:** an engine tuning simulator that opens on an assembled engine. The first install has every layout (I3 to W16), turbo and three supercharger types, nitrous, a real sensor set, the dyno and generated sound.
  - **Driving:** a drag strip with ¼, ½ and 1 mile markers and a proving ground, both driven with proper simulation.
  - **Other decisions:** no career; sound plays on silent; dark-grey theme.

  The builder's own calls are marked in the document so Zach can correct them. A reviewer agent read the document as a builder would; its gaps were settled or put to Zach.
- **`docs/research/2026-11-16-{realitykit,audio,uitest,engines}.md`:** four read-only research reports from Haiku agents, with sources. Why: decisions on 3D performance, sound, testing without a Mac and engine firing data had to rest on checked facts. Findings that changed the design:
  - The Simulator has no motion data or haptics, so tilt steering and haptics sit behind stand-ins with an on-screen fallback.
  - The W16's real firing order could not be verified, so the game's W16 is generic and claims no manufacturer.
  - Mac runner minutes cost about ten times Linux.
- **`docs/superpowers/plans/2026-11-16-piston-forge-stage-1.md`:** a 15-task plan for stage 1, revised after an advisor review. The advisor's fixes:
  - A commit-and-push loop, because CI is the only compiler.
  - The Mac job compiles once and tests both simulators from that build.
  - The cross-plane V8 test pins the full bank pattern; the old version would have passed on a wrong engine.
  - The fixture test maps old layout names.
  - The fuelling strategy arrives in the task that needs it.
  - The 3D engine is built before the screen previews, so Zach approves previews that show the real engine. A frame-rate `.ipa` follows the 3D task.
  - Engine-sound WAV files come out of the cheap Linux job, so Zach can listen early.

### Changed
- **`docs/roadmap.md`:** career and economy items replaced with sandbox equivalents (no career, Zach 16/11/2026); fixtures are now plausibility ranges, not exact targets.
- **`.zb/state.json` and `.zb/events.log`:** Zach's decisions recorded as his. The events log is corrected: the design document is approved, but gate E waits on the screen previews.
- **`docs/plan/phase-e-plan.md`** marked superseded.

### Verification
- No code changed in this commit; the documents were read back after editing. The stage 1 plan has not yet been executed.

### Files Touched
- `docs/superpowers/specs/2026-11-16-piston-forge-native-design.md`, `docs/superpowers/plans/2026-11-16-piston-forge-stage-1.md`, `docs/research/2026-11-16-*.md` (new)
- `docs/roadmap.md`, `docs/plan/phase-e-plan.md`, `.zb/state.json`, `.zb/events.log`, `CHANGELOG.md`

## 16/11/2026 @ 01:58:01 IST — "claude-opus-5-5"

**Project completion: 10.87%**
Basis: 5 of 46 items ticked in `docs/roadmap.md`. The figure drops from 52.50% on purpose, for two reasons. First, the roadmap was rewritten for the native Swift app, so the web game's ticks (typecheck, smoke test, Capacitor shell, haptics, save mirroring, WebGL recovery, web CI) no longer count. Second, items 41-46 were added for five verified bugs and the design gate. Still ticked: app icon, git history, pricing model, no in-app purchase needed, funnel state. Everything about the native app is open.

### Goal
Restart Piston Forge through the full ZB funnel on Zach's instruction, and record his decisions: iOS only forever, built natively in Swift, with a dark-grey (never black) theme. Remove the Manus tooling, find out what the Manus-built game is actually worth, and set up a build loop that works without a Mac.

### Added
- **`docs/plan/phase-e-plan.md`.** Inventory of every part of the code: origin, audit verdict, keep or rewrite. Also the five bugs that decide the plan, a game brief, the cut list, the Phase E steps for an internal product, and Zach's decisions. Why: "delete everything" or "keep everything" needed evidence, and nobody had audited the Manus code itself.
- **Bugs reproduced by running the game's own code** (throwaway tests, deleted after):
  1. The career cannot pass job 3: the customer engines for jobs 4 and 5 are 116 mm and 129 mm too long for their own cars.
  2. The economy cannot be finished: jobs pay 35,200 in total, the supercar costs 48,000, and the Legend tier needs 550 rep with 485 available.
  3. The second and third cam upgrades on the old fuel map seize the engine on the next pull.
  4. A kilowatts-versus-watts mix-up pins every car's handling speed at 99 km/h.

  A fifth bug, a possible double audio start, comes from reading the code only and has not been run.
- **Golden fixtures** (`PistonForge/tests/export-fixtures.test.ts` writes `Native/PistonForgeKit/Tests/PistonForgeKitTests/Fixtures/sim-golden.json`, 18 cases). Why: the Swift port has to reproduce the model that was played and audited, number for number, until a fix changes a number on purpose. The exporter is skipped in normal test runs.
- **Native build-loop scaffold** (`Native/`):
  - A pure-Swift simulation package with the first ported formula (displacement) and a fixture test.
  - A one-screen SwiftUI + RealityKit loop-test app on the approved dark-grey theme.
  - An XcodeGen `project.yml`, so no project file is ever hand-edited.
- **`.github/workflows/native.yml`.** `swift test` runs on Linux. A macOS job builds for the Simulator, launches the app, screenshots it and builds an unsigned `.ipa`. Why: there is no Mac or Swift toolchain on this PC, so the cloud screenshot is the only way to see the screens. RealityKit was chosen over SceneKit because Apple deprecated SceneKit for new apps at WWDC 2025.

### Changed
- **Funnel moved back from Phase F to Phase E** (`.zb/state.json`, `.zb/events.log`), with Zach's decisions logged as his and the agent's readings logged separately.
- **`docs/roadmap.md`:** items 1-24 rewritten for the native app; item 1 (career unplayable past job 3) and item 33 (screenshots of an interface being replaced) unticked; items 41-46 added.
- **`docs/legal/manus-rights.md`** records that the tooling was deleted.

### Removed
- **Manus preview tooling:** `PistonForge/scripts/__manus__/`, `manus-game-sharing/`, `manus-tuning/`, the Manus Vite plugin and preview hosts, and the `manus:build-source` script. Why: Zach's instruction. The tooling is Manus's own service code, not output generated for the game, and none of it was inside the built app.
- **The `build` script name.** Why: on this 8 GB machine `pnpm build` must never run; the bundle is `pnpm build:web`, used only in CI.

### Verification
- `pnpm typecheck`: 0 errors.
- `pnpm test`: 63 passed, 1 skipped (the fixture exporter).
- `node scripts/smoke.mjs`: OK, after the tooling was removed.
- NOT verified: none of the Swift has been compiled; the native workflow runs for the first time on this push. Nothing installed on a phone yet.

### Files Touched
- `Native/**` (new), `.github/workflows/native.yml` (new), `docs/plan/phase-e-plan.md` (new), `PistonForge/tests/export-fixtures.test.ts` (new)
- `PistonForge/package.json`, `PistonForge/vite.config.ts`, `PistonForge/README.md`, `PistonForge/TODO.md`
- `docs/roadmap.md`, `docs/legal/manus-rights.md`, `.zb/state.json`, `.zb/events.log`, `.gitignore`, `CHANGELOG.md`, `.github/workflows/ios.yml` (old Capacitor build made manual-only)
- Deleted: `PistonForge/scripts/__manus__/**`, `PistonForge/scripts/manus-game-sharing/**`, `PistonForge/scripts/manus-tuning/**`

## 15/11/2026 @ 16:28:44 IST — "claude-fable-5-2"

**Project completion: 52.50%**
Basis: 21 of 40 items ticked in `docs/roadmap.md` (added 33, screenshots). Item 29 stays open on purpose: the privacy manifest half is done, but the App Privacy label can only be answered inside App Store Connect. Still open: phone UX pass, economy balance, audio pass, everything on a real iPhone, TestFlight, and the App Store Connect items that wait for the Developer Program.

### Goal
Close the three App Store compliance gaps raised in the last entry (rights to the Manus-built code, the missing privacy manifest, screenshots for every device the app targets) and settle how the game is tested on a real phone.

### Added
- **Privacy manifest** (`PistonForge/ios/App/App/PrivacyInfo.xcprivacy`, added to the Xcode project's resources). No tracking, no collected data, UserDefaults declared with reason CA92.1. Why: Apple does not accept apps that use a required-reason API without declaring it. The Preferences plugin uses `UserDefaults.standard` and ships no manifest; Capacitor core's manifest declares nothing, so the app has to. The code and its wording were confirmed from Apple's documentation, not from memory.
- **App Store screenshots from the real game** (`scripts/store-screenshots.mjs`, `pnpm store:screenshots`): 15 images in `docs/store/screenshots/`, five screens in three sets (iPhone 1320 x 2868, iPhone 1206 x 2622, iPad 2064 x 2752). The script fails if a file is the wrong pixel size or has an alpha channel. Why iPad: the project targets iPhone and iPad, and Apple requires a 13-inch iPad set for any app that runs on iPad.
- **`docs/legal/manus-rights.md`** and a dated text copy of Manus's Terms of Use. Finding: section 5.2 says the user owns the output and Manus claims no ownership; nothing read restricts App Store release. Our own risks are recorded: no warranty against third-party rights, output may not be unique, Manus trademarks must not be used, and Manus's preview tooling in `scripts/manus-*` is theirs (checked: none of it is inside the built app).

### Changed
- **Phone testing:** the Safari route is dropped on Zach's instruction, because players will run the installed app. The guide now covers only the sideloaded app, with steps quoted from Apple's and Sideloadly's own pages. It also records that TestFlight needs the paid membership (Apple's programs overview lists TestFlight as a membership resource), which corrects the assumption that it could be used for free.

### Removed
- `public/fonts/ManusCC0SansCJKSC-Regular.woff2` (943 KB). Why: the game is English only and nothing referenced the file, but it shipped inside the app.

### Verification
- `pnpm typecheck`: 0 errors. `pnpm test`: 63 of 63 passed.
- Screenshot script: exit 0 for all three sets after one real failure. The first run timed out on the iPad set (software rendering a 2064 x 2752 scene took longer than the 30 s capture limit); the limit was raised and the set recaptured. Images were opened and looked at.
- Known weak spot: the strip screenshot has the car out of frame and shows two small UI bugs (a "SPACE" key hint on a touch screen, a "READY" badge during a run). It should be redone before submission.
- The Xcode project edit is unproven until the cloud build runs; see the next entry or the run for this commit.
- NOT verified: nothing installed on a phone; the rights finding is a reading of published terms, not legal advice.

### Files Touched
- `PistonForge/ios/App/App/PrivacyInfo.xcprivacy`, `PistonForge/ios/App/App.xcodeproj/project.pbxproj`
- `PistonForge/scripts/store-screenshots.mjs`, `PistonForge/scripts/check-size.mjs`, `PistonForge/package.json`
- `docs/store/screenshots/**`, `docs/legal/manus-rights.md`, `docs/legal/manus-terms-of-use-2026-11-15.txt`
- `docs/ios-release.md`, `docs/roadmap.md`, `CHANGELOG.md`, `.zb/events.log`
- Deleted: `PistonForge/public/fonts/ManusCC0SansCJKSC-Regular.woff2`

## 15/11/2026 @ 15:42:23 IST — "claude-fable-5-2"

**Project completion: 50.00%**
Basis: 20 of 40 items ticked in `docs/roadmap.md` (added 7 and 18). Caveats on what was ticked: item 7 is a "next step" coach card, lighter than a full tutorial (it does not walk through building an engine); item 18's icon is technically valid but the mark reads a little like a clock at icon size, which is Zach's call. Still open: phone UX pass (18 audit findings logged), economy balance (12 findings logged), audio pass, everything on a real iPhone, TestFlight, and the App Store items that wait for the Developer Program.

### Goal
Get the game onto Zach's iPhone 13 without the paid Developer Program, and move the next items that need neither a phone nor an Apple account, using a four-agent workflow (Haiku agents, separate files each) with the orchestrator verifying the result.

### Added
- **Unsigned iPhone .ipa from CI** (`.github/workflows/ios.yml`). Why: TestFlight needs the paid membership, which Zach is buying later. A sideloading tool signs this build with a free Apple ID at install time, so the real app (haptics, native save) can be tested now.
- **Two phone-testing routes documented** in `docs/ios-release.md`: Safari over Wi-Fi from the dev server, and the sideloaded .ipa.
- **"Next step" coach card** for career mode (`src/sim/tutorial.ts`, rendered once in `src/ui/ui.ts`): first dyno pull, first strip run, first contract, deliver it. Derived only from existing game state, so there is no new save data to migrate. A "Tips" setting turns it off and "Hide tips" on the card does the same with a toast saying where to turn it back on. Why: a new player landed in the garage with seven tabs and no hint of what to do first.
- **App icon and launch screen** from the brand mark (`scripts/make-icons.mjs`, `pnpm icons`), replacing Capacitor's defaults. The launch screen background now matches the game so there is no white flash.
- **Store drafts** in `docs/store/`: listing (name, subtitle, 98-byte keyword field, description, captions, review notes), privacy policy with placeholders for contact details, and suggested App Store Connect answers. Drafts only; nothing entered anywhere.
- **`docs/audit-2026-11-15.md`**: 18 phone UX findings against the ZB UX standard and 12 career-economy findings, with file and line evidence.

### Fixed
- **The console sat under the notch.**
  - Cause: the page draws edge to edge (`viewport-fit=cover`) and the top bar had no top inset; only the title screen and the bottom rail used the safe-area values. Found by the audit and confirmed in `forge.css` (`.topbar{top:0}` with no inset).
  - Fix: the whole console shell is inset by the top, left and right safe areas, with the strip behind the status bar filled. In a desktop browser the insets are 0, so nothing moves.
  - Verification: smoke screenshots unchanged at desktop and phone sizes. NOT verified on a device; that is what the phone test is for.

### Verified from the audit (checked against the code, not yet fixed)
- Total contract payouts are 30,400 and starting cash is 4,800, so the 48,000 supercar can never be bought in career.
- Total reputation on offer is 485, so the Legend tier at 550 can never be reached.

### Verification
- `pnpm typecheck`: 0 errors. `pnpm test`: 4 files, 63 of 63 passed.
- `node scripts/smoke.mjs`: exit 0 on the final run (`smoke: OK (dev)`, 86 hp, 18.52 s). The run before it FAILED with a 30 s timeout while switching to the test screen; it happened while the stylesheet was being edited mid-run on a loaded machine and did not repeat. Treated as a timing stall, not proven to be one.
- iOS run 43730456447: `** BUILD SUCCEEDED **` for both the simulator and `iphoneos`; the 1.8 MB .ipa was downloaded and its contents checked.
- Icon files: 1024x1024 and 2732x2732, PNG colour type 2 (RGB, no alpha channel).
- Agents' reports were not taken on trust: file scope was checked with `git status`, and typecheck, tests and smoke were rerun by the orchestrator.
- NOT verified: the .ipa has not been installed on a phone; store copy has not been checked against the live App Store Connect forms.

### Files Touched
- `.github/workflows/ios.yml`, `.gitignore`, `CHANGELOG.md`, `.zb/events.log`
- `docs/ios-release.md`, `docs/roadmap.md`, `docs/audit-2026-11-15.md`, `docs/store/{listing,privacy-policy,app-store-connect-answers}.md`
- `PistonForge/src/sim/{tutorial,types,career,save}.ts`, `src/ui/ui.ts`, `src/ui/views/{shared,settings}.ts`, `src/styles/forge.css`, `tests/tutorial.test.ts`
- `PistonForge/scripts/make-icons.mjs`, `PistonForge/package.json`, `PistonForge/ios/App/App/Assets.xcassets/**`, `ios/App/App/Base.lproj/LaunchScreen.storyboard`

## 15/11/2026 @ 15:21:10 IST — "claude-fable-5-2"

**Project completion: 45.00%**
Basis: 18 of 40 items ticked in `docs/roadmap.md` (added 22, 23, 27, 28). Still open: tutorial, phone UX pass, balance and audio passes, app icon, everything that needs a real iPhone (17, 19, 20), TestFlight, and the App Store items that wait for the Apple Developer Program.

### Goal
Record Zach's four decisions and the first cloud build results, so the next session does not re-ask or re-prove them.

### Changed
- **Decisions by Zach (15/11/2026):** private GitHub repository; Apple Developer Program to be bought when needed, not now; bundle ID `ie.zbautomations.pistonforge` confirmed; the game is fully free for now. Why it matters: "free" removes all in-app purchase work (item 28 closed as not needed) and gives the simplest App Review; "Developer Program later" means TestFlight and any on-device check stay blocked by choice, not by a fault.
- `docs/ios-release.md`: steps 2, 3 and 5 marked done with evidence; the open-decision list is down to analytics and iPad support.
- `docs/record.md`, `.zb/state.json`: decision log and money section updated.
- `capacitor.config.ts`: comment now says the bundle ID is confirmed, not proposed.

### Verification
- **The iOS project compiles.** `iOS build` run 43681025886 on `macos-26`: Xcode 26.6, 2 Capacitor plugins found, `** BUILD SUCCEEDED **`, simulator app artifact uploaded (2.9 MB), 48 seconds. This was the unproven item in the previous entry. The `xcodebuild` flags that were marked UNVERIFIED are now proven.
- **CI is green.** Run 43681025930: typecheck, unit tests, production build (`bundle (gzip): js 0.21 MB / fonts 1.00 MB / transfer 1.22 MB`, inside budget) and the smoke test against the built bundle: `smoke: OK (preview)`, same dyno (86 hp) and drag (18.52 s) figures as locally.
- Still NOT verified: nothing has run on a real iPhone.

### Files Touched
- `CHANGELOG.md`, `docs/roadmap.md`, `docs/record.md`, `docs/ios-release.md`, `.zb/state.json`, `.zb/events.log`, `PistonForge/capacitor.config.ts`

## 15/11/2026 @ 05:23:18 IST — "claude-fable-5-2"

**Project completion: 35.00%**
Basis: 14 of 40 items ticked in `docs/roadmap.md` (1 to 6, 11 to 16, 21, 37). The honest caveat: items 12, 13 and 14 (haptics, background/resume, durable save) are ticked on unit tests only. No build has run on an iPhone yet, so "works on a device" is still unproven and is tracked separately as items 17, 19 and 20. Still open: tutorial, phone UX pass, balance and audio passes, app icon, GitHub and CI, TestFlight, and every App Store item.

### Goal
Turn the web game into something that can become an iOS app: add the native shell, the phone-specific behaviour a web page does not have, and protection for the player's save, without breaking the browser build.

### Added
- **Capacitor 8.6.2 iOS project** (`PistonForge/ios/`, `capacitor.config.ts`). Why Capacitor and not a native rewrite: the simulation, 3D scenes and UI already work, and a rewrite would discard them. Why it is committed: there is no Mac here, so the Xcode project has to be in the repo for a macOS CI runner to build it. Bundle ID `ie.zbautomations.pistonforge` is a proposal for Zach to confirm.
- **`src/platform/`: the only place the game touches the native shell.**
  - `haptics.ts`: game code asks for a cue (tap, select, shift, launch, success, warning, failure) and the module picks a strength that matches how important the event is. Small cues are throttled so a dragged slider does not buzz. Why a cue layer: game code never imports a plugin, so the browser build and the tests keep working.
  - `lifecycle.ts`: saves and suspends audio when the app is hidden, restores both on return. Why: on a phone the game is interrupted constantly; before this the engine sound had no way to stop in the background and nothing resumed it after an interruption.
  - `durableSave.ts` + `index.ts`: inside the app every save is also written to native storage and put back at boot if the web view's storage was cleared. Why: iOS is allowed to clear web-view storage, and that would silently delete a player's whole career.
- **Save file protection** (`src/sim/save.ts`): a backup copy of the last save that loaded cleanly, recovery from it when the main save is missing or corrupt, a version-migration chain, and a save from a newer build is set aside untouched. Why: the old code treated any unreadable or unknown-version save as "no save" and then overwrote it, so one bad write or one format change after launch would have wiped players' progress.
- **WebGL context recovery** (`src/game/stage.ts`). Why: phones take the GPU context away in the background; without handling, the scene comes back black.
- **Vibration setting** in Settings, on by default, saved with the other settings.
- Web-view hardening in CSS: no long-press menu, tap highlight, text zoom or rubber-band scroll.
- `tests/platform.test.ts` and `tests/save.test.ts`: 32 new unit tests.
- `docs/ios-release.md` (the path to the App Store, device checks, review risks, competitor pricing, open decisions), `docs/record.md` (project record), rewritten `PistonForge/README.md`.

### Changed
- Audio now keeps listening for touches after the first one, so sound can come back after iOS suspends it (previously the unlock listener removed itself after one use).
- `package.json`: scripts reordered around `typecheck`, `test`, `smoke`, `build:web`, `ios:sync`.

### Removed
- 21 unused files left over from the starter template's "Sky Cores" game (player, drones, world, input, physics, i18n, a 26 KB stylesheet) and the unused Rapier physics library. Why: none of it was reachable from the game's entry point (checked by walking the import graph), it shipped a second save system and a second audio system that could be mistaken for the real ones, and the README still described the wrong game. The files remain in the first commit and in the original zip.

### Verification
- `pnpm typecheck`: 0 errors.
- `pnpm test`: 3 files, 51 of 51 passed (was 19).
- `node scripts/smoke.mjs`: exit 0. `smoke: WebGL context lost and restored, scene still drawing`, `smoke: dyno pull 86 hp / 146 torque over 54 points`, `smoke: drag run valid=true et=18.52 s top=134`, `smoke: save restored after reload (pulls 1)`, `smoke: OK (dev)`. Same dyno and drag figures as before the changes, so the simulation is unchanged.
- `cap sync ios`: found both plugins and wrote `Package.swift` for iOS 15.
- NOT verified: the iOS project has never been compiled (needs a macOS runner, which needs a GitHub remote), and nothing has run on a device. No production build was run locally (8 GB machine).

### Files Touched
- `PistonForge/capacitor.config.ts`, `PistonForge/ios/**`, `PistonForge/package.json`, `PistonForge/pnpm-lock.yaml`
- `PistonForge/src/platform/{index,haptics,lifecycle,durableSave}.ts`
- `PistonForge/src/main.ts`, `src/app.ts`, `src/audio/sound.ts`, `src/game/stage.ts`, `src/sim/{save,types,career}.ts`, `src/ui/ui.ts`, `src/ui/views/settings.ts`, `src/styles/forge.css`
- `PistonForge/tests/platform.test.ts`, `PistonForge/tests/save.test.ts`, `PistonForge/scripts/smoke.mjs`, `PistonForge/README.md`
- Deleted: `PistonForge/src/engine/{assets,audio,i18n,input,physics,renderer,save}.ts`, `src/game/{camera,collectibles,config,drones,fx,game,player,rules,tuning,world}.ts`, `src/i18n/*`, `src/styles/main.css`, `src/ui/touch.ts`
- `docs/ios-release.md`, `docs/record.md`, `docs/roadmap.md`, `CHANGELOG.md`, `.zb/events.log`

## 15/11/2026 @ 05:12:06 IST — "claude-fable-5-2"

**Project completion: 15.00%**
Basis: 6 of 40 items ticked in `docs/roadmap.md` (items 1, 2, 3, 4, 21, 37). Still open: template cleanup, the whole phone shell (Capacitor, haptics, lifecycle, durable save), the GitHub/CI pipeline, and every App Store item.

### Goal
Take the Manus export of Piston Forge under version control and prove, with a real play-through, that the MVP actually works before building the iOS framework on top of it.

### Fixed
- **The game would not start on the development machine.**
  - Cause: Vite searches parent folders for a PostCSS config. An unrelated `postcss.config.js` on the Desktop (it expects Tailwind) was picked up, the stylesheet request returned HTTP 500, and the game sat on its loading screen forever.
  - Fix: `vite.config.ts` now declares its own empty PostCSS config, so the project never looks outside itself. The Desktop file was left alone because other projects may rely on it.
  - Verification: `node scripts/smoke.mjs` reaches the title screen and plays the full loop (exit 0).
- **The smoke test was testing a different game.**
  - Cause: `scripts/smoke.mjs` was still the starter template's test for "Sky Cores" (it looked for a player character, a play button and a results screen that do not exist in Piston Forge), so nothing had ever proven the Piston Forge loop end to end.
  - Fix: rewritten to play Piston Forge: title, career, garage, engine, ECU, a dyno pull, a quarter-mile run, settings, then a reload to confirm the save survives; then every screen again at iPhone portrait size (430 pt) with a check that no screen is wider than the display, and the garage in landscape. It fails on any console error, page error or failed request. It runs against the dev server by default because production builds are not run on this 8 GB machine; `SMOKE_TARGET=preview` tests a built bundle in CI.
  - Verification: `smoke: dyno pull 86 hp / 146 torque over 54 points`, `smoke: drag run valid=true et=18.52 s top=134`, `smoke: save restored after reload (pulls 1)`, `smoke: OK (dev)`; 16 screenshots written to `PistonForge/shots/` and looked at.

### Added
- Git repository at the project root, with `.gitignore` (tooling state, the original zip, build output, signing files).
- `.zb/state.json` and `.zb/events.log`: funnel state for an internal ZB Automations product (Phase F, money gates not applicable).
- `docs/roadmap.md`: the 40-item launch checklist this completion figure is counted from.
- `.github/workflows/ci.yml` and `ios.yml`: CI (typecheck, tests, production build, smoke) and an unsigned iOS Simulator build on a macOS runner. Neither has run yet: there is no GitHub remote, and the iOS project does not exist until the next commit.

### Why
The MVP arrived as a zip with no history and no evidence it ran. Building an iOS shell on an unverified base would hide problems until they are expensive. The two fixes above were found only because the loop was actually played.

### Verification
- `pnpm typecheck`: 0 errors.
- `pnpm test`: 19 of 19 passed.
- `node scripts/smoke.mjs`: exit 0 (output above).

### Files Touched
- `.gitignore`, `CHANGELOG.md`, `.zb/state.json`, `.zb/events.log`, `docs/roadmap.md`
- `.github/workflows/ci.yml`, `.github/workflows/ios.yml`
- `PistonForge/vite.config.ts`, `PistonForge/scripts/smoke.mjs`
- `PistonForge/**` (Manus export, imported as received apart from the two files above)
