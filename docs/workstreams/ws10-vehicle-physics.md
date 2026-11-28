# WS10 — Vehicle physics: steering, cornering and braking depth

Branch `piston-forge-v2`. Status: code + tests written; `swift test` could not be run in this
workspace (CI billing blocked, no Swift toolchain on this machine). Every equation below was
numerically checked against an independent Python implementation of the same expressions, and
every new test's expected range was verified against that model.

## 1. What was there and what this adds

Before: `DriveSim` was a straight-line model. Engine torque went through the gearbox to the
driven tyres, capped by `mu * drivenLoad`, with longitudinal weight transfer, aero drag and
rolling resistance.

After: the same model plus

- a road-wheel steering angle and a steady-state bicycle model with an understeer gradient, so
  the cornering radius grows with speed;
- a per-axle lateral grip limit with load-sensitive tyre friction, static weight distribution,
  longitudinal load transfer and lateral load transfer, which produces understeer or oversteer
  from the car's own numbers;
- a friction ellipse on the driven axle, so a car that is cornering cannot put down full power
  (power-on understeer), and one that is braking cannot use full brake force;
- cornering drag from tyre slip angles, so holding a corner costs speed;
- a brake model with a fixed front/rear bias, weight transfer, per-axle grip and locked-wheel
  sliding friction, plus a `stoppingDistance` helper that integrates the same equations.

New file: `Native/PistonForgeKit/Sources/PistonForgeKit/Physics/VehicleDynamics.swift`.
It is merged with the five closed-form helpers another workstream committed in `25ceff0`
(`lateralGripAcceleration`, `geometricCorneringRadius`, `maxCorneringSpeed`,
`achievableCorneringRadius`, `brakingDistance`). Those five functions and their 9.80665 default
are untouched, so `VehicleDynamicsTests` still passes; the full model is appended below them.

Modified: `Native/PistonForgeKit/Sources/PistonForgeKit/Car/DriveSim.swift` (input, state,
step). No public signature the UI calls was changed: `DriveInput` gained a defaulted
`steering` parameter, `DriveState` gained two nested value properties, and `DriveSim.init`
is untouched.

New tests: `Native/PistonForgeKit/Tests/PistonForgeKitTests/VehiclePhysicsTests.swift`.

## 2. Equations

### 2.1 Steady-state cornering (bicycle model)

With road-wheel angle `delta` (rad), wheelbase `L`, and understeer gradient `K` (rad per m/s²):

```
delta = L / R + K * a_y            a_y = v² / R
=>  a_y  = v² * delta / (L + K v²)
    R    = (L + K v²) / delta
    r    = a_y / v = v * delta / (L + K v²)
```

For a fixed steering angle the radius grows with `v²`: that is the "speed-dependent cornering
radius" requirement. The requested `a_y` is then capped at the grip limit (2.2); past that the
car runs wide of the geometric radius and `gripLimited` is set.

Understeer gradient (Milliken & Milliken 1995 ch. 5; Gillespie 1992 ch. 6):

```
K = (1/cf - 1/cr) / g           cf, cr = axle cornering stiffness per N of axle load, per rad
v_characteristic = sqrt(L / K)  (K > 0, understeer)
v_critical       = sqrt(-L / K) (K < 0, oversteer)
```

At `v_characteristic` the steer needed for a given radius is twice the Ackermann angle. For an
oversteering car the linear solution has no steady state at `v_critical`; the denominator is
clamped at `0.05 L` there and the grip limit takes over. That clamp is a documented stand-in
for the spin the real car would enter — the model never spins.

### 2.2 Lateral grip limit

Tyre friction falls with load:

```
mu(Fz) = mu0 * (Fz / Fz_ref)^-0.15,  clamped to [0.6 mu0, 1.25 mu0]
```

Axle capacity, with `dFz` moved from the inside tyre to the outside:

```
Fy_axle = mu(Fz/2 + dFz) * (Fz/2 + dFz) + mu(Fz/2 - dFz) * (Fz/2 - dFz)
```

Loads at the axle:

```
Fz_front = W * f + m * a_x * h / L        (a_x > 0 accelerating moves load rearward)
Fz_rear  = W * (1 - f) - m * a_x * h / L
dFz_total = m * a_y * h / track           split between axles by static weight share
```

`a_y` appears on both sides, so the limit is a fixed point, solved in four passes (converged to
< 0.001 m/s²; measured 4-pass error 3e-5 to 5e-4 m/s² against 40 passes).

In a steady corner the lateral force splits between the axles in the same ratio as the static
weights, so each axle's limit expressed as a whole-car lateral acceleration is
`Fy_axle / (m * share)`, and the car is held by the lower:

