# Wireless install and driving of Piston Forge on Zach's iPhone 13

Research note, 23/11/2026. Question: **can the Piston Forge iOS build be installed and driven on
the phone without it being plugged into this Windows PC by USB?**

Everything under "Verified" was produced by a command on this machine tonight. Everything under
"Documented" comes from vendor docs or binary inspection and was **not** exercised end to end.

---

## Verdict

**Possible with caveats — but not today, and not without plugging the phone in exactly once.**

- The phone is **already reachable on the LAN right now** (it answers ARP at `192.168.0.103` and
  accepts TCP on the lockdown port `62078` and on `49152`), so Wi-Fi is not the problem.
- The host still has **no usable device connection**: `usbmuxd`, go-ios, and pymobiledevice3 all
  report zero devices, and a hand-rolled lockdown handshake to `62078` is reset by the phone.
  That is the signature of "this host is not authorised for Wi-Fi connections", not of a network
  fault.
- Fixing it needs **one USB session** to set the per-host `EnableWifiConnections` flag
  (`pymobiledevice3 lockdown wifi-connections on`) and, for the iOS 17+ developer path, to write a
  RemotePairing record. Apple's own equivalent is the iTunes checkbox "Sync with this iPhone over
  Wi-Fi", which is also set with the phone plugged in.
- After that one session, both halves — install and driving — should work over Wi-Fi, **subject to
  one unresolved risk on this LAN**: every mDNS/Services browse I ran returned nothing, including
  for AirPlay, which suggests multicast discovery is filtered on this network. That would break
  device auto-discovery even with Wi-Fi sync on, and it is untested.

So: **no cable-free install today; one cable session converts it into a cable-free workflow, with
a discovery caveat to verify immediately afterwards.**

---

## 1. Verified: current state of the device on the network

### 1.1 Toolchain views of the device

```
> pymobiledevice3 usbmux list
[]
```

```
> ios list --details
{"deviceList":[]}
```

```
> pymobiledevice3 doctor
pymobiledevice3 11.63.0 on Windows-11-10.0.26200-SP0, python 3.12.10

Host - this works:
  usbmux daemon        reachable, 0 device(s): none listed
  Wi-Fi devices        Apple Mobile Device Service (iTunes) (C:\Program Files\Common Files\Apple\Mobile Device Support\AppleMobileDeviceService.exe) supports it (no device is currently listed over the network)
      fix: not seeing a Wi-Fi device? it must have `pymobiledevice3 lockdown wifi-connections on` set, and *this* host must be paired with it over USB -- a device advertises one tag per paired host, so an unpaired host cannot recognise it however the setting is set
  Bonjour discovery    queries left the host on 8 of 54 interface(s)
  Tunnel (userspace)   pmd-pytcp 0.3.9
  Pairing              0 own, 0 RemotePairing, 2 in C:\ProgramData\Apple\Lockdown

Host - not available here:
  Service access       no device to connect to
  Tunnel (native)      macOS only
  Tunnel (tunneld)     not running on 127.0.0.1:49151

No device is attached, so only the host was checked.
Nothing here is blocking a device connection.
```

That "fix:" line is the tool's own diagnosis, and it names the exact missing action.

### 1.2 Bonjour / mDNS discovery

```
> pymobiledevice3 bonjour mobdev2 --timeout 12
[]
> pymobiledevice3 bonjour rsd
[]
> pymobiledevice3 bonjour remotepairing
[]
```

Because an empty browse can mean "device silent" **or** "host cannot hear mDNS", I browsed six
service types with pymobiledevice3's own mDNS implementation:

```
_apple-mobdev2._tcp.local.   0 instance(s)
_remoted._tcp.local.         0 instance(s)
_airplay._tcp.local.         0 instance(s)
_raop._tcp.local.            0 instance(s)
_googlecast._tcp.local.      0 instance(s)
_ipp._tcp.local.             0 instance(s)
```

Zero for AirPlay and RAOP as well as for the Apple device services. Every iPhone on Wi-Fi
advertises AirPlay when it is awake, so **this is most likely host- or router-side multicast
filtering, not evidence that the phone is silent.** Windows has a built-in `mDNS (UDP-In)` allow
rule, but it is scoped to `%SystemRoot%\system32\svchost.exe` (verified), and Windows Firewall
rules are per-program. Conclusion: **the Bonjour result is inconclusive.** Treat mDNS as broken
here until proven otherwise.

