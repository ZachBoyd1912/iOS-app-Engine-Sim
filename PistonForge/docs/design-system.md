# Piston Forge — design system

**Direction:** Industrial Instrumentation. Dark workshop materials, printed scales, amber action, cyan measurement. The 3D machine is the stage; the interface is the operator's console bolted around it.

## Tokens

| Token | Value | Use |
|---|---|---|
| `--ink` | `#090b0c` | page, deepest shadows |
| `--steel-900` | `#101416` | console base |
| `--steel-800` | `#151a1d` | panel |
| `--steel-700` | `#1d2428` | raised surface |
| `--steel-600` | `#2a3338` | borders, tracks |
| `--steel-500` | `#3b474c` | disabled, ticks |
| `--bone` | `#e8e1d2` | primary type |
| `--bone-dim` | `#b7b0a2` | secondary type |
| `--muted` | `#858e8f` | captions |
| `--amber` | `#ffb23e` | primary action, warning lamps |
| `--amber-hot` | `#ff7a1a` | danger action, redline |
| `--cyan` | `#65e3d3` | measurement, fuel traces |
| `--red` | `#ff5a4d` | failure only |
| `--green` | `#9bc76a` | healthy condition |

Fonts: bundled **ManusCC0** for display/body, system monospace for every numeral, table cell and telemetry value. Numerals use `font-variant-numeric: tabular-nums`.

Radii: 2px small, 4px panels, 8px only for mobile sheets. Shadows are hard and low, not soft glass. Borders 1px, highlighted with a 1px inner top highlight `rgba(255,255,255,.05)`.

## Type scale

- Display: `clamp(2.6rem, 5.4vw, 5.4rem)`, uppercase, line-height .88, tracking -.02em.
- H1 screen: `clamp(1.5rem, 2.4vw, 2.2rem)`, uppercase, tracking .04em.
- H2 card: 1.0–1.15rem uppercase tracking .08em.
- Label: .68rem uppercase tracking .14em, muted or amber.
- Body: .88rem, line-height 1.5, bone-dim.
- Data large: `clamp(1.8rem, 3.2vw, 3rem)` monospace.
- Data small: .78rem monospace.

## Layout

Desktop: 64px topbar, 76px left rail, 30px status bar, console 340–430px on the left, 3D stage on the right. Phone: 54px topbar, 42dvh 3D stage, bottom sheet console, 60px bottom rail. Primary actions are never below the safe area.

The console always has a kicker, title, optional one-line brief, scrollable content and a sticky action bar. The largest number on a screen is the one the player came for.

## Components

- **Panel:** steel gradient, 1px `--steel-600`, corner screw marks, inset top highlight.
- **Button:** rectangular, 36–44px, uppercase .72rem tracking .12em; primary amber with ink text; ghost steel with bone; danger outlined red. Press translates 1px and darkens.
- **Segmented control:** recessed track, active segment amber underline or fill depending on importance.
- **Range:** 4px track, tick marks, 16px amber thumb; value in monospace to the right.
- **Stat tile:** label above, number below, optional delta underneath; no shadow.
- **Pill:** 11px uppercase, 1px border; amber for action, cyan for data, red for failure.
- **Gauge:** SVG analog tachometer, 240px desktop / 160px mobile, ticks every 500 rpm, redline arc, needle with slight overshoot.
- **Map grid:** 8×8 cells with color interpolation from cyan (lean) to amber (rich) / blue (retarded) to amber (advanced); selected cell 2px cyan outline; axes fixed.
- **Chart:** inline SVG, 1px grid, amber torque line, cyan power line, no gradient fill except a faint area under torque.
- **Toast:** bottom right, 2px amber left edge, 240px max, 4s.

## Motion

- Panel reveal: 8px rise + opacity, 180ms ease-out; stagger 20ms per child, max 8 children.
- Needle: 140ms spring (CSS `cubic-bezier(.2,.8,.2,1)`), slight overshoot via keyframes on update.
- Dyno: rollers spin; car squats; camera shake 0.4px at high rpm; exhaust heat shimmer only in 3D.
- Tree: 600ms between ambers, green 400ms after third.
- Reduced motion: all durations 1ms, no shake, no looping needle animation.

## Copy

Terse, mechanical, confident. Use "Build", "Map", "Pull", "Deliver", "Service". Avoid hype. Sample: "Every degree costs." / "The dyno doesn't lie." / "The strip remembers." / "No paper queens."

## Screen hierarchy

1. Title — wordmark, promise, two entries, bests.
2. Garage — car is hero; power/weight/fitment; body and appearance controls.
3. Engine — 3D cutaway is hero; assembly controls and live spec; commit cost.
4. ECU — map is hero; selected cell and warnings; targets.
5. Dyno — tach and chart are heroes; run pull or free-rev; condition and result.
6. Test — drag tree/timer or handling map; launch and shift.
7. Shop — parts counter; cash; effect before price.
8. Jobs — contract board and active job; fault diagnosis and deliver.
9. Settings — audio, quality, motion, save reset.