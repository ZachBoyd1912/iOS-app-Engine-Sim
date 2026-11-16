# Piston Forge: Phase E plan (Planning & Design) — SUPERSEDED 16/11/2026 by docs/superpowers/specs/2026-11-16-piston-forge-native-design.md

Written 15/11/2026. Funnel state: Phase E, gate WAITING_FOR_DESIGN_APPROVAL. No build work
happens until Zach approves this plan and the screen previews in writing.

Zach's instruction: restart through the full funnel (plan, preview, approve, build, test,
fix, publish, monitor, improve). The Manus preview tooling is already deleted. The game code
Manus generated is still in place until Zach decides on each part below.

## 0. Decisions from Zach, 16/11/2026 (supersede parts of what follows)

- Section 1 list and section 4 cut list **approved** (handling lap cut from v1).
- **iOS only, forever. Native Swift**, built with the Apple iOS skills. No web code, no Capacitor.
  So no TypeScript is kept: the physics and 3D that section 1 marks "keep" are **ported** to
  Swift, with the TypeScript sim as the reference model. The career and interface are
  redesigned as planned.
- **Dark only, not black:** dark grey with game-colour hues in the background.
- **Preview widths:** 430 px phone, 1032 px iPad, plus landscape phone.

How the native build works (no Mac here):
- `Native/PistonForgeKit`: the simulation as a pure-Swift package. `swift test` runs on a Linux
  CI runner against golden fixtures exported from the TypeScript sim
  (`PistonForge/tests/export-fixtures.test.ts`, 18 cases including the stale-map seizure).
- `Native/App`: SwiftUI app, 3D in RealityKit (SceneKit is deprecated for new apps since WWDC
  2025). The Xcode project is generated from `Native/project.yml` by XcodeGen in CI.
- `.github/workflows/native.yml`: on a macOS runner, builds for the Simulator, launches it and
  takes a screenshot (how the screens are seen without a Mac), then builds the unsigned `.ipa`
  for sideloading.
