# tools/android-emulator/measure.ps1 - drive one interaction and print the frame report the
# app logs for it (see lib/ui/frame_stats.dart).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\measure.ps1 -Scenario week
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\measure.ps1 -Scenario all
#
# Coordinates are fractions of the screen, taken from the seeded demo layout at
# 1080x2400 and scaled to whatever `wm size` reports, so the script survives a
# different AVD profile. ASCII-only.

param(
    [ValidateSet("week", "popup", "drag", "all")][string]$Scenario = "all",
    [string]$Serial = "emulator-5554",
    [int]$Repeat = 2,
    [switch]$Cold
)

$ErrorActionPreference = "Stop"

$Sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "D:\tool\sdk" }
$Adb = Join-Path $Sdk "platform-tools\adb.exe"
$Package = "com.hsu.hsu_schedule"
if (-not (Test-Path -LiteralPath $Adb)) { throw "missing $Adb" }

function Get-Size {
    $raw = & $Adb -s $Serial shell wm size 2>&1 | Out-String
    if ($raw -match "(\d+)x(\d+)") { return @([int]$matches[1], [int]$matches[2]) }
    return @(1080, 2400)
}
$size = Get-Size
$W = $size[0]
$H = $size[1]
function P([double]$fx, [double]$fy) {
    return @([int]($W * $fx), [int]($H * $fy))
}

function Invoke-Adb([string[]]$a) { & $Adb -s $Serial @a 2>&1 | Out-Null }
function Tap([double]$fx, [double]$fy) {
    $p = P $fx $fy
    Invoke-Adb @("shell", "input", "tap", "$($p[0])", "$($p[1])")
}
function Swipe([double]$fx, [double]$fy, [double]$tx, [double]$ty) {
    $a = P $fx $fy
    $b = P $tx $ty
    Invoke-Adb @("shell", "input", "swipe", "$($a[0])", "$($a[1])", "$($b[0])", "$($b[1])", "250")
}

function Clear-Log { Invoke-Adb @("logcat", "-c") }
function Read-Report([string]$tag) {
    $line = & $Adb -s $Serial logcat -d -s flutter 2>&1 | Select-String -Pattern "$tag:" | Select-Object -Last 1
    if ($line) { return $line.Line -replace "^.*flutter : ", "" }
    return $null
}

function Warm-Up {
    Write-Host "warm-up (first paint after launch is shader compilation, not steady state)"
    Tap 0.26 0.39; Start-Sleep -Milliseconds 1200
    Tap 0.93 0.12; Start-Sleep -Milliseconds 800   # dismiss popup
    Tap 0.30 0.08; Start-Sleep -Milliseconds 800   # one week switch
    Tap 0.08 0.08; Start-Sleep -Milliseconds 800   # back
}

function Measure-Week {
    Clear-Log
    for ($i = 0; $i -lt $Repeat; $i++) {
        Tap 0.30 0.08
        Start-Sleep -Milliseconds 1500
    }
    $r = Read-Report "week-switch"
    Write-Host ("week-switch  " + ($r ?? "(no report)"))
}

function Measure-Popup {
    Clear-Log
    Tap 0.26 0.39
    Start-Sleep -Milliseconds 2000
    $r = Read-Report "course-popup"
    Write-Host ("course-popup " + ($r ?? "(no report)"))
    Tap 0.93 0.12
    Start-Sleep -Milliseconds 800
}

function Measure-Drag {
    Clear-Log
    # long-press a course, then move: the app starts dragging after ~500 ms held
    $s = P 0.65 0.36
    Invoke-Adb @("shell", "input", "motionevent", "DOWN", "$($s[0])", "$($s[1])")
    Start-Sleep -Milliseconds 1000
    foreach ($fy in @(0.42, 0.48, 0.54, 0.60, 0.66, 0.60, 0.54, 0.48)) {
        $m = P 0.45 $fy
        Invoke-Adb @("shell", "input", "motionevent", "MOVE", "$($m[0])", "$($m[1])")
    }
    Invoke-Adb @("shell", "input", "motionevent", "UP", "$($s[0])", "$($s[1])")
    Start-Sleep -Milliseconds 2000
    $r = Read-Report "course-drag"
    Write-Host ("course-drag  " + ($r ?? "(no report)"))
}

if ($Cold) {
    Invoke-Adb @("shell", "am", "force-stop", $Package)
    Invoke-Adb @("shell", "monkey", "-p", $Package, "-c", "android.intent.category.LAUNCHER", "1")
    Start-Sleep -Seconds 8
    Write-Host "cold start measured without warm-up"
} else {
    Warm-Up
}

switch ($Scenario) {
    "week"  { Measure-Week }
    "popup" { Measure-Popup }
    "drag"  { Measure-Drag }
    "all"   { Measure-Week; Measure-Popup; Measure-Drag }
}
