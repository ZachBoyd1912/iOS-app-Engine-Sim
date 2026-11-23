# WS02 — Valve train animation

**Workstream:** 2 of 15 · **Branch:** `piston-forge-v2` · **Scope:** `Native/App/Engine3D/**` only.

The engine used to move only its crank, pistons and rods. The heads carried a cam cover and
nothing else. This workstream puts a working valve train on top of every bank — one camshaft
per valve row, two valves, two springs and two rockers per cylinder — and poses it from the
**existing** crank angle. No new timer, no new per-frame state, nothing outside `Engine3D`.

---

## 1. What is on screen now

| Part | Motion | Per 720° cycle |
|---|---|---|
| Camshaft (2 per bank: intake row, exhaust row) | turns about **its own shaft axis**, `crankAngle / 2` | 1 turn |
| Valve (2 per cylinder) | slides down its bank axis by the lift, then back | 232° intake, 236° exhaust |
| Spring (2 per cylinder) | compresses along its local y to 53 % of free length at full lift | same as its valve |
| Rocker (2 per cylinder) | turns about the pedestal shaft, ±18.5° | same as its valve |

The crank, pistons and rods keep their existing motion. Above roughly 2 000 rpm the cam
advances ~100° of its own rotation per frame and strobes (the crank already does); the
rockers and springs still read.

---

## 2. How it is driven (no new timer)

```
GameStore.frame(dt:)      16 ms loop                        Native/App/Game/GameStore.swift:224
  state.crankAngle        0..<720, from EngineSim           Native/PistonForgeKit/.../EngineSim.swift:167, 240
EngineViewport.update     root.components.set(              Native/App/Engine3D/EngineViewport.swift:44
                            EngineMotionComponent(crankAngle: state.crankAngle, heat: heat))
EngineAnimationSystem     reads the root component per entity, per frame
                                                            Native/App/Engine3D/EngineAnimationSystem.swift:126
```

`EngineMotionComponent` (`EngineAnimationSystem.swift:7`) is the only input. The rebuild path
is unchanged: `EngineModelBuilder.signature` (`EngineModelBuilder.swift:162`) still decides
when the whole engine is rebuilt, and the valve train is built inside `build`
(`EngineModelBuilder.swift:247`) — so it rebuilds exactly when the rest of the model does.
`EngineViewport`'s `.id(signature)` is untouched.

---

## 3. Components (`Native/App/Engine3D/EngineAnimationSystem.swift`)

| Type | Line | Purpose |
|---|---|---|
| `CamshaftComponent { tilt }` | 41 | Marks a cam entity; `tilt` is the bank's lean, radians. |
| `ValveTrainComponent` | 47 | One part's whole pose: `motion`, `rest`, `centre`, `halfDuration`, `lift`. |
| `.slide(axis:)` | 50 | Valve. Axis points **up** the bank; `rest` is the shut position. |
| `.compress(free:)` | 52 | Spring. Free length along local +y. |
| `.rock(angle:swing:)` | 54 | Rocker. Rest angle and the angle it turns through at full lift. |
| `CamLift.fraction` | 70–79 | The lift curve, 0…1. Pure, allocation-free. |

Registration is at `EngineAnimationSystem.swift:188–189`, inside the existing `Engine3D.register()`.

**Line references below:** `Anim:` = `EngineAnimationSystem.swift`, `Builder:` = `EngineModelBuilder.swift`.

---

## 4. The maths

### 4.1 Cycle and valve events

One four-stroke cycle is 720 crank degrees and the cam turns once in that time:

```
cam angle (rad) = tilt + crankAngle · 0.5 · π / 180                Anim:144
```

Each cylinder's firing top dead centre `θ_tdc` comes straight from the layout's firing order —
`spec.firingOrder` / `spec.firingAngles` mapped to cylinder index (`Builder:534–537`) — so the
valve train respects cylinder count, bank layout and firing order for all 15 catalogue layouts
(i2 … w16). For every valve:

```
θ_centre = (θ_tdc + eventOffset) mod 720                           Builder:618
intake:  eventOffset = 460°, halfDuration = 116°                   Builder:527, 565
exhaust: eventOffset = 258°, halfDuration = 118°                   Builder:528, 566
```

