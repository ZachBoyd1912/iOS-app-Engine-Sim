# Piston Forge v2: design update (engine-sim sound, big catalogue, generated 3D, portrait cockpit)

Status: DRAFT for Zach's approval, 18/11/2026. This **amends** `2026-11-16-piston-forge-native-design.md`.
Where the two disagree, this one wins; everything not mentioned here stands (iOS only, Swift only, dark
theme, free, no real brands, built only in GitHub Actions, no career in v1).

Marked **[Zach]** = decided by Zach. **[call]** = the builder's call, open to correction.

## 1. Why this changes

Zach rejected the stage 1 previews (17/11): the landscape layouts wasted the width, the game "is clearly
very rudimentary", the sound "sounds like trash", and the game must be as deep as RevLab, Engine Simulator
and Tuning Simulator. Research (`docs/research/raw/`) and a working sound test (18/11) now give us what we
needed. Zach's verdict on the test: the engine-sim sound is "perfect... tones, rumbles, cylinders",
and "could probably sound a little bit more realistic".

## 2. Goals, non-goals, anti-goals (changes only)

**Goals**
- **Sound is engine-sim** (AngeTheGreat, MIT) **[Zach]**: real cylinder firing, exhaust and intake acoustics.
- **The largest engine list we can source** (RevLab has 21) **[Zach]**; far above 21 is the target. Every
  engine has correct timing and firing order, internals and externals, at every rpm **[Zach]**.
- **Every engine fully 3D**: moving pistons, rods, crank, valves and rockers, and exhaust parts that glow
  with heat under load **[Zach]**.
- **The largest gearbox list and Comfort / Eco / Sport / Sport+ drive modes** **[Zach]**; gearboxes:
  5-speed and 6-speed manual, 6-speed sequential, 7-speed dual-clutch, 8-speed automatic **[Zach]**.
- **Exhaust choices that change tone and power**, rev limiters, pops and the rest **[Zach]**.
- **Portrait is the default and preferred; landscape is allowed [Zach]**, and the garage/tune side takes
  Tuning Simulator's density (icon rail, gauges, tiles, ECU grids, dyno sheet) fitted to portrait **[Zach]**.

**Non-goals (unchanged or new)**
- Career: later, not v1 **[Zach, 18/11]**.
- Copying any reference game's look, art or text; we take depth and conventions only **[Zach, call]**.
- Shipping upstream engine-sim's engine scripts or exhaust recordings (licence unstated) **[Zach: "write our own"]**.

**Anti-goals (new)**
- A sound that does not match the dyno: if the tune changes, the sound changes.
- A different look per engine because models came from different artists.
- Overheating the phone: sustained audio plus 3D must stay cool enough to play for 20 minutes.

## 3. Approaches considered

**Sound**
1. **engine-sim as the sound engine, our Swift model keeps the numbers [call, recommended].** Proven to
   build and render on iPhone-class chips (spike, section 8). Risk: two physics models must agree.
2. engine-sim as the single authority (rewrite our dyno on it). Rejected for now: it has no torque input,
   no turbo or nitrous, and our tested model (96 tests) would be thrown away.
3. enginesound (Rust pipe model) in Swift. Fallback only if engine-sim cannot hold a W16 on the phone.
4. Recordings per engine. Rejected: cannot follow exhaust or tune changes.

**3D engines [Zach agreed 18/11]**
1. **One consistent kit generated from the catalogue [call, recommended]**: pistons, rods, crank, cams,
   valves, rockers, heads, manifolds, turbos and blowers assembled per engine by script. Free, consistent,
   legally clean, covers every layout.
2. Internet models per layout. Rejected: no usable free model exists for I3, I5, I6, V10, W12, W16, VR6,
   flat-8, a clean flat-4/flat-6, wastegate or blow-off valve; about 30 artists would give 30 looks; most
   are 50k to 2M triangles (phone budget ~150k).
3. Paid artist. Open later if the generated look is not good enough; Zach's money, Zach's call.

## 4. The design

### 4.1 One engine catalogue drives everything **[call]**
A single data file per engine (cylinders, banks, bank angle, crank pin phases, firing order, bore/stroke
ranges, valvetrain, valves per cylinder, redline range, allowed aspiration, character) is the only source.
A generator produces from it: (a) the engine-sim script, (b) the 3D engine, (c) `PistonForgeKit`'s
`LayoutSpec`, (d) the firing-order timeline in the UI. So the sound, the model, the animation and the
timeline cannot disagree. Firing orders missing from the research are **derived** from the crank phases
and checked by tests (even spacing where the engine is even-fire, total 720 degrees, every cylinder once);
any that cannot be derived are marked "unverified" and held back.