- iOS 18 minimum (RealityKit's non-AR view needs it; an iPhone 13 runs iOS 26).
- The TypeScript game and Capacitor shell are deleted once the Swift sim passes the fixtures.

Proposed change to the preview rules for a native app (needs Zach's OK, it changes a house
rule): previews are SwiftUI screens shown as Simulator screenshots at the approved sizes, and
the accessibility check is Xcode's built-in accessibility audit in UI tests instead of axe,
which only works on web pages.

## 1. What the code is today

Origin measured against the Manus import commit (`a792589`). Quality from a read-only audit of
every file in `src/sim`, `src/game`, `src/audio`; the two worst findings were re-checked by
running the game's own code.

| Part | Lines | Origin | Audit verdict | Proposal |
|---|---|---|---|---|
| `src/sim` physics (`airflow`, `engine`, `ecu`, `performance`, `vehicle`) | 1,248 | Manus, untouched | Works, opinionated, but constants are copied in 2-3 places and several bugs (below) | **Keep the model, refactor**: one constants file, fix bugs, add tests first |
| `src/sim` career + catalogue (`career`, `data`, `builds`) | 902 | Manus, untouched | **Broken past job 3** (see section 2) | **Rewrite** the economy to a written design; keep the data shapes |
| `src/sim/save.ts` | 327 | Manus + ours (backup, recovery) | Sound and tested; small version-stamp bug | Keep |
| `src/sim/tutorial.ts` | 52 | Ours | Pure, tested | Keep, rewrite copy with the new UI |
| `src/platform/*` | 318 | Ours | Phone layer: haptics, lifecycle, durable save | Keep |
| `src/game` 3D scenes | 2,793 | Manus, untouched | Works; very long functions, a few visual bugs (one turbo drawn for twin-turbo, six-cylinder fires wrong order, pinch zoom reset every frame) | **Keep for v1**, fix the listed bugs; restyle only if the new art direction needs it |
| `src/audio/sound.ts` | 488 | Manus + ours | Works; bug: first tap can start two audio engines, one keeps droning | Keep, fix the bug, then audio pass |
| `src/ui` + `src/app.ts` + CSS | 3,564 | Manus, near untouched | Desktop-first, small touch targets, keyboard hints on a phone, game rules buried in `app.ts` | **Rewrite** to the ZB UX standard after previews are approved |
| `src/sim/types.ts` | 330 | Manus + 4 lines ours | Shared types; mixes screen state into save types | Keep, split screen state out during the rewrite |
| `src/engine/loop.ts` | 73 | Manus, untouched | Fixed-step game loop | Keep |
| `src/main.ts` | 75 | Manus + ours (start-up, phone layer) | Start-up wiring | Keep, adjust for the new interface |

Short version: keep the engine physics and the 3D scenes, rebuild the career economy and the
whole interface. That replaces about 4,500 of the 9,800 Manus lines and refactors the rest.

## 2. Bugs that decide the plan

Bugs 1 to 4 were reproduced by running the game's own code on 15/11/2026. Bug 5 comes from
reading the code and has not been run.

1. **Career stalls after three jobs (run).** Contracts 4 and 5 ship customer engines that are
   116 mm and 129 mm too long for their own cars (`fitment()` run on every contract). The game
   refuses dyno, strip and handling tests on an engine that does not fit (`canRun` in `app.ts`),
   so those jobs cannot be delivered without re-engineering the customer's engine. Contracts 6
   and 7 then stay locked by reputation. Rep reachable in practice: 80; cash about 10,800
   (hand sum, not run).
2. **The economy cannot finish even if 1 is fixed (run).** All seven jobs pay 35,200 cash and
   485 rep in total. The supercar costs 48,000 and the Legend tier needs 550 rep.
3. **Fitting a cam can seize the engine on the next pull (run).** Fitting a part keeps the old
   fuel map. On the starting engine, the second and third cam upgrades on the old map seize it
   on the first dyno pull (condition 58 → 0, cause "lean"); the same engine on a fresh map is
   unharmed. The top head upgrade costs 11 points of condition per pull. A seized engine can be
   repaired or rebuilt for cash, so the player loses money and the job budget, not the car.
4. **Handling top speed is a units bug (run).** Power in kilowatts is compared with demand in
   watts (`vehicle.ts:243-249`), so the loop exits at once and every car's handling speed trap
   reads 99 km/h.
5. **Audio (code reading).** Three tap handlers can each start the audio before the first
   finishes, which can leave a second audio engine droning under the game.

All five get tests written first, then fixes, in the Build phase.

## 3. Game brief (draft for Zach to correct after playing)

- **One line:** build, tune and run engines in a workshop, on a phone, in short sessions.
- **Player:** car people who like tuning games; plays in 5-15 minute sessions, one hand often.
- **Core loop:** take a job → diagnose and fix → tune on the dyno → prove it on the strip →
  deliver for cash and reputation → spend on parts and cars.
- **Price:** free, no ads, no purchases (Zach, 15/11/2026).
- **Platforms:** iPhone first; iPad supported because the project targets it.
- **Original only:** no real car designs, logos, brands or recordings.

## 4. Proposed cut list for v1 (Zach to approve or change)

| Feature | Proposal | Why |
|---|---|---|
| Handling lap | Cut from v1 | Bugged, thin, and a third test mode on a phone screen |
| Rotary engine | Keep | Distinctive, works |
| Sandbox mode | Keep | Free play with no economy risk |
| Paint and finish options | Keep, simplify | Already works and costs little to keep |
| Seven-job career | Replace with a designed ladder (about 12 jobs) that reaches every car and tier | Current one cannot be finished |

## 5. Decisions needed from Zach

1. **Approve the keep/refactor/rewrite proposals** in section 1, part by part.
2. **Play the sideloaded build** and send three things you liked and three you didn't. They
   go into the brief.
3. **Approve the cut list** in section 4.
4. **UI parts source.** House rule (§18) says components come from Lightswind/Watermelon first,
   but those are React libraries and the game's interface is plain TypeScript. Options:
   (a) keep plain TypeScript and follow the ZB UX standard's rules without the libraries;
   (b) move the interface to React so the libraries apply (bigger bundle, more work).
   Recommendation: (a). A game HUD over a 3D canvas is not a web app, and the libraries add
   weight for screens they were not designed for.
5. **Light theme.** The ZB UX standard asks for previews in light and dark. The game is
   dark-only today, which suits a workshop scene. Options: dark-only (recommended), or add a
   light theme.
6. **Preview widths.** The standard's widths are 1280 px and 430 px. For a phone game the useful
   pair is 430 px phone and 1032 px iPad. Recommendation: use 430 and 1032, plus landscape phone.

## 6. Phase E steps for an internal product

Checked against the funnel's Phase E (steps 34-44):

| Step | Applies? | How |
|---|---|---|
| Content request with 5-day deadline | No | Internal product; the content is ours |
| Sitemap / wireframe | Yes | Screen map in plain words, with the previews |
| 2-3 design directions, screenshots at 430 px and desktop | Yes | 2-3 visual directions for the HUD and one key screen; widths per decision 6 |
| Design approval gate | Yes | Zach approves in writing ("design approved for Piston Forge") |
| Build plan, stack, early preview deploy | Partly | Plan and stack (this document plus decision 4); the "preview deploy" is the sideloaded build, not a website |
| Seed `docs/spec.md`, `docs/design.md`, `docs/plan.md` | Yes | Written from this plan once approved |
| Confirm plan and start date | Yes | With Zach |

## 7. What happens after approval

1. **Preview:** each rebuilt screen as a labelled PREVIEW with sample data, from the ZB UX
   standard's rules, listing the pattern rules it uses, checked with axe (WCAG 2.2 AA), at the
   widths and themes Zach picks in decisions 5 and 6. Zach approves screens before they are built.
2. **Build:** tests for section 2 first, then fixes, economy rewrite, interface rewrite.
3. **Test:** unit tests, smoke run, cloud iOS build, then a sideloaded build on Zach's iPhone.
4. **Fix, publish, monitor, improve:** TestFlight and App Store once the Developer Program is
   bought; analytics decision before launch.
