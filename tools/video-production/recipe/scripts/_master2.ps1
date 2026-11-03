<#
.SYNOPSIS
  两级母带（压缩 + 斜坡限制器）：量测 → 压缩/限幅 → 封装 → 复测 + crest 分析。
  输出到 .work/master2/，不覆盖 promo/ 下的正式文件。

.DESCRIPTION
  与旧版 _master.ps1 的差别（Lead 指出的问题）：
  旧版只有「静态增益 + 瞬时压下」的限制器，能量削减全落在两个峰上：
  母带后全片最响点从 37.5s 的片尾 impact 漂移到 13.0s 的 detail 段，impact 相对前 5s 的
  crest 从 21.3 掉到 ~16.3 dB。
  新版：
    stage 1 软拐点总线压缩（-24 dB / 2.5:1 / knee 8 / 15ms / 150ms，stereo-linked RMS）
    stage 2 限制器改为「整个 lookahead 线性斜降」，release 150ms，ceiling 0.75
  这样削减由压缩器分担，限制器 maxReductionDb 目标 ≤3 dB。

.EXAMPLE
  .\_master2.ps1 -In ..\.work\vertical-raw.mp4 -Name hsu-promo-vertical -TargetI -16.0
#>
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Name,
    [double]$TargetI = -16.0,
    [double]$TargetTP = -1.5,
    [double]$MaxBoost = 10.0
)

$ErrorActionPreference = "Stop"

$PromoRoot  = Split-Path -Parent $PSScriptRoot
$Compositor = Join-Path $PromoRoot "remotion\node_modules\@remotion\compositor-win32-x64-msvc"
$Ffmpeg     = if ($env:FFMPEG_PATH) { $env:FFMPEG_PATH } else { Join-Path $Compositor "ffmpeg.exe" }
$Ffprobe    = if ($env:FFPROBE_PATH) { $env:FFPROBE_PATH } else { Join-Path $Compositor "ffprobe.exe" }
$OutDir     = Join-Path $PromoRoot ".work\master2"
$WorkDir    = Join-Path $PromoRoot ".work\master2\tmp"
New-Item -ItemType Directory -Force -Path $OutDir, $WorkDir | Out-Null

$InAbs  = (Resolve-Path $In).Path
$OutAbs = Join-Path $OutDir "$Name.mp4"

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
    if (-not $m.Success) { throw "loudnorm 未返回 JSON（$File）" }
    $j = $m.Value | ConvertFrom-Json
    return [pscustomobject]@{ I = [double]$j.input_i; TP = [double]$j.input_tp; LRA = [double]$j.input_lra }
}

function Get-Crest {
    param([string]$Mp4, [string]$Tag)
    $wav = Join-Path $WorkDir "$Tag.crest.wav"
    $ex = Invoke-Native -Exe $Ffmpeg -ArgList @("-y", "-hide_banner", "-nostats", "-i", $Mp4, "-vn", "-ac", "1", "-c:a", "pcm_s24le", "-ar", "48000", $wav)
    if ($ex.Code -ne 0) { throw "crest 抽音轨失败：$($ex.Text)" }
    $r = Invoke-Native -Exe "node" -ArgList @((Join-Path $PSScriptRoot "analyze-crest.mjs"), "--in", $wav, "--impact", "37.5")
    if ($r.Code -ne 0) { throw "analyze-crest 失败：$($r.Text)" }
    Remove-Item $wav -Force -ErrorAction SilentlyContinue
    return ($r.Text | ConvertFrom-Json)
}

Write-Host "=== [$Name] 基线：raw 的 loudness 与 crest ===" -ForegroundColor Cyan
$rawL = Measure-Loudness -File $InAbs
$rawC = Get-Crest -Mp4 $InAbs -Tag "$Name-raw"
Write-Host ("  raw  I={0} TP={1} LRA={2}  最响0.5s@{3}s  crest37.5={4} dB" -f $rawL.I, $rawL.TP, $rawL.LRA, $rawC.loudestHalfSecondAtSec, $rawC.crest.crestDb)

$ex = Invoke-Native -Exe $Ffmpeg -ArgList @("-y", "-hide_banner", "-nostats", "-i", $InAbs, "-vn", "-c:a", "pcm_s24le", "-ar", "48000", (Join-Path $WorkDir "$Name.raw.wav"))
if ($ex.Code -ne 0) { throw "抽音轨失败：$($ex.Text)" }
$wavRaw = Join-Path $WorkDir "$Name.raw.wav"

$gain = [math]::Min($MaxBoost, $TargetI - $rawL.I)
$inv = [Globalization.CultureInfo]::InvariantCulture
$fmt = { param($v) [string]::Format($inv, "{0}", $v) }

