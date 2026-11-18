# Portrait cockpit: fitting a dense engine-tuning simulator into a phone

Status: research notes, patterns only. No app art is copied. All downloaded screenshots are private reference in
`builds/research/portrait-dense/` and are never shipped.

## What was checked, and how far to trust it

- Downloaded 56 iPhone App Store screenshots for 22 apps (manifest with source URLs: `builds/research/portrait-dense/SOURCES.tsv`).
  Source is the iTunes lookup API (`itunes.apple.com/lookup?id=`), which returns the `mzstatic.com` image URLs in the manifest.
- Read (viewed) 12 images closely: `tuning-simulator/01.jpg`, `rev-lab/01.jpg`, `tradingview-01`, `lumafusion-01`,
  `racechrono-pro-01`, `trackaddict-01`, `tunebench-01`, `holley-terminator-x-01`, `car-scanner-elm-01`, `cubasis-3-01`,
  `webull-01`, `csr-2-drag-racing-02`. The other 44 downloaded files and the other existing reference folders were not opened.
- Most App Store shots are marketing composites (headline text, device frame, sometimes a stock background). They prove
  what the product wants to show, not how a screen behaves at a given size. Behaviour claims below are marked as
  "seen" (in a downloaded image) or "general" (standard iOS/HIG pattern, not verified in the downloads).
- The `ipadScreenshotUrls` field is populated for almost every app, so it is NOT evidence that an app supports landscape.
  The landscape evidence here is the Tuning Simulator landscape shot only.
- Not found in the App Store index: Real Racing 3, Forza Street, a Gran Turismo companion, MegaLogViewer, Dynojet Power Core as its own app.
  Not searched: Bosch and Torque dashboards beyond the Torque Pro entry.

## (a) Patterns found

Each pattern lists what it solves and where it was seen.

1. **Five-item bottom tab bar as the only top-level nav.**
   Solves: the sidebar (Garage/Tune/Dyno/Logs/Learn/Career/Setup) cannot survive a 390pt width.
   Seen: RaceChrono Pro uses a 4-item bottom bar (Camera / Timer / Gauges / Map). TrackAddict uses a 3-item bar with a raised
   centre action (a "start" button that is bigger than the others). Webull and TradingView use bottom bars.
   Note: the tab bar must stay at 5 or fewer items (HIG); the rest goes behind a "More" sheet.

2. **Raised centre action in the tab bar** for the one primary verb.
   Solves: START/STOP needs to be reachable from every tab and be visually dominant.
   Seen: TrackAddict (centre "checkered flag" is larger and ringed). General: iOS tab bars allow a custom centre control.

3. **Big-digit readout tiles with a delta bar on top.**
   Solves: many numbers must be glanceable at arm's length while driving.
   Seen: RaceChrono Timer tab. Large numerals fill the tile, a tick-marked delta bar sits above, the unit is small
   and sits on the left baseline. Relevant for the digital tiles (power, torque, timing, knock, EGT, IAT).

4. **Chart with a stacked sub-pane.**
   Solves: several series that share an x-axis (power and torque on one plot, AFR or knock on a sub-pane below).
   Seen: TradingView. Price chart on top, indicator sub-pane below, value tags on the right axis. Maps directly to the
   dyno chart plus a timing/knock sub-pane.

5. **Segmented range or metric picker directly under the chart.**
   Solves: switching the x-range or the plotted series without a toolbar.
   Seen: Webull (1D / 1W / 1M / 1Y / ALL under the chart). Tuning Simulator uses the same idea for Power / Mixture / Boost / Timing.

6. **Floating action fan for chart tools.**
   Solves: reset zoom, edit mode and info need to exist without a toolbar eating space.
   Seen: Holley Terminator X, Coolant Temp Enrich editor: a red FAB opens three labelled pills (Reset Zoom, Edit Mode, Info).
   The line graph has draggable dot handles on the curve. Map this to the ECU curve editors (boost, enrichment, timing vs load).

7. **Sectioned action list on the landing screen.**
   Solves: connect / read / log / buy actions need labels and sub-labels, not icons alone.
   Seen: TuneBench. A vehicle card with status chip, a "Recent" table, then a "Start" list with title + one-line description per row.
   Good model for the Garage/Setup entry point.

8. **Icon grid of categories.**
   Solves: many equal-weight destinations on a single screen.
   Seen: Car Scanner ELM OBD2 (2 columns of icon + label tiles: Dashboard, Live data, Freeze frame, DTC, Monitors...).
   Use for the "More" sheet (Logs, Learn, Career, Setup).