### 1.3 The phone itself — present and listening

Host: Wi-Fi `192.168.0.100/24`, gateway `192.168.0.1`. Subnet sweep found `.100`, `.101`, `.104`
responding to ICMP (the phone does not answer ICMP while asleep, so ping is not a usable test).

```
> arp -a | findstr 98-69-8a
  192.168.0.103        98-69-8a-e3-5f-a4     dynamic
```

`98:69:8a:e3:5f:a4` is byte-for-byte the `WiFiMACAddress` in this host's pairing record for the
phone (below), so `192.168.0.103` is the iPhone 13, not a neighbour that happens to answer.

```
> Test-NetConnection 192.168.0.103 -Port <n>
7000   -> TcpTestSucceeded=False      # AirPlay receiver port, closed
49152  -> TcpTestSucceeded=True       # the port pymobiledevice3 docs call the RemotePairing port
62078  -> TcpTestSucceeded=True       # lockdownd
62079  -> (timed out)                 # control: a closed port behaves differently
```

### 1.4 The decisive failure: the lockdown handshake is reset

I opened a socket to `192.168.0.103:62078` and sent a length-prefixed lockdown plist
(`QueryType`, then `StartSession` with this host's `HostID`/`SystemBUID` from the pair record),
in XML and in binary, plus a `GetValue`:

```
StartSession XML                   sent  428 bytes -> [WinError 10054] forcibly closed by the remote host
StartSession binary                sent  182 bytes -> [WinError 10054] forcibly closed by the remote host
QueryType XML                      sent  291 bytes -> [WinError 10054] forcibly closed by the remote host
QueryType binary                   sent   93 bytes -> EOF (device closed, 0 bytes back)
GetValue ProductVersion XML        sent  339 bytes -> [WinError 10054] forcibly closed by the remote host
62078 connect-only                 connected; 0 unprompted bytes, socket stays open
```

A bare TCP connect succeeds and the socket just sits there; the moment a lockdown request arrives
the phone resets it. That is an authorisation refusal, not a routing or firewall problem — the
packets reach the phone and the phone answers them.

### 1.5 This host is paired with the phone — but only over USB

```
> Get-ChildItem C:\ProgramData\Apple\Lockdown
00008110-001A2D200CDB801E.plist   9495   16/11/2026 15:23:05
SystemConfiguration.plist          257   16/11/2026 15:22:58
```

Keys in that record (certs and private keys redacted):

```
HostID            = 312908461617949812310098376
SystemBUID        = 312908461551358380198608376
WiFiMACAddress    = 98:69:8a:e3:5f:a4
DeviceCertificate, HostCertificate, HostPrivateKey, RootCertificate, RootPrivateKey, EscrowBag ...
```

So trust exists and the Wi-Fi MAC is on file; what is missing is the per-host "may connect over
Wi-Fi" flag (and a RemotePairing record for the iOS 17+ path). Both are set over USB.

---

## 2. go-ios 1.3.2: what network support actually exists

Read from `ios help` on the installed binary, and from the shipped binary's own strings.

Global flags that exist (verbatim from `ios list --help` and `ios --help`):

```
--udid=<udid>              Target a specific device.
--tunnel-info-port=<port>  Tunnel info API port (default 28100).
--tunnel-info-host=<host>  Tunnel info API host (default 127.0.0.1 or GO_IOS_AGENT_HOST).
--address=<ipv6addr>       Device tunnel address.
--rsd-port=<port>          Device tunnel RSD port.
--proxyurl=<url>           Outbound HTTP proxy URL.
--userspace-port=<port>    Userspace tunnel port.
```

What those do and do not give you:

| Flag | What it actually addresses | Wireless value |
|---|---|---|
| `--address` / `--rsd-port` | An **already-established** RSD tunnel endpoint (typically an IPv6 `fd…` address inside a TUN/tunnel) | None on its own — it skips discovery but assumes a tunnel exists |
| `--tunnel-info-host/port` | Where go-ios looks up an already-running tunnel agent (`ios tunnel start`, default 127.0.0.1:28100) | None on its own |
| `--userspace-port` | Local port for the userspace tunnel | None on its own |

There is **no** Wi-Fi/network discovery flag. The binary contains **0** occurrences of `bonjour`
and **0** of `mobdev2`, so go-ios does not discover devices itself — it enumerates whatever
usbmuxd (`Apple Mobile Device Service` on Windows) reports. Its only network-adjacent feature:

```
ios wifi    Install or remove a Wi-Fi auto-connect profile
            (supervised + setup = silent, else confirm on device).
            Usage: ios wifi [--ssid=<ssid>] [--password=<password>] [--enc-type=<encType>] [--remove]
```

That profile configures which Wi-Fi network the device may auto-join; it does **not** create the
host-side Wi-Fi pairing, and it needs a device connection to install in the first place.

**Net:** go-ios gains Wi-Fi the day AMDS lists the phone as a network device, and not before. The
`--address`/`--rsd-port` flags are a manual shortcut for a known tunnel, not a discovery mechanism.

---

## 3. pymobiledevice3: the Wi-Fi path it documents for Windows

From the project's own docs (v11.63.0, `docs/guides/ios17-tunnels.md`), quoted because it is
unusually specific to this exact situation:

> **Wi-Fi-only usage (no USB cable)**: run `pymobiledevice3 lockdown wifi-connections on` once over
> USB. After that the host's own daemon finds the device over Wi-Fi and every command keeps working
> with no extra flag — on macOS always, and on Windows when the *Apple Mobile Device Service* comes
> from the classic iTunes installer. If `pymobiledevice3 usbmux list` stays empty while the device
> is on the same network, the daemon has no network-device support. On Windows that means the
> Microsoft Store "Apple Devices" app, whose service discovers nothing over Wi-Fi … install iTunes
> from apple.com instead, which is the real fix and needs no flags afterwards.

Two checks against that text, both done here:

- `pymobiledevice3 doctor` reports the AMDS at
  `C:\Program Files\Common Files\Apple\Mobile Device Support\AppleMobileDeviceService.exe` — the
  **classic iTunes** component, i.e. the supported one. Good.
- `pymobiledevice3 usbmux list` is still `[]`. So by the doc's own rule, the missing piece is the
  `wifi-connections on` setting (which needs the cable), not the daemon.

The same doc also states the reverse dependency for the iOS 17+ developer services:

> **Bootstrap the RemotePairing record over USB (no Trust dialog)** … `pymobiledevice3 lockdown
> remotepairing --pair` … Because this runs over the already-trusted lockdownd (USB) transport,
> pairing is promptless.

and, on discovering a network device at a **known** address instead of via Bonjour:

> Bonjour only finds a network-paired device on the same local network. To reach one at an address
> you already know … give `UserspaceRsdTunnel` a `provider_factory` that connects to it …
> The device must already be paired for the network.

Also relevant: `pymobiledevice3 remote start-tunnel` takes `-t/--connection-type usb|wifi`
(verified in `--help`), so once the device is visible over Wi-Fi, the whole developer surface is
reachable without a cable.

Note for this phone specifically: it is on **iOS 27.2**, well past iOS 17.4, so it is on the
supported (no-root, no-tunneld) side of every one of these paths.

---

## 4. What must be enabled, and where

| Requirement | Set where | Needs a cable? |
|---|---|---|
| "Sync with this iPhone over Wi-Fi" / `EnableWifiConnections` for **this host** | iTunes on Windows: device → Summary → tick the box → Apply. Equivalent CLI: `pymobiledevice3 lockdown wifi-connections on` | **Yes — once.** Apple's own words: "Turn on Wi-Fi syncing: 1. Connect your device to your computer." |
| Same Wi-Fi network, phone awake and unlocked for the first connection | Phone | No |
| RemotePairing record (iOS 17+ developer services over Wi-Fi) | `pymobiledevice3 lockdown remotepairing --pair` over USB | **Yes — once** |
| Developer Mode (iOS 16+) | Settings → Privacy & Security → Developer Mode, then restart | No (already on for this phone — `launch`/`screenshot`/`syslog` work over USB today) |
| Trust "This Computer" | Phone dialog on first USB connect | Already done (pair record from 16/11/2026) |
| Device awake/unlocked while wirelessly driven | Phone | No |

Sources:

- Apple, *iTunes User Guide — Sync iTunes content on PC with devices on Wi-Fi*
  <https://support.apple.com/en-ie/guide/itunes/itns3751d862/windows>: "**Turn on Wi-Fi syncing**
  1. Connect your device to your computer. … 5. Select the checkbox for 'Sync with this [device]
  over Wi-Fi.' 6. Click Apply." Same page: syncing over Wi-Fi works when "your computer and device
  are connected to the same network", and "Syncing over Wi-Fi is slower than syncing over a cable."
- pymobiledevice3 docs, *iOS 17+ Developer Services via Tunnel* (quoted in §3): `wifi-connections on`
  and `lockdown remotepairing --pair` are both explicitly "once over USB".

**So yes: something must be done physically, once, with a cable.** There is no supported path that
starts from zero cable contact with a free-Apple-ID-signed app.

---

## 5. Can Sideloadly install over Wi-Fi?

**Documented in its own binary, not verified here.** Sideloadly's GUI was not running (only
`sideloadlydaemon`), and the brief forbade launching it, so I did not touch its UI or its settings.

