<#
.SYNOPSIS
  Authorise this PC to reach the iPhone over Wi-Fi, so later sessions need no cable.

.DESCRIPTION
  Findings from docs/research/2026-11-23-wireless-device-testing.md:
    - The phone is already on the LAN (192.168.0.103, MAC matches this host's pair record) and
      accepts TCP on 62078/49152, but lockdown resets every request: an authorisation refusal.
    - `pymobiledevice3 doctor` names the missing setting: Wi-Fi connections are off for this host.
    - go-ios has no discovery of its own, so it can only use a tunnel that already exists.

  This enables Wi-Fi connections while the phone IS plugged in (it must be, once), then tells you
  to unplug. Verify afterwards with -Verify.

.EXAMPLE
  .\scripts\enable-wireless-device.ps1          # while plugged in, once
  .\scripts\enable-wireless-device.ps1 -Verify   # after unplugging
#>
[CmdletBinding()]
param(
  [switch]$Verify
)

$ErrorActionPreference = 'Stop'

if ($Verify) {
  Write-Output 'network devices visible to this PC:'
  pymobiledevice3 usbmux list --network
  Write-Output ''
  Write-Output 'If that list is empty, the phone has not authorised Wi-Fi for this host yet.'
  exit 0
}

Write-Output 'checking USB...'
$usb = pymobiledevice3 usbmux list --usb 2>&1 | Out-String
if ($usb -match '\[\s*\]' -or [string]::IsNullOrWhiteSpace($usb)) {
  throw 'No USB device. Plug the iPhone in, unlock it, and trust the computer; Wi-Fi can only be authorised over a cable, once.'
}
Write-Output $usb.Trim()

Write-Output ''
Write-Output 'enabling Wi-Fi connections for this host...'
pymobiledevice3 lockdown wifi-connections on
if ($LASTEXITCODE -ne 0) { throw 'wifi-connections on failed. On iOS 17+ this may need Developer Mode enabled.' }

Write-Output ''
Write-Output 'done. Now:'
Write-Output '  1. unplug the cable'
Write-Output '  2. run: .\scripts\enable-wireless-device.ps1 -Verify'
Write-Output ''
Write-Output 'Note: Sideloadly almost certainly still needs USB to sign with a free Apple ID, even if'
Write-Output 'screenshots and logs work over Wi-Fi. Enable it anyway - it makes the drive/verify half cable-free.'
