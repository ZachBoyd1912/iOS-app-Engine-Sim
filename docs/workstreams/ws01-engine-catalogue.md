# Workstream 01 — Engine catalogue (16 layouts → 83 researched rows)

Branch `piston-forge-v2`. Scope: `Native/PistonForgeKit/` catalogue/types only. No app, workflow or
git changes. CI is blocked, so nothing here has been compiled or run.

## What I added

A **provenance-tagged data layer beside `EngineLayout`**, not a change to it.

| File | What |
|---|---|
| `Native/PistonForgeKit/Sources/PistonForgeKit/Catalog/EngineCatalog.swift` (1040 lines) | `EngineCycle`, `EngineFamily`, `FiringOrderRecord`, `Playability`, `EngineCatalogEntry`, `EngineCatalog` + all 83 rows |
| `Native/PistonForgeKit/Tests/PistonForgeKitTests/EngineCatalogTests.swift` | 6 invariant tests over the data layer |
| `docs/workstreams/ws01-engine-catalogue.md` | this report |

### Why a separate layer instead of 67 new `EngineLayout` cases

`EngineLayout` is `CaseIterable` and is the *playable* set, not the research set:

- `RootView.swift:196` builds the engine picker from `EngineLayout.allCases`.
- `SaveStore.swift:48` seeds a starter save per case, and `CarSaveTests.swift:139` asserts the save
  holds exactly `allCases.count` builds.
- `LayoutTests.swift:17/85`, `DynoTests.swift:124`, `InductionTests.swift:20`, `EngineVoiceTests.swift:44`,
  `EngineSimScriptTests.swift:10/24`, `CombustionTests.swift:30`, `ReviewFixTests.swift:107`,
  `CarSaveTests.swift:25` all iterate `allCases` and assert firing-order, dyno, fitment, audio and
  script invariants for **every** case.
- `EngineBuild.stockGeometry` and `LayoutSpec.makeSpec` are exhaustive switches, so a new case needs
  a bore, stroke and compression immediately.

Adding a case therefore requires a full firing order **and** geometry. The research sources bore and
stroke for exactly one of the 83 rows (row 47, Subaru EJ25, 99.5 x 79 mm) and that layout already
ships. Any new case would have had to invent bore/stroke, and rows without a sourced order would
have had to invent an order — both forbidden. So the catalogue carries the 83 rows with their
evidence, `EngineLayout` stays at 16, and the two cannot drift because a test asserts the mapping.

## Counts

**Catalogue rows: 83 of 83** (`EngineCatalog.all.count == 83`, ids 1...83, no gaps, no duplicates).
**Playable layouts: 16** — unchanged from before this workstream.

Playability, summing to 83:

| Bucket | Count | Meaning |
|---|---|---|
| `.playable(layout)` | **16** | Maps onto a shipped `EngineLayout` case |
| `.blockedOnGeometry` | **12** | Order known, but no sourced bore/stroke in the research |
| `.blockedOnFiringOrder` | **39** | Four-stroke piston design, order not sourced |
| `.unsupportedArchitecture` | **16** | Wrong cycle or no piston mechanism |

Firing-order evidence, summing to 83:

| Status | Count |
|---|---|
| `sourced` (citation states the sequence) | **14** |
| `derived` (research or catalogue derives it from stated crank/wire timing) | **13** |
| `notSourced` | **46** |
| `notApplicable` (single cylinder, Wankel, turbine, electric) | **10** |

Unsourced rows keep `cylinders: nil` in `FiringOrderRecord` and carry the research's own words in
`text`. No order was guessed: rows 41, 53, 67 and 68 say outright that no sequence exists.

## Where the data is

| What | Location |
|---|---|
| Types (`EngineCycle` … `EngineCatalogEntry`) | `Catalog/EngineCatalog.swift:7-157` |
| Queries and counts | `Catalog/EngineCatalog.swift:166-207` |
| **Row 01** (first data row) | `Catalog/EngineCatalog.swift:214` |
| **Row 83** (last data row) | `Catalog/EngineCatalog.swift:1030` |
| Full row block | `Catalog/EngineCatalog.swift:212-1039` |
| Tests | `Tests/PistonForgeKitTests/EngineCatalogTests.swift:7-59` |

