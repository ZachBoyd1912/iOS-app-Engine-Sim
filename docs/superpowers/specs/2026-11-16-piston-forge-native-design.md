# Piston Forge (native Swift): design

Status: APPROVED by Zach 16/11/2026 ("design approved"). Screen previews still need approval per stage. Supersedes `docs/plan/phase-e-plan.md`
(which planned around the web game). Funnel: Phase E; the design gate passes only on Zach's
written approval of this document and, later, of the screen previews.

Marked **[Zach]** = decided by Zach. Marked **[call]** = the builder's call, open to correction.

## 1. Intent

An engine tuning simulator for iPhone and iPad **[Zach]**. You open the app and an engine is
sitting there, fully assembled, every hose, wire and sensor hooked up, ready to start. You
change the engine, run it on the dyno, read what changed, change it again. When it is the
engine you want, you put it in a car and drive it: down a drag strip or around a proving
ground.

The point is the tinkering. The engine is the star; the driving is the proof.

## 2. Goals, non-goals, anti-goals

**Goals**
- The first screen is a running-ready engine, not a menu **[Zach]**.
- Wide build choice: I3, I4, V6, V8, V10, V12, W16; 60° and 90° V angles; flat-plane and
  cross-plane cranks; naturally aspirated, turbo, supercharger; big injectors; nitrous;
  sensors (MAF, injector and others) that actually change how the engine runs **[Zach]**.
- A dyno for testing, modifying and upgrading **[Zach]**.
- Put the engine in a car and drive it with proper simulation: tyre grip and slip, weight
  transfer, wheelspin, clutch and gears **[Zach]**.
- A drag strip with quarter, half and full mile variants, markers at each, and distance
  markers the whole way **[Zach]**. A flat open proving ground with a straight, corners,
  skidpads and a chase camera **[Zach]**.
- Engine sound generated from the engine itself, so layout, firing order and crank type are
  audible **[call]**.

**Non-goals (v1)**
- No career, money, jobs or unlocks: a sandbox with everything open **[Zach]**.
- No open-world roads **[Zach, "for now"]**.
- No soft-body crash damage **[call: not feasible on a phone]**.
- No online features, accounts, ads or purchases (the game is free) **[Zach, 15/11]**.
- No Android, no web version, ever **[Zach]**.

**Anti-goals (it fails even if it works if...)**
- The engine feels like a spreadsheet: changes that do not show on the dyno, in the sound or
  on the strip.
- Physics that contradicts car people's intuition (a turbo with no lag, a flat-plane V8 that
  sounds like a cross-plane, a lean engine that does not suffer).
- Stutter on an iPhone 13.
- Real brands, real car designs, logos or recordings (original only, App Store and rights).

## 3. Constraints

