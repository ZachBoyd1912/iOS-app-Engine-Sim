# Workstream 09 — Dyno screen

**Scope:** `Native/App/Screens/DynoScreen.swift` (rewritten) and the new
`Native/App/Screens/DynoLogView.swift`. No game, kit, sound, tune or workflow files were
touched. The screen still takes the same five inputs from `RootView` (`build`, `current`,
`last`, `isPulling`, `onPull`); `preview` and `onPull` remain defaulted, so neither
`RootView.swift` nor `PreviewRoot.swift` needed a change.

CI is blocked (GitHub billing), so this has **not been compiled**. Every API used from
`PistonForgeKit` was read from source first (listed at the bottom).

---

## What each mode does

### Pull (`DynoMode.pull`, the default)

The existing behaviour, with the missing states added.

- Calls the injected `onPull()`, which is `GameStore.startPull()` in the app. `GameStore`
  creates a fresh `EngineSim`, wraps it in a `DynoRun`, and `GameStore.frame(dt:)` steps it.
  The sweep starts at 2,000 rpm, climbs at 400 rpm/s, samples every 100 rpm and ends at the
  rev limiter, at 60 s, or when the engine breaks (`DynoRun`, `PistonForgeKit/Sources/
  PistonForgeKit/Dyno/Dyno.swift:15-109`).
- The power/torque chart redraws from `current` and overlays `last` as a thin grey line.
- The four traces (AFR, boost, knock, EGT) draw from the live samples.
- **New states:**
  - The primary action is disabled (`opacity(0.45)` + `.disabled`) while `isPulling`, and
    reads "Pulling…". This is done on the screen because the shared `PrimaryButton`
    (`Components.swift:69-84`) still has no disabled appearance, and workstation rules
    forbid editing it.
  - An inline progress block appears above the button: an indeterminate spinner while the
    run settles, then a `ProgressView(value:)` with "Pulling · 4,300 rpm · 46%". Progress is
    `(last sample rpm − 2,000) / (rev limit − 2,000)`; it is an approximation because
    `DynoResult` does not carry the run's `fromRpm` (TODO below).
  - The button's supporting line states the expected duration, derived from the public
    `DynoRun.sweepRpmPerSecond` (400) and the rev limit, e.g. "About 14 s from 2000 rpm to
    the limiter at 7000 rpm."
- A finished pull is written to the log automatically (see **Logs**).

### Hold (`DynoMode.hold`)

- A target-rpm slider (`1000 … rev limit − 200`, step 100) and a "Hold at 3,500 rpm" /
  "Release the hold" primary action.
- Holding steps a **fresh local `EngineSim`** at 30 Hz on the main actor at full throttle,
  with the dyno brake applying the same proportional load `DynoRun` uses to settle its
  start speed:
  `load = max(0, torque + (rpm − target) × inertia × 2π/60 / 0.25)`
  (`Dyno.swift:75-82`, `inertiaKgM2` is public at `EngineSim.swift:119`). Moving the slider
  retargets the live servo.
- Live readouts: engine speed, torque and power (in the selected basis), AFR, boost, knock,
  exhaust temperature, oil temperature, injector duty. Warnings come from
  `EngineSim.warnings` and render through the existing `WarningBanner`.
- If the engine breaks, the hold stops but the last reading stays on screen, so the failure
  card and the numbers that caused it are still visible. "Save this point to the log" keeps
  the point explicitly; holds are not auto-logged (a moving target would spam the log).
- **Why it is view-local:** `GameStore` has no hold API (no `startHold`/`stopHold`,
  no `holdState`), and this workstream may not edit `GameStore`. The audible engine is the
  game's own idle, so **a hold is silent** and does not run the saved engine. The clean fix
  is a `GameStore` hold (see **Missing from GameStore**).
- The hold is stopped when the screen disappears, when the build changes, when a pull
  starts, or when the mode is switched back to Pull.

The two modes share the same basis, peak strip, chart, failure card and log.

---

## What the wheel/crank toggle changes

`DynoBasis` (Crank / Wheels) is a segmented picker in the "Dyno mode" card.

- **Peaks:** peak power becomes `hp` or `whp`; peak torque becomes crank Nm or wheel Nm.
- **Hold readouts:** torque and power scale; everything else (rpm, AFR, boost, knock, EGT,
  oil, duty) is unchanged.
- **Chart:** y-values scale and the y-axis label changes from "hp / Nm" to
  "whp / Nm at the wheels". The chart data shape is unchanged — the same `Point` struct,
  the same series names, the same `DynoResult.samples`; only the plotted value is scaled.
