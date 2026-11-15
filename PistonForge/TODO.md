# Piston Forge — Build Ledger

## 1. Playable 3D game shell and workshop
- A title/loading screen with the Piston Forge wordmark, real load progress and Retry on failure; first gesture unlocks audio.
- A keyboard- and touch-navigable workshop UI over a live Three.js scene; desktop and phone layouts both remain usable with no clipped primary controls.
- The camera orbits by drag and zooms by wheel/pinch; reduced-motion setting removes nonessential motion.
- Game is English-only, offline-capable, and works without pointer lock.

## 2. Engine assembly from scratch
- The player can choose engine layout, bore, stroke, compression ratio, cam profile, cylinder-head flow, induction (NA, turbo, twin-turbo, supercharger, nitrous), fuel type (95, 98, E85, race), exhaust, injectors, fuel pump and internals.
- Live derived specification shows displacement, bore/stroke, static and effective compression, mechanical redline, estimated mass, cost and engine envelope.
- Invalid or dangerous configurations are explained before commit; assembly/upgrade cost is charged from cash or a contract budget.
- Several factory presets and a free-build sandbox path make the builder approachable.

## 3. Nine car bodies, fitment and visual customization
- Body catalogue includes kei hatch, hot hatch, sedan, coupe, muscle car, supercar, pickup, van and off-roader, each with distinct length, width, height, wheelbase, engine-bay limits, kerb mass, drag coefficient, frontal area and drivetrain.
- An engine that exceeds any bay dimension cannot be fitted; the blocking dimension and value are shown.
- Paint colour and finish, wheel style and size, stance, aero parts and interior strip-out are selectable and visibly update the 3D car and vehicle mass/performance.
- Body ownership/unlock state is visible; locked bodies show their reputation requirement.

## 4. Standalone ECU remapping
- Fuel VE and ignition tables are editable over RPM and load with a selected-cell editor, heatmap, smoothing, auto-base and post-pull correction.
- AFR target, boost target, rev limiter and launch-control RPM are adjustable; boost is clipped by hardware and safety limits.
- The ECU screen reports injector duty, fuel-pump margin, knock risk, octane suitability and estimated output before a pull.
- Lean mixtures, excessive timing, overboost and over-rev produce visible knock/heat/failure consequences rather than silent penalties.

## 5. Animated dyno and engine health
- Dyno cell scene straps the car to spinning rollers; a full pull animates from low RPM to the limiter with engine audio and live analog/digital gauges.
- Live and logged power, torque, boost, AFR, ignition, knock, EGT and condition are shown; a power/torque chart is drawn from the simulation.
- Peak power/torque and RPM are recorded; a failed pull reports the failure cause and repair cost.
- Free-rev throttle mode lets the player hear and watch the engine build revs without a full pull.

## 6. Drag strip and handling test
- Quarter-mile drag run stages with a christmas tree, launch control, wheelspin/traction, gear shifts and a live speed/RPM/gear HUD.
- Results record 60 ft, 0–100 km/h, quarter-mile ET, trap speed and top speed; manual shift timing affects the result.
- Handling test produces a lap time, peak lateral g and balance verdict from power, mass, grip, aero, braking and drivetrain, with an animated course run.
- Both tests apply wear/damage from abuse and feed career contract completion.

## 7. Career contracts, economy and upgrades
- Career starts with $4,800, a rusty kei hatch and a salvage 1.6 inline-four.
- Contract board offers customer cars with injected faults (vacuum leak, weak fuel pump, stuck wastegate, burnt valve), a parts budget, a target and a cash/reputation reward.
- Faults can be diagnosed, repaired and tuned; delivering a car that meets its target pays out, while an unmet target or dead engine does not.
- Shop supports turbo/supercharger kits, injectors, pumps, cams, head work, valves, forged internals, gaskets, intercoolers, clutch, tyres, suspension, aero and weight reduction, each with a visible effect and cost.
- Reputation unlocks body archetypes and part tiers. Condition wears with use and can be serviced/repaired.
- Sandbox mode unlocks all bodies/parts, ignores cash, and preserves the career garage when switching.

## 8. Computed engine audio and immersion
- Engine note is synthesized from cylinder count, firing pattern, RPM and load; no recorded engine audio is used.
- Turbo whistle/spool, blow-off, limiter cut, lift-off pops, starter crank and gear-shift mechanical cues respond to state.
- Audio unlocks on first gesture, follows volume settings, and degrades gracefully if Web Audio is unavailable.

## 9. Original identity and sharing
- Original wordmark, crank/piston mark, palette and copy; no reference-app names, logos, assets, copy or trade dress inside the game.
- Procedural 3D geometry for every car and engine; no third-party models, copyrighted car designs or badges.
- Game-specific favicon and social cover prepared; title, description and captions describe Piston Forge.
- Loading screen, title and share metadata all carry the Piston Forge name.

## 10. Delivery validation
- Unit tests cover engine displacement/VE monotonicity, ECU interpolation, boost/knock behavior, drag physics, career payout/fault logic and save migration.
- `pnpm build` passes typecheck, size and font budgets; production build loads with no console or network errors.
- Smoke test covers title → career → engine edit → ECU edit → dyno pull → drag run → save/reload, plus a phone viewport capture.
- A read-only validation pass checks the delivered game against this ledger before checkpoint.