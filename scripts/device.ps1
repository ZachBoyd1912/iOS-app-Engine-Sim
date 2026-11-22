<#
.SYNOPSIS
  Drive a real iPhone from Windows over USB. No Mac, no Xcode, no jailbreak.

.DESCRIPTION
  Thin wrapper around go-ios (userspace tunnel, so no admin rights and no wintun.dll)
  plus the signing path that free Apple IDs need.

  Verified working on: iPhone13 (D17AP) / iOS 27.2 (24B5099f) / go-ios 1.3.2 / Windows 11.

.EXAMPLE
  .\scripts\device.ps1 status
  .\scripts\device.ps1 shot title
  .\scripts\device.ps1 launch ie.zbautomations.pistonforge
  .\scripts\device.ps1 logs -Seconds 30 -Filter pistonforge
  .\scripts\device.ps1 report
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('status', 'start', 'stop', 'apps', 'launch', 'kill', 'install', 'shot', 'logs',
    'tree', 'tap', 'swipe', 'type', 'button', 'ui', 'report', 'ddi', 'ui-run', 'crash', 'help')]
  [string]$Command = 'status',

  [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
  [string[]]$Rest,

  # Explicit device. Defaults to the single attached device.
  [string]$Udid,

  # logs / report: how long to sample syslog
  [int]$Seconds = 20,

  # logs: only keep lines matching this regex
  [string]$Filter = '.',

  # shot: output name (without extension)
  [string]$Name
)

$ErrorActionPreference = 'Stop'
$script:Root = Split-Path -Parent $PSScriptRoot
$script:StateDir = Join-Path $env:LOCALAPPDATA 'ioslab'
$script:LogFile = Join-Path $script:StateDir 'tunnel.log'

New-Item -ItemType Directory -Force -Path $script:StateDir | Out-Null

# ---------------------------------------------------------------- helpers

function Get-IosExe {
  $cmd = Get-Command ios -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $fallback = Join-Path $env:APPDATA 'npm\node_modules\go-ios\dist\go-ios-windows-amd64_windows_amd64\ios.exe'
  if (Test-Path $fallback) { return $fallback }
  throw "go-ios not found. Install it with: npm i -g go-ios"
}

function Resolve-Udid {
  if ($script:ResolvedUdid) { return $script:ResolvedUdid }
  if ($Udid) { $script:ResolvedUdid = $Udid; return $script:ResolvedUdid }

  $json = & (Get-IosExe) list --nojson 2>$null
  $match = [regex]::Match(($json -join ''), '[0-9A-F]{8}-[0-9A-F]{16}')
  if (-not $match.Success) {
    throw "No iPhone detected. Plug it in, unlock it, and tap Trust. Then re-run."
  }
  $script:ResolvedUdid = $match.Value
  return $script:ResolvedUdid
}

function Invoke-Ios {
  param([string[]]$IosArgs)
  $exe = Get-IosExe
  $all = @($IosArgs) + @("--udid=$(Resolve-Udid)")
  & $exe @all
  # Callers check $LASTEXITCODE; output stays on the pipeline for display.
}

function Get-TunnelProcess {
  Get-CimInstance Win32_Process -Filter "Name='ios.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'tunnel' -and $_.CommandLine -match 'start' }
}

function Test-Tunnel {
  $p = Get-TunnelProcess
  return [bool]$p
}

function Start-Tunnel {
  if (Test-Tunnel) {
    Write-Host "tunnel: already running" -ForegroundColor DarkGray
    return
  }
  $exe = Get-IosExe
  $udid = Resolve-Udid
  Write-Host "tunnel: starting userspace tunnel for $udid ..." -ForegroundColor Cyan
  Start-Process -FilePath $exe `
    -ArgumentList @('tunnel', 'start', '--userspace', "--udid=$udid") `
    -WindowStyle Hidden `
    -RedirectStandardOutput $script:LogFile `
    -RedirectStandardError (Join-Path $script:StateDir 'tunnel.err') | Out-Null

  # The agent needs ~2-4s to negotiate; poll instead of sleeping blind.
  for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 500
    Invoke-Ios @('apps', '--list') *> $null
    if ($LASTEXITCODE -eq 0) {
      Write-Host "tunnel: up (userspace, no admin needed)" -ForegroundColor Green
      return
    }
  }
  throw "Tunnel did not come up. Check $script:LogFile"
}