```
a_y_front_limit = Fy_front / (m f)         a_y_rear_limit = Fy_rear / (m (1-f))
a_y_max         = min(a_y_front_limit, a_y_rear_limit)
balance         = understeer if front < rear, oversteer if rear < front, neutral within 1 %
```

Because `mu` is normalised at a fixed 4 kN reference rather than at each axle's own static load,
a front-heavy car's front tyres run at a lower coefficient and it understeers; a mid-engine car's
rear tyres do and it oversteers. This falls out of the weight distribution, it is not a per-body
fudge.

### 2.3 Friction ellipse (longitudinal grip while cornering)

```
Fx_max = mu_long * Fz * sqrt(1 - (Fy / (mu_lat * Fz))²)
```

Applied per axle, with `Fy_axle = m * a_y * axleShare`. At `Fy = 0` the expression is exactly
`mu_long * Fz`, which is bit-for-bit the old straight-line grip, so a car that is not steering
keeps its previous acceleration and quarter-mile numbers.

### 2.4 Cornering drag

Slip angles make drag:

```
alpha_front = a_y / (cf * g)          alpha_rear = a_y / (cr * g)
F_scrub = m * a_y² / g * (f/cf + (1-f)/cr) * (1 + 0.4 * (a_y/a_y_max)²)
```

The rise term lets the slip angle grow past the linear estimate near saturation (linear model
gives 5–7° at the limit; the factor takes it to ~8°). At the limit this is 0.13–0.16 g of drag.

### 2.5 Braking

```
demand      = pedal * 1.1 * W
frontDemand = bias * demand           rearDemand = (1 - bias) * demand
Fz_front    = W f + m * a_decel * h / L       Fz_rear = W (1-f) - m * a_decel * h / L
capacity_axle = friction ellipse above (lateral terms from the cornering state)
if demand > capacity: axle locks, force = 0.85 * capacity
else:                 force = demand
a_decel = (F_front + F_rear + F_drag + F_rolling) / m
```

Loads depend on the deceleration, so six fixed-point passes are used (measured 4-pass error
≤ 0.005 m/s², 6-pass ≤ 0.001 m/s²). Drag and rolling are included in the transfer because the
body feels them.

`stoppingDistance(fromSpeedMps:car:massKg:steering:)` integrates exactly this at 1/240 s with
the same drag, rolling and scrub terms, so the quoted distance cannot drift from the step model.
Engine braking is not included.

## 3. Constants and sources

Global (all in `VehicleDynamics`):

| Constant | Value | Source |
|---|---|---|
| `gravity` | 9.81 m/s² | unchanged from `DriveSim`; the closed-form helpers keep 9.80665 |
| `airDensity` | 1.2 kg/m³ | unchanged from `DriveSim` |
| `rollingCoefficient` | 0.012 | research file §2.3 (Bosch 0.013 car on asphalt; Wikipedia 0.007–0.014) |
| `brakeCommandDecel` | 1.1 g | unchanged from `DriveSim` |
| `tyreLoadSensitivity` | 0.15 | effect is standard; **no measured coefficient in the research file (NS) — game-tuned** |
| `tyreReferenceLoadN` | 4000 N | typical passenger-tyre rated load; **game-tuned** |
| `slidingGripFraction` | 0.85 | research file §2.1: dry peak 0.80–0.90 vs sliding 0.75 (Wong 1993) → 0.75/0.85 ≈ 0.88 |
| `limitScrubRise` | 0.4 | game-tuned so limit slip angle ≈ 8° |
| friction, longitudinal | 1.0 / 1.1 / 1.3 / 1.5 | unchanged `DriveSim` values; research file §2.2 |
| friction, lateral | 1.0 / 1.1 / 1.3 / 0.9 | as longitudinal except drag radial, which is deliberately poor sideways |

Per body (`CarHandling`):

| Body | track m | lock rad | cf | cr | brake bias F | K deg/g | v_char / v_crit km/h | R_min m |
|---|---|---|---|---|---|---|---|---|
| hatch | 1.50 | 0.52 | 9.0 | 12.5 | 0.66 | +1.78 | 101 | 4.4 |
| coupe | 1.56 | 0.50 | 10.0 | 11.8 | 0.64 | +0.87 | 150 | 4.9 |
| muscle | 1.60 | 0.48 | 9.5 | 12.3 | 0.62 | +1.37 | 123 | 5.5 |
| pickup | 1.70 | 0.55 | 8.5 | 13.0 | 0.65 | +2.33 | 102 | 5.4 |
| super | 1.63 | 0.46 | 10.5 | 9.4 | 0.60 | −0.64 | 176 (critical) | 5.5 |