9. **Two-pane timeline with a sticky track column.**
   Solves: a table larger than the screen width, with row labels that must stay visible.
   Seen: Cubasis 3. Track names are pinned at the left, the timeline scrolls horizontally. Use for the ECU table: row header
   (RPM or load) stays pinned while columns scroll.

10. **Game HUD: throttle and gear controls in the bottom corners.**
    Solves: one-handed play; the thumb rests on the lower corners.
    Seen: CSR 2. Large +/- pads at the bottom left and right, speed read-out centre bottom.
    Use for the throttle slider and START/STOP placement in portrait.

11. **Studio-lit hero object on a dark stage with minimal copy.**
    Solves: a 3D engine must dominate the top half without crowding its readouts.
    Seen: RevLab, a single rendered object with a short headline above the phone frame. The Tuning Simulator landscape
    shot puts the 3D engine in the centre column with readouts on either side, the same idea in a different axis.

12. **Bottom sheets with detents** (general, not verified in the downloads).
    Solves: the tune cell editor and parts details should not push the main screen off. Apple's sheet presentation
    (`UISheetPresentationController`, `.medium` / `.large` / custom peek) gives peek / half / full states.
    Map to: peek (selected cell value only), half (numeric keypad and paint modes), full (table list, part compare).

13. **Landscape for large tables and charts** (general, plus Tuning Simulator).
    Solves: a 390pt-wide table is unreadable. Rotating to landscape gives a full-width grid or chart.
    Tuning Simulator's dyno sheet and ECU surface are the reference. Portrait keeps the summary; landscape opens the grid.

14. **Tab-hosted segmented control for the mode switch** (seen in Tuning Simulator's Free / Hold / Pull, and in the RevLab
    drive-mode concept as described in the brief).
    Solves: 3-4 mutually exclusive modes that must be visible at all times. Use a segmented control of 44pt rows, not a menu.

## (b) Proposed PORTRAIT wireframes (390 x 844 pt)

Scale of the ASCII below: 1 character is about 8pt wide, 1 line about 16pt tall. Zone heights are given in points
in the tables, and those are the source of truth.

Shared frame, every portrait screen:
- Status bar and Dynamic Island: 0 to 59pt (safe area).
- Header: 59 to 103pt.
- Content: 103 to 761pt.
- Tab bar: 761 to 844pt (49pt bar plus 34pt home-indicator inset).

Tab bar, five items, left to right: **Engine, Tune, Dyno, Garage, Drive**. Everything else moves behind the
header "≡" menu as a "More" sheet: Logs, Learn, Career, Setup. (Logs becomes a segment inside Dyno.)

### 1. Engine screen (cockpit)

```
+-----------------------------------------------+ 0
| 9:41                 Dynamic Island           |
| Twin Turbo V6   ● RUN       Base map    [≡]    | 59-103 header
+-----------------------------------------------+ 103
| ( tach ring 120pt )            ( boost 88pt ) |
|                                               |
|             [ 3D engine on dyno stand ]       | 103-333 stage (230pt)
|                                               |
+-----------------------------------------------+ 333
| WIDEBAND  12.6   AFR target 12.5              | 341-389 AFR bar
| RICH [========|===========================] LEAN |
+-----------------------------------------------+
| [ POWER  162 hp ]        [ TORQUE 329 Nm ]    |
| [ TIMING 16.5 deg ]      [ KNOCK  0.0 deg ]   | 397-581 digital tiles, 3 rows
| [ EGT    947 C   ]       [ IAT    46 C    ]   |
+-----------------------------------------------+
| firing  1 > 3 > 4 > 2                         | 589-617 firing-order strip
+-----------------------------------------------+
| THR [=============o---------------]  32%       | 625-673 throttle slider (48pt)
| [ Free | Hold | Pull ]        ( START / STOP )| 681-737 controls (56pt)
+-----------------------------------------------+ 737
|  Engine    Tune    Dyno    Garage    Drive     | 761-844 tab bar
+-----------------------------------------------+ 844
```

Zone table:

