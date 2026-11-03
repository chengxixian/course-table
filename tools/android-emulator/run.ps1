# tools/android-emulator/run.ps1 - boot the AVD headless and wait until Android is up.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\run.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\run.ps1 -NoWindow:$false
#
# Headless by default: the emulator is only used to read FrameTiming numbers, and a
# window costs frames. ASCII-only.

param(
    [switch]$NoWindow = $true,
    [string]$Gpu = "host",
    [int]$Port = 5554,
    [int]$TimeoutSeconds = 240
)

$ErrorActionPreference = "Stop"

$Sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "D:\tool\sdk" }
$AvdName = if ($env:AVD_NAME) { $env:AVD_NAME } else { "hsu_atd" }
$Emulator = Join-Path $Sdk "emulator\emulator.exe"
$Adb = Join-Path $Sdk "platform-tools\adb.exe"
foreach ($p in @($Emulator, $Adb)) { if (-not (Test-Path -LiteralPath $p)) { throw "missing $p (run setup.ps1 first)" } }

$serial = "emulator-$Port"
$already = & $Adb devices 2>&1 | Select-String -Pattern "$serial\s+device"
if ($already) {
    Write-Host "$serial already running"
    exit 0
}

$args = @("-avd", $AvdName, "-no-audio", "-no-boot-anim", "-no-snapshot",
          "-gpu", $Gpu, "-port", "$Port")
if ($NoWindow) { $args += "-no-window" }

Write-Host ("starting emulator: " + ($args -join " "))
$proc = Start-Process -FilePath $Emulator -ArgumentList $args -PassThru

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 5
    if ($proc.HasExited) { throw "emulator exited early (code $($proc.ExitCode))" }
    $boot = & $Adb -s $serial shell getprop sys.boot_completed 2>&1
    if (($boot -join "").Trim() -eq "1") {
        Write-Host "booted: $serial"
        & $Adb -s $serial shell input keyevent 82 | Out-Null   # dismiss keyguard
        exit 0
    }
}
throw "emulator did not finish booting within $TimeoutSeconds s"