What the evidence shows:

- `C:\Users\zboyd\AppData\Local\Sideloadly\sideloadly.exe` (84 MB) contains Wi-Fi transport logic,
  not just labels. Extracted strings:
  - `This device is WiFi-connected, cannot re-pair!`
  - `Pairing repaired, now the device should be available through Wi-Fi`
  - `WiFiAddress` alongside `HostID`, `SystemBUID`, `PairRecord`, `DevicePublicKey` in its pairing
    code, and a `*model.Device` struct with a `WiFi` field.
- Its daemon log (`sideloadlydaemon.log`) dumps exactly that model on every poll:

```
Apps [{Udid:00008110-001A2D200CDB801E Name:Zach 's iPhone IsM1:false IsTV:false WiFi:false ...}
      {Udid:00008150-00056CEE3CB8C01C Name:Chloe's iPhone ... WiFi:false ...}]
```

`WiFi:false` for both devices in the last recorded run (21/11/2026) — consistent with "no Wi-Fi
pairing has been established", and it means the field is populated from real state, not hardcoded.

Conclusion: Sideloadly has the code paths for Wi-Fi-connected devices (it even repairs pairing over
Wi-Fi), and would likely list the phone as `WiFi:true` and install over it once the host is
Wi-Fi-authorised. **Untested by me** — I did not run an install, per the brief.

