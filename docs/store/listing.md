# Piston Forge: App Store listing (draft for version 1.0)

Status: draft. Nothing here has been entered in App Store Connect yet. Character and byte
counts were measured by a script (see "Measured" at the end). Apple's field limits are as
known at the time of writing; confirm them in App Store Connect before entering text.

Publisher: ZB Automations (Ireland). Price: free. No in-app purchases, no ads.

## 1. App name and subtitle

Name options (limit 30 characters):

| Option | Text | Characters | Status |
| --- | --- | --- | --- |
| Name 1 | Piston Forge | 12 | Picked |
| Name 2 | Piston Forge: Engine Builder | 28 | Alternative |
| Name 3 | Piston Forge: Build and Prove | 29 | Alternative |

Subtitle options (limit 30 characters):

| Option | Text | Characters | Status |
| --- | --- | --- | --- |
| Subtitle 1 | Build, tune and prove engines | 29 | Picked |
| Subtitle 2 | Build an engine, then prove it | 30 | Alternative |
| Subtitle 3 | Engine builder and tuning game | 30 | Alternative |

Picked pair: "Piston Forge" with "Build, tune and prove engines". No word is shared between
the two. Name 2 and Name 3 each repeat a word that Subtitle 1 or Subtitle 2 also uses, so if
either is chosen, pick a subtitle that avoids the name's words.

## 2. Keywords (limit 100 bytes, comma separated, no spaces after commas)

```text
car,dyno,drag,turbo,ecu,garage,workshop,offline,racing,sandbox,boost,v8,career,fuel,strip,ignition
```

No keyword repeats a word from the picked name or subtitle, and none is a plural of another
keyword. No competitor app name is used. 98 bytes (see "Measured").

## 3. Promotional text (limit 170 characters)

```text
Build an engine from parts, fit it to one of nine car bodies, map the ECU, then prove it on the dyno and the drag strip. No ads, no purchases, no account.
```

## 4. Description

Plain text. No social proof is included, because there is none yet.

```text
Build an engine from bare parts, bolt it into one of nine car bodies and see whether it holds up. Map the ECU, then prove the build on the dyno and the drag strip.

• Choose from ten engine layouts, from a three-cylinder inline to a V12 and a rotary.
• Upgrade ten groups of parts, from cylinder heads and cams to forged internals and intercoolers.
• Fit your engine to nine car bodies. Each body has real bay limits, so a big engine may not fit.
• Map the fuel and ignition tables, the air-fuel target, the boost target and the rev limit.
• Prove each build on the dyno, the quarter-mile drag strip or the handling course.
• Take on seven customer jobs. Each one has a fault to find and fix before you deliver the car on target.

No ads, no purchases and no account. Everything runs on your device, and nothing needs an internet connection to play.
```

## 5. Screenshot captions (first five)

Benefit first, two to five words each. Each one names the game screen it shows (screen labels
as the game shows them).

| No. | Caption | Words | Game screen shown |
| --- | --- | --- | --- |
| 1 | Build an engine from parts | 5 | Engine bench (engine build panel) |
| 2 | Fit it to nine bodies | 5 | Garage (car body selection) |
| 3 | Map fuel and ignition yourself | 5 | ECU calibration (fuel and ignition tables) |
| 4 | Prove it on the dyno | 5 | Dyno cell, during a pull |
| 5 | Run it down the strip | 5 | Prove it, Quarter mile tab |

Screenshot 2 shows the Garage. Confirm on the captured image that the body selection is
visible there before it is used.

## 6. What's New (version 1.0)

```text
First release. Build engines from ten layouts, fit them to nine car bodies, map the ECU, then prove each build on the dyno, the drag strip or the handling course. Career and Sandbox modes included.
```

Apple does not show "What's New" for a first version. Keep this text for the next update.

## 7. Notes for App Review

```text
Piston Forge is a single-player game. It runs entirely on the device, needs no login or account, and needs no internet connection to play. The game code and assets are bundled in the app, and nothing is downloaded after install. It has no advertising, no analytics, no in-app purchases and no user accounts, and it collects no personal data.

To reach the main features in under a minute: on the first screen, tap Sandbox. This opens the Garage with every car body and part unlocked and no cash cost. Tap Engine to build or change an engine, ECU to change the fuel and ignition tables, and Dyno to run a pull (press and hold HOLD PEDAL, or tap Run pull). Tap Prove it to run a quarter-mile or handling course run. If an action is blocked, a short message says why.

Career mode is also available from the first screen (Enter career). To start over, open Setup and tap Reset all progress.
```