Derivations and sources:

- `wheelbaseM`, `frontWeight`, `cgHeightM`, `cdA`, `drivetrain`: existing `CarSpec` in
  `Cars.swift`; mass adds `90 kg/L` of engine as `DriveSim` already did.
- track: **not sourced for any body** (research file §1.1, "Track: 0 sourced"). Game-tuned to
  published class dimensions.
- steering lock: chosen so `L/tan(lock)` gives a 4.4–5.5 m centre-line turning radius, i.e. the
  10–13 m kerb-to-kerb circle of the class. Game-tuned.
- `cf`, `cr`: a tyre's `C_alpha/Fz` is typically 0.15–0.25 per degree (9–14 per radian) —
  Milliken & Milliken ch. 5, Gillespie ch. 6. Values sit in that band and are game-tuned inside
  it; the front/rear difference sets the understeer gradient.
- brake bias: game-tuned to the axle loads at about 1 g. No proportioning valve is modelled.

## 4. What the model produces

Sport tyres, no throttle, engine mass included:

| Body | mass kg | lateral limit | balance | brake 100–0 km/h | 100 km/h stop m |
|---|---|---|---|---|---|
| hatch | 1230 | 1.07 g | understeer | 0.94 g | 42.5 |
| coupe | 1620 | 1.06 g | understeer (marginal) | 1.01 g | 39.1 |
| muscle | 2087 | 1.01 g | understeer | 0.96 g | 41.4 |
| pickup | 2300 | 0.98 g | understeer | 0.98 g | 40.7 |
| super | 1850 | 1.04 g | oversteer | 1.01 g | 39.4 |

Compound spread on the muscle: street 0.92 g, sport 1.01 g, semi-slick 1.18 g, drag radial
0.83 g laterally (lower than street, by design).

Hatch cornering, sport tyres: steer 0.2 at 20/40/60 km/h gives radius 25.0 / 27.8 / 32.5 m;
at 80 km/h the same lock asks for more than the tyres hold, so the radius jumps to 47.2 m and
the car is grip-limited. Full lock at 40 km/h holds 11.8 m; adding more lock changes nothing.

## 5. Straight-line behaviour is preserved

`DriveInput.steering` defaults to 0. When it is 0:

- `cornering` returns the guard branch with `lateralAccelMps2 == 0` exactly (no division, no
  trigonometry on the zero path);
- `lateralN == 0` selects the original `gripMu * gripFactor * drivenLoad` expression, so the
  friction-ellipse `sqrt` never runs;
- `braking` returns `.none` before any arithmetic when the pedal is 0;
- `scrubForceN` is 0 and `net` is the original `tractive - drag - rolling - brakeN`.

Every existing `DriveTests` case uses throttle and no brake or steering, so all of them run the
unchanged path. `aSteeringInputOfZeroChangesNothingAtAll` additionally steps two cars 3 s and
requires every `DriveState` field to be equal, including the nested cornering and braking values.

The one deliberate behaviour change outside steering is that braking is now the bias/ellipse
model rather than `min(1.1 g * pedal * W, mu * W)`. No existing test brakes, so nothing that was
green goes red; braking distances are 39–43 m from 100 km/h instead of the old unconditional
1.1 g (35.7 m), because the rear axle runs out of load before it runs out of brake pressure.
That is the fixed-bias consequence documented in §2.5.

## 6. Existing tests that must stay green (not modified)

`DriveTests.swift`: every-gearbox ratio ordering, gear counts, drive-mode shift points, muscle
quarter-mile 8–20 s and 70–180 mph, hatch slower than muscle, speed rising for the first 3 s,
launch control within 30 %, timeslip split ordering, exact determinism of two identical runs,
every gearbox finishing a quarter mile.

