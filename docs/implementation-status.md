# Piston Forge: what is built, and how complete each part is

Written 18/11/2026 evening for the "push as much as you can" build. **Percent = how much of the
finished feature this part is**, judged against the v2 design
(`docs/superpowers/specs/2026-11-18-piston-forge-v2-design.md`) and the three reference games, not
against "does it run". A low number on a working part means "a rush job, redo it properly".
Updated whenever a part changes; "unverified" means no one has seen or heard it on a phone yet.

Legend: **Verified** = proved by a CI run (Linux tests, engine-sim render) or on Zach's phone.
**Unverified** = written, compiles in CI, never run on a phone.

## Sound (engine-sim)
| Part | % | State and what is missing |
|---|---|---|
| engine-sim core on iPhone (build, bridge, app audio) | 80 | Verified: builds and renders in CI; phone test app sounded "perfect" (Zach, 18/11). The new in-app wiring is unverified. Missing: interruption handling, route changes, background behaviour, volume stage. |
| Engine scripts generated from our catalogue | 55 | One generator for all 16 layouts. Free-run checks in CI show which layouts rev. Cam timing, valve lift and flow are one scaled template, not tuned per engine. Bank phase sign is a guess confirmed only by CI. |
| Exhaust presets (7) | 35 | Our own synthetic impulse responses (6) plus engine-sim's recording as "Reference" (personal test only, no licence). Tone unverified by ear; no power effect yet (design: dyno stage). |
| Rev limiter styles (3) | 45 | Spark-cut length by style; the model's limiter also cuts the spark. No fuel-cut sound, no bangs. |
| Pops, crackles, overrun, anti-lag | 0 | Not started. |
| Turbo whine, blow-off, wastegate, blower whine, nitrous hiss | 0 | Not started (engine-sim has none). |
| Starter crank and shutdown | 0 | Model starts instantly; engine-sim is held at the model's rpm. |
| Listening positions (bay, cabin) | 0 | Not started. |
| Sound follows the tune (mixture, advance) | 15 | Only rpm, throttle and spark cut reach engine-sim. Mixture and advance need patches to the core. |

## Engines and 3D
| Part | % | State and what is missing |
|---|---|---|
| Engine catalogue | 19 | 16 layouts in the game (I2, I3, I4, I5, I6, I8, V2, V6 60/90, V8 cross/flat, V10, V12, W16, flat-4, flat-6) of 83 researched rows. Many firing orders still need a source. |
| Generated 3D engine kit (Blender) | 0 | Not started; the older procedural RealityKit builder is used. |
| 3D engine (existing builder): block, heads, crank, pistons, rods, intake, exhaust, turbo, blower, fuel, sensors, wiring, nitrous | 45 | Procedural boxes and tubes, one look. New layouts (I2, I5, I8, V2, flat-4/6) have never been seen in 3D. |
| Valves, rockers, cams, springs moving | 0 | Not modelled. |
| Exhaust heat glow | 55 | Added tonight: glows from exhaust temperature. Unverified; tuning of the colour ramp needed. |
| X-ray cutaway with combustion glow | 0 | Not started. |
| Firing-order timeline strip | 0 | Not started. |

## Engine model, tune, dyno
| Part | % | State and what is missing |
|---|---|---|
| Engine physics model (airflow, fuel, combustion, boost, damage) | 60 | 100+ tests. Sensible but not tuned against real engines. |
| Tune screen | 35 | Existing tables and auto-base map. Missing: most ECU tables (warm-up, acceleration enrichment, dwell, wastegate duty), 3D surface, paint-by-drag, data logging. |
| Dyno | 50 | Live pull with traces and last-pull overlay; sound follows the pull. Missing: Hold and Pull modes, wheel/crank toggle, logs tab. |
| Parts screen | 50 | Existing groups; only some parts change anything visible. |

## Cars, gearboxes, driving
| Part | % | State and what is missing |
|---|---|---|
| Gearboxes (9 types) | 40 | 5/6-speed manual, 6-speed sequential, 7-speed dual-clutch, 4/8/10-speed automatic, CVT, single-speed EV. Ratios game-tuned from public data; shift logic is simple (torque cut and ramps). A rush job: redo clutch, converter and shift maps properly. |
| Drive modes (Comfort, Eco, Sport, Sport+) | 35 | Four sets of numbers invented by us (manufacturers do not publish them). Track, Launch and Snow not started. |
| Vehicle physics | 30 | Straight-line only: grip, weight transfer, drag, rolling resistance. No steering, cornering, braking depth, slip curve or tyre width effect. |
| Drag strip | 30 | Screen with speed, rpm, gear, distance, timeslip (60 ft to a mile). No 3D strip, no Christmas tree, no reaction time. |
| Proving ground | 0 | Not started. |
| Cars | 33 | 5 bodies (target about 15). |
| Tyres and differentials | 15 | Four tyre compounds (grip number only); no differential model. |

## App and screens
| Part | % | State and what is missing |
|---|---|---|
| Portrait tab layout (Engine, Tune, Dyno, Garage, Drive) | 55 | Live and connected to one game state. Not yet the dense Tuning Simulator-style cockpit (tiles, gauges, sidebars). |
| Landscape layout | 10 | The same portrait screens stretched. The wide cockpit is not built. |
| Garage: saved engines, add any layout, car | 70 | Works. Compare screen and cards not built. |
| Saving | 80 | Versioned JSON with backup. |
| Settings | 60 | Units, sound, quality. Several settings are not used yet. |
| Accessibility audit | 40 | Earlier audit had open issues on the old screens; not rechecked. |
| Logs, Learn, fault codes, coach | 0 | Not started. |
| Career | 0 | Later, by decision. |