In crank degrees after the firing TDC: intake opens 16° BTDC and closes 36° ABDC; exhaust
opens 40° BBDC and closes 16° ATDC — 32° of overlap, a fast-road cam.

### 4.2 Lift curve

```
Δ = wrap(θ − θ_centre) into (−360, 360]                            Anim:75–76
u = clamp(Δ / halfDuration, −1, 1)                                 Anim:77
f = ½ (1 + cos πu)                                                 Anim:78
lift = f · 0.11 · bore                                             Builder:544
```

`f = 0` outside the window and `f = 1` at `θ_centre`, with zero velocity at both ends, so the
valve eases on and off its seat instead of snapping. Because `θ_centre` is normalised at build
time, one unwrap step is always enough (`|Δ| < 720°` before, `≤ 360°` after).

### 4.3 Camshaft and lobes

Per bank, per valve row, one `ModelEntity` is built **centred on the cam axis** and then placed
on that axis (`Builder:679`):

```
camU = rollerU + rollerRadius + camRadius      Builder:560  (the base circle rests on the roller)
axis = (bankCentreX, 0, 0) + bankAxis · camU + bankInner · (±camRow)
```

The mesh must be built around the origin, not at world height, because RealityKit rotates a
child about **its own** position. An earlier draft built the cams in world coordinates and set
only `orientation`, which swung the whole camshaft around the *crank* axis.

Each lobe is an eccentric disc — radius `0.78 · camRadius`, centre offset
`0.22 · camRadius + camRise` (`Builder:667–672`) — so the peak reach is `camRadius + camRise`:
the base circle plus exactly the rise the rocker needs.

Its phase is what puts the lift at the right crank angle. With the entity rotation `tilt + θ/2`,
a lobe offset at local angle ψ points at world angle `tilt + θ/2 + ψ`; it must point straight
**down the bank** (world angle `tilt + π`) when `θ = θ_centre`, hence

```
ψ = π − θ_centre / 2                                              Builder:666
```

Checked over bank tilts 0°, ±30°, ±45°, ±60° and every event offset in the catalogue: the lobe
direction at full lift is within 0.01° of the bank axis.

### 4.4 Rocker

The pivot sits outboard of the valve with the cam between them: pivot row `0.60 · bore`, valve
row `0.26 · bore`, cam row `0.42 · bore`. The roller is `0.53` along the blade, which lands it at
`0.60 − 0.53 · 0.34 = 0.42 · bore` — exactly under the cam.

```
hub     = place(x, pivot, ±pivotRow)                              Builder:645
contact = place(x, toe, ±valveRow) − hub                          Builder:646
angle   = atan2(contact.z, contact.y)                             Builder:652
swing   = sign(sin(angle − tilt)) · lift / reach                  Builder:659
```

**The angle is the contact direction's world angle, not its angle in the bank frame.** The
rocker entity carries a single rotation about x and inherits no bank tilt, so
`atan2(contact.z, contact.y)` maps its local +y straight onto the valve. Measuring in the bank
frame instead leaves the pad 12 mm off on a 15° bank, 27 mm on a 45° V and 46 mm on a 90° boxer
— numerically checked; this is why the comment at `Builder:647–651` exists.

`swing` is signed against `sin(angle − tilt)` because the toe's height along the bank is
`reach · cos(angle − tilt)`; that is what keeps a boxer's valves opening downwards. At full lift
the toe travels `−9.81 mm` for a `9.90 mm` nominal lift — the 0.9 % difference is the arc.

### 4.5 Spring

```
free  = retainer − seat = 21.0 mm                                  Builder:547, 550, 551
scale = max(free − lift·f, 0.25 free) / free                       Anim:154–156
```

Full lift gives 11.1 mm (scale 0.529). The 25 % floor is never reached with this lift; it is kept
so a later cam grind cannot invert the spring.

---

## 5. Verification

Compilation and on-device rendering are **unverified**: CI is blocked on GitHub billing and this
workstream had no Xcode. What was checked instead:

1. **Geometry harness** (Node, mirroring the Swift arithmetic exactly — same constants, same
   rotation order) over bank tilts 0°, ±15°, ±30°, ±45° and ±90°, both valve rows. Result:
   pad-to-valve clearance `4.00 mm` at every tilt, toe travel `−9.81 mm`, roller drop `−5.20 mm`
   against a `5.25 mm` cam rise, base-circle/roller tangency exact at `camRadius + rollerRadius`.
