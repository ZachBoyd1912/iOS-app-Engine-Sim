# WS08 — Editable tune tables

**Branch:** `piston-forge-v2` · **Files:** `Native/App/Screens/TuneScreen.swift` (only) ·
**Components.swift:** unchanged — no reusable control was needed; the cell button and the cell
editor exist on this screen alone.

The Tune tab used to draw a read-only 38 × 26 pt fuel/ignition grid. Tuning is the product, so a
cell is now a control: select it, change it, and the edit goes straight into `EngineBuild` — which
means `GameStore.build` → `EngineSim.setBuild` → the running engine, the warnings banner, the dyno
pull and the exhaust sound all see it immediately. **Nothing is held in a local draft: there is no
unwired setter to wire.** `ECUMap.afrTable` / `.ignitionTable` are already `public var`, and
`TuneScreen` already has `@Binding var build`, so `build.ecu.<table>[row][column] = value` is the
whole wiring. The GameStore API was not touched.

## Interaction model

1. **Tap a cell** → it gains an accent outline and a *cell editor bar* slides in along the bottom of
   the screen (`safeAreaInset`, so it never covers the table and never scrolls away). The bar names
   the cell ("Load 140 kPa · 4,000 rpm"), says what the number does, and holds:
   - **Less / More** buttons — one step (1° of timing, 0.1 of AFR), 44 pt each.
   - **Value field** — decimal pad, numeric entry. Nothing is written keystroke by keystroke; the
     typed number is committed on Done, on focus loss, or when the player moves to another control.
   - **Slider** across the model's own range, same step. Live: each step it crosses is a real edit.
2. **Table picker** switches Ignition ↔ AFR. The selected coordinate is kept, so the same cell in
   the other table can be edited next (both tables share the 12 × 16 load/rpm axes).
3. **Paint by drag** (bonus) — hold a cell for half a second, then drag: every cell the finger
   crosses is set to the value of the cell where the stroke started. Let go to stop. The stroke is
   a *simultaneous* gesture, so a tap still selects, and the horizontal scroll still works normally.
4. **X** closes the editor (commits whatever is typed), and the bar disappears.

Every write is clamped to the range `ECUMap.sanitized` accepts (ignition −10…50°, AFR 6…20:1) and
snapped to the displayed step, so the saved map can never be a shape or a number the model rejects
or quietly rewrites. Writes that would not move the number are dropped, so a drag across cells that
already hold the value does not hammer the save file.

Because it is a real tune change, abusing a cell is *playable*: pull timing out of the top row and
the engine goes flat; lean the high-load columns and `.runningLean` / `.knocking` appear in the
banner and the model starts doing damage.

## Accessibility and Dynamic Type

- Cell size is a `@ScaledMetric` pair (44 pt at default text, growing with the text), so no number
  is ever clipped at large sizes and the 44 pt touch floor holds at every size. The old fixed
  `38 × 26` is gone.
- Each cell is a real button: label "Load 140 kPa, 4,000 rpm", value "12.5 to one", hint
  "Selects the cell so it can be changed below", plus the `.isSelected` trait on the chosen cell.
  Axis labels are hidden from VoiceOver (the cell labels already carry both numbers) but the grid
  keeps its summary label and `grid.table` identifier.
- The bar is the accessible path for changing a value: 44 pt buttons, a labelled slider (an
  adjustable control), full-size text that never shrinks into the grid.
- Colour still never carries meaning alone: the numbers are printed in every cell and the accent
  tint is decoration on top of them.
- The table scrolls horizontally, which is the only way to show 16 rpm columns at 44 pt. The load
  labels sit outside the horizontal scroller, so the row you are in stays named while you scroll
  across the revs.

## Wired vs TODO