- **Log rows:** stored values stay crank; the row converts on the way out, so switching the
  toggle re-labels the whole history.
- **Power** uses `DynoSample.wheelHp`, which the kit already computes. **Torque** has no
  wheel equivalent in `DynoSample`, so the screen multiplies by `1 − 0.15` to stay
  consistent with the kit's power figure.
- The 15% is `DynoRun`'s default `drivetrainLoss`; `DynoResult` does not record the loss
  used, so the screen assumes the default. TODO is in code
  (`DynoScreen.swift:42-46`).
- AFR, boost, knock and EGT are engine-side readings, so their traces do not change.

---

## Where the logs live

- **Model:** `DynoLogEntry` (`DynoLogView.swift:9-68`) is a summary, not the samples:
  engine id/name, date, kind (pull/hold), hold target rpm, peak hp/Nm and their rpm,
  rev limit, sample count, max boost, leanest AFR, max knock, max EGT and `Failure?`.
- **Storage:** `DynoLogStore` (`DynoLogView.swift:72-103`) persists a JSON array in
  `UserDefaults` under the key `dyno.log.v1`. This is deliberate for the workstream: saving
  the log in `GameStore`/`SaveFile` would have meant editing the game. Retention is capped
  at the newest 24 runs per engine and 60 overall. Loads are sorted newest first.
- **Lifecycle:** loaded once on first appearance (not on every SwiftUI body pass, which
  matters because `RootView` re-creates the screen at frame rate during a pull). Every
  mutation saves through `.onChange(of: log)`. Previews neither read nor write the key.
- **What is written:**
  - every pull that finishes while the screen is alive — detected as `current` changing
    while `isPulling` is false (`DynoScreen.swift:106-110`), which also catches a pull that
    fails before its first sample;
  - a held point, only when the user taps "Save this point to the log".
- **Where it is shown:**
  - the "Previous runs" card lists the latest 3 for the current engine, with a
    "All N runs" `NavigationLink`;
  - `DynoLogList` (`DynoLogView.swift:185-227`) shows this engine's full history with swipe
    to delete, plus a "Show every engine" toggle;
  - "Clear this engine's log" asks for confirmation before deleting.
- **Limitation:** samples are not persisted, so a log row cannot redraw its chart or be
  loaded back as the `last` overlay. That needs the game to own a `[DynoResult]` history
  (TODO below).

---

## Other states the audit asked for

- **Empty state instead of blank charts:** when neither `current` nor `last` has samples,
  one `ContentUnavailableView` ("No pull yet" / "No pull this session") sits in the
  "Power and torque" card and the traces card is not rendered at all. The description
  adapts if the log already holds saved runs for this engine
  (`DynoScreen.swift:300-340`).
- **Failure:** the card still shows `StatusLabel(.bad)` + the plain-words `explanation`,
  and now adds the next step ("Repair the engine on the Engine tab…"). It also shows a
  hold failure, not just a pull failure.
- **Series do not rely on hue alone:** power is a solid line, torque a dashed line, the last
  pull a thin line; the legend describes each pattern, not just its colour.
- **Peaks read the last pull when there is no current one**, with a footnote saying so,
  rather than showing four dashes.

---

## File:line map

### `Native/App/Screens/DynoScreen.swift`

| Lines | What |
|---|---|
| 6-26 | `DynoMode` (Pull / Hold) + the explanation shown under the picker |
| 29-59 | `DynoBasis` (Crank / Wheels), 15% loss, units, axis label |
| 64-86 | `DynoScreen` inputs, state (`mode`, `basis`, `hold`, `log`), chart `Point` |
| 88-138 | Body, mode/action/failure/hold/peaks/chart/log order, `onChange` wiring |
| 140-171 | `modeCard`: mode picker and wheel/crank picker |
| 174-212 | `actionArea`: pull and hold primary actions, disabled + explanation |
| 214-238 | `pullProgress`: indeterminate settle then determinate sweep |
| 242-256 | `failureCard`: pull or hold failure with next step |
| 260-290 | `peaks`: power, torque, power rpm in the selected basis |
| 300-340 | `chartSection`: chart + legend, or `ContentUnavailableView`; traces only with data |
| 342-380 | `points` + `powerChart` (values scaled by basis; series shape unchanged) |
| 382-403 | `legend` + `legendRow` |
| 405-417 | `trace` (unchanged shape, now from `currentSamples`) |
| 430-492 | `holdCard`: target slider, nine live readouts, warnings, save point |
| 494-508 | `canPull`, `canHold`, progress fraction, duration estimate |
| 511-517 | `logSection` |
| 519-577 | `DynoHold`: fresh sim, 30 Hz main-actor servo, start/stop/clamp |

