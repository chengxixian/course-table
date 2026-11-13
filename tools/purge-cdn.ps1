# tools/purge-cdn.ps1 - purge the version.json cache after publishing a release.
#
# Why: jsdelivr keys its GitHub-branch cache by path and IGNORES query strings,
# so an app's `?t=`/`?b=` cache-buster cannot force it fresh. Without a purge,
# a stale version.json can make installed apps report "already latest" for
# hours after a release. Run this right after `gh release create` + pushing the
# new version.json.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\purge-cdn.ps1
#
# ASCII-only (Windows PowerShell 5.1 + non-ASCII .ps1 without BOM = mojibake).

$Repo = "chengxixian/course-table"
$Path = "gh/$Repo@main/version.json"

Write-Host "requesting purge..."
try {
    $r = Invoke-RestMethod -Uri "https://purge.jsdelivr.net/$Path" -TimeoutSec 30
    $r.purged | ForEach-Object { "  purged: $_" }
} catch {
    Write-Warning "purge request failed: $($_.Exception.Message)"
}

Write-Host "verifying cdn.jsdelivr.net serves the new version (up to 8 tries)..."
$expected = $null
try {
    $raw = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/chengxixian/course-table/main/version.json" -TimeoutSec 20
    $expected = $raw.version
    "  raw.githubusercontent: $expected"
} catch { Write-Warning "cannot read raw source: $($_.Exception.Message)" }

for ($i = 0; $i -lt 8; $i++) {
    Start-Sleep -Seconds 15
    try {
        $cdn = Invoke-RestMethod -Uri "https://cdn.jsdelivr.net/$Path" -TimeoutSec 20
        if ($null -eq $expected -or $cdn.version -eq $expected) {
            "  cdn.jsdelivr: $($cdn.version)  OK"
            exit 0
        }
        "  cdn.jsdelivr still $($cdn.version), waiting..."
    } catch {
        "  cdn check failed, waiting..."
    }
}
Write-Warning "cdn.jsdelivr did not confirm the new version within 2 minutes; the app's multi-source check (max across sources) still protects users."
