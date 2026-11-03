<#
.SYNOPSIS
  渲染竖版 1080×1920 60fps 宣传片（无 BGM，仅 SFX）。

.EXAMPLE
  .\render-vertical-nobgm.ps1 -Out hsu-promo-vertical-nobgm.mp4

.EXAMPLE
  # 只渲前 10 秒做管线自检
  .\render-vertical-nobgm.ps1 -Out preview/selfcheck-nobgm.mp4 -Frames 0-599
#>
param(
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$Frames = "",
    [int]$Concurrency = 4
)

. "$PSScriptRoot\_render-common.ps1"

$outAbs = Resolve-OutputPath -Out $Out
$props  = Write-PropsFile @{ bgm = $false }

Write-Host "[config] composition=HsuPromoVertical bgm=OFF (SFX only) frames=$(if($Frames){$Frames}else{'all'})" -ForegroundColor Cyan
Invoke-RemotionRender -Composition "HsuPromoVertical" -OutAbs $outAbs -PropsFile $props -Frames $Frames -Concurrency $Concurrency | Out-Null