---

## 6. Ranked fallbacks

Costs verified where marked; otherwise indicative.

### 1. One USB session to turn Wi-Fi on — free, ~2 minutes, unblocks everything
The only action that makes the question's premise true. Sequence when a cable is next attached:

```powershell
pymobiledevice3 lockdown wifi-connections on      # per-host Wi-Fi authorisation
pymobiledevice3 lockdown wifi-connections         # read it back, expect on
pymobiledevice3 lockdown remotepairing --pair     # iOS 17+ network pairing record, promptless
# unplug, then, with the phone on the same Wi-Fi:
pymobiledevice3 usbmux list                       # expect the device, connection type Network
pymobiledevice3 bonjour mobdev2                   # the mDNS check from §1.2 — see caveat below
```

Caveat: if §1.2's mDNS silence turns out to be the router rather than this host, discovery still
fails and the LAN/router becomes the next thing to fix (multicast/IGMP snooping on the TP-Link, or
Windows Firewall rules for whichever process does the browsing).

### 2. USB for install only, wireless for screenshots/logs — free, partial
Realistic **only if step 1 succeeds**; the "wireless half" is the same transport as the install
half, so if Wi-Fi pairing fails outright, this fallback fails with it. Its genuine value is
different: keep the phone on the charger across the room and only plug in for the 7-day re-sign.