$result = $null
for ($iter = 1; $iter -le 3; $iter++) {
    $wavMaster = Join-Path $WorkDir "$Name.mastered.wav"
    $nr = Invoke-Native -Exe "node" -ArgList @(
        (Join-Path $PSScriptRoot "master-audio.mjs"), "--in", $wavRaw, "--out", $wavMaster,
        "--gain", (& $fmt $gain), "--ceiling", "0.75",
        "--comp", "on", "--comp-threshold", "-24", "--comp-ratio", "2.5", "--comp-knee", "8",
        "--comp-attack-ms", "15", "--comp-release-ms", "150",
        "--attack-ms", "4", "--release-ms", "150"
    )
    if ($nr.Code -ne 0) { throw "master-audio.mjs 失败：`n$($nr.Text)" }
    $dsp = $nr.Text | ConvertFrom-Json

    $mx = Invoke-Native -Exe $Ffmpeg -ArgList @(
        "-y", "-hide_banner", "-nostats", "-i", $InAbs, "-i", $wavMaster,
        "-map", "0:v:0", "-map", "1:a:0", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
        "-movflags", "+faststart", $OutAbs
    )
    if ($mx.Code -ne 0) { throw "封装失败：`n$($mx.Text)" }

    $m = Measure-Loudness -File $OutAbs
    Write-Host ("  迭代{0}: gain={1} dB → I={2} TP={3} LRA={4}  limiter={5} dB  comp.max={6} dB avg={7} dB" -f `
            $iter, [math]::Round($gain, 2), $m.I, $m.TP, $m.LRA, $dsp.limiter.maxReductionDb, $dsp.compressor.maxGainReductionDb, $dsp.compressor.avgGainReductionDb)

    $result = [pscustomobject]@{ m = $m; dsp = $dsp; gain = $gain; iter = $iter }
    $delta = $TargetI - $m.I
    if ([math]::Abs($delta) -le 0.15) { break }
    $gain = [math]::Min($MaxBoost, $gain + $delta)
}

$crest = Get-Crest -Mp4 $OutAbs -Tag "$Name-master"
$iOk = ($result.m.I -ge ($TargetI - 0.2)) -and ($result.m.I -le ($TargetI + 0.2))
$tpOk = ($result.m.TP -le $TargetTP)
$posOk = ([math]::Abs($crest.loudestHalfSecondAtSec - 37.5) -le 0.51)
$crestOk = ($crest.crest.crestDb -ge 18.0)
$limOk = ($result.dsp.limiter.maxReductionDb -le 3.0)
$clipOk = ($result.dsp.hardClampedSamples -eq 0)
$lraOk = ($result.m.LRA -ge 3.0)
$pass = $iOk -and $tpOk -and $posOk -and $crestOk -and $limOk -and $clipOk -and $lraOk

$json = [ordered]@{
    name            = $Name
    source          = $InAbs
    output          = $OutAbs
    targetI         = $TargetI
    targetTP        = $TargetTP
    iterations      = $result.iter
    gainDb          = [math]::Round($result.gain, 2)
    raw             = [ordered]@{
        input_i      = $rawL.I
        input_tp     = $rawL.TP
        lra          = $rawL.LRA
        loudestHalfSecondAtSec = $rawC.loudestHalfSecondAtSec
        crest37_5Db  = $rawC.crest.crestDb
        overallRmsDbfs = $rawC.overallRmsDbfs
        peakDbfs     = $rawC.peakDbfs
    }
    master          = [ordered]@{
        input_i      = $result.m.I
        input_tp     = $result.m.TP
        lra          = $result.m.LRA
        loudestHalfSecondAtSec = $crest.loudestHalfSecondAtSec
        loudestHalfSecondRmsDbfs = $crest.loudestHalfSecondRmsDbfs
        crest37_5Db  = $crest.crest.crestDb
        impactPeakDbfs = $crest.crest.impactPeakDbfs
        prev5sRmsDbfs = $crest.crest.prevRmsDbfs
        overallRmsDbfs = $crest.overallRmsDbfs
        peakDbfs     = $crest.peakDbfs
    }
    dsp             = [ordered]@{
        compressor   = $result.dsp.compressor
        limiter      = $result.dsp.limiter
        hardClampedSamples = $result.dsp.hardClampedSamples
    }
    acceptance      = [ordered]@{
        loudnessInWindow = $iOk
        truePeakOk       = $tpOk
        loudestStillAt375 = $posOk
        crestAtLeast18   = $crestOk
        limiterUnder3dB  = $limOk
        noClipping       = $clipOk
        lraAtLeast3      = $lraOk
        pass             = $pass
    }
}
$path = Join-Path $OutDir "report-$Name.json"
$text = $json | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
$text
$color = if ($pass) { "Green" } else { "Red" }
Write-Host ("[{0}] {1}  I={2} TP={3} 最响@{4}s crest={5} dB limiter={6} dB LRA={7}" -f `
        $Name, $(if ($pass) { "PASS" } else { "FAIL" }), $result.m.I, $result.m.TP, $crest.loudestHalfSecondAtSec, $crest.crest.crestDb, $result.dsp.limiter.maxReductionDb, $result.m.LRA) -ForegroundColor $color
