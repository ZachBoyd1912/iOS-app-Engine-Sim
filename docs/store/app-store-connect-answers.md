# App Store Connect answers for Piston Forge (suggested)

Every answer in this file is suggested. Confirm each one in App Store Connect before you submit.
The live questionnaire wording was not checked, so the question names below are from memory and
may differ from the form. The evidence column cites the code or the file that supports each answer.

## 1. Age rating questionnaire

| Category | Suggested answer | Reason and evidence |
| --- | --- | --- |
| Cartoon or fantasy violence | None | Cars, engines and parts only. No characters are hurt. Damage is mechanical, such as a failed engine (`src/sim/data.ts` FAULTS, lines 418-443). |
| Realistic violence | None | No weapons, no injury, no combat. |
| Prolonged graphic or sadistic violence | None | Same as above. |
| Profanity or crude humour | None | No profanity found in the game text in `src/sim/data.ts`. |
| Horror or fear themes | None | No horror content. |
| Mature or suggestive themes | None | No mature themes in the game text reviewed. |
| Sexual content or nudity | None | No sexual content. |
| Alcohol, tobacco or drug use or references | None | None in the game text reviewed. |
| Medical or treatment information | None | No medical content. |
| Simulated gambling | None | Contract payouts are in-game money, with no chance element and no real-money play (`CONTRACT_TEMPLATES`, lines 464-514). |
| Gambling with real money | None | No real-money play, no purchases. |
| Contests | None | No contests. |
| Unrestricted web access | No | No browser feature in the app. |
| User-generated content | No | No uploads, sharing or community content. |
| Messaging or chat | No | No messaging. |
| Advertising | No | No ads (no ad SDK in `package.json`). |
| Health or wellness topics | No | None. |
| Parental controls | No | The app has no account and no parental settings. |
| Age assurance | No | No age-restricted features. |

Suggested result: 4+. Confirm the result shown in App Store Connect after you answer.

## 2. App Privacy

| Question | Suggested answer | Reason and evidence |
| --- | --- | --- |
| Data collection | Data Not Collected | The app sends nothing off the device. Zero matches in `src/` and `index.html` for `https?://`, `fetch(`, `XMLHttpRequest`, `WebSocket`, `sendBeacon` or `EventSource`. The only dependencies are `three`, `@capacitor/core`, `@capacitor/ios`, `@capacitor/haptics` and `@capacitor/preferences` (`package.json` lines 18-22). No analytics or advertising SDK. |
| Tracking | No | The app does not track users across other companies' apps or websites. |
| Third-party partners | None | No third-party SDK sends data. |
| Privacy policy URL | Required, not yet hosted | The draft is `docs/store/privacy-policy.md`. It needs a public address before submission. No address has been invented. |
| Privacy manifest (`PrivacyInfo.xcprivacy`) | Missing, must be added | `find ios -iname "*xcprivacy*"` returned nothing, and `NSPrivacyAccessedAPITypes` appears nowhere under `ios/`. The save uses Capacitor Preferences, which is backed by UserDefaults (`src/platform/index.ts` lines 43-45). Declare the UserDefaults access category with a reason code. The reason code CA92.1 is UNVERIFIED (`docs/ios-release.md` line 59). Check it on Apple's page before using it. Also check whether the Capacitor plugins ship their own manifests. |

## 3. Export compliance

| Question | Suggested answer | Reason and evidence |
| --- | --- | --- |
| Does the app use non-exempt encryption? | No | `ITSAppUsesNonExemptEncryption` is set to `false` in `ios/App/App/Info.plist` lines 25-26. The app has no network code and no custom cryptography. |

## 4. Content rights

| Question | Suggested answer | Reason and evidence |
| --- | --- | --- |
| Does the app contain, show or access third-party content? | Yes, limited to the items below. We hold the rights to all of them. | (a) The bundled font ManusCC0 is CC0 1.0 Universal. The licence header is in `PistonForge/public/fonts/ManusCC0-LICENSE.txt`, and CC0 waives rights, so no attribution is needed. (b) Open-source code libraries are three.js (MIT) and Capacitor (MIT), as credited in `PistonForge/README.md`. These are code, not content. (c) Car bodies, engines, scenes and sounds are generated in code, per the README credits. |

Points for the owner to confirm (not checked here):

- The first MVP was built by Manus (`docs/record.md` line 23). Confirm that the owner holds rights to the code produced by that tool, and that Manus's terms allow commercial release.
- `PistonForge/public/fonts/ManusCC0SansCJKSC-Regular.woff2` (942.6K) is bundled in `public/fonts/`, but no file in `src/`, `index.html` or `public/` refers to it. The game is English only, so it may be removable. This is a size question, not a rights question. Nothing was changed.

## 5. Other items that came up (not asked, for reference)

- Account deletion: not applicable, because no account is created. Confirm against the current App Review guidelines.
- Sign in with Apple: not applicable, because there is no login.
- Price: Free, with no in-app purchases (decision recorded in `docs/record.md`).
- Territories and iPad: owner decisions. `TARGETED_DEVICE_FAMILY = "1,2"` (`ios/App/App.xcodeproj/project.pbxproj` lines 316 and 337) means the build targets iPad as well as iPhone. If iPad is included, a 13-inch iPad screenshot set is required. iPad support is still an open decision (`docs/ios-release.md` line 88).
- Accessibility Nutrition Labels: not covered here.