2. **Lift curve** at the window edge (`0.000000`), just outside it, across the 720° wrap
   (`centre = 820` and `1000`) and for symmetry about the peak — continuous and bounded.
3. **Brace/paren balance** of both edited files, and a line-by-line read against the existing
   piston/rod pattern.

What the numbers do not prove is how the extra meshes read at the app's framing: they say the
parts meet correctly, not that they are legible.

---

## 6. Performance budget assumed

60 Hz, 16.67 ms per frame, sharing the CPU with the audio engine.

| Layout | Cyl. | Valves + springs + rockers | Cams | Nodes animated / frame |
|---|---|---|---|---|
| i2 | 2 | 12 | 2 | 14 |
| i3 / i4 | 3 / 4 | 18 / 24 | 2 | 20 / 26 |
| flat4 / v6 | 4 / 6 | 24 / 36 | 4 | 28 / 40 |
| i6 / v8 | 6 / 8 | 36 / 48 | 2 / 4 | 38 / 52 |
| v12 | 12 | 72 | 4 | 76 |
| w16 | 16 | 96 | 8 | **104** |

Per animated node, per frame: one component read, one `cos` + clamp, one transform write
(`position`, `scale` or `orientation`). No arrays, dictionaries, closures or strings are created
inside the loops — the per-frame path is struct maths and transform writes only, matching the
existing piston path. On the worst layout (w16) that is ~104 writes at 60 Hz ≈ 6 200/s, expected
well under 0.3 ms of CPU.

**The risk is draw calls, not maths.** Every valve, spring and rocker is its own `ModelEntity`, so
the w16 adds ~104 draws on top of the merged static meshes (assume 20–40 µs each on an A-series
GPU → 2–4 ms of a 16.7 ms frame). If a device stalls, the cheapest mitigations in order are: drop
to one spring per cylinder (halves the extra nodes), then animate the near bank only. Nothing
allocates per frame, so the audio thread is not competing for heap.

---

## 7. Known limitations

1. **The lobe is an eccentric disc, the valve follows a raised cosine.** The disc's angular window
   is ±139.6° crank against the declared ±116/118°, so mid-flank the roller sits up to 2.3 mm
   inside the lobe (90 mm bore). Invisible at the app's framing (~1 pt), but real. Matching the
   window with the eccentricity only halves it (1.5 mm): a circle cannot follow a raised cosine.
   A true fix needs a lofted non-circular lobe profile.
2. **The cam is decoration for the lift, not its source.** Valve, spring and rocker are driven by
   `CamLift.fraction`, so the lobe can never disagree with the seat timing — only by the 2.3 mm
   above.
3. **`parts.cams` does nothing visually.** Duration and lift are fixed constants
   (`Builder:527–528, 544`); a hotter grind does not change the geometry. Doing that needs the cam
   level added to `EngineModelBuilder.signature`, a one-line follow-up that changes when the whole
   engine rebuilds.
4. **Collision shapes do not follow the valves.** Valves are `makeTappable` so a tap still selects
   "Heads"; their 10 mm slide leaves the tap box at the shut position. Same part group, so the
   only effect is a millimetre of tap error.

---

## 8. Files

| File | Change |
|---|---|
| `Native/App/Engine3D/EngineAnimationSystem.swift` | `CamshaftComponent`, `ValveTrainComponent`, `CamLift`, two new queries, cam and valve-train posing loops, registration. |
| `Native/App/Engine3D/EngineModelBuilder.swift` | `addValveTrain` and its meshes/materials; `addHeads` cam cover turned into a lid-less frame with rocker pedestals and per-row cam towers; wiring lifted clear of the cover; `build` calls `addValveTrain`. |

Nothing outside `Native/App/Engine3D/` was touched. `EngineViewport`, `GameStore` and every screen
are unchanged.

---

## 9. Rollback

Delete the `CamshaftComponent` / `ValveTrainComponent` / `CamLift` definitions, the two queries and
their loops, and their two `registerComponent()` calls; drop `addValveTrain` and its call, and the
`addHeads` additions. The engine returns to crank + pistons exactly as before — the valve-train
entities are added to the root and referenced nowhere else.
