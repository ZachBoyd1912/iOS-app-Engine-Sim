<#
.SYNOPSIS
  Prove an app actually LOADS and STAYS UP on the real iPhone - not just that it flashed a
  frame. Samples the foreground state and screenshots over time, and counts crash reports.

.DESCRIPTION
  A single screenshot seconds after launch proves nothing: 0.2.0 rendered a correct-looking
  Tune screen and then died on its audio thread a moment later. This samples repeatedly and
  treats "the process is gone" and "a new crash report appeared" as failures.

  Frontmost detection uses the accessibility tree (ios ui source) and looks for labels only
  Piston Forge has, so SpringBoard or a cached snapshot cannot pass.

.EXAMPLE
  .\scripts\verify-load.ps1 -Seconds 120
#>
[CmdletBinding()]
param(
  [string]$BundleId = 'ie.zbautomations.pistonforge',
  [int]$Seconds = 120,
  [string]$Udid,
  # Labels that only prove the app under test is on screen (verified against the live tree)
  [string[]]$Markers = @('Start engine', 'Rev limiter', 'Engine speed')
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$device = Join-Path $PSScriptRoot 'device.ps1'

function Invoke-Device { param([string[]]$A) & $device @A 2>&1 }

function Get-CrashCount {
  # Count report *filenames* mentioning the app. `ios crash ls <glob>` returns files:null for a
  # pattern that does not match exactly, which silently reads as "zero crashes" - that bug made
  # this verifier report 0 for an app that had eleven reports on file.
  $out = (& ios crash ls 2>&1 | Out-String)
  return ([regex]::Matches($out, 'PistonForge-\d{4}-\d{2}-\d{2}')).Count
}

function Get-TreeJson {
  $tmp = Join-Path $env:TEMP "verify-tree-$(Get-Random).json"
  & ios ui source 2>$null | Out-File -Encoding utf8 $tmp
  if (-not (Test-Path $tmp)) { return $null }
  try { return (Get-Content $tmp -Raw | ConvertFrom-Json) } catch { return $null } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
}

function Find-Node {
  param($Node, [string[]]$Markers, [System.Collections.ArrayList]$Hits)
  if ($null -eq $Node) { return }
  if ($Node -is [System.Management.Automation.PSCustomObject]) {
    $label = "$($Node.label) $($Node.name)"
    foreach ($m in $Markers) {
      if ($label -like "*$m*") { [void]$Hits.Add($m); break }
    }
    foreach ($c in $Node.children) { Find-Node -Node $c -Markers $Markers -Hits $Hits }
  } elseif ($Node -is [array]) {
    foreach ($c in $Node) { Find-Node -Node $c -Markers $Markers -Hits $Hits }
  }
}

$dir = Join-Path $root ("builds\device\" + (Get-Date -Format 'yyyy-MM-dd'))
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$stamp = Get-Date -Format 'HHmmss'

Write-Host "`n=== load verification: $BundleId for $Seconds s ===" -ForegroundColor Cyan

$crashesBefore = Get-CrashCount
Write-Host "crash reports before: $crashesBefore"

Invoke-Device @('kill', $BundleId) | Out-Null
Start-Sleep -Milliseconds 500
Invoke-Device @('launch', $BundleId) | Out-Null
$launchedAt = Get-Date

$schedule = @(2, 8, 20, 40, 70, 110, 150) | Where-Object { $_ -le $Seconds }
$results = @()
foreach ($t in $schedule) {
  $wait = $t - ((Get-Date) - $launchedAt).TotalSeconds
  if ($wait -gt 0) { Start-Sleep -Seconds ([math]::Ceiling($wait)) }

  $shots = Invoke-Device @('shot', "verify-$stamp-t$t")
  $png = ($shots | Where-Object { $_ -match '\.png$' } | Select-Object -Last 1)

  $tree = Get-TreeJson
  $hits = New-Object System.Collections.ArrayList
  if ($tree) { Find-Node -Node $tree.result -Markers $Markers -Hits $hits }

  $alive = ($hits.Count -ge 1)
  $results += [pscustomobject]@{
    At      = "t+${t}s"
    App     = if ($alive) { 'FRONTMOST' } else { 'not frontmost' }
    Markers = ($hits | Select-Object -Unique) -join ','
    Shot    = $png
  }
  Write-Host ("  t+{0,-4}s {1,-14} {2}" -f $t, $(if ($alive) { 'FRONTMOST' } else { 'not frontmost' }), (($hits | Select-Object -Unique) -join ','))
}

$crashesAfter = Get-CrashCount
$uptime = [math]::Round(((Get-Date) - $launchedAt).TotalSeconds)

Write-Host "`ncrash reports after: $crashesAfter (new: $($crashesAfter - $crashesBefore))"
Write-Host "observed uptime: ${uptime}s`n"
$results | Format-Table -AutoSize

$stayed = ($results | Where-Object { $_.App -ne 'FRONTMOST' }).Count -eq 0
$noNewCrash = ($crashesAfter -le $crashesBefore)

Write-Host ''
if ($stayed -and $noNewCrash -and $results.Count -ge 3) {
  Write-Host "PASS - app was frontmost at every sample and produced no crash report." -ForegroundColor Green
  exit 0
}

Write-Host "FAIL - see the table above." -ForegroundColor Red
if ($crashesAfter -gt $crashesBefore) { Write-Host "  new crash report(s): run .\scripts\device.ps1 crash copy, then read exception/termination." }
if (-not $stayed) { Write-Host "  app was not frontmost at one or more samples." }
exit 1