| Zone | Y (pt) | Height | Contents | Notes |
|---|---|---|---|---|
| Header | 59-103 | 44 | Engine name, RUN/STOP state chip, base-map name, "≡" More | State chip is text plus colour; not colour alone |
| Stage | 103-333 | 230 | 3D engine, analog tach (120pt), boost (88pt) overlaid top corners | Overlays on a 30% scrim; 3D view is decorative for VoiceOver |
| AFR | 341-389 | 48 | Wideband value and rich-lean bar | Bar is 6pt tall with a 44pt hit area only if it is interactive (it is not) |
| Tiles | 397-581 | 184 | 2 x 3 digital tiles | Monospaced digits; tiles do not need 44pt (read-only) |
| Firing | 589-617 | 28 | Firing-order strip | Read-only |
| Throttle | 625-673 | 48 | Horizontal slider, full width | Thumb reach: centre and lower third |
| Controls | 681-737 | 56 | Free/Hold/Pull segmented (left, 200pt), START/STOP round 64pt (right) | Both in the bottom third, easy thumb reach |
| Tab bar | 761-844 | 83 | Five items | Tab hit area 390/5 = 78pt wide |

Reach zones (right-handed, phone held in one hand):
- Easy (bottom third, y > 560): throttle, Free/Hold/Pull, START/STOP, tab bar. All primary controls live here.
- OK (middle third, y 300-560): tiles, AFR bar, detent sheet peek.
- Hard (top third, y < 300): read-only stage and gauges. Nothing that must be tapped in a hurry sits up here.

### 2. Tune screen (ECU table editor)

```
+-----------------------------------------------+ 0
| 59-103  Ignition advance      [ ≡ ]   Saved   |
| [ Timing | VE | AFR | Boost | Enrich ]  ->     | 103-147 table chips, scroll
+-----------------------------------------------+ 147
|   load\rpm  1k   2k   3k   4k   5k   6k   7k    |
|  100 kPa  12  14  16  18  20  22  22           | 7 x 7 grid, 44pt rows
|   90 kPa  12  14  17  19  21  23  23           | pinned row + column headers
|   80 kPa  13  15  18  20  22  24  24           |
|   70 kPa  ...                                  |
|   ...                                          | 147-455 grid (approx 308pt)
+-----------------------------------------------+ 455
| Row [ 80 kPa  v ]  Col [ 3k  v ]   [ Paint ]  | 463-507 row/col pickers
| [ Numeric entry: 18.0 ]   [ - ]   [ + ]       | 515-563 entry + steppers
+-----------------------------------------------+ 563
| (bottom sheet at peek: "80 kPa / 3000 rpm = 18.0 deg")  | 563-640 peek detent
+-----------------------------------------------+
|  Engine    Tune    Dyno    Garage    Drive     | 761-844 tab bar
+-----------------------------------------------+
```

Tune interaction rules:
- Paint mode: drag across cells. Each cell is 44pt tall and about 45pt wide (7 columns in 310pt of grid), so a drag never needs
  a precise tap. The paint value is the value the user picked in the numeric entry above.
- Numeric entry: the sheet at half detent with a keypad. Values change in steps; the steppers are 44 x 44.
- Row and column pickers: wheel pickers in the bottom sheet, for precise selection when painting is too coarse.
  They are also the VoiceOver route into a cell (see section d).
- Pinch to zoom the grid is NOT used on phones. Use horizontal pan with a pinned row header (pattern 9).
- A 7 x 7 window is the default; the full ECU table (for example 16 x 16) pans in both axes.

Bottom sheet detents on Tune:
- Peek (about 80pt): selected cell value and the row/column labels.
- Half (about 50% of the screen): numeric entry, paint toggle, pickers.
- Full: the table list (which tables this map has), table notes, and undo history.

### 3. Dyno screen

```
+-----------------------------------------------+ 0
| 59-103  Dyno              Run 1 · Base map    |
+-----------------------------------------------+ 103
| [ Power | Torque | Mixture | Boost | Timing ]  | 111-155 chart tabs, scroll
+-----------------------------------------------+ 155
|  hp /Nm                                       |
|  400 .  ---------dashed-----------            |
|  200 .                                        | 163-423 chart (260pt)
|    0 .  ------solid------                     |
|       2k   3k   4k   5k   6k   7k             |
+-----------------------------------------------+ 423
| sub-pane: knock / timing (60pt)               | 431-491
+-----------------------------------------------+ 491
| Runs:  Run 1 383 hp   Run 2 371 hp   [ Records ] | 499-539 run chips
+-----------------------------------------------+
| (bottom sheet peek: start / stop / pull)      | 561-641
+-----------------------------------------------+
|  Engine    Tune    Dyno    Garage    Drive     |
+-----------------------------------------------+ 844
```