**Engine list [call]:** from `docs/research/raw/engines.md` (83 rows, about 60 distinct designs):
inline 1 to 8 (incl. I3, I5, I6), V2 (45/60/75/90), V4, V6 (60/75/90, even and odd fire), V8 (cross, flat,
60/75), V10 (72/90), V12 (60/65), V16, flat 2/4/6/8/12, W8/W12/W16/W18, VR5/VR6, rotary 1/2/3-rotor, radial
5/7/9, two-stroke, diesel I4/I6/V8, motorcycle twins/triples/fours. They ship in tiers: tier 1 (verified
orders, in the first sound stage), later tiers as orders are verified or derived. The game never shows
real engine or car brand names; real engines appear only as reference in the data.

### 4.2 Sound **[call, details open]**
- **Core:** engine-sim's sound core as static libraries (`scs`, `piranha`, `enginesim_core`) plus a small
  C bridge (`esim_bridge`), built in CI for iPhone arm64. Source: pinned upstream commit `85f7c3b` plus the
  patch set from the spike (`Native/EngineSimSpike/prepare.sh`), kept as a committed patch series so
  builds do not depend on editing upstream at build time. MIT notices go in the in-app licence screen.
- **Our engines and exhausts:** engine scripts are generated from the catalogue (4.1); exhaust sound uses
  **our own generated impulse responses** shaped by the exhaust parts (header length and type, pipe
  diameter, cat, resonator, muffler type, single/dual, H or X pipe). Upstream's recordings are never shipped.
- **Who owns what:** `PistonForgeKit` owns power, torque, AFR, knock, damage. engine-sim is run in dyno-hold
  at our rpm with our throttle, ignition advance and mixture mapped into its parameters, so timbre follows
  load. If sound and dyno visibly disagree, the first fix is the mapping, not a second physics model.
- **Extras engine-sim lacks (built by us, layered or patched):** rev limiter styles (fuel cut, ignition cut
  with bangs, soft), launch control and flat-shift, anti-lag, overrun pops and crackles (off/mild/
  aggressive), turbo spool, blow-off and wastegate, supercharger whine, nitrous hiss, starter crank,
  listening positions (exhaust, bay, cabin). Pops and forced-induction sound are **not yet proven**; the
  first stage that needs each builds a small test like the spike did.
- **Phone budget [call]:** quality tiers (simulation frequency, impulse-response length) chosen per device and
  lowered if the phone's thermal state rises; target 20 minutes without "serious" heat. Measured by the
  phone test app before the tiers are finalised.

### 4.3 3D engine kit **[call]**
Blender runs headless on a free Linux CI job. A script builds the parts from the catalogue (about 40 part
types: block, crank, rods, pistons, heads, cams, valves, springs, rockers/followers/pushrods, timing drive,
manifolds, throttle bodies, turbos, blowers, intercooler, headers by type, cats, resonators, mufflers,
injectors, sensors, wiring, nitrous) and exports USDZ with named nodes, merged where static and separate
where moving. One crank angle drives every moving part; exhaust parts take an emissive glow from
exhaust temperature. Budget about 150k triangles per engine on screen. Two views: assembled, and an
X-ray cutaway showing combustion chambers lighting as each cylinder fires. Looks are our own.

### 4.4 Transmissions, cars, drive modes **[call, numbers from research]**
- Gearboxes: 5-speed and 6-speed manual, 6-speed sequential, 7-speed dual-clutch, 8-speed torque-converter
  automatic **[Zach]**; generic names only. Later candidates from the research: 4-speed and 10-speed
  automatics, CVT, single-speed EV. Ratios use sourced sets from `gearbox-ratios-2.md` where they exist,
  otherwise clearly game-tuned.
- Drive modes **Comfort, Eco, Sport, Sport+** (later Track, Launch, Snow) change throttle map, shift
  points, shift speed, torque limits and traction control. Manufacturers do not publish these numbers, so
  they are our design, tuned by feel.
- Cars: the five bodies grow to about 15 body types (research: weights, Cd, wheelbase sourced for many;
  frontal area and bay size are our estimates). Tyre model from the sourced Pacejka sets.

### 4.5 Portrait-first cockpit **[Zach direction; layout call]**
Five bottom tabs (the sidebar of the reference becomes a tab bar): **Engine, Tune, Dyno, Garage, Drive**;
Logs, Learn and Settings sit under "More". Engine: 3D stage with tach and boost overlaid, wideband AFR bar,
a 2x3 block of live tiles, a throttle slider and a row of Free/Hold/Pull plus START/STOP in the thumb zone.
Tune: full ECU tables (fuel, lambda, ignition, boost, warm-up, cranking, acceleration enrichment, knock,
dwell, wastegate duty) as pinned-header grids and a 3D surface, with row and column pickers, numeric entry
and paint-by-drag; a bottom sheet with peek/half/full detents. Dyno: chart with metric tabs and a stacked
sub-pane, hold and pull modes, logs. Garage: engine, parts and compare in two-column cards. Drive:
gearbox, drive mode picker, shifter and pedals. Landscape reuses the Tuning Simulator-style layout (left
rail, right control rail, wide centre). All at 44 pt targets, Dynamic Type and status never by colour alone.

