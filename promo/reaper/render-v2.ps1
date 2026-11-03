# render-v2.ps1 — build the melody-first BGM v2 in REAPER and render
# promo/audio/bgm-v2.wav (48 kHz stereo, 40.000 s, WAV).
#
# Usage (close REAPER first):
#   powershell -ExecutionPolicy Bypass -File D:\hsu_flutter\promo\reaper\render-v2.ps1
#
# The script installs promo/reaper/build-v2.lua as REAPER's __startup.lua,
# launches a new REAPER instance, waits for the offline render, then restores
# the previous __startup.lua (if any) and stops only the instance it started.

$ErrorActionPreference = "Stop"
$Root = "D:\hsu_flutter"
$Reaper = "C:\Program Files\REAPER (x64)\reaper.exe"
$Startup = Join-Path $env:APPDATA "REAPER\Scripts\__startup.lua"
$Backup = "$Startup.bak"
$Build = Join-Path $Root "promo\reaper\build-v2.lua"
$Out = Join-Path $Root "promo\audio\bgm-v2.wav"
$Log = Join-Path $Root "promo\reaper\build-v2.log"

if (-not (Test-Path $Reaper)) { throw "REAPER not found at $Reaper" }
if (Get-Process reaper -ErrorAction SilentlyContinue) { throw "Close REAPER before running this script." }
if (-not (Test-Path $Build)) { throw "Missing $Build" }

$HadStartup = Test-Path $Startup
if ($HadStartup) { Copy-Item $Startup $Backup -Force }
Copy-Item $Build $Startup -Force
Remove-Item $Log -ErrorAction SilentlyContinue

$proc = $null
Remove-Item $Out -ErrorAction SilentlyContinue
try {
  $proc = Start-Process -FilePath $Reaper -ArgumentList "-new", "-nosplash" -PassThru
  $deadline = (Get-Date).AddSeconds(180)
  $stable = 0
  while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 500
    if (Test-Path $Out) {
      $len = (Get-Item $Out).Length
      Start-Sleep -Seconds 1
      if ((Test-Path $Out) -and (Get-Item $Out).Length -eq $len -and $len -gt 1000000) {
        $stable++
        if ($stable -ge 2) { break }
      }
    }
  }
  if (-not (Test-Path $Out)) { throw "Render did not produce $Out — see $Log" }
  if ((Get-Item $Out).Length -lt 1000000) { throw "Render looks incomplete: $Out" }
} finally {
  if ($proc) { Get-Process -Id $proc.Id -ErrorAction SilentlyContinue | Stop-Process -Force }
  if ($HadStartup) { Move-Item $Backup $Startup -Force } else { Remove-Item $Startup -ErrorAction SilentlyContinue }
}

$hash = (Get-FileHash $Out -Algorithm SHA256).Hash
Write-Output "rendered $Out"
Write-Output "sha256   $hash"
Write-Output "bytes    $((Get-Item $Out).Length)"
