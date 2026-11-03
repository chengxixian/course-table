# tools/_sync.ps1 - re-build tools/ from the installed skill sources.
#
# Copies two skill workspaces into tools/ so they can be reused and versioned
# with the repo. Upstream file contents are not modified; only binary media is
# excluded (see each README "Not included" section).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\_sync.ps1
#
# Idempotent: the destination skill/ folder is deleted before each copy.
# ASCII-only on purpose: Windows PowerShell 5.1 mis-parses non-ASCII .ps1 files
# that are saved without a BOM.

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ScriptDir) { $ScriptDir = (Get-Location).Path }

$Tools = $ScriptDir
$Root = Split-Path -Parent $Tools

$VideoSrc = Join-Path $Root "promo\_skilldl\video-shotcraft-main"
$MusicSrc = Join-Path $Root ".skills\music-production"
$MusicZip = Join-Path $Root ".skills\music-production.zip"

function Copy-Tree {
    param(
        [string]$From,
        [string]$To,
        [string[]]$ExcludeDirs = @()
    )

    if (-not (Test-Path -LiteralPath $From)) { throw "source missing: $From" }
    if (Test-Path -LiteralPath $To) { Remove-Item -LiteralPath $To -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $To | Out-Null

    $robo = @($From, $To, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NP", "/R:1", "/W:1")
    if ($ExcludeDirs.Count -gt 0) {
        $robo += "/XD"
        foreach ($d in $ExcludeDirs) { $robo += (Join-Path $From $d) }
    }

    robocopy @robo | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE): $From -> $To" }
}

Write-Host "== video-production =="
$VideoDst = Join-Path $Tools "video-production\skill"
Copy-Tree -From $VideoSrc -To $VideoDst -ExcludeDirs @(
    "assets\audio",
    "assets\readme",
    "gallery",
    ".github",
    ".claude-plugin"
)

Write-Host "== music-production =="
$MusicDst = Join-Path $Tools "music-production\skill"
Copy-Tree -From $MusicSrc -To $MusicDst

Write-Host "== sound-effects =="
# assets/ is a 168 KB WeChat QR image that belonged to the upsell block this
# copy removes; it is not needed to run the scripts.
$SoundDst = Join-Path $Tools "sound-effects\skill"
Copy-Tree -From (Join-Path $Root ".skills\sound") -To $SoundDst -ExcludeDirs @("assets")

# Upstream LICENSE / README / CHANGELOG only exist inside the downloaded zip.
if (Test-Path -LiteralPath $MusicZip) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($MusicZip)
    try {
        foreach ($name in @("LICENSE", "README.md", "CHANGELOG.md")) {
            $entry = $zip.Entries | Where-Object { $_.FullName -eq "music-production-skills-main/$name" } | Select-Object -First 1
            if ($entry) {
                $out = Join-Path $MusicDst $name
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $out, $true)
                Write-Host "  extracted $name"
            }
        }
    } finally { $zip.Dispose() }
}

Write-Host "== project recipes =="

# NOTE: use -Path with explicit relative names; -LiteralPath does not accept
# wildcards and silently leaves the destination empty.

function Copy-Named {
    param([string]$FromDir, [string[]]$Names, [string]$ToDir)
    New-Item -ItemType Directory -Force -Path $ToDir | Out-Null
    $copied = 0
    foreach ($n in $Names) {
        $src = Join-Path $FromDir $n
        if (Test-Path -LiteralPath $src) {
            Copy-Item -LiteralPath $src -Destination $ToDir -Force
            $copied++
        } else {
            Write-Warning "missing: $src"
        }
    }
    Write-Host ("  {0} -> {1} ({2} files)" -f $FromDir, $ToDir, $copied)
}

# Video: the render + master harness this repo actually ships.
Copy-Named -FromDir (Join-Path $Root "promo\scripts") -ToDir (Join-Path $Tools "video-production\recipe\scripts") -Names @(
    "render-vertical-bgm.ps1",
    "render-vertical-nobgm.ps1",
    "render-wide.ps1",
    "_render-common.ps1",
    "_master.ps1",
    "_master2.ps1",
    "master-audio.mjs",
    "analyze-crest.mjs",
    "sfx-search.ps1",
    "sfx-analyze.mjs",
    "retrim-sfx.mjs"
)

# Music: REAPER project builder, render driver, analysis and mastering tools.
Copy-Named -FromDir (Join-Path $Root "promo\reaper") -ToDir (Join-Path $Tools "music-production\reaper\scripts") -Names @(
    "compose-v2.mjs",
    "make-samples.mjs",
    "analyze-v2.mjs",
    "finalize-v2.mjs",
    "build-v2.lua",
    "build-data.lua",
    "render-v2.ps1",
    "bgm-v2.rpp",
    "analysis-v2.json"
)
Copy-Named -FromDir (Join-Path $Root "promo\audio") -ToDir (Join-Path $Tools "music-production\reaper\scripts") -Names @(
    "analyze-wav.mjs",
    "spectral-report.mjs",
    "visualize-bgm.mjs"
)

# Superseded v1 attempt, kept as a worked counter-example.
Copy-Named -FromDir (Join-Path $Root "promo\audio") -ToDir (Join-Path $Tools "music-production\reaper\legacy") -Names @("make-bgm.mjs")

# Original, project-specific skill addendum, preserved verbatim.
Copy-Named -FromDir (Join-Path $Root ".skills\music-production") -ToDir (Join-Path $Tools "music-production\reaper") -Names @("SKILL.md")
$addendum = Join-Path $Tools "music-production\reaper\SKILL.md"
if (Test-Path -LiteralPath $addendum) {
    Move-Item -LiteralPath $addendum -Destination (Join-Path $Tools "music-production\reaper\SKILL-addendum.original.md") -Force
}

function Show-Size {
    param([string]$Path, [string]$Label)
    $s = Get-ChildItem -LiteralPath $Path -Recurse -File | Measure-Object -Property Length -Sum
    $mb = $s.Sum / 1MB
    "{0,-28} {1,5} files {2,9:N2} MB" -f $Label, $s.Count, $mb
}

Write-Host ""
Show-Size (Join-Path $Tools "video-production") "video-production/"
Show-Size (Join-Path $Tools "music-production") "music-production/"
Show-Size $Tools "tools/ total"
