# Piston Forge — Implementation Plan

**Goal:** Build an original, playable 3D engine-building, remapping and proving-grounds game in the Three.js starter, with a full career and sandbox loop, procedural vehicle/engine geometry and computed engine audio.

**Approach:** A pure TypeScript simulation core owns every number (engine assembly, airflow, fuel, ignition, knock, wear, vehicle performance, economy). A thin application layer exposes simulation actions and owns persistence. The UI is HTML/CSS instrument paneling over a Three.js viewport, and a scene director moves one shared car and one shared engine between the workshop, dyno cell and proving ground. Audio is synthesized at runtime from the engine firing pattern; no recordings or third-party models are used.

## Reference reading (feature categories only)

- RevLab: computed engine sound and motion, engine family breadth, 3D engine display, gauges, drive/transmission feel, drag strip timing, computed rather than recorded audio.
- Engine Simulator: build from scratch (layout, bore, stroke, cam, firing order), live 3D, dyno power/torque, ECU fuel and ignition maps, rev limiter damage, free-rev interaction.
- Tuning Simulator: standalone ECU with fuel VE, lambda/AFR targets, ignition, boost/wastegate, limiters; knock and lean conditions causing failures; parts catalog; dyno data logs; career jobs with faults; daily challenge and leaderboards.

Piston Forge uses these as product-category evidence only. It does not copy code, names, artwork, layouts, vehicle shapes, audio, copy or progression values.

## Product loop

1. **Build** an engine: layout, bore, stroke, compression, cam, head flow, induction, fuel, exhaust, injectors, pump, internals, valves, gasket and intercooler.
2. **Fit** it into one of nine original body archetypes with real bay limits, mass, drag and drivetrain.
3. **Map** a standalone ECU: fuel VE grid, ignition grid, AFR target, boost target, rev limiter and launch RPM.
4. **Prove** it on an animated dyno pull, a live quarter-mile drag run and a computed handling lap.
5. **Earn and upgrade** through customer contracts, dyno challenges and race events; manage cash, reputation, condition and failures.
6. **Experiment** in sandbox with everything unlocked and no cash cost.

Career starts with $4,800, a rusty kei hatch and a salvage 1.6 inline-four. Reputation unlocks body archetypes and higher part tiers.

## Simulation model

### Engine geometry and specification

- Displacement: `π/4 × bore² × stroke × cylinders`.
- Engine envelope from layout, bore, stroke, bank angle and ancillaries; compared with each body's bay limits before fitment.
- Mechanical redline from internals, valves and mean piston speed; ECU limiter is separately adjustable but cannot exceed mechanical limit safely.
- Engine mass from displacement, layout, induction and internals.
- Build cost is the sum of selected part prices plus assembly labour; upgrading charges only the positive difference.

### Air, fuel and torque

- Volumetric efficiency curve: head flow, cam duration/overlap, intake and exhaust flow, peaking at a cam-dependent RPM with a low-speed penalty.
- Boost from turbo spool curve, supercharger RPM curve or nitrous; capped by wastegate target, turbo maximum and head-gasket rating. Charge temperature rises with boost and heat soak, reduced by the intercooler.
- Airflow from displacement, VE, RPM, pressure ratio and charge density.
- Fuel demand from airflow and actual AFR; injector duty and pump ceiling can force lean running.
- ECU fuel table is compared with physical VE: under-reporting airflow makes the engine lean, over-reporting makes it rich.
- Ignition advance is compared with MBT and a fuel/boost/charge-temperature-dependent safe advance. Too little timing loses power; too much knocks; knock removes power and damages the engine.
- BMEP → torque → power at 100 RPM steps, with a hard limiter cut.
- Damage accumulates from knock, lean running, overboost, over-rev and heat. Severe pulls can crack pistons or lift a head gasket. Normal pulls wear condition slowly; servicing restores it for cash.

### Vehicle performance

