# Testing Piston Forge on the real iPhone from Windows

Written 22/11/2026. Everything marked **Verified** below was run on this PC against the
attached phone, not inferred.

## Why not an emulator

There is no virtual iPhone on Windows:

| Option | Reality |
|---|---|
| `ipasimulator/ipasim` | WinObjC-era UWP emulator; README says "only simple applications can be emulated"; no SwiftUI/RealityKit; author states he does not plan to continue |
| vPhone / `iphone-vm` | Apple Silicon macOS only — no Windows build |
| touchHLE | High-level emulator for iPhone OS 2.x–4.x era apps only |
| `vphone-win-port` | Alpha GPU experiment; "Nothing here runs a virtual machine yet" |

So this harness drives the **physical phone** over USB. For testing a real IPA that is
strictly better than any emulator: it is the same install a player gets from the App Store.

## Verified state (22/11/2026)

| Item | Value |
|---|---|
| Device | iPhone 13 (`iPhone14,5`), **iOS 27.2** (24B5099f, beta), UDID `00008110-001A2D200CDB801E` |
| Tool | go-ios **1.3.2** (`npm i -g go-ios`) |
| Tunnel | **userspace** — no admin rights, no `wintun.dll` needed |
| Install | Piston Forge **0.2.0** (build 1) present, identical to `builds/v2-latest/PistonForge-native-unsigned.ipa` |
| Proven | `apps`, `info`, `launch`, `screenshot`, `syslog` all work over USB |
| Not yet | Taps/swipes — needs a signed UI driver, see below |

Screenshots from the first working run: `builds/device/2026-11-22/`.

## Daily use

```powershell
.\scripts\device.ps1 status        # device, iOS, tunnel, installed version
.\scripts\device.ps1 start         # idempotent; needed after reboot or re-plug
.\scripts\device.ps1 launch ie.zbautomations.pistonforge
.\scripts\device.ps1 shot title    # prints the PNG path
.\scripts\device.ps1 logs -Seconds 30 -Filter "pistonforge|crash"
.\scripts\device.ps1 install <signed.ipa>
.\scripts\device.ps1 report        # screenshot + version + syslog -> report.md
```

`shot` prints a bare absolute path over stdout so an agent can pass it straight to a
file reader and actually look at the phone.

## The one manual step: signing

An unsigned IPA is rejected by `install` with `ApplicationVerificationFailed` — verified
above with the DeviceKit runner. `ios install` is not a signer.

So the loop is:

1. CI (or a local build) produces `*-unsigned.ipa`.
2. **Sideloadly** signs it with the free Apple ID and installs it. This is the only step
   that needs a human.
3. Everything after that — launch, screenshot, syslog, report — is scripted.

**Free-account limits:** profile expires after 7 days (re-sign to fix), 3 sideloaded apps
per device. The paid Developer Program removes both and adds TestFlight; not needed yet.

## UI automation (taps, swipes, typing, element tree)

Artifacts live in `C:\Users\zboyd\tools\ioslab\ui\` — `devicekit-ios-runner-0.0.18.ipa`
(preferred) and `WebDriverAgentRunner-13.2.0.zip` (fallback). They need the same Sideloadly
signing pass once. Signing the driver costs one of the three free app slots.

Then the sequence is **not** obvious, and three things block it in order:

**1. Mount the Developer Disk Image.** `ios ui run` needs `com.apple.dt.testmanagerd.remote`,
which only exists once a DDI is mounted. go-ios's own `ios image auto` fails on this PC:

```
failed to get signature from Apple: Post "https://gs.apple.com/TSS/controller?action=2":
tls: failed to verify certificate: x509: certificate signed by unknown authority
```

That is not an Apple outage. `gs.apple.com` returns only its leaf (issuer `Apple Server
Authentication CA`) with no intermediate, and Windows' AIA fetch cannot build the chain —
`curl` reports the same `SEC_E_UNTRUSTED_ROOT`. pymobiledevice3 ships its own trust bundle and
gets through, so mount with that:

```powershell
.\scripts\device.ps1 ddi        # pymobiledevice3 mounter auto-mount
# -> DeveloperDiskImage mounted successfully
```

**2. Start the runner through testmanagerd.** The DeviceKit app is an `.xctrunner`, not a
normal app: tapping it on the home screen aborts with `XCTRunnerDaemonSession sharedSession`
assertion failure. It must be launched as a test session, and Sideloadly has rewritten its
bundle id, so pass it explicitly:

```powershell
.\scripts\device.ps1 ui-run com.mobilenext.devicekit-iosUITests.xctrunner
```

**3. Enable UI Automation on the phone.** Without it the session authorizes and then dies with
`Timed out while enabling automation mode (com.apple.dt.XCTest.XCTFuture, code 1000)` — the
phone being locked is *not* the cause. Turn it on in **Settings → Developer → Enable UI
Automation**, then re-run step 2. Keep Auto-Lock off while testing.

Once `ios ui status` answers:

```powershell
ios ui source                 # accessibility tree - match by label, not coordinates
ios ui tap --x=.. --y=..      # or tap by element once the tree is available
.\scripts\device.ps1 tree | tap | swipe | type    # pass-through wrappers
```

## Reading crash reports

The single most useful thing this harness bought on day one. Crash reports come off the
device and are symbolicated:

```powershell
.\scripts\device.ps1 crash                 # list (filter: crash 'PistonForge*')
.\scripts\device.ps1 crash copy            # -> %TEMP%\ioscrash\*.ips
```

`.ips` files are a one-line JSON header plus a JSON body. Read `exception`, `termination`,
the faulting thread's frames and `asi` — that is enough to name the bug without a debugger,
which is how the Swift 6 audio-isolation SIGTRAP was found (see CHANGELOG 22/11/2026).

## What this finally makes answerable

`docs/ios-release.md` lists six things that "cannot be proven from Windows". With this
harness they become measurable — screenshot, syslog and frame timing all come off the
device:

1. Frame rate, heat and memory on 3D scenes at High quality
2. Haptics on shift, launch and results
3. Audio stopping on background and resuming
4. The ringer-switch (silent mode) behaviour
5. Notch and home-indicator spacing, portrait and landscape
6. Save surviving force-quit and reinstall-over-the-top

Still out of reach for an agent: **whether the engine note sounds right** and **how the
haptics feel**. Those need a human ear and hand; the harness can only prove the code path
ran and capture video with sound for review.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `No iPhone detected` | Unlock, tap Trust, re-plug; check `Apple Mobile Device Service` is Running |
| Tunnel won't start | `.\scripts\device.ps1 stop` then `start`; log at `%LOCALAPPDATA%\ioslab\tunnel.log` |
| "needs elevated privileges" | You used the kernel tunnel. Pass `--userspace`; the script already does |
| `ApplicationVerificationFailed` | Unsigned IPA — sign in Sideloadly |
| App vanishes after a week | Free-account profile expired — re-sign in Sideloadly |
| Wrong phone targeted | Two devices paired; pass `-Udid` explicitly |
