<#
.SYNOPSIS
  Dispatch the iOS build and prove it built the commit you think it did.

.DESCRIPTION
  `gh workflow run --ref <branch>` resolves the branch head on GitHub's side, which can lag a
  push by a second or two. On 23/11/2026 that produced a build of the previous commit that
  still went green and published a stale .ipa to the device-test release - the version check
  in the .ipa was the only thing that caught it.

  This pushes nothing. It dispatches, waits, and fails loudly if the run's headSha is not the
  local HEAD, so a stale build can never be mistaken for a current one.

  By default it builds only the phone .ipa (fast). -Full also builds the Simulator app, runs
  the UI tests and publishes the Simulator zip + .sha for the AI testers. An IPA-only run never
  compiles the Simulator build, so a break there (as on 25/11/2026) stays invisible until a
  full run.

.EXAMPLE
  .\scripts\ci-build.ps1
.EXAMPLE
  .\scripts\ci-build.ps1 -Full -Wait
#>
[CmdletBinding()]
param(
  [string]$Branch = 'piston-forge-v2',
  [switch]$Full,
  [switch]$Wait
)

$ErrorActionPreference = 'Stop'
$local = (git rev-parse HEAD).Trim()
$ipaOnly = if ($Full) { 'false' } else { 'true' }
Write-Output "local HEAD: $local  (ipa_only=$ipaOnly)"

gh workflow run native.yml --ref $Branch -f ipa_only=$ipaOnly -f runner=macos-26 | Out-Null
Start-Sleep -Seconds 10

# --event workflow_dispatch: a push to the same branch also starts a native.yml run, and
# without this filter the newest run could be that push run instead of this dispatch.
$run = (gh run list --workflow=native.yml --event workflow_dispatch --limit 1 --json databaseId,headSha,status | ConvertFrom-Json)[0]
Write-Output "run $($run.databaseId) headSha $($run.headSha)"

if ($run.headSha -ne $local) {
  Write-Output "STALE BUILD: run is for $($run.headSha), local is $local"
  Write-Output "GitHub had not caught up with the push. Re-run this script; do not trust the .ipa."
  exit 2
}

Write-Output 'headSha matches local HEAD'
if ($Wait) {
  gh run watch $run.databaseId --interval 15 --exit-status | Out-Null
  $conclusion = gh run view $run.databaseId --json conclusion -q '.conclusion'
  Write-Output "conclusion: $conclusion"
  if ($conclusion -ne 'success') { exit 1 }
}
exit 0