function Get-ArtifactDir {
  $d = Join-Path $script:Root ("builds\device\" + (Get-Date -Format 'yyyy-MM-dd'))
  New-Item -ItemType Directory -Force -Path $d | Out-Null
  return $d
}

function Show-AppVersion {
  $line = (Invoke-Ios @('apps', '--list')) 2>$null | Select-String 'pistonforge'
  if ($line) { return ($line -join ' ').Trim() }
  return '(Piston Forge not installed)'
}

# ---------------------------------------------------------------- commands

switch ($Command) {

  'help' {
    @'
scripts/device.ps1 <command> [args]

  status                  device, tunnel, installed Piston Forge version
  start | stop            userspace tunnel lifecycle (no admin required)
  apps [--list]           installed applications
  launch  <bundleId>      launch an app
  kill    <bundleId>      terminate an app
  install <path.ipa>      install an IPA  (must already be signed)
  shot    [name]          screenshot -> builds\device\<date>\<name>.png
  logs    [-Seconds N]    sample syslog, optionally -Filter regex
  report                  screenshot + version + 20s syslog -> report.md
  ddi                     mount the Developer Disk Image (needed for UI automation)
  ui-run                  start the DeviceKit runner through testmanagerd
  crash [pattern|copy]    list crash reports, or copy them to %TEMP%\ioscrash
  tree | tap | swipe | type | button | ui   (needs ui-run first, see docs)

Free Apple ID: an unsigned IPA is rejected by `install`. Sign it in Sideloadly
first (that also refreshes the 7-day signature). Everything else is scriptable.
'@
  }

  'ddi' {
    # go-ios `image auto` cannot do this on Windows: gs.apple.com returns a bare
    # leaf certificate that the Windows root store rejects (SEC_E_UNTRUSTED_ROOT).
    # pymobiledevice3 carries its own trust bundle, so it gets through TSS.
    Write-Host 'mounting Developer Disk Image via pymobiledevice3 ...' -ForegroundColor Cyan
    & pymobiledevice3 mounter auto-mount
    if ($LASTEXITCODE -ne 0) { throw 'DDI mount failed (is pymobiledevice3 installed? `uv tool install pymobiledevice3`)' }
  }

  'ui-run' {
    Start-Tunnel | Out-Null
    if (-not (Get-TunnelProcess)) { throw 'tunnel must be running first' }
    $bundle = if ($Rest) { $Rest[0] } else { 'com.mobilenext.devicekit-iosUITests.xctrunner' }
    $exe = Get-IosExe
    Write-Host "starting DeviceKit runner ($bundle) - Sideloadly rewrites this id, check ``.\scripts\device.ps1 apps``" -ForegroundColor Cyan
    Start-Process -FilePath $exe -WindowStyle Hidden -ArgumentList @(
      'ui', 'run', 'devicekit', "--udid=$(Resolve-Udid)",
      "--bundleid=$bundle", "--test-runner-bundleid=$bundle"
    ) -RedirectStandardOutput (Join-Path $script:StateDir 'uirun.log') `
      -RedirectStandardError (Join-Path $script:StateDir 'uirun.err') | Out-Null
    Start-Sleep -Seconds 12
    Get-Content (Join-Path $script:StateDir 'uirun.err') -ErrorAction SilentlyContinue | Select-Object -Last 3
    Write-Host 'check with: ios ui status' -ForegroundColor DarkGray
  }

  'crash' {
    $mode = if ($Rest) { $Rest[0] } else { 'list' }
    if ($mode -eq 'copy') {
      $dir = Join-Path $env:TEMP 'ioscrash'
      New-Item -ItemType Directory -Force -Path $dir | Out-Null
      $pattern = if ($Rest.Count -gt 1) { $Rest[1] } else { 'PistonForge*' }
      Invoke-Ios @('crash', 'cp', $pattern, $dir) | Out-Host
      Write-Output $dir
    } else {
      if ($mode -eq 'list') { Invoke-Ios @('crash', 'ls') | Out-Host }
      else { Invoke-Ios @('crash', 'ls', $mode) | Out-Host }
    }
  }

  'status' {
    $udid = Resolve-Udid
    $info = (Invoke-Ios @('info')) 2>$null | Out-String
    $name = [regex]::Match($info, '"DeviceName":"([^"]+)"').Groups[1].Value
    $ver = [regex]::Match($info, '"ProductVersion":"([^"]+)"').Groups[1].Value
    $model = [regex]::Match($info, '"ProductType":"([^"]+)"').Groups[1].Value

    [pscustomobject]@{
      Device  = "$name ($model)"
      iOS     = $ver
      UDID    = $udid
      Tunnel  = if (Test-Tunnel) { 'running (userspace)' } else { 'stopped' }
      App     = Show-AppVersion
      Artifacts = Get-ArtifactDir
    } | Format-List
  }

  'start' { Start-Tunnel }

  'stop' {
    $p = Get-TunnelProcess
    if (-not $p) { Write-Host 'tunnel: not running'; break }
    $p | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Write-Host 'tunnel: stopped'
  }

  'apps' { Invoke-Ios @('apps', ($Rest + '--list')) | Out-Host }

  'launch' {
    Start-Tunnel | Out-Null
    $bundle = if ($Rest) { $Rest[0] } else { 'ie.zbautomations.pistonforge' }
    Invoke-Ios @('launch', $bundle) | Out-Host
  }

  'kill' {
    $bundle = if ($Rest) { $Rest[0] } else { 'ie.zbautomations.pistonforge' }
    Invoke-Ios @('kill', $bundle) | Out-Host
  }

  'install' {
    Start-Tunnel | Out-Null
    if (-not $Rest) { throw 'Usage: device.ps1 install <path-to-signed.ipa>' }
    $ipa = (Resolve-Path $Rest[0]).Path
    Invoke-Ios @('install', "--path=$ipa")
    if ($LASTEXITCODE -ne 0) {
      Write-Host ''
      Write-Host 'Install rejected. Almost always one of:' -ForegroundColor Yellow
      Write-Host '  1. IPA is unsigned / signed for another device -> sign it in Sideloadly'
      Write-Host '  2. Free Apple ID limit (3 apps, 7-day profile) -> remove an old sideload first'
      Write-Host '  3. IPA is a simulator build (no arm64 iphoneos slice) -> rebuild for device'
    }
  }

  'shot' {
    Start-Tunnel | Out-Null
    $dir = Get-ArtifactDir
    $label = if ($Name) { $Name } elseif ($Rest) { $Rest[0] } else { Get-Date -Format 'HHmmss' }
    $out = Join-Path $dir "$label.png"
    Invoke-Ios @('screenshot', "--output=$out") | Out-Null
    if (Test-Path $out) {
      # Printed bare so an agent can read the path straight out of the output.
      Write-Output $out
    } else {
      throw 'Screenshot failed.'
    }
  }

  'logs' {
    Start-Tunnel | Out-Null
    $job = Start-Job -ScriptBlock {
      param($exe, $udid) & $exe syslog "--udid=$udid" 2>&1
    } -ArgumentList (Get-IosExe), (Resolve-Udid)

    Start-Sleep -Seconds $Seconds
    $out = Receive-Job $job
    Stop-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -Force -ErrorAction SilentlyContinue

    $lines = $out | Select-String -Pattern $Filter
    Write-Host ("syslog: {0} of {1} lines matched '{2}' in {3}s" -f $lines.Count, $out.Count, $Filter, $Seconds) -ForegroundColor DarkGray
    $lines | Select-Object -Last 40
  }

  'report' {
    Start-Tunnel | Out-Null
    $dir = Get-ArtifactDir
    $stamp = Get-Date -Format 'HHmmss'
    $png = Join-Path $dir "$stamp.png"
    Invoke-Ios @('screenshot', "--output=$png") | Out-Null

    $log = & $PSCommandPath logs -Seconds $Seconds -Filter 'pistonforge|PistonForge|crash|Crash' 2>&1

    $md = Join-Path $dir 'report.md'
    @(
      "# Device smoke report — $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
      ''
      "- Device: $(Resolve-Udid)"
      "- App: $(Show-AppVersion)"
      "- Screenshot: ``$png``"
      ''
      '## syslog excerpt'
      '```'
      $log
      '```'
    ) | Set-Content -Path $md -Encoding utf8
    Write-Output $md
  }

  default {
    # Pass-through for the UI driver commands: tree / tap / swipe / type / button / ui
    Start-Tunnel | Out-Null
    Invoke-Ios (@('ui', $Command) + $Rest) | Out-Host
  }
}