| Thing | State |
| --- | --- |
| Cell read/write through `@Binding build` → `GameStore.build` → sim + save | **Wired** |
| Warnings, dyno, sound responding to a cell edit | **Wired** (existing `setBuild` path) |
| Ranges and clamping matching `ECUMap.sanitized` | **Wired** |
| Numeric entry, ±1 step, slider | **Wired** |
| Paint by drag | **Wired** in code; gesture-behaviour needs one device check |
| Malformed-table guard (Auto-tune prompt instead of a crash) | **Wired** |

No `TODO` markers were needed. Known gaps left for a later workstream, none of them blocking:

- **Pinned header row/column while scrolling.** The load column is pinned (outside the horizontal
  scroller); the rpm header row is not pinned vertically because the grid is not in its own vertical
  scroller (a nested vertical scroll inside the Tune page was judged worse than a long page).
- **Bottom sheet with peek/half/full detents** from the design spec. This workstream used a fixed
  inspect bar instead: it is always reachable while tapping cells, needs no presentation state, and
  is far less to get wrong on a build we cannot run.
- **Reset cell to the auto-base value**, multi-cell selection, and undo.
- **Landscape two-rail layout** (design 4.5) — untouched.

## file:line map (`Native/App/Screens/TuneScreen.swift`)

| Line | What |
| --- | --- |
| 11 | `struct TuneScreen` — unchanged public surface (`build`, `warnings`, `preview`, `onAutoTune`) |
| 17–25 | New state: `table`, `selection`, `entry` (text), `brush`/`paintedCell` (paint stroke), `entryFocused` |
| 28–33 | `@ScaledMetric` cell size / header height, cell spacing, named coordinate space |
| 36 | `SelectedCell` (load row + rpm column) |
| 41 | `Table` + its `range`, `step`, `format`, `unit`, `explanation` (one source of truth for grid and editor) |
| 83 | `body`: unchanged limits/fuelling/nitrous cards; table notes; `safeAreaInset` bar (141); `onChange` for selection / table / `build.ecu` (142, 146, 157) |
| 170 | `tableGrid`: guarded shape check, pinned load labels, scrolling rpm header, cell rows, `.coordinateSpace` + `.simultaneousGesture(paintGesture)`, `grid.table` summary |
| 229 | `axisLabel` — scaled axis text, hidden from VoiceOver |
| 239 | `cellButton` — the editable cell (44 pt, tint by share of range, selected outline, a11y label/value/hint, `cell.table.<row>.<column>`) |
| 273 | `paintGesture` — long press (0.5 s) then drag, in the grid's coordinate space |
| 287 | `paint(at:)` — point → cell, brush from the first cell touched, writes each new cell |
| 305 | `cellEditor` — the bottom bar (title, explanation, X, Less/field/More, slider); `panel.cellEditor` |
| 390 | `stepButton` — 44 pt ± control |
| 410 | `valueAt` — safe read of the current table |
| 419 | `write` — clamp, snap, skip no-ops, then write into `build` (the wired path) |
| 439 | `commitEntry` — parse the field, write, restore the canonical text |
| 449 | `format`, `loadText` (453), `rpmText` (458) — one set of formats for grid, bar and a11y |
| 465 | The pre-existing `slider` helper for the limits/boost/nitrous cards, unchanged |

## Verification

CI is blocked (GitHub billing), so this was **not compiled**. Everything above was checked by
reading the API surface it calls (`ECUMap`, `EngineBuild`, `GameStore.build`, `Warning`,
`Theme`). When a build is possible, check in this order:

1. `Tune → Tables → tap a cell → More` — the cell number changes, the bar stays open, the app
   relaunches with the new number (it is saved).
2. `Tune → cell → type 18 → Done` on an AFR cell at 300 kPa — the value becomes 18.0 and Dyno peak
   power drops versus the auto-base pull; `Warning` banner shows lean if the engine is run.
3. Long-press-drag across a row — the painted cells take the first cell's value, and a plain drag
   on the table still scrolls it.
4. Largest accessibility text — cells grow, nothing clips, and the bar still fits above the
   keyboard.
5. No other screen or test references the old 38 × 26 grid; `LiveAppUITests` only screenshots this
   screen and is unaffected.
