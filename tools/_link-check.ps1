# link-check.ps1 - verify that every relative markdown link in tools/*.md resolves.
# External links (http/https/mailto) are skipped.

$ErrorActionPreference = "Stop"
$Tools = $PSScriptRoot

$files = Get-ChildItem -LiteralPath $Tools -Recurse -File -Filter "*.md" |
    Where-Object { $_.FullName -notmatch "\\skill\\" -and $_.FullName -notmatch "\\legacy\\" }

$bad = 0
$checked = 0

foreach ($f in $files) {
    $dir = Split-Path -Parent $f.FullName
    $text = Get-Content -LiteralPath $f.FullName -Raw
    foreach ($m in [regex]::Matches($text, '\]\(([^)\s]+)\)')) {
        $target = $m.Groups[1].Value
        if ($target -match '^(https?:|mailto:|#)') { continue }
        $clean = ($target -split '#')[0]
        if (-not $clean) { continue }
        $checked++
        $full = Join-Path $dir $clean
        if (-not (Test-Path -LiteralPath $full)) {
            $bad++
            Write-Host ("MISSING  {0}`n         -> {1}" -f $f.FullName.Replace($Tools, 'tools'), $target)
        }
    }
}

Write-Host ""
Write-Host ("checked {0} relative links in {1} files, {2} missing" -f $checked, $files.Count, $bad)
if ($bad -gt 0) { exit 1 }