- Nine bodies define length, width, height, wheelbase, bay envelope, kerb mass, drag coefficient, frontal area, drivetrain and default gearing.
- Mass includes engine, drivetrain, interior, aero and weight-reduction parts.
- Drag run integrates wheel force, traction limit, aero drag and rolling resistance at 60 Hz; manual shifting and launch RPM matter. Records 60 ft, 0–100 km/h, ET, trap speed and top speed.
- Handling lap uses a simplified 2.1 km course with straights, a hairpin, fast sweeps and a chicane; speed limits come from power, drag, tyre grip, downforce, braking and drivetrain.
- Reports lap time, peak lateral g and balance (understeer/oversteer index).

### Economy and career

- Cash, reputation, owned bodies, saved builds, best dyno/drag/lap results.
- Contract templates instantiate a customer car with an engine, injected fault(s), a budget and a target. Faults: vacuum leak, weak fuel pump, stuck wastegate, burnt valve.
- Contracts are completed by fixing faults and/or tuning to the stated target, then delivering the car with the engine alive. Payout plus reputation.
- Reputation tiers: Rookie 0, Apprentice 50, Journeyman 140, Master 300, Legend 550.
- Sandbox uses a separate build and never charges cash; career state is preserved when switching.

## Application architecture

```
src/
  main.ts                  Boot, loading, first-gesture audio unlock, app wiring
  app.ts                   Application actions, active build, timers, scene switching
  sim/
    types.ts               Serializable engine/build/result/career types
    data.ts                Layouts, bodies, fuels, parts, paints, course, contracts
    engine.ts              Derived specs, fitment, cost, validation, presets
    ecu.ts                 Default maps, interpolation, auto-base, smoothing
    performance.ts         VE, boost, AFR, knock, torque curve, dyno result, damage
    vehicle.ts             Mass, gearing, drag simulation, handling, launch
    career.ts              Contracts, fault injection, rewards, unlocks, economy
    save.ts                Versioned localStorage parse/migrate
  audio/
    sound.ts               User-gesture unlock, UI cues, engine audio graph
  game/
    stage.ts               Renderer, camera, orbit controls, quality, resize
    workshop.ts            Workshop room, props, engine stand, lighting
    carModel.ts            Procedural body archetypes, paint, wheels, aero, engine bay
    engineModel.ts         Procedural engine, cutaway, crank/piston/valve/turbo animation
    dynoScene.ts           Dyno cell, rollers, extraction fan, straps
    stripScene.ts          Drag strip, tree, timing tower, smoke, handling course
    sceneKit.ts            Shared materials, procedural textures, geometry helpers
  ui/
    ui.ts                  Shell, header, rail, screen routing, modals, event delegation
    views.ts               Per-screen HTML builders and binders
    gauges.ts              SVG tachometer, charts, map grid
    format.ts              Number/unit/currency helpers
  styles/main.css          Full design system and responsive layout
```

### State and rendering rules

- Simulation is pure and serializable; the UI and Three.js read from it. No DOM or Three.js imports inside `sim/`.
- The fixed-step loop advances active dyno/drag/lap timers; rendering is interpolated and frame-rate independent.
- One `CarModel` and one `EngineModel` instance are reparented between workshop, dyno and strip scenes to avoid duplicated GPU resources and keep paint/engine state consistent.
- Engine rebuilding is debounced and disposes replaced geometries/materials. Scene geometry uses shared materials and low draw counts.
- No post-processing bloom is used; lighting, tone mapping and emissive accents stay within a bounded brightness budget. Custom shaders are avoided.
- Touch input: drag to orbit, pinch/wheel to zoom, large pedal/shift/run controls; desktop keyboard shortcuts (Space shift/launch, R pull, Esc close).

## Design

### Candidate directions

- Industrial Instrumentation — probability 0.08
- Neo-Blueprint Minimalism — probability 0.05
- Tuner Brutalism — probability 0.04

**Chosen: Industrial Instrumentation.** A workshop that feels like a calibrated machine: dark steel, printed scales, amber warning lamps, cyan measurement traces, and one large analog tach as the emotional centre.

