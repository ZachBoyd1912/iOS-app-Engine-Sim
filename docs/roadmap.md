# Piston Forge — launch checklist

The countable list behind the "Project completion" figure in `CHANGELOG.md`. An item is ticked
only when there is evidence for it (a passing command, a file in the repo, or Zach's word for
business items). 40 items.

## A. The game (web core)

- [x] 1. Core loop playable: build engine, fit body, map ECU, dyno pull, drag run, career jobs (Manus MVP)
- [x] 2. Typecheck clean and unit tests on the simulation
- [x] 3. End-to-end smoke test plays the real loop at desktop, phone portrait and phone landscape sizes
- [x] 4. Runs on the development machine (`pnpm dev`)
- [ ] 5. Leftover template code removed (21 unused files from the starter game, unused physics library)
- [ ] 6. README describes Piston Forge, not the starter template
- [ ] 7. First-run tutorial that walks a new player through one build, one pull, one run
- [ ] 8. Phone UX pass to the ZB UX standard (44 pt targets, label sizes), preview approved by Zach
- [ ] 9. Career economy balance pass (cash, reputation, job payouts) with real play sessions
- [ ] 10. Audio pass: music bed, mix levels, engine note checked on phone speakers

## B. The phone shell

- [ ] 11. Capacitor iOS project in the repo
- [ ] 12. Haptics wired to game events
- [ ] 13. Background and resume: save on hide, engine sound stops and comes back
- [ ] 14. Durable second copy of the save in native app storage
- [ ] 15. Save backup and a version-migration path
- [ ] 16. Recovery when iOS drops the WebGL context
- [ ] 17. Web-view hardening (no text selection, long-press menu, zoom or rubber-band), safe areas checked on a device
- [ ] 18. App icon and launch screen
- [ ] 19. Silent-switch audio behaviour decided and tested on a device
- [ ] 20. Performance checked on a real iPhone (frame rate, heat, memory)

## C. The pipeline

- [x] 21. Git repository with history
- [ ] 22. GitHub remote and CI green (typecheck, tests, production build, smoke)
- [ ] 23. iOS Simulator build green on a macOS runner
- [ ] 24. Signed build uploaded to TestFlight

## D. The store

- [ ] 25. Apple Developer Program membership (paid, Zach)
- [ ] 26. Bundle ID and app record in App Store Connect
- [ ] 27. Pricing model decided (Zach)
- [ ] 28. In-app purchase and restore, if the model needs one
- [ ] 29. Privacy manifest and App Privacy label
- [ ] 30. Privacy policy page live
- [ ] 31. EU trader details entered (they become public on the product page)
- [ ] 32. Age-rating questionnaire answered
- [ ] 33. Screenshots in the required sizes
- [ ] 34. Name, subtitle, keywords, description
- [ ] 35. TestFlight with at least 10 real players, feedback logged
- [ ] 36. App Review passed

## E. The business side

- [x] 37. Funnel state and project record in the build folder
- [ ] 38. Vault mirror and pipeline row (needs Zach's OK for the new project folder)
- [ ] 39. Analytics decision for v1 (ZB standard kit or none)
- [ ] 40. Launch post or reel
