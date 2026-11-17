# Reference games, 3D models and gearboxes (research, 17/11/2026)

Zach rejected the stage 1 previews on 17/11/2026: the landscape layouts wasted the width, and
the game must be as deep as the three games below. Five Haiku research agents gathered this.
Store screenshots are kept privately in `builds/research/` (git-ignored, never shipped). We
study these games for depth and genre conventions; our look and layouts stay our own.

## The three games

| | RevLab - Engine Simulator | Engine Simulator | Tuning Simulator |
|---|---|---|---|
| Developer | Vibalyze OÜ (Tallinn); © Jehyung Lee | Muhammad Saad Ata | Scott Busby |
| Store | [App Store id6817417979](https://apps.apple.com/us/app/revlab-engine-simulator/id6817417979) | [App Store id6772016143](https://apps.apple.com/us/app/engine-simulator/id6772016143) | [App Store id6817126925](https://apps.apple.com/us/app/tuning-simulator/id6817126925) |
| Price | Free; Pro $4.99 once | Free; lifetime $8.99 | Free; Pro $14.99 once |
| Rating | 3.8 (6) | 4.4 (308) | 4.6 (17) |
| Orientation | Portrait | Portrait | **Landscape only** |
| Engines | 21 (I4, I6, V8 cross-plane, W16, rotaries, radial, turbofan, electric...) | Procedural 1-cyl to V12 | 10 (I4, flat-4, I6, V6, V8) |
| Strength | Studio-lit 3D engine with real materials; firing-order timeline strip; analog and TFT gauges; 3D gated shifter and pedals; drag strip with time slip and leaderboard; five sound listening positions | See-through cutaway with glowing combustion chambers, moving cams and valves; paint-to-tune ECU map with safe/edge/peak/danger bands; camshaft editor; fault codes | Dense landscape cockpit: icon sidebar (Garage, Tune, Dyno, Logs, Learn, Career, Setup), 3D engine on a dyno stand, analog tach and boost, wideband bar, digital tiles (power, torque, timing, knock, EGT, IAT), dyno sheet with tabs, right rail with START/STOP, throttle, Free/Hold/Pull. Full ECU (VE, lambda, warmup, cranking, accel enrich, ignition, IAT trim, knock, dwell, boost, wastegate duty) as grid or 3D surface; data logs; career |
| Gearboxes | 5MT, 6MT, 7-speed DCT, 8-speed auto, 6-8-speed sequential; auto-clutch modes; Comfort/Eco/Sport | none found | none found (drag and rally events in updates) |
| Complaints | shifting bugs, paywall | built engines locked behind paywall | price of new engines |

## 3D engine models from the internet

- No single source covers our ten layouts. No verified candidates for I3, V10, flat-plane V8,
  90° V6 or turbo kits.
- Found: free CC-BY V6 (1.3M polys, parts not confirmed separate); CGTrader V12s $55-349
  (875k-7.5M polys, rigged per listing, licence unverified); W16s, two branded "Bugatti".
- Licences: Sketchfab CC-BY and CC0 and Standard are usable; Editorial, NC and ND are not.
  CGTrader/TurboSquid "royalty free" terms need reading per item.
- iPhone budget: about 100-200k triangles for one engine on screen; merged static parts,
  separate moving parts.
- Conversion without a Mac: Blender on Windows to `.usdc`, packaged with `usd-core`
  (Windows wheels; USDZ packaging unverified).
- Heat glow: `PhysicallyBasedMaterial.emissiveColor`/`emissiveIntensity` (iOS 15+), changed
  each frame from the exhaust temperature; bloom unverified on iOS.

## Gearboxes (figures for the simulation)

| Type (generic name in game) | Ratios | Shift |
|---|---|---|
| 5-speed manual | ~3.1 / 1.9 / 1.3 / 1.0 / 0.8 (sporty) | 0.5-1 s, clutch ramp 150-300 ms (defaults) |
| 6-speed manual | same pattern, 6th ~0.7-0.8 | as above |
| 6-speed sequential | close ratios | 30-80 ms dog engagement, ~100 ms ignition cut, no clutch once moving |
| 7-speed dual-clutch | 3.765 / 2.273 / 1.531 / 1.133 / 0.956(?) / 0.795 class | 40-150 ms, next gear pre-selected; launch control; creep |
| 8-speed automatic | 4.696 / 3.130 / 2.104 / 1.667 / 1.285 / 1.000 / 0.839 / 0.667 | ~200 ms; torque converter (stall ratio 1.8-2.5, stall ~2200 rpm, lock-up in higher gears); shift maps by throttle × speed, Comfort/Sport |

Names such as DSG, PDK, 8HP, Tiptronic and SMG are trademarks; the game uses generic names.
Sources: Wikipedia articles on ZF 8HP, DSG, shift time; NREL ADVISOR torque converter model;
HPAcademy; several marked unverified in the agent reports.