Source of truth for every row: `docs/research/raw/engines.md:16-100` (master table) and `:195-248`
(source key). `displacement` and `redline` keep the research's `(calc)` and `(unverified)`
qualifiers verbatim, so a design choice can never be read as a sourced figure.

## Audit: the 16 shipped layouts against the research

Of the 16 playable rows, comparing the catalogue's numeric order with the order `LayoutSpec` ships:

- **7 match exactly:** rows 04 (`i2`), 08 (`i4`), 10 (`i5`), 11 (`i6`), 16 (`v2`), 22 (`v6_60`),
  55 (`w16`). Row 55 matches *by construction* — the catalogue records the shipped derived order,
  so it is not independent evidence.
- **6 disagree:** rows 05 (`i3`: research 1-3-2, shipped 1-2-3), 12 (`i8`: research 1-4-7-3-8-5-2-6,
  shipped 1-6-2-5-8-3-7-4), 30 (`v8Cross`: research 1-8-7-2-6-5-4-3, shipped 1-8-4-3-6-5-7-2),
  31 (`v8Flat`: research 1-5-3-7-4-8-2-6, shipped 1-8-2-7-4-5-3-6), 35 (`v10`: research
  1-6-2-7-4-9-5-10-3-8, shipped 1-6-5-10-2-7-3-8-4-9), 47 (`flat4`: research 1-3-4-2, shipped
  1-3-2-4).
- **3 cannot be compared:** 27 (`v6_90`: no source states the cylinder-to-angle mapping; the shipped
  1-6-5-4-3-2 is flagged `notSourced`), 39 (`v12`: source is bank-lettered 1a-6b-4a-… and not
  translatable without its numbering convention), 48 (`flat6`: source offers two valid options).

I did **not** change any of the six. Each is pinned by `LayoutTests.knownOrders`/`allOrdersPinned`,
and changing one silently changes the engine's sound (`EngineVoice` builds per-bank schedules from
it) and its 3D crank pose. That is a call for the owner, recorded here rather than made blind with
no build.

## Two judgement calls, both flagged in code

1. **Row 28 VR6 bank angle = 15 deg.** The research says "10.5-15 deg"; 15 is the top of the stated
   range, not a new number.
2. **Row 66 radial-9 order `[1,8,6,4,2,9,7,5,3]` is marked `derived`, not `sourced`.** The source
   gives distributor wiring `b0,b7,b5,b3,b1,b8,b6,b4,b2`; the b-index → cylinder-number translation
   is taken from row 64, where the article supplies the numeric form of the same convention.

## What still blocks 83 playable

1. **39 rows — no sourced firing order.** Needs a citation (Wikipedia, manufacturer, or an engine-sim
   script), not a derivation. 41 is a genuine gap in the research; 53's W8 bank count conflicts
   between two Wikipedia sections; 67/68 (twin-row radials) have no order in the source at all.
2. **12 rows — geometry.** The order is known (or trivial, for the single cylinder) but the research
   records displacement, not bore and stroke. Row 01's "518 cc (calc, E11)" was computed from a
   bore/stroke pair that was not copied into the table. Either fetch those figures or take an owner
   decision that stock geometry is a design choice like the shipped 16.
3. **16 rows — architecture.** 4 Wankel (57-60), 3 rotary-crankcase (61-63), 4 two-stroke (69-72),
   1 electric (79), 4 turbines (80-83). These need a cycle-aware simulator plus separate 3D and sound
   paths, exactly as the v2 design already scopes them (`2026-11-18-piston-forge-v2-design.md:157-161`).
4. **Shipped-order conflicts.** Design §4.1 wants the catalogue to be the single source. Six shipped
   orders disagree with it, so today it is not.
5. **Build risk.** Every new playable case must survive `allCases`-driven dyno, fitment (`everyStarterFitsSomeCar`),
   audio and script tests. None of that can be run while CI billing is blocked.

## Verification done / not done

Done mechanically: 83 entries, ids exactly 1...83 and unique; playability buckets sum to 83
(16+12+39+16); evidence buckets sum to 83 (14+13+46+10); every recorded numeric order is a
permutation of `1...cylinders`; balanced braces/parens/brackets; file is pure ASCII.

**Not done — no Swift toolchain on this Windows machine and CI is blocked: nothing here has been
compiled, `swift test` has not run, and no test in `EngineCatalogTests.swift` has ever executed.**
