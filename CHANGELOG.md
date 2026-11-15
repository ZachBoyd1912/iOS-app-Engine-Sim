# Changelog
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
