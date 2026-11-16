# Piston Forge — launch checklist

The countable list behind the "Project completion" figure in `CHANGELOG.md`. An item is ticked
only when there is evidence for it (a passing command, a file in the repo, or Zach's word for
business items). 46 items (41-46 added 15/11/2026 when the project went back to Phase E).

Rewritten 16/11/2026 when Zach chose a native Swift app, iOS only. Items 1-24 now describe
the native app. The web game's ticks (typecheck, smoke test, Capacitor shell, haptics,
save mirroring, WebGL recovery, web CI) no longer count: that code is being replaced. The
TypeScript sim stays only as the reference model and fixture source until the port passes.

## A. The game (Swift)

- [ ] 1. Core loop playable natively: build engine, tune, dyno pull, fit to a car, drive (no career: Zach 16/11/2026)
- [x] 2. Engine simulation in PistonForgeKit, tested on Linux (`swift test`); old-game fixtures used as plausibility ranges only
- [ ] 3. UI tests drive the real loop in the Simulator, with screenshots at phone and iPad sizes
- [ ] 4. Theme tokens: dark grey (never black) with game-colour hues, approved by Zach
- [ ] 5. TypeScript game and Capacitor shell deleted once stage 1 ships
- [ ] 6. README describes the native project
- [ ] 7. First-run coach for one build, one pull, one run
- [ ] 8. Screens to the ZB UX standard (44 pt targets, Dynamic Type), previews approved by Zach
- [ ] 9. Tuning balance pass: every layout and part makes a visible, believable difference on the dyno, in the sound and on the strip
- [ ] 10. Audio pass: engine note, mix levels, checked on phone speakers

## B. The iPhone

- [ ] 11. Native Xcode project generated from `Native/project.yml` (XcodeGen), builds in CI
- [ ] 12. Haptics on game events (Core Haptics), felt on a device
- [ ] 13. Background and resume: save on backgrounding, sound stops and comes back
- [ ] 14. Save file with backup and a version-migration path (tested)
- [ ] 15. 3D scenes in RealityKit: engine, workshop, dyno, strip
- [ ] 16. Rotation and safe areas correct on iPhone and iPad
- [ ] 17. Accessibility: VoiceOver labels, Dynamic Type, Reduce Motion
- [x] 18. App icon (carried into the native app; Zach to judge the look, the mark reads a little like a clock at icon size)
- [ ] 19. Silent-switch audio behaviour decided and tested on a device
- [ ] 20. Performance checked on a real iPhone (frame rate, heat, memory)

## C. The pipeline

- [x] 21. Git repository with history
- [ ] 22. Native CI green: `swift test` on Linux and the app build on macOS
- [ ] 23. Simulator screenshot and unsigned .ipa produced by CI and installed on Zach's iPhone
- [ ] 24. Signed build uploaded to TestFlight

## D. The store

- [ ] 25. Apple Developer Program membership (paid, Zach)
- [ ] 26. Bundle ID and app record in App Store Connect (bundle ID `ie.zbautomations.pistonforge` confirmed by Zach 15/11/2026; app record waits for the Developer Program)
- [x] 27. Pricing model decided (Zach, 15/11/2026: fully free for now)
- [x] 28. In-app purchase and restore, if the model needs one (not needed: the game is free with nothing to buy)
- [ ] 29. Privacy manifest and App Privacy label (manifest done and in the app; the App Privacy label waits for App Store Connect)
- [ ] 30. Privacy policy page live
- [ ] 31. EU trader details entered (they become public on the product page)
- [ ] 32. Age-rating questionnaire answered
- [ ] 33. Screenshots in the required sizes (unticked 15/11/2026: the 15 captures and the script exist, but they show the interface that is being rewritten, so they must be retaken after it)
- [ ] 34. Name, subtitle, keywords, description
- [ ] 35. TestFlight with at least 10 real players, feedback logged
- [ ] 36. App Review passed

## E. The business side

- [x] 37. Funnel state and project record in the build folder
- [ ] 38. Vault mirror and pipeline row (needs Zach's OK for the new project folder)
- [ ] 39. Analytics decision for v1 (ZB standard kit or none)
- [ ] 40. Launch post or reel

## F. Phase E restart (added 15/11/2026; reworded 16/11/2026 for the approved native design `docs/superpowers/specs/2026-11-16-piston-forge-native-design.md`)

- [ ] 41. Every layout x induction x nitrous combination stays finite and fails with a stated cause (tested)
- [ ] 42. Changing a part never silently seizes the engine: map re-based or warning shown (tested)
- [ ] 43. Drag strip (1/4, 1/2, 1 mile, full markers, timeslip) and proving ground built (stages 2 and 3)
- [ ] 44. Engine sound generated per layout, plays on silent, stops in background (tested where CI can)
- [x] 45. Direction approved by Zach (keep/rewrite list 16/11/2026, then superseded by the native rebuild and the approved design doc)
- [ ] 46. Design approved by Zach in writing (funnel gate E): design doc approved 16/11/2026; stage 1 screen previews still to approve