- **Native Swift only**, SwiftUI + Apple frameworks, iOS 18 minimum (iPhone 13 runs iOS 26)
  **[Zach: Swift only; call: iOS 18 for RealityKit's non-AR view]**.
- **No Mac.** Everything Apple-side builds on GitHub Actions `macos-26` (Xcode 26). The
  simulation and sound maths must compile and test on Linux too.
- **Seeing screens** = Simulator screenshots from CI. **Feel** (sound, steering, frame rate,
  haptics) is proven only on Zach's phone via a sideloaded `.ipa` (free Apple ID, 7-day expiry).
- macOS runner minutes are limited on a private repo: macOS jobs run only when the app changes.
- Theme: dark only, dark grey (never black) with game-colour hues in the background **[Zach]**.
- ZB UX standard, iOS-adapted **[Zach approved 16/11]**: previews are SwiftUI screens as
  Simulator screenshots at 430 pt phone, 1032 pt iPad and landscape phone; Xcode's
  accessibility audit replaces axe; 44 pt hit areas; status never colour alone.
- App Store: privacy manifest, no tracking, no data collected; original assets only.

## 4. Approaches considered

**How it is built**
1. **SwiftUI + RealityKit, with our own engine and vehicle physics in a pure-Swift package.**
   RealityKit only draws; the physics positions the models. Chosen **[call]**: testable on Linux,
   deterministic, and the tyre/engine model is the product so we must own it.
2. SceneKit with its built-in vehicle physics: rejected, Apple deprecated SceneKit for new apps
   (WWDC 2025), and its vehicle model is a black box we could not tune or test.
3. A game engine (Unity, Godot): rejected, breaks the Swift-only decision.
4. A custom Metal renderer: rejected, months of work for no visible gain at this art level.

**Build order** (each stage ends with an `.ipa` on Zach's phone) **[Zach chose]**
1. Engine view, parts, dyno, engine sound.
2. Drag strip.
3. Proving ground.
Rejected order: driving first. The driving is only as good as the engine under it.

## 5. The game

### 5.1 Screens **[call]**

```
┌──────────────────────────┐   Home = the Engine screen
│ Forge 2.0 · I4 NA   [⚙] │   - 3D engine fills the screen, turn with one finger, pinch zoom
│                          │   - tap a part (turbo, injectors, MAF...) → its options sheet
│      [ 3D ENGINE ]       │   - START button: engine runs in place, rev with a slider
│                          │   - live strip: rpm · hp · AFR · boost
│ rpm 950  AFR 14.7  0 psi │
│ [START] [Parts] [Tune]   │
│ [Dyno]  [Car]   [Drive]  │
└──────────────────────────┘
```
- **Engine** (home): above. A saved-builds garage sits behind the title (name, duplicate,
  delete).
- **Parts**: grouped by system (block & crank, head & cams, induction, fuel, ignition,
  sensors, nitrous, exhaust, cooling). Each option shows what it changes in plain words.
- **Tune** (ECU): fuel and ignition tables, boost target, rev limit, launch control, nitrous
  activation, fuelling strategy (MAF or speed-density). Includes an "auto-base map" button.
- **Dyno**: engine in the dyno cell; a pull draws power and torque live with AFR, boost,
  knock and EGT traces; the last pull is overlaid; crank and wheel figures.
- **Car**: pick a car body, see whether the engine fits the bay, choose gearbox, final drive,
  tyres, drivetrain.
- **Drive**: choose drag strip (¼, ½, 1 mile) or proving ground.
- **Settings**: units (imperial/metric), controls (tilt or touch steering, auto or manual
  gears), sound, haptics, reset.

### 5.2 Engine model **[call, ranges from research]**

- **Layouts**: I3, I4, V6 60° and 90°, V8 cross-plane and flat-plane, V10, V12 60°, W16. Each
  carries cylinder count, bank angles, crank pin layout, firing order and firing intervals.
  These drive the model's pulse timing, the 3D crank animation and the sound.
- **Geometry**: bore, stroke, compression, rod ratio within safe ranges per layout;
  displacement, mean piston speed and a mechanical redline follow.
- **Breathing**: volumetric efficiency curve from head, cams, intake and exhaust; induction
  adds boost:
  - turbo: spool from exhaust energy, lag, wastegate, boost target.
  - supercharger: roots, twin-screw or centrifugal, each with its own boost-vs-rpm shape and
    parasitic loss.
- **Fuel**: injector size (cc/min) and fuel pump capacity cap fuel flow; duty cycle above about
  80-85% runs out of headroom and the engine leans out at the top. Fuel type (pump 95/98, E85,
  race fuel) changes energy, knock resistance and required flow.
- **Sensors (they matter)**: MAF (has a maximum airflow; past it the reading clips and the
  engine runs lean unless you switch to speed-density), MAP, intake air temperature, wideband
  O2 (closed-loop correction), knock sensor (pulls timing), EGT, oil pressure and temperature.
  Removing or downgrading a sensor removes its protection.
- **Ignition**: timing table vs MBT and the knock limit (fuel, boost, charge temperature).
- **Nitrous**: dry or wet kit, shot size (e.g. 50-300 hp), activation rpm and throttle window;
  adds power and cylinder pressure; needs extra fuel and less timing or it detonates.
- **Damage**: lean running, knock, over-boost and over-rev wear or break parts with clear
  causes shown after the pull. Repairs are free (no money), but a broken engine stops the run.
- **Design rule:** every parameter visible on the dyno, in the sound or on the strip; no hidden
  stats.

### 5.3 Sound **[call]**
Synthesised in real time from the engine state: one pulse per cylinder firing, timed by the
firing order and crank angles, shaped by load, rpm, exhaust and induction (turbo whistle and
flutter, supercharger whine, nitrous hit). The synthesis maths lives in the Swift package; the
app only feeds samples to the audio output. **Plays with the ringer switch on silent [Zach]** (`.playback` category, mixing with other audio off by default); only the volume buttons and the in-game sound toggle mute it. No background audio: sound stops when the app leaves the screen.

### 5.4 Cars **[call]**
Five original bodies, no real designs: hatch (FWD), coupe (RWD), muscle (RWD), pickup (RWD),
super (AWD). Each has an engine bay size; an engine that does not fit cannot be installed, and
the car screen says why and by how much. Gearbox (5- or 6-speed manual, 6-speed sequential,
8-speed auto), final drive, tyre compound and width, drivetrain.

### 5.5 Vehicle physics **[Zach: proper sim; details call]**
Fixed-step simulation (~240 Hz) in the Swift package. Engine torque → clutch → gearbox →
differential → driven wheels. Tyres with a slip-based grip model (longitudinal and lateral),
load sensitivity and combined slip; weight transfer under acceleration, braking and cornering;
aerodynamic drag and rolling resistance; launch control from the ECU. Rendering reads the
latest state at screen rate.

### 5.6 Drag strip **[Zach]**
A straight strip on the flat ground. Run length chosen before the run: ¼ mile (402.3 m), ½ mile
(804.7 m), 1 mile (1609.3 m). Finish gantry at each length. Distance boards the whole way up,
every 100 ft, with 60 ft, 330 ft, ⅛, ¼, ½ and 1 mile highlighted **[board spacing: call]**. A
Christmas tree start with reaction time. Timeslip: reaction, 60 ft, 330 ft, ⅛ (time + trap), ¼
(time + trap), and ½ and 1 mile when run, plus peak speed.

### 5.7 Proving ground **[Zach]**
A large flat open area with a grid-textured surface (our own design), a long straight, a set of
corners marked with cones and lines, and two skidpads (constant-radius circles) with a lateral-g
readout. Chase camera **[Zach]**.

### 5.8 Controls **[call]**
On-screen throttle and brake pedals in the bottom corners; steering by tilting the phone, with
an on-screen steering option; shift paddles in manual mode; automatic mode available.
Haptics on gear changes, the limiter, wheelspin and the launch.

### 5.9 Saving **[call]**
Builds and settings saved locally as a versioned JSON file with a backup copy and a migration
path. No cloud, no account.

## 6. Testing and delivery

- **Swift package tests** (Linux and Mac): engine model, sensors, fuelling, nitrous, damage,
  dyno sweep, vehicle physics, drag timing, sound synthesis output checks. Old web-game results
  are only plausibility ranges, not exact targets.
- **UI tests on the macOS runner**: launch into named states with sample data; screenshots at
  the approved sizes; Xcode's accessibility audit.
- **Every stage ends with an unsigned `.ipa`**, copied to `builds/` and installed by Zach. What
  CI cannot prove is listed per stage.

| Stage | Done when (CI) | Only Zach's phone can prove |
|---|---|---|
| 1 Engine + dyno + sound, **everything at once [Zach]**: all seven layouts (I3, I4, V6 60°/90°, V8 cross/flat-plane, V10, V12, W16), NA/turbo/all three supercharger types, nitrous, the full sensor set, full tune screen | Tests green for every layout and part; screenshots of engine, parts, tune, dyno, car; audit clean; `.ipa` built | Sound quality, frame rate, touch feel |
| 2 Drag strip | Drag physics tests (times in sensible ranges per build); strip screenshots with markers; `.ipa` | Launch and shift feel, tilt, haptics |
| 3 Proving ground | Handling tests (skidpad g, cornering); screenshots; `.ipa` | Steering feel, camera, frame rate |

## 6b. Delivery rules **[call]**

- **Stage flow:** engine and physics code starts once this document is approved; screen code
  starts once that stage's previews are approved. The next stage starts when the current one
  is green in CI and its `.ipa` is delivered. Zach's phone verdict feeds back as fixes into
  the following stage, not as a blocker. Tuned constants live in one place so feel changes
  are cheap.
- **Frame rate:** 60 fps target on iPhone 13 and iPad in every 3D scene; 120 Hz not targeted.
  Physics runs at a fixed rate separate from rendering. A quality setting (standard / low)
  exists in Settings for heat and battery.
- **3D models:** made in code from RealityKit primitives and generated meshes (blocks, heads,
  pipes, hoses swept along curves, wheels, simple car bodies). No bought, downloaded or
  AI-generated models, so the "original only" rule holds and nothing needs a Mac tool.
- **Orientation:** Engine, Parts, Tune, Dyno and Car work in portrait and landscape; Drive is
  landscape only, which suits tilt steering and pedals.
- **Sound acceptance:** CI checks timing and firing order in the synthesised signal; Zach's ear
  is the judge of quality, per stage.
- **Devices:** iPhone 13 and newer, iPads that run iOS 18.

## 6c. What the research changed (full reports in `docs/research/2026-11-16-*.md`)

- **3D:** one RealityKit `System` reads the simulation state and moves the few moving parts;
  static parts are merged into few meshes per material; hoses built once with `MeshDescriptor`
  (moving ones use a pre-allocated `LowLevelMesh`, never rebuilt per frame); drag-strip boards
  and ground markings baked into one mesh, not one entity each. Frame rate is proven on the
  phone; Apple publishes no per-frame budget.
- **Sound:** `AVAudioSourceNode` real-time synthesis, maths in the Swift package; offline
  rendering (manual rendering mode) lets the Mac CI render a WAV and check it. Audio session
  category is `.playback` (Zach: sound plays on silent).
- **Testing:** the Simulator gives no motion data and no haptics, so tilt steering and haptics
  sit behind protocols with test fakes, and tilt falls back to on-screen steering. UI tests
  launch straight into named screens with sample data; screenshots come out of the test
  results; Xcode's accessibility audit runs per screen. The runner may not have an iOS 18
  Simulator; tests run on the newest available iOS.
- **Engines:** firing intervals and orders for I3 to V12 are well documented. The W16's real
  firing order and balance could not be verified (sources conflict), so the game's W16 is
  modelled as a generic 16-cylinder W with even 45° firing and our own firing order. It does
  not claim to be any manufacturer's engine **[call]**. Nitrous, injector and boost figures use
  the researched rules of thumb, tuned for feel.
- **Cost:** macOS runner minutes are billed around 10x Linux per minute and rounded up per job,
  so the app job runs only on app changes and tests are grouped into one macOS job.

## 7. Left to the builder

Exact formulas and constants (within researched ranges), code structure, the art level of the
3D models within the frame-rate budget, the exact screen layouts (subject to preview approval),
the car bodies' specs.

## 8. Old code

The web game in `PistonForge/` and its CI stay as reference until stage 1 ships; then they are
deleted (Zach approved deleting what Manus built). The golden fixtures stay as plausibility
checks.
