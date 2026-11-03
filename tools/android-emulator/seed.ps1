# tools/android-emulator/seed.ps1 - push a demo schedule into the installed app so the
# week grid has courses to drag.
#
# Needs an AVD from a userdebug image (the ATD image qualifies): it writes
# shared_prefs directly, which requires `adb root`.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\seed.ps1
#
# ASCII-only.

param(
    [string]$Serial = "emulator-5554",
    [string]$Package = "com.hsu.hsu_schedule"
)

$ErrorActionPreference = "Stop"

$Sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "D:\tool\sdk" }
$Adb = Join-Path $Sdk "platform-tools\adb.exe"
if (-not (Test-Path -LiteralPath $Adb)) { throw "missing $Adb" }

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Prefs = Join-Path $Here "prefs.xml"

& node (Join-Path $Here "seed.mjs") --out $Prefs | Out-Null
if (-not (Test-Path -LiteralPath $Prefs)) { throw "seed.mjs produced no $Prefs" }

$root = & $Adb -s $Serial root 2>&1
if (($root -join "") -notmatch "running as root") { Write-Warning "adb root said: $root" }
Start-Sleep -Seconds 2

& $Adb -s $Serial shell am force-stop $Package | Out-Null
& $Adb -s $Serial push $Prefs /data/local/tmp/flclash_prefs.xml | Out-Null

$target = "/data/data/$Package/shared_prefs/FlutterSharedPreferences.xml"
$cmd = "cp /data/local/tmp/flclash_prefs.xml $target" +
       " && chown `$(stat -c '%u:%g' /data/data/$Package/shared_prefs) $target" +
       " && chmod 660 $target" +
       " && restorecon $target 2>/dev/null; echo seeded"
$result = & $Adb -s $Serial shell $cmd 2>&1
Write-Host ($result -join " ")

& $Adb -s $Serial shell monkey -p $Package -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
Write-Host "relaunched $Package with the demo schedule"