### 3. TestFlight — 99 USD/year, zero cable forever
Apple Developer Program is "99 USD per membership year" (verified on
<https://developer.apple.com/programs/enroll/>; local currency at checkout). Then App Store
Connect + TestFlight: internal testers (≤100) need no review; external testing needs a Beta App
Review. No cable, no 7-day expiry, no 3-app limit, and it is the only option here that never
involves this PC at all. Overkill for a solo prototype unless the free-account limits (7-day
expiry, 3 apps, and the UI-automation driver eating one of those slots) are already hurting.

### 4. Cloud device farm — paid, and a free-signed IPA will not install
Verified price: **AWS Device Farm $0.17/device-minute**, one-time 1,000 free minutes, $250/month
per unmetered slot, private devices from $200/month
(<https://aws.amazon.com/device-farm/pricing/>). BrowserStack, Sauce Labs, LambdaTest and Kobiton
are the usual alternatives; their app-testing tiers are quoted per-seat/per-parallel-session and I
did not verify them tonight.

The blocker is not price, it is signing: these farms install a **signed** `.ipa` whose provisioning
profile covers **their** device UDIDs (or an ad-hoc/enterprise build). A free-Apple-ID profile is
tied to Zach's team and a 7-day expiry, so it will be rejected. Practical cost is therefore
"developer programme + a build pipeline", not "a few dollars of device time" — and none of them run
*this* phone, so they answer "does it work on an iPhone", not "does it work on Zach's iPhone".

### 5. On-device refresh tools (SideStore / AltStore) — free, still needs one USB session
Both refresh the 7-day profile from the phone itself over Wi-Fi (SideStore via a WireGuard loopback
on the device; AltStore via AltServer on the same network). Both need a pairing file produced over
USB first, so they do not remove the cable requirement — they only reduce how often it is needed.
Worth knowing if re-signing every 7 days becomes the real pain point rather than the cable.

### 6. Anything else credible
- **A Mac with Xcode**: wireless debugging ("Connect via network") is first-class, but Apple still
  requires the device to be paired by cable once. Buying a Mac to avoid a USB cable is not a
  serious option here.
- **Long cable / powered USB hub / USB-over-IP**: solves reach, not the requirement.
- **Safari-based testing of a web build**: already documented in `docs/ios-release.md`, but it
  tests a different artifact, not the shipped binary.

---

## 7. Verified vs documented — one table

| Claim | Status |
|---|---|
| The phone is on this LAN at `192.168.0.103`, MAC `98:69:8a:e3:5f:a4` | **Verified** (ARP, matches pair record) |
| The phone accepts TCP on `62078` and `49152` | **Verified** (`Test-NetConnection`) |
| No tool sees it as a device (`usbmux`, go-ios, pymobiledevice3) | **Verified** (three commands) |
| A lockdown request to `62078` is reset by the phone | **Verified** (six probe variants) |
| This host holds a USB pair record incl. the phone's Wi-Fi MAC | **Verified** (plist keys) |
| mDNS discovery on this host/network returns nothing, even for AirPlay | **Verified**, cause not determined |
| go-ios has no Wi-Fi discovery of its own; only `--address`/`--rsd-port`/tunnel-info | **Verified** (help + binary strings) |
| `pymobiledevice3 lockdown wifi-connections on` / `remotepairing --pair` require USB | **Documented** (project docs), consistent with tonight's evidence |
| Setting the iTunes "Sync over Wi-Fi" checkbox is the Apple path, and needs the cable | **Documented** (Apple iTunes User Guide) |
| Sideloadly can install to a Wi-Fi-connected device | **Documented in its binary**, not exercised |
| After the one-time enablement, install + driving work over Wi-Fi on this LAN | **Untested**, and contingent on the mDNS caveat |
| AWS Device Farm $0.17/device-minute, 1,000 free minutes | **Verified** (pricing page) |
| Apple Developer Program 99 USD/year | **Verified** (enrolment page) |

## 8. What I did not do

No settings changed on the phone or on this PC; nothing installed or uninstalled; no build, no
Sideloadly launch, no git commit. The only artifacts are this note and four throwaway probe scripts
in `%TEMP%\opencode\` (`lockdown_probe.py`, `lockdown_probe2.py`, `lockdown_probe3.py`,
`mdns_browse.py`, `mdns_unicast.py`, `banner_probe.py`). They are read-only network probes and can
be deleted.

## 9. One-line answer

The phone is already on the Wi-Fi and even listens on the right ports, but this PC is not
authorised to talk to it over Wi-Fi — one USB session running
`pymobiledevice3 lockdown wifi-connections on` (or ticking iTunes' "Sync with this iPhone over
Wi-Fi") is what converts this into a cable-free workflow.
