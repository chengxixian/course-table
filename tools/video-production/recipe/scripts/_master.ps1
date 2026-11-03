<#
.SYNOPSIS
  三遍母带：量测 → 静态增益 + look-ahead 限制器 → 复测；若限制器吃掉能量导致
  响度未落入窗口，用实测值再做一次增益修正（最多 2 次迭代）。视频流 -c:v copy。

.DESCRIPTION
  目标常量写死在脚本里：TARGET_I = -16.0 LUFS-I，TARGET_TP = -1.5 dBTP。
  为什么不是 -14：本片混音是打击乐主导、crest ≈19 dB，硬拉到 -14 要再吃掉 3 dB 以上瞬态，
  会把刚做强的鼓压平。详见 docs/promo/04-audio-and-assets.md。

  本工程 ffmpeg 是 Remotion 的裁剪版，**没有 alimiter**（实测 "No such filter"）。
  pass 2 用等价实现：master-audio.mjs 做 4ms attack / 80ms release、ceiling 可调
  （默认 0.794 ≈ −2.0 dBFS）的前瞻限制器，语义与 alimiter 参数一致。

.EXAMPLE
  .\_master.ps1 -In ..\.work\vertical-raw.mp4 -Out ..\hsu-promo-vertical.mp4 -Label vertical-bgm -MaxBoost 8
  .\_master.ps1 -In ..\.work\vertical-nobgm-raw.mp4 -Out ..\hsu-promo-vertical-nobgm.mp4 -TargetI -18.0 -Label vertical-nobgm
#>
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out,
    [double]$TargetI = -16.0,
    [double]$TargetTP = -1.5,
    [string]$Label = "master",
    [double]$MaxBoost = 6.0,
    [switch]$KeepWork
)

$ErrorActionPreference = "Stop"

$CEILING = if ($env:MASTER_CEILING) { [double]$env:MASTER_CEILING } else { 0.794 }
$TOLERANCE = 0.3

$PromoRoot  = Split-Path -Parent $PSScriptRoot
$Compositor = Join-Path $PromoRoot "remotion\node_modules\@remotion\compositor-win32-x64-msvc"
$Ffmpeg     = if ($env:FFMPEG_PATH) { $env:FFMPEG_PATH } else { Join-Path $Compositor "ffmpeg.exe" }
$Ffprobe    = if ($env:FFPROBE_PATH) { $env:FFPROBE_PATH } else { Join-Path $Compositor "ffprobe.exe" }
$WorkDir    = Join-Path $PromoRoot ".work"

if (-not (Test-Path $Ffmpeg)) { throw "找不到 ffmpeg：$Ffmpeg（可用 `$env:FFMPEG_PATH 覆盖）" }
if (-not (Test-Path $In)) { throw "找不到输入视频：$In" }
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
$InAbs = (Resolve-Path $In).Path
if ([IO.Path]::IsPathRooted($Out)) { $OutAbs = $Out } else { $OutAbs = Join-Path (Get-Location) $Out }
$OutDir = Split-Path -Parent $OutAbs
if ($OutDir -and -not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

function Invoke-Native {
    param([string]$Exe, [string[]]$ArgList)
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & $Exe @ArgList 2>&1
        $code = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $old }
    return [pscustomobject]@{ Text = ($out | Out-String); Code = $code }
}

function Measure-Loudness {
    param([string]$File)
    $r = Invoke-Native -Exe $Ffmpeg -ArgList @(
        "-hide_banner", "-nostats", "-i", $File, "-vn",
        "-af", "loudnorm=I=-16:TP=-1.5:print_format=json", "-f", "null", "-"
    )
    $m = [regex]::Match($r.Text, '(?s)\{[^{}]*"input_i".*?\}')
    if (-not $m.Success) { throw "loudnorm 未返回 JSON（$File）：`n$($r.Text)" }
    $j = $m.Value | ConvertFrom-Json
    return [pscustomobject]@{
        InputI   = [double]$j.input_i
        InputTP  = [double]$j.input_tp
        InputLRA = [double]$j.input_lra
        Thresh   = [double]$j.input_thresh
    }
}

function Get-AudioInfo {
    param([string]$File)
    $r = Invoke-Native -Exe $Ffprobe -ArgList @(
        "-v", "error", "-select_streams", "a:0",
        "-show_entries", "stream=codec_name,sample_rate,channels", "-of", "json", $File
    )
    try { return ($r.Text.Trim() | ConvertFrom-Json).streams[0] } catch { return $null }
}

$base      = [IO.Path]::GetFileNameWithoutExtension($OutAbs)
$wavRaw    = Join-Path $WorkDir "$base.raw.wav"
$wavMaster = Join-Path $WorkDir "$base.mastered.wav"

Write-Host "=== [$Label] pass 1 · 量测输入 ===" -ForegroundColor Cyan
$p1 = Measure-Loudness -File $InAbs
Write-Host ("  I={0} LUFS  TP={1} dBTP  LRA={2} LU" -f $p1.InputI, $p1.InputTP, $p1.InputLRA)

