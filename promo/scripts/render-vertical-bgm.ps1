<#
.SYNOPSIS
  渲染竖版 1080×1920 60fps 宣传片（带 BGM）。

.EXAMPLE
  .\render-vertical-bgm.ps1 -BgmFile audio/bgm/bgm-final.wav -Volume 0.46 -Out hsu-promo-vertical.mp4

.EXAMPLE
  # 只渲前 10 秒做管线自检
  .\render-vertical-bgm.ps1 -BgmFile audio/bgm/bgm-v2-draft.wav -Volume 0.46 -Out preview/selfcheck.mp4 -Frames 0-599
#>
param(
    [Parameter(Mandatory = $true)][string]$BgmFile,
    [Parameter(Mandatory = $true)][double]$Volume,
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$Frames = "",
    [int]$Concurrency = 4
)

. "$PSScriptRoot\_render-common.ps1"

$bgmRel = Assert-BgmFile -BgmFile $BgmFile
$vol    = Assert-Volume -Volume $Volume
$outAbs = Resolve-OutputPath -Out $Out
$props  = Write-PropsFile @{ bgm = $true; bgmFile = $bgmRel; bgmVolume = $vol }

Write-Host "[config] composition=HsuPromoVertical bgm=$bgmRel volume=$vol frames=$(if($Frames){$Frames}else{'all'})" -ForegroundColor Cyan
Invoke-RemotionRender -Composition "HsuPromoVertical" -OutAbs $outAbs -PropsFile $props -Frames $Frames -Concurrency $Concurrency | Out-Null
