# tools/android-emulator/setup.ps1 - install the emulator and create the AVD used by the
# frame-timing measurements.
#
# Idempotent: skips anything already installed.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\setup.ps1
#
# ASCII-only: Windows PowerShell 5.1 mis-parses non-ASCII .ps1 saved without a BOM.

$ErrorActionPreference = "Stop"

$Sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { "D:\tool\sdk" }
$AvdName = if ($env:AVD_NAME) { $env:AVD_NAME } else { "hsu_atd" }
$Image = "system-images;android-35;aosp_atd;x86_64"
$Device = "pixel_6"

if (-not (Test-Path -LiteralPath $Sdk)) { throw "Android SDK not found: $Sdk (set ANDROID_HOME)" }
$SdkManager = Join-Path $Sdk "cmdline-tools\latest\bin\sdkmanager.bat"
$AvdManager = Join-Path $Sdk "cmdline-tools\latest\bin\avdmanager.bat"
if (-not (Test-Path -LiteralPath $SdkManager)) { throw "sdkmanager not found: $SdkManager" }

if (-not $env:JAVA_HOME) {
    $candidate = "D:\tool\jdk"
    if (Test-Path -LiteralPath $candidate) { $env:JAVA_HOME = $candidate }
    else { throw "JAVA_HOME is not set and D:\tool\jdk does not exist" }
}

Write-Host "SDK        $Sdk"
Write-Host "AVD        $AvdName"
Write-Host "Image      $Image"

# ---- packages -------------------------------------------------------------
$installed = & $SdkManager --list_installed 2>&1 | Out-String
$need = @()
if ($installed -notmatch "emulator\s+\|") { $need += "emulator" }
if ($installed -notmatch [regex]::Escape($Image)) { $need += $Image }

if ($need.Count -gt 0) {
    Write-Host ("installing: " + ($need -join ", "))
    # Answer the licence prompts without pinning the script to one licence text.
    $answers = ("y`n" * 40)
    $answers | & $SdkManager --install @need 2>&1 | Select-Object -Last 3
} else {
    Write-Host "packages already installed"
}

# ---- AVD ------------------------------------------------------------------
$avds = & (Join-Path $Sdk "emulator\emulator.exe") -list-avds 2>&1
if ($avds -notcontains $AvdName) {
    Write-Host "creating AVD $AvdName"
    & $AvdManager create avd -n $AvdName -k $Image -d $Device --force 2>&1 | Select-Object -Last 2
} else {
    Write-Host "AVD $AvdName already exists"
}

Write-Host ""
Write-Host "next:"
Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\run.ps1"
