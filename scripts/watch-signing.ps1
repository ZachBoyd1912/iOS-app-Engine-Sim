# Watches for the artifact Sideloadly writes when it signs, so its embedded
# mobileprovision can be reused for headless `ios sign app` / `ios install`.
# Runs for an hour, logs anything new to %LOCALAPPDATA%\ioslab\signing-watch.log
$log = "$env:LOCALAPPDATA\ioslab\signing-watch.log"
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
"watch started $(Get-Date -Format 'HH:mm:ss')" | Add-Content $log

$roots = @($env:TEMP, "$env:LOCALAPPDATA\Temp", "$env:APPDATA\sideloadly",
           "$env:LOCALAPPDATA\Sideloadly", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop")
$seen = @{}
$deadline = (Get-Date).AddMinutes(60)

while ((Get-Date) -lt $deadline) {
    foreach ($r in $roots) {
        if (-not (Test-Path $r)) { continue }
        try {
            Get-ChildItem $r -Recurse -Depth 3 -Filter *.ipa -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-3) } |
                ForEach-Object {
                    if (-not $seen.ContainsKey($_.FullName)) {
                        $seen[$_.FullName] = 1
                        "$(Get-Date -Format 'HH:mm:ss') IPA  $($_.FullName)  ($([math]::Round($_.Length/1MB,2)) MB)" | Add-Content $log
                    }
                }
            Get-ChildItem $r -Recurse -Depth 4 -Directory -Filter Payload -ErrorAction SilentlyContinue |
                Where-Object { $_.CreationTime -gt (Get-Date).AddMinutes(-3) } |
                ForEach-Object {
                    if (-not $seen.ContainsKey($_.FullName)) {
                        $seen[$_.FullName] = 1
                        "$(Get-Date -Format 'HH:mm:ss') DIR  $($_.FullName)" | Add-Content $log
                    }
                }
        } catch { }
    }
    Start-Sleep -Seconds 3
}
"watch ended $(Get-Date -Format 'HH:mm:ss')" | Add-Content $log