## 5. Staging (replaces the old stage 1 definition) **[call; each ends with an .ipa on Zach's phone]**
1. **Sound and Engine screen:** engine-sim in the app, catalogue tier 1, generator, portrait Engine
   screen with the existing 3D as placeholder, START/crank/rev/hold, exhaust choice, limiter.
2. **3D kit:** generated engines with moving parts, X-ray cutaway and heat glow.
3. **Tune and Dyno depth:** ECU tables, logs, Hold/Pull dyno, fault codes.
4. **Garage, gearboxes and drive modes:** cars, transmissions, Comfort/Eco/Sport/Sport+.
5. **Drag strip.** 6. **Proving ground.** (As before.)
The old stage 1 code (model, dyno, saves, screens) is kept where it fits; the screens are rebuilt.

## 6. Testing and delivery
Linux `swift test` for the model and catalogue generator (including firing-order invariants); a Linux job
renders engine-sim audio for each catalogue engine and checks it is non-silent and stable; macOS job
builds the iPhone libraries, the app, screenshots and the `.ipa`. Feel (sound quality, heat, frame rate)
is proven only on Zach's phone with a test build, as in the spike.

## 7. Left to the builder
Names of drive modes beyond the four, exact tile set, part prices (none: no money), the generated look
(materials), the order engines move through tiers, impulse-response generation method.

## 7b. Builder's calls from the reviewer's questions (18/11) **[call, open to correction]**
- **Stage done-when.** Stage 1 is done when: Linux tests pass (catalogue invariants, audio renders for
  every tier 1 engine and is non-silent and stable); the macOS job builds the iPhone libraries and an
  `.ipa`; and on Zach's phone every tier 1 engine starts, revs, holds an rpm and plays for 10 minutes
  without a dropout burst. Stages 2 to 4 get their own done-when lines when each is planned.
- **Exhaust and limiter in stage 1** are chosen in a "Parts" sheet on the Engine screen (the full Garage
  is stage 4). In stage 1 an exhaust choice changes the **sound only**; its effect on power (back pressure
  changes airflow, exhaust temperature) arrives with the dyno depth stage, and the same part table feeds
  both the impulse response and the power model so they cannot disagree.
- **Tier 1** = the 10 current layouts (I3, I4, I6, V6 60/90, V8 cross/flat, V10, V12, W16) plus any other
  four-stroke piston layout whose order is sourced. The W16 order is **derived** (even 45 degree spacing
  across four banks) and marked "derived" in the data until a source confirms it. Rotary, two-stroke,
  diesel and radial are later tiers; their own invariants apply (two-stroke 360 degree cycle, rotary has no
  pistons so a separate 3D and sound path).
- **Conflicting orders:** engine-sim's bundled scripts win (they are measured to sound right), then
  Wikipedia; a conflict is recorded in the data and the engine is held back until a test proves the order
  is physically valid (every cylinder once, intervals sum to the cycle).
- **Sound follows the tune** (the anti-goal) in stages: stage 1 maps rpm, throttle and ignition on/cut
  (limiter) into engine-sim; mixture and ignition advance need small patches to the pinned core and arrive
  with the tune stage. The test that defines "matches": a Linux job renders the same engine with a
  lean/rich or advanced/retarded tune and requires a measurable change in loudness and brightness.
- **Real names:** the "real examples" column stays in the repo data and is never in the app or the `.ipa`.
- **Drive** works in portrait (default) and landscape (pedals in the bottom corners); landscape is
  suggested, never forced.
- **3D chain:** Blender (headless, Linux CI) exports USD and `usd-core` packages USDZ for RealityKit. Blender's
  own licence does not cover work made with it; verified again before stage 2 ships.
- **Branch and plan:** work continues on a new branch from `native-stage-1` (which keeps the model, dyno,
  saves); the spike merges in when stage 1 starts; the old stage 1 plan is replaced by a new plan written
  after this document is approved.
- **Phone gate:** the pass line is 1.5x real time or better on Zach's phone for a given engine, and heat
  state "fair" or better after 20 minutes. Engines that miss it get a lighter sound quality tier, or are held
  back. Needs Zach's phone numbers (section 8).

## 8. Evidence and open risks
- Spike (`docs/research/raw/engine-sim-spike-results.md`): builds and renders on Linux, macOS arm64, iOS
  Simulator; iPhone arm64 libraries and a test app build; Zach's phone test: sound approved. CPU and heat
  on the phone were not reported yet.
- Risks: W16 and 12-cylinder load on a phone; our pops and forced-induction sound are unproven; many
  firing orders are derived, not sourced; upstream engine-sim is unmaintained and carries patches.
