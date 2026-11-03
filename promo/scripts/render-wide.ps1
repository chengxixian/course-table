<#
.SYNOPSIS
  渲染横版 1920×1080 60fps 宣传片（带 BGM）。

.EXAMPLE
  .\render-wide.ps1 -BgmFile audio/bgm/bgm-final.wav -Volume 0.46 -Out hsu-promo-wide.mp4
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

Write-Host "[config] composition=HsuPromoWide bgm=$bgmRel volume=$vol frames=$(if($Frames){$Frames}else{'all'})" -ForegroundColor Cyan
Invoke-RemotionRender -Composition "HsuPromoWide" -OutAbs $outAbs -PropsFile $props -Frames $Frames -Concurrency $Concurrency | Out-Null