**Design movement:** Mid-century industrial instrumentation crossed with contemporary motorsport telemetry — Braun-style discipline, aircraft cockpit hierarchy, workshop grime.

**Core principles:**
1. Every screen is an instrument: the number that matters is the largest thing on it.
2. Physical materiality: panels look stamped, riveted, scratched and repainted, not floating glass cards.
3. One accent per job: amber for action and danger, cyan for measured data; never both competing for the same element.
4. The machine is always visible: 3D viewport is the stage, UI is the operator's console around it.

**Colour philosophy:** The base is graphite and oily black because the workshop is a low-light, focused place. Amber is the colour of warning lamps, hot metal and the one control you are about to press. Cyan is cold measurement — dyno traces, sensor readouts, fuel maps. Off-white "bone" is reserved for engraved labels and numerals. Red is only failure.

**Layout paradigm:** Asymmetric console. A 3D stage occupies the right 60–70% of the screen; a vertical control stack occupies the left, with a fixed status rail on top and an instrument strip at the bottom. On phones it becomes a top stage and a bottom sheet that snaps between "read" and "adjust", with a persistent action bar. Avoids centred cards and symmetric dashboards.

**Signature elements:**
- Notched, riveted panel corners with exposed screw heads.
- A large analog tach with a redline arc and a needle that overshoots on limiter cut.
- Blueprint-grid insets behind technical diagrams, with measurement ticks and callouts.
- Hazard-striped "HOT" markers on boost and exhaust readouts.

**Interaction philosophy:** Controls behave like hardware. A press has travel; a slider has detents; a table cell is selected like a probe point; applying a tune is a deliberate commit with a cost and a warning. The player is always told what changed and what it will cost.

**Animation:** Instrument needle springs to value with 120–180 ms ease-out; map cells flash on edit; dyno pull adds a low-amplitude camera shake and exhaust heat shimmer; tree lights sequence with real staging delays; panels reveal with a short mechanical slide. Reduced-motion collapses all to instantaneous state changes. No decorative looping animation on data screens.

**Typography system:** ManusCC0 (bundled CC0) for headings and body, uppercase with 0.08em tracking for labels. A system monospace stack for all numerals, tables and telemetry, tabular numerals mandatory. Display sizes use `clamp(2.4rem, 6vw, 5.2rem)`; data sizes `clamp(1.4rem, 3.4vw, 3rem)`; labels 0.68–0.76rem. Hierarchy is driven by weight and colour, not many sizes.

**Brand essence:** The dyno doesn't lie — a workshop simulator for people who want to feel a build come together and then prove it. Personality: exacting, tactile, restless.

**Brand voice:** Terse, mechanical, confident; no hype. Example lines: "Every degree costs." / "Build it. Map it. Prove it." / "The strip remembers."

**Wordmark & logo:** Stacked wordmark "PISTON / FORGE" in heavy uppercase, second line outlined. The mark is a crank circle with an offset pin and a connecting rod forming a subtle "P"; it doubles as the favicon and loading mark.

**Signature brand colour:** Forge Amber `#ffb23e`, with Hot Amber `#ff7a1a` for danger.

## Build phases

1. Simulation core + unit tests (engine math, ECU, dyno, drag, economy, save).
2. UI shell, design system, title/loading, garage and engine builder wired to simulation.
3. Procedural engine and car models, workshop scene, orbit camera, reparenting.
4. ECU editor, dyno cell, live pull, free-rev audio.
5. Drag strip and handling course with live timers, telemetry and results.
6. Career contracts, faults, shop, upgrades, sandbox switching, persistence.
7. Sharing metadata, favicon, OG cover, smoke tests, responsive audit, build and checkpoint.

## Constraints and exclusions

- English-only game content. No language selector.
- No third-party 3D models, textures, audio recordings, fonts beyond the bundled CC0 family, or copyrighted vehicle designs/trademarks.
- No online accounts, leaderboards, payments or multiplayer (Blueprint selected none).
- Single-player, offline-capable, local save only.
- Must remain usable with touch and keyboard; no pointer-lock requirement.