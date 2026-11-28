<#
.SYNOPSIS
  Signs and installs an .ipa through Sideloadly, with no hands.

.DESCRIPTION
  Two things make this automatable, both verified on 22/11/2026:
    1. Sideloadly accepts the IPA path as a command-line argument, so the file chooser (which
       is a container of unnamed Qt buttons and unreliable through UIA) is never needed.
    2. Its Qt window exposes real UI Automation controls: an iDevice combo, an Apple ID combo
       and a named "Start" button plus a status/percent label.

  It kills any running instance first, relaunches with a uniquely named copy of the IPA (so the
  window label proves which build is being signed), selects the right device and account, then
  presses Start and polls until 100% / Done.

  It refuses to continue and reports NEEDS_CREDENTIALS if Apple asks for a password or 2FA code.

.EXAMPLE
  .\scripts\sideloadly-install.ps1 -IpaPath builds\device-latest\PistonForge-native-unsigned.ipa
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$IpaPath,
  [int]$TimeoutSeconds = 420,
  [string]$Tag
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes

$AE = [System.Windows.Automation.AutomationElement]
$TS = [System.Windows.Automation.TreeScope]
$CT = [System.Windows.Automation.ControlType]
$Exe = 'C:\Users\zboyd\AppData\Local\Sideloadly\sideloadly.exe'
$Udid = '00008110-001A2D200CDB801E'

function Get-MainWindow([int]$procId) {
  $cond = New-Object System.Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $procId)
  foreach ($w in $AE::RootElement.FindAll($TS::Children, $cond)) {
    if ($w.Current.ClassName -eq 'QMainWindow') { return $w }
  }
  return $null
}

function Find-All($root, $controlType) {
  $cond = New-Object System.Windows.Automation.PropertyCondition($AE::ControlTypeProperty, $controlType)
  return $root.FindAll($TS::Descendants, $cond)
}

function Get-Labels($root) {
  $out = @()
  foreach ($e in (Find-All $root $CT::Text)) { $out += $e.Current.Name }
  return $out
}

function Invoke-Element($element) {
  $pattern = $null
  if ($element.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$pattern)) { $pattern.Invoke(); return $true }
  if ($element.TryGetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern, [ref]$pattern)) { $pattern.Select(); return $true }
  return $false
}

if (-not (Test-Path $Exe)) { throw "Sideloadly not found at $Exe" }
$source = (Resolve-Path $IpaPath).Path

# installd will not replace an app that is running: the install sits at 89% "Installing..."
# until it is killed. Terminate it before handing the IPA to Sideloadly.
try { & ios kill 'ie.zbautomations.pistonforge' 2>&1 | Out-Null } catch { }

# Unique name per build so the window label is proof of what is being signed.
$stamp = if ($Tag) { $Tag } else { Get-Date -Format 'yyyyMMdd-HHmmss' }
$staged = Join-Path $env:TEMP "PistonForge-$stamp.ipa"
Copy-Item $source $staged -Force
Write-Output "staged: $staged"

Get-Process sideloadly -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Start-Process $Exe -ArgumentList "`"$staged`""
Start-Sleep -Seconds 6

$proc = Get-Process sideloadly -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { throw 'Sideloadly did not start.' }
$win = $null
for ($i = 0; $i -lt 15 -and -not $win; $i++) { $win = Get-MainWindow $proc.Id; if (-not $win) { Start-Sleep -Milliseconds 500 } }
if (-not $win) { throw 'Sideloadly window not found.' }

# Confirm the app actually loaded the file we passed. Sideloadly's label collapses some
# punctuation to '?', so compare alphanumerics only.
$labels = Get-Labels $win
$normalisedLabel = (($labels -join ' ') -replace '[^A-Za-z0-9]', '')
$needle = ($stamp -replace '[^A-Za-z0-9]', '')
if (-not $normalisedLabel.Contains($needle)) {
  throw "Sideloadly did not load $staged (label shows: $($labels -join ' | '))"
}
Write-Output "window title: $($win.Current.Name)"

# Select the right device and the cached Apple ID.
foreach ($combo in (Find-All $win $CT::ComboBox)) {
  foreach ($item in (Find-All $combo $CT::ListItem)) {
    $n = $item.Current.Name
    if ($n -match [regex]::Escape($Udid)) { Invoke-Element $item | Out-Null; Write-Output "device: $n" }
    elseif ($n -match 'zachb5404@gmail\.com') { Invoke-Element $item | Out-Null; Write-Output "account: $n" }
  }
}

$start = $null
foreach ($b in (Find-All $win $CT::Button)) { if ($b.Current.Name -eq 'Start') { $start = $b; break } }
if (-not $start) { throw 'Start button not found.' }
Write-Output 'pressing Start...'
Invoke-Element $start | Out-Null

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$last = ''
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 3
  if ($start.Current.IsEnabled -eq $false) { $state = 'busy' } else { $state = 'idle' }
  $labels = Get-Labels $win
  $status = ($labels | Where-Object { $_ -match 'Done|ERROR|Error|failed|Failed|password|Password|2FA|verification|Signing|Installing' } | Select-Object -First 1)
  $pct = ($labels | Where-Object { $_ -match '^\d+%$' } | Select-Object -First 1)
  $line = "$pct $status"
  if ($line -ne $last) { Write-Output ("  " + (Get-Date -Format 'HH:mm:ss') + "  " + $line); $last = $line }

  if ($status -match 'password|2FA|verification') { Write-Output 'NEEDS_CREDENTIALS'; exit 3 }
  if ($status -match 'Done' -and $pct -eq '100%') { Write-Output 'INSTALLED'; exit 0 }
  if ($status -match 'ERROR|Error|failed|Failed') { Write-Output 'FAILED'; exit 2 }
}
Write-Output 'TIMEOUT'
exit 1
