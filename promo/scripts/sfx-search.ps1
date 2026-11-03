# sfx-search.ps1 - run every Freesound query this promo needs, append to one log.
# ASCII-only on purpose (Windows PowerShell 5.1 mangles non-ASCII .ps1 without BOM).

$ErrorActionPreference = "Stop"

# Resolve the bundled Python at runtime: the install path contains non-ASCII
# characters (the Windows user name), which a BOM-less .ps1 cannot carry safely.
$Py = Join-Path $env:USERPROFILE ".dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe"
if (-not (Test-Path -LiteralPath $Py)) {
    $Py = (Get-ChildItem -LiteralPath (Join-Path $env:USERPROFILE ".dsh\dsh-runtimes") -Recurse -Filter "python.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1).FullName
}
if (-not $Py -or -not (Test-Path -LiteralPath $Py)) { throw "bundled python not found" }
Write-Host "python: $Py"
$Sfx = "D:\hsu_flutter\.skills\sound\scripts\sfx.py"
$Log = "D:\hsu_flutter\promo\.work\sfx-search.log"

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Log) | Out-Null
Set-Content -LiteralPath $Log -Value "" -Encoding UTF8

$env:PYTHONIOENCODING = "utf-8"

$queries = @(
    @{ cue = "paper-slide"; q = "paper slide"; n = 8 },
    @{ cue = "swish";       q = "soft whoosh"; n = 8 },
    @{ cue = "stamp";       q = "card drop table"; n = 8 },
    @{ cue = "pop";         q = "bubble pop short"; n = 8 },
    @{ cue = "snap";        q = "click snap"; n = 8 },
    @{ cue = "key";         q = "keyboard single key press"; n = 8 },
    @{ cue = "riser";       q = "riser transition"; n = 8 },
    @{ cue = "impact";      q = "impact thud"; n = 8 },
    @{ cue = "chime";       q = "bell chime small"; n = 8 }
)

foreach ($row in $queries) {
    Add-Content -LiteralPath $Log -Value ("===== {0}  q='{1}' =====" -f $row.cue, $row.q) -Encoding UTF8
    # Native stderr must not abort the batch: drop EAP to Continue for the call.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & $Py $Sfx freesound $row.q --license by -n $row.n --pages 2 2>&1
    } finally {
        $ErrorActionPreference = $prev
    }
    Add-Content -LiteralPath $Log -Value ($out | Out-String) -Encoding UTF8
    Write-Host ("done {0}" -f $row.cue)
}

Write-Host "ALL DONE -> $Log"
