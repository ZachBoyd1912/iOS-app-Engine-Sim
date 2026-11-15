# Piston Forge — getting to the App Store

How the web game becomes an App Store app, what is done, and what only Zach can do.
Research was done on 15/11/2026; anything marked UNVERIFIED was not confirmed from a primary
source and must be checked on the live Apple page before it is relied on.

## The approach

The game is a web app. Capacitor 8 wraps it in a native iOS shell (a WKWebView) with the whole
game bundled inside the app, so it works offline and downloads nothing after install.

There is no Mac here. Xcode only runs on macOS, so every iOS build happens on GitHub Actions
macOS runners (`.github/workflows/ios.yml`).

| Fact | Value | Source |
| --- | --- | --- |
| Capacitor | 8.6.2, Swift Package Manager, minimum iOS 15.0, needs Xcode 26 and Node 22 | capacitorjs.com/docs/updating/8-0 |
| App Store upload floor | Built with Xcode 26 and the iOS 26 SDK | developer.apple.com/news/upcoming-requirements |
| CI runner | `macos-26` (default Xcode 26.6) | github.com/actions/runner-images |
| macOS runner cost | Free on public repos; billed at a much higher rate than Linux on private repos | docs.github.com billing pages |

## Steps

1. **Done.** Capacitor added, iOS project generated in `PistonForge/ios/`, plugins synced (Haptics, Preferences).
2. **Done.** Private GitHub repository `ZachBoyd1912/iOS-app-Engine-Sim`.
3. **Done.** The iOS project compiles: `iOS build` run 43681025886 on `macos-26`, Xcode 26.6,
   `** BUILD SUCCEEDED **` in 48 seconds. It is an unsigned Simulator build: proof that the
   project compiles, not something that can go on a phone.
4. **Waiting, Zach's call: Apple Developer Program membership.** USD 99 a year per
   developer.apple.com/programs (the EUR price for Ireland is UNVERIFIED). Enrol as an individual.
   Zach will buy it when it is needed. Everything from step 6 on needs it: without it there is
   no TestFlight and no way to put the game on a real iPhone.
5. **Done.** Bundle ID `ie.zbautomations.pistonforge` confirmed by Zach. It is permanent once
   the app record exists in App Store Connect.
6. Create an App Store Connect API key, store it as GitHub secrets, add the signed archive and
   TestFlight upload job (fastlane `pilot` with the API key is the documented route).
7. First TestFlight build on Zach's iPhone. This is the first time the game runs on a real
   device; the device checklist below is worked through here.
8. Store listing, privacy answers, screenshots, age rating, then App Review.

## Must be checked on a real iPhone (cannot be proven from Windows)

- Frame rate, heat and memory on the 3D scenes at High quality.
- Haptics fire on shift, launch and results, and the Vibration setting turns them off.
- Engine sound stops when the app goes to the background and returns after coming back.
- **The ringer switch.** WebKit treats Web Audio as "ambient", so the game is silent when the
  phone is on silent. Reports say an AVAudioSession change does not fix this from inside a
  web view (UNVERIFIED). Decide on a device: accept it (many games do) or route audio differently.
- Notch and home-indicator spacing in portrait and landscape.
- The save survives force-quit and reinstall-over-the-top.

## App Review risks

- **Guideline 4.2 (minimum functionality).** Apple rejects apps that are "a repackaged website".
  Piston Forge's defence is real: a full simulation, 3D scenes, offline play, haptics, native
  save. Keep the store listing about the game, never about the technology.
- **Guideline 2.5.2.** No code may be downloaded after install. The game loads nothing remote. Keep it so.
- **Privacy.** The game collects nothing. It still needs a privacy manifest covering the
  UserDefaults API that the Preferences plugin uses (reason code CA92.1 is UNVERIFIED), an
  App Privacy answer of "Data Not Collected", and very likely a privacy policy URL.
- **EU trader details.** Selling in the EU means an address, phone number and email are shown
  publicly on the product page. For an individual these are entered by hand (a P.O. Box is
  allowed with proof). Zach decides what goes there.

## Pricing: what the competition does (US App Store pages, read 15/11/2026)

| App | Model | Rating | Size |
| --- | --- | --- | --- |
| RevLab - Engine Simulator | Free, one-time Pro unlock $4.99 | 3.8 (6 ratings) | 146.2 MB |
| Tuning Simulator | Free, one-time Pro unlock $14.99 | 4.7 (16 ratings) | 74.1 MB |
| Engine Simulator | Free, Lifetime unlock $8.99 | 4.4 (269 ratings) | 23.3 MB |
| Mechanic: Car Tuning Simulator | Free, 10 purchases $1.99 to $7.99, ads | 4.7 (682 ratings) | 1.7 GB |

Every direct competitor is free to download; the three closest sell a one-time unlock and the
fourth uses ads plus small purchases.

**Decision (Zach, 15/11/2026): Piston Forge is fully free for now.** No price, no purchases, no
ads. That also means no StoreKit work and the simplest possible review. If a paid unlock is
added later, Apple's Small Business Program takes 15% (under USD 1M a year in proceeds).

## Open decisions for Zach

Decided on 15/11/2026: private repository, Developer Program later, bundle ID confirmed, free game.

Still open:

1. Analytics in v1: none (simplest privacy answer) or a consented kit.
2. iPad support at launch (adds a required 13-inch screenshot set) or iPhone only.