## Fact sources (not for the store)

Each number used above, and where it was counted in the code. Counts are from
`C:/Users/zboyd/Desktop/iOS-app-Engine-Sim/PistonForge/src/sim/data.ts` unless stated.

- Engine layouts: 10. `LAYOUTS` record, lines 42-93 (i3, i4, i6, v6, v8, v10, v12, flat4, rotary2, rotary3). Two of them are rotaries (`rotors: 2` and `rotors: 3`).
- Car bodies: 9. `BODIES` array, lines 268-341.
- Fuels: 4 (not stated in the copy). `FUELS`, lines 114-135.
- Induction types: 7, including naturally aspirated. `INDUCTIONS`, lines 153-161. Not stated as a number in the copy.
- Part groups: 10. `HEADS` (168-173), `CAMS` (176-182), `INTAKES` (185-189), `EXHAUSTS` (191-196), `INJECTORS` (199-205), `PUMPS` (208-213), `INTERNALS` (216-221), `VALVES` (224-228), `GASKETS` (231-235), `INTERCOOLERS` (238-242). Part options in total: 4 + 5 + 3 + 4 + 5 + 4 + 4 + 3 + 3 + 3 = 38. Not stated as a number in the copy.
- Customer jobs: 7. `CONTRACT_TEMPLATES`, lines 464-514. `src/sim/career.ts:38` copies this list into every new career, and `src/sim/save.ts:171` falls back to it, so it is the full job source. Every template has at least one fault (lines 469, 476, 483, 490, 497, 504, 511).
- Faults: 4 (vacuum leak, weak fuel pump, stuck wastegate, burnt valve). `FAULTS`, lines 418-443. Not stated as a number in the copy.
- Aero options: 4 including "No aero" (381-386). Paints: 12 (388-401). Not stated as numbers in the copy.
- ECU fields: fuel table, ignition table, AFR target, boost target, rev limit, launch RPM. `EMPTY_ECU`, lines 540-547.
- Screen labels: Garage, Engine bench, ECU calibration, Dyno cell (`src/ui/ui.ts:21-24`); rail items Garage, Engine, ECU, Dyno, Prove it, Parts, Jobs (`src/ui/ui.ts:31-38`).
- Prove it tabs: "Quarter mile" and "Handling course" (`src/ui/views/test.ts:29-30`).
- Dyno buttons: "HOLD PEDAL" and "Run pull" (`src/ui/views/dyno.ts:42-43`).
- Title buttons: "Enter career" or "Continue career", and "Sandbox" (`src/ui/views/title.ts:22, 26`).
- Sandbox unlocks: unlock checks are skipped when `mode === 'sandbox'` (`src/app.ts:258, 458, 732`), and no cash is charged (`src/app.ts:1489`).
- Blocked action message: `this.toast(gate.reason, 'bad')` (`src/app.ts:891-892`).
- Reset: "Reset all progress" in Setup (`src/ui/views/settings.ts:27`).
- No network code: zero matches in `src/` and `index.html` for `https?://`, `fetch(`, `XMLHttpRequest`, `WebSocket`, `sendBeacon`, `EventSource`.
- No download after install: `capacitor.config.ts` (no remote URL) and `docs/ios-release.md` line 57.

## Measured

Counted by a script over the text in this file (run on the final version):

- Name options: 12, 28, 29 characters. Subtitle options: 29, 30, 30 characters. All within 30.
- Keywords: 98 characters, 98 bytes (limit 100 bytes). No spaces. 16 keywords. No duplicates, no plural pairs, no word shared with "Piston Forge" or "Build, tune and prove engines".
- Promotional text: 154 characters (limit 170).
- Description: 849 characters in total (Apple's limit is 4000). Hook of two sentences, six bullet lines (each starting with the bullet character U+2022), one closing line.
- Captions: each has five words.
- What's New: 197 characters.
- Notes for App Review: 887 characters, 162 words.