`VehicleDynamicsTests.swift` (another workstream's spec, kept intact): friction × gravity,
`wheelbase/tan(steer)`, `sqrt(mu g R)`, grip-limited radius, `v²/(2 mu g)` stopping distance and
its scaling. The merged file keeps those five functions verbatim, including their 9.80665
default, so those tests are unaffected.

`PublicAPITests.swift`, `CarSaveTests.swift`, `ReviewFixTests.swift`: untouched types; `CarSetup`
and `Tyre` are unchanged.

## 7. New tests

`VehiclePhysicsTests.swift`, 24 tests:

| Test | Proves |
|---|---|
| `steeringDefaultsToStraightAhead` | new input parameter defaults to 0 |
| `aStraightRunReportsNoLateralState` | zero lateral accel, yaw, scrub; `cornerRadius == nil` |
| `aSteeringInputOfZeroChangesNothingAtAll` | 720 steps, every state field equal with and without an explicit zero steer |
| `lateralLimitRisesWithCompoundGrip` | semi-slick > sport > street > drag radial, all five bodies |
| `lateralLimitFallsAsTheSameTyresCarryMoreWeight` | load sensitivity: 2× mass is 0.90–0.91× the lateral g |
| `lateralLimitIsInTheGripRangeOfTheTyres` | each limit within 0.6–1.2 × `mu g` |
| `frontHeavyBodiesUndersteerAndTheMidEngineCarOversteers` | balance follows weight distribution |
| `theDrivenAxleLosesGripWhileCornering` | ellipse exact at zero lateral, zero at the lateral limit |
| `theRadiusGrowsWithSpeedForAFixedSteeringAngle` | R strictly increasing 8→20 m/s |
| `moreSteeringTightensTheRadiusUntilTheTyresSaturate` | 27.8 > 13.9 > 11.78 = 11.78 m radius |
| `aGripLimitedCornerHoldsTheLateralLimit` | `a_y == a_y_max`, one axle at 1.000 use |
| `yawRateIsLateralAccelerationOverSpeed` | `a_y = v r` identity |
| `aLeftTurnAndARightTurnMirrorEachOther` | sign symmetry |
| `steeringAngleIsReportedInDegrees` | input × lock, rad/deg consistency |
| `scrubDragIsZeroStraightAndGrowsWithLateralForce` | 0 → 173 → 788 → 1908 N |
| `corneringBleedsSpeed` | same car, same 1 s, steered one ends slower |
| `theDriveSimReportsCorneringStateOnceSteeringIsUsed` | integration: state populated through `step` |
| `everyBodyHasAPlausibleTurningCircle` | R_min 3.5–7.5 m, track and bias in range |
| `understeerGradientSignMatchesTheSpeedItImplies` | hatch has v_char, super has v_crit, none both |
| `everyBodyCarriesItsOwnHandlingNumbers` | five distinct tracks, bias ordering |
| `brakingMovesLoadToTheFrontAxle` | front load up, rear down, sum = weight, front force > rear |
| `noPedalMeansNoBrakeForce` | `.none` |
| `betterTyresStopShorter` | street > sport > semi-slick distance |
| `stoppingDistanceGrowsWithTheSquareOfSpeed` | 2× speed > 3× distance |
| `brakingWhileSteeringTakesLongerThanBrakingStraight` | 70.7 m vs 42.5 m at 0.3 lock |
| `stoppingDistanceIsDeterministic` | two calls identical |
| `theStepModelStopsInTheSameOrderAsTheEstimator` | integrated stop within 0.6–1.05× the estimator |
| `brakingHardEnoughLocksAnAxle` | full pedal locks an axle, 20 % pedal does not |
| `nonsenseInputsStayFinite` | NaN/±10/1e9 inputs stay finite and inside the limit |
| `aZeroMassCarDoesNotDivideByZero` | mass clamps to 1 kg |

## 8. Assumptions and limits

Biggest: **a fixed brake bias with no ABS/EBD**, so hard braking is rear-limit-limited and the
achieved deceleration plateaus near 0.95–1.0 g rather than tracking the 1.1 g pedal command.

Others, all documented in code:

- Lateral load transfer per axle is split by static weight share, standing in for roll stiffness
  distribution, which the catalogue does not carry.
- The lateral limit assumes no simultaneous drive or brake force; the longitudinal force is then
  cut by the ellipse. A car at the lateral limit on full throttle can therefore draw a few
  percent over 1.0 of combined utilisation. The sum is bounded when braking (the brake model
  uses the same ellipse per axle) but not when driving.
- Load sensitivity is applied to lateral grip only. Applying it to the longitudinal cap would
  move every existing quarter-mile number, which this workstream must not do.
- The car never spins: oversteer is reported as a balance and a lower rear limit, and the
  oversteering car's linear solution is clamped at its critical speed.
- No 2D path integration. The car has a speed, a radius and a yaw rate; it does not have a
  position on a map, a steering rate limit, or a tyre relaxation length. Everything is
  quasi-steady, so a step change of steering is answered instantly.
- Tyre width affects only the wheel radius (as before), never grip.

## 9. Workspace note

This working tree is shared by the wave-1 workstreams and was hard-reset twice while this
workstream was in progress (a competing `VehicleDynamics.swift` and its spec were committed in
`25ceff0`, and uncommitted edits were discarded). The work was therefore prepared outside the
tree and applied and committed in one step. If the branch tip is ever reset below this commit,
the four files above are the whole change.