### `Native/App/Screens/DynoLogView.swift`

| Lines | What |
|---|---|
| 9-68 | `DynoLogEntry` + pull/hold initialisers |
| 72-103 | `DynoLogStore` (UserDefaults key, load/save, retention) |
| 106-182 | `DynoLogView` card: latest 3, "All N runs", clear with confirmation |
| 185-227 | `DynoLogList`: full history, all-engines toggle, swipe delete |
| 230-284 | `DynoLogRow`: kind, date, converted peaks, failure or worst AFR/boost |

---

## Missing from GameStore (would have removed the workarounds)

1. **A hold API.** Needed: `startHold(rpm:)`, `stopHold()`, `isHolding`, `holdState`
   and the hold driven by the real `GameStore.frame` loop so sound follows it, the saved
   engine is the one held, and the dyno brake load is not duplicated in a view. Today
   `DynoHold` owns a second `EngineSim` and runs alongside the game's 60 Hz loop.
2. **A pull history.** Needed: `pullHistory: [DynoResult]` (persisted, per build) or at
   least the ability to promote a logged run back to `lastPull`. Today `GameStore` keeps
   only `currentPull` + `lastPull` (`GameStore.swift:26-28`), which is why the log is a
   summary in `UserDefaults` and cannot redraw a saved run.
3. **Run provenance on `DynoResult`.** The screen hard-codes `fromRpm = 2000` and
   `drivetrainLoss = 0.15`. `DynoRun` has both (`Dyno.swift:24-26, 36-39`) but the result
   loses them. Add `fromRpm` and `drivetrainLoss` to `DynoResult` (or expose the run).
4. **A run identity/timestamp.** `GameStore` has no run id, so auto-logging keys off
   `current` changing while not pulling. It is correct today but a `DynoRun.id` would make
   "log this run exactly once" explicit.
5. **A failure affordance.** The failure card tells the user to repair on the Engine tab
   because `repair()` is not passed into `DynoScreen`; a `onRepair` closure would let the
   card fix the engine in place.
6. **Nitrous arming in the live pull.** `GameStore.startPull` does not set
   `pullSim.nitrousArmed`; `runDynoToEnd` does (`Dyno.swift:114-117`). The live pull and
   this screen's hold therefore both read without nitrous, consistently — but a nitrous
   build reads lower than the batch/preview result. Not changed here.

---

## Verification (for when CI is back)

1. Build and open the Dyno tab: no pull yet → one `ContentUnavailableView`, no empty traces,
   the "Start pull" action near the top (not buried under the charts).
2. Pull: button disabled and dimmed, progress goes 0→100%, peaks/traces fill, and exactly
   one "Pull" row appears in "Previous runs" when it ends.
3. Switch to Wheels: peaks, chart axis, hold readouts and log rows all re-label together.
4. Hold: slide to 4,000 rpm, tap Hold → rpm settles near 4,000; move the slider → the hold
   follows; Release clears the reading; "Save this point" adds one "Hold" row.
5. Kill the engine on a lean tune: the failure card names the failure and the next step;
   switch engine in Garage and back: the hold stops and the log is filtered per engine.
6. Leave and reopen the tab: the log is still there (loaded once), the chart is the empty
   state with "No pull this session".
7. VoiceOver: the mode/basis pickers, the disabled action, all readouts and every log row
   read as complete elements; the chart is described by the legend text.

Accessibility identifiers kept: `screen.dyno`, `button.pull`, `chart.dyno`, `label.peakHp`,
`card.failure`. New: `picker.dynoMode`, `picker.dynoBasis`, `button.hold`,
`slider.holdRpm`, `button.logHold`, `card.hold`, `card.dynoLog`, `state.dynoEmpty`.

## Kit surface relied on (all read, not guessed)

`DynoResult`/`DynoSample` including `wheelHp` (`Dyno.swift:4-13`), `DynoRun.sweepRpmPerSecond`
(`Dyno.swift:19`), `EngineSim.inertiaKgM2` (`EngineSim.swift:119`), `EngineSim.start/step`
(`EngineSim.swift:79, 103`), `EngineState` fields (`EngineSim.swift:4-29`), `ECUMap.revLimit`
(`ECUMap.swift:20`), `Failure.explanation/title` (`Damage.swift:8-21`,
`Components.swift:213-224`), `Warning` (`Damage.swift:25-53`), `EngineBuild`
(`EngineBuild.swift:4-25`).