$gain = $TargetI - $p1.InputI
$capped = $false
if ($gain -gt $MaxBoost) { $gain = $MaxBoost; $capped = $true }
Write-Host ("  → 目标 I={0}，首轮增益 {1} dB{2}" -f $TargetI, [math]::Round($gain, 2), $(if ($capped) { "（封顶 +$MaxBoost dB）" } else { "" }))

Write-Host "=== [$Label] pass 2 · 抽音轨 ===" -ForegroundColor Cyan
$ex = Invoke-Native -Exe $Ffmpeg -ArgList @("-y", "-hide_banner", "-nostats", "-i", $InAbs, "-vn", "-c:a", "pcm_s24le", "-ar", "48000", $wavRaw)
if ($ex.Code -ne 0) { throw "抽音轨失败：`n$($ex.Text)" }

$inv = [Globalization.CultureInfo]::InvariantCulture
$fmt = { param($v) [string]::Format($inv, "{0}", $v) }

$limiter = $null
$p3 = $null
$iterations = 0
for ($iter = 1; $iter -le 2; $iter++) {
    $iterations = $iter
    Write-Host "=== [$Label] pass 2/$iter · 增益 + 前瞻限制器（gain=$([math]::Round($gain,2)) dB）===" -ForegroundColor Cyan
    $nr = Invoke-Native -Exe "node" -ArgList @(
        (Join-Path $PSScriptRoot "master-audio.mjs"), "--in", $wavRaw, "--out", $wavMaster,
        "--gain", (& $fmt $gain), "--ceiling", (& $fmt $CEILING), "--attack-ms", "4", "--release-ms", "80"
    )
    if ($nr.Code -ne 0) { throw "master-audio.mjs 失败：`n$($nr.Text)" }
    $limiter = $nr.Text | ConvertFrom-Json
    Write-Host ("  限制器前 {0} dBFS → 后 {1} dBFS；最大压限 {2} dB；受限样本 {3}" -f `
            $limiter.peakBeforeLimiterDbfs, $limiter.peakAfterLimiterDbfs, $limiter.maxReductionDb, $limiter.limitedSamples)

    $mx = Invoke-Native -Exe $Ffmpeg -ArgList @(
        "-y", "-hide_banner", "-nostats", "-i", $InAbs, "-i", $wavMaster,
        "-map", "0:v:0", "-map", "1:a:0", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
        "-movflags", "+faststart", $OutAbs
    )
    if ($mx.Code -ne 0) { throw "封装失败：`n$($mx.Text)" }

    Write-Host "=== [$Label] pass 3/$iter · 复测成品 ===" -ForegroundColor Cyan
    $p3 = Measure-Loudness -File $OutAbs
    Write-Host ("  I={0} LUFS  TP={1} dBTP  LRA={2} LU" -f $p3.InputI, $p3.InputTP, $p3.InputLRA)

    $delta = $TargetI - $p3.InputI
    if ($iter -eq 1 -and [math]::Abs($delta) -gt $TOLERANCE) {
        $gain = [math]::Min($MaxBoost, $gain + $delta)
        Write-Host ("  → 差 {0} dB，修正增益到 {1} dB 再跑一次" -f [math]::Round($delta, 2), [math]::Round($gain, 2)) -ForegroundColor Yellow
        continue
    }
    break
}

$codec = Get-AudioInfo -File $OutAbs
$iOk = ($p3.InputI -ge ($TargetI - 0.5)) -and ($p3.InputI -le ($TargetI + 0.5))
$tpOk = ($p3.InputTP -le $TargetTP)
$pass = $iOk -and $tpOk

if (-not $KeepWork) {
    Remove-Item $wavRaw -Force -ErrorAction SilentlyContinue
    Remove-Item $wavMaster -Force -ErrorAction SilentlyContinue
}

$report = [ordered]@{
    label          = $Label
    source         = $InAbs
    output         = $OutAbs
    targetI        = $TargetI
    targetTP       = $TargetTP
    ceiling        = $CEILING
    maxBoost       = $MaxBoost
    pass1_input_i  = $p1.InputI
    pass1_input_tp = $p1.InputTP
    pass1_lra      = $p1.InputLRA
    gainDb         = [math]::Round($gain, 2)
    gainCapped     = $capped
    iterations     = $iterations
    limiterMaxDb   = $limiter.maxReductionDb
    pass3_input_i  = $p3.InputI
    pass3_input_tp = $p3.InputTP
    pass3_lra      = $p3.InputLRA
    audioCodec     = $codec.codec_name
    pass           = $pass
}
$json = $report | ConvertTo-Json -Depth 4
$json
[System.IO.File]::WriteAllText((Join-Path $WorkDir "master-$Label.json"), $json, (New-Object System.Text.UTF8Encoding($false)))

if ($pass) {
    Write-Host ("[{0}] PASS：I={1} ∈ [{2},{3}]（目标 {4}），TP={5} ≤ {6}" -f $Label, $p3.InputI, ($TargetI - 0.5), ($TargetI + 0.5), $TargetI, $p3.InputTP, $TargetTP) -ForegroundColor Green
}
else {
    Write-Host ("[{0}] FAIL：实测 I={1}、TP={2}（目标写死 {3}/{4}，未自行调整）" -f $Label, $p3.InputI, $p3.InputTP, $TargetI, $TargetTP) -ForegroundColor Red
}
