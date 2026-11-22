---
name: ios-device
description: Drive a real iPhone from this Windows PC over USB — install, launch, screenshot, read syslog and tap the UI — with no Mac, no Xcode and no jailbreak. Use when a task needs proof on a physical iPhone (Piston Forge or any IPA), when asked to "test on the phone", "run it on the real device", "take a device screenshot", or when a Windows-only limitation blocks something that only a real device can settle.
---

# iOS device harness (Windows → real iPhone)

A real iPhone is attached to this machine. Everything below is verified on
**iPhone14,5 / iOS 27.2 (24B5099f) / go-ios 1.3.2 / Windows 11**.

## What this replaces

There is no usable virtual iPhone on Windows. `ipasim` is an abandoned WinObjC-era
emulator for toy apps; vPhone needs Apple Silicon macOS. This harness drives the
**actual phone over USB**, which is stronger than any emulator for testing a real IPA.

## One command entry point

Run from the Piston Forge repo root (`C:\Users\zboyd\Desktop\iOS-app-Engine-Sim`).
The script resolves the repo root itself, so `scripts\device.ps1` works from any cwd.

```powershell
.\scripts\device.ps1 status      # device, iOS, tunnel, installed Piston Forge version
.\scripts\device.ps1 start       # userspace tunnel (no admin, no wintun)
.\scripts\device.ps1 launch ie.zbautomations.pistonforge
.\scripts\device.ps1 shot title  # -> builds\device\<date>\title.png  (path printed)
.\scripts\device.ps1 logs -Seconds 30 -Filter "pistonforge|crash"
.\scripts\device.ps1 install <signed.ipa>
.\scripts\device.ps1 report      # screenshot + version + syslog excerpt -> report.md
```

`shot` prints a bare absolute path — pass that straight to the Read tool to actually
look at the phone.

## Non-negotiable traps

| Trap | What to do |
|---|---|
| `install` rejects unsigned IPAs (`ApplicationVerificationFailed`) | Sign in Sideloadly first. Free Apple ID = it must be signed on this PC, every 7 days. |
| Free Apple ID may rewrite the bundle ID | Resolve from `.\scripts\device.ps1 apps`, never hardcode |
| Two devices can be paired | The script auto-detects one device; pass `-Udid` whenever more than one is attached |
| Tunnel dies on reboot / USB re-plug | `.\scripts\device.ps1 start` (idempotent — safe to call every time) |
| `ios screenshot` vs `ios ui screenshot` | The first works with just the tunnel. The second needs a UI driver installed. |
| 3 sideloaded apps / 7-day profiles | Piston Forge + one UI driver leaves one spare. Don't burn it. |
| Taps need a driver that must be signed | DeviceKit or WDA — see below. Without it, screenshot + launch + syslog still work. |

## UI automation (taps, swipes, typing, element tree)

Requires a signed helper app on the phone. Artifacts are already downloaded:

```
C:\Users\zboyd\tools\ioslab\ui\devicekit-ios-runner-0.0.18.ipa
C:\Users\zboyd\tools\ioslab\ui\WebDriverAgentRunner-13.2.0.zip
```

1. Sign + install the DeviceKit IPA once through **Sideloadly** (free Apple ID).
2. `ios ui status` → should report the driver healthy.
3. Then: `ios ui tap --x=.. --y=..`, `ios ui swipe`, `ios ui type`, `ios ui source`
   (the accessibility tree — prefer matching on labels over coordinates).

`ios ui source` is the important one: tap by accessibility label instead of pixel
guessing, which is what makes agent-driven UI testing reliable.

## Piston Forge specifics

- Bundle: `ie.zbautomations.pistonforge`
- Latest local build: `builds\v2-latest\PistonForge-native-unsigned.ipa` (0.2.0, build 1, min iOS 18.0)
- Artifacts from a run: `builds\device\<yyyy-MM-dd>\` (gitignored — don't commit screenshots)

## What an agent still cannot verify

- **Sound quality and haptics** — the code path, logs and frame timing are checkable;
  whether it sounds right in your ears is not. Capture video with sound if it matters.
- **Thermals over long sessions** — needs a 10+ minute run; sample, don't guess.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `No iPhone detected` | Unlock the phone, tap Trust, re-plug. Apple Mobile Device Service must be Running. |
| Tunnel won't come up | `.\scripts\device.ps1 stop; .\scripts\device.ps1 start`; read `%LOCALAPPDATA%\ioslab\tunnel.log` |
| Tunnel needs admin / wintun | You're on the kernel path. Use `--userspace` (the script already does). |
| App crashes on launch | `.\scripts\device.ps1 logs -Seconds 20 -Filter "crash|exception|PistonForge"` |
