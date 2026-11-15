# Piston Forge — project record

Source of truth for this project. The vault copy is a mirror of this file.

## Identity

- **Project:** Piston Forge
- **Type:** Internal ZB Automations product (not a client). iOS game for the App Store.
- **Owner:** ZB Automations
- **Build folder:** `C:/Users/zboyd/Desktop/iOS-app-Engine-Sim` (game in `PistonForge/`)
- **Stage:** building
- **Funnel:** Phase F. Money gates D, H and I do not apply (no client, no deposit, no invoice).

## What it is

A single-player, offline workshop game: build an engine from parts, fit it into one of nine car
bodies, map a standalone ECU, then prove the build on a dyno, a quarter-mile strip and a
handling course. Career mode with customer contracts, and a sandbox. All 3D models and sounds
are generated in code.

## How it is built

- Web game: three.js, TypeScript, Vite. First MVP built by Manus.
- iOS shell: Capacitor 8 (WKWebView), game bundled fully offline.
- No Mac on site: iOS builds run on GitHub Actions macOS runners.
- Orchestrated by Claude Code from 15/11/2026.

## Money

- Nothing spent and nothing earned as of 15/11/2026.
- Known upcoming cost: Apple Developer Program, USD 99 a year (Apple's listed price). Not paid; Zach will buy it when it is needed, which is not yet.
- GitHub repository is private, so macOS build minutes are billed at GitHub's higher macOS rate. The iOS build runs only when the native shell changes; the first run took 48 seconds.
- The game is fully free for now: no price, no purchases, no ads (Zach, 15/11/2026).

## Minimalist Entrepreneur stage

Stage 3, Build (MVP). The playbook has Stage 5 (Sell) as the current ZB focus and a note to
freeze new building until Sell moves. This project is new building; Zach chose to start it on
15/11/2026. Stage 2 (Validate) is open for this product: no player outside ZB has seen it.

## Decision log

| Date | Decision | Who |
| --- | --- | --- |
| 2026-11-15 | Start Piston Forge as an internal product; Claude Code orchestrates the build from the Manus MVP. | Zach |
| 2026-11-15 | Wrap the web game with Capacitor 8 instead of rewriting it natively; build iOS in CI because there is no Mac. | Agent (reversible) |
| 2026-11-15 | Bundle ID is `ie.zbautomations.pistonforge`. | Zach |
| 2026-11-15 | GitHub repository is private (`ZachBoyd1912/iOS-app-Engine-Sim`). | Zach |
| 2026-11-15 | Apple Developer Program: buy it when it is needed, not now. Testing continues without it. | Zach |
| 2026-11-15 | Pricing: fully free game for now. | Zach |

## Open decisions (Zach)

See `docs/ios-release.md`, "Open decisions for Zach": analytics in v1, iPad support at launch.

## Progress

Countable checklist: `docs/roadmap.md`. History and evidence: `CHANGELOG.md`.
