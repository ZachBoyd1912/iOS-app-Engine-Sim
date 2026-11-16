# Changelog
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
- GREEN: pending the run on the implementation commit.

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