- Rotate to landscape for a full-screen chart with the sub-pane, the same way Tuning Simulator shows the dyno sheet.
- Logs live here as a segment (Dyno / Logs), replacing the sidebar's Logs entry.
- Run chips are 44pt tall and scroll horizontally.

### 4. Garage / Parts screen

```
+-----------------------------------------------+ 0
| 59-103  Garage                    [ + Add ]   |
| [ Engine | Intake | Exhaust | Turbo | Cam ]     | 111-155 category chips
+-----------------------------------------------+ 155
| +-----------------+  +-----------------+       |
| | intake  stage 2 |  | exhaust  stock  |       | 2-column part cards
| | +12 hp  $---    |  | +0 hp           |       | 163-291 (each 128pt)
| +-----------------+  +-----------------+       |
| +-----------------+  +-----------------+       |
| | turbo  GT2860   |  | cam  243 dur    |       | 299-427
| +-----------------+  +-----------------+       |
+-----------------------------------------------+
| bottom sheet at peek: "Garrett GT2860 ... [Fit] [Compare]" | 561-641
+-----------------------------------------------+
|  Engine    Tune    Dyno    Garage    Drive     |
+-----------------------------------------------+ 844
```

- A card grid is the right fit for parts (2 columns, 390 width minus 32pt gutters).
- Part detail and "Compare" open in a bottom sheet (half detent). Compare is a two-column table, which rotates to landscape
  when there are more than two parts.
- Long names truncate with a second line; Dynamic Type grows the card height, not the font size past the card.

### 5. Gearbox / Drive-mode screen

```
+-----------------------------------------------+ 0
| 59-103  Drive                                 |
+-----------------------------------------------+ 103
| [ Comfort | Eco | Sport | Sport+ ]             | 111-155 drive-mode segments (4 x 97pt)
+-----------------------------------------------+ 155
|              [ 3D shifter ]                    | 163-363 shifter view (decorative)
|           gear  3   next 4  shift up           |
|          ( auto )  ( manual )                  | 371-415 transmission switch
+-----------------------------------------------+ 415
|    gear strip 1 2 [3] 4 5 6                    | 423-471 gear strip, 44 x 44 cells
+-----------------------------------------------+ 471
| [ BRAKE ]                    [ THROTTLE ]      | 553-657 pedals, bottom corners
|  (pedal, 120 x 104 each)                       |
+-----------------------------------------------+
|  Engine    Tune    Dyno    Garage    Drive     |
+-----------------------------------------------+ 844
```

- Mode picker is a 4-segment control. It is always visible; it is not hidden in a menu.
- Pedals sit in the bottom corners (pattern 10), the same reach zone as the Engine screen's throttle.
- Gear strip cells are 44 x 44 with the gear number as text; the current gear is shown by fill plus outline, not colour alone.

### Portrait summary table

| Screen | Primary control | Where | Sheet detents |
|---|---|---|---|
| Engine | START/STOP, throttle, Free/Hold/Pull | bottom third | peek only |
| Tune | cell paint, numeric entry, row/col pickers | middle + bottom sheet | peek / half / full |
| Dyno | chart tabs, run chips, start/stop/pull | top chart, bottom sheet | peek / full (logs) |
| Garage | part cards, fit, compare | grid, bottom sheet | peek / half |
| Drive | mode segments, shifter, pedals | top modes, bottom pedals | none |

## (c) LANDSCAPE adaptation (reuse the Tuning Simulator layout)

Tuning Simulator's landscape shot (`builds/research/tuning-simulator/01.jpg`, 2000 x 921 px) maps to a 844 x 390 pt device
(factor about 0.42). Measured from the image, approximately:

- Left sidebar: about 133px wide, so about 56pt. Seven items. In portrait this becomes the 5-item tab bar.
- Right rail: about 218px wide, so about 92pt. START/STOP round control, throttle slider (vertical), Free/Hold/Pull stack.
- Centre column: about 690pt. Top-left analog tach and boost, wideband bar under them, a 2 x 3 tile block left of the
  dyno sheet, and the 3D engine on the dyno stand filling the top right.
- Dyno sheet: bottom right, about 380pt wide, with tabs and run chip.

Landscape usable height is only about 350pt after the notch and home-indicator insets. The layout therefore:

| Portrait zone | Landscape placement |
|---|---|
| Header with ≡ | Top strip, 44pt, shared across the centre column |
| Tab bar (5 items) | Left rail, 56pt wide, icons plus short labels; "More" at the bottom |
| Stage + tach/boost | Centre-top, same overlay idea |
| AFR bar | Under the gauges, full centre width |
| Digital tiles (2 x 3) | Left of the dyno sheet; 3 x 2 instead of 2 x 3 to fit the height |
| Firing order | Thin strip at the bottom of the centre column |
| Throttle slider | Right rail, vertical (as in Tuning Simulator) |
| Free/Hold/Pull | Right rail, under START/STOP |
| START/STOP | Right rail top, 64pt round |
| Tune grid | Full width. Rotate to 12 x 12 or larger grid visible, row/column headers pinned |
| Dyno sheet | Full-screen chart with sub-pane; the sheet becomes the whole content area |
| Garage grid | 4 columns of part cards |
| Drive | Shifter left, gear strip centre, pedals right; modes top |

Rules for the landscape switch:
- Rotation keeps state. A running engine stays running across rotation.
- Only the Tune and Dyno screens get a full-width rebuild. Engine and Drive keep their rails.
- On landscape, the bottom sheet becomes a right-side inspector column (about 260pt) instead of a sheet.
- Landscape is supported but not the default; portrait must be complete on its own.

## (d) Accessibility concerns for dense screens

Targets and layout
- 44 x 44pt minimum for every interactive control (Apple HIG). WCAG 2.2 AA 2.5.8 requires only 24 x 24 CSS px; AAA 2.5.5 is 44.
  Aim for 44 across the board, including grid cells and steppers.
- Tune grid cells are 44pt tall and about 45pt wide at 7 columns. Do not go below 44 in either direction; scroll instead.
- Tab bar: five items at 78pt each, well above 44.
- Read-only tiles and the 3D view are not interactive and are excluded from the 44pt rule, but they must not be tap targets by accident.

Dynamic Type
- Digital tiles use scaled fonts up to the accessibility sizes. At AX sizes the 2 x 3 tile block switches to a single column list.
- Set a `minimumScaleFactor` only as a last resort; prefer reflow.
- Tab bar labels must not truncate; at large sizes, show icons only with a VoiceOver label.
- Headers and chips wrap or scroll horizontally; they never clip.

Contrast
- Text at least 4.5:1 (WCAG 1.4.3). Large numerals at least 3:1.
- Non-text at least 3:1 (WCAG 1.4.11): gauge needles, chart lines, the AFR bar fill, tile outlines, and the throttle track.
- Dark theme: the orange and yellow warning tones seen in Tuning Simulator (EGT, knock) need checking against the dark
  surface. Red-green is not the only signal for rich/lean; keep the text labels "RICH" and "LEAN".
- Do not use colour alone for run/stop, knock or the selected firing cylinder. Pair colour with text or shape.

Motion and 3D
- Respect Reduce Motion: no gauge overshoot, no auto-orbit of the 3D engine, no animated firing-order sweep.
- Reduce Transparency: the overlay scrim over the 3D stage becomes an opaque panel.
- Pause the 3D render when the Engine tab is not visible.

Screen reader and alternative input
- Gauges expose a value (`accessibilityValue` for the number, not a dial description).
- Tiles are grouped: label, value, unit read as one element.
- The 3D engine is decorative; give it a summary label only.
- ECU tables: expose as a grid with row and column headers, or provide a "Read table" action that speaks the row and column values.
- Paint mode is hard for VoiceOver. Provide the numeric entry and the row/column pickers as the accessible path (they are already in the design).
- Switch Control and Full Keyboard Access: every control reachable in a linear order; avoid gesture-only actions (paint drag needs a button alternative).
- Haptics: knock and over-limit events give a haptic plus visible text, not haptic alone.

Testing
- Run VoiceOver end to end on the Engine and Tune screens at AX5 text size.
- Check contrast with a tool on every colour pair; the research screenshots are not measured values.
- Check that the 44pt targets hold at the smallest supported iPhone width (390pt is the minimum for this design).

## Open items

- Real Racing 3, Forza Street and a Gran Turismo companion were not found in the App Store index used here, so their garage
  and tuning screens are not in the set. Re-search by publisher if needed.
- The 44 downloaded images not listed in section "What was checked" were not opened. Several Holley, Haltech, Syvecs and
  dyno apps are the most relevant for the Tune screen and should be viewed before the Tune wireframe is finalised.
- Bottom-sheet detents and landscape rotation patterns are general iOS knowledge, not verified in the downloads.
- No measured contrast values exist yet for the Tuning Simulator palette.
