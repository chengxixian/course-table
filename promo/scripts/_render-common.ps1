# _render-common.ps1 — 共享的渲染工具函数（被三个 render-*.ps1 dot-source）
# 只负责：定位 Chrome、校验 BGM 输入、写 props、调用 remotion render。
# 约定：所有路径以 promo/ 为根；BGM 路径是相对 remotion/public/ 的 posix 路径。

$ErrorActionPreference = "Stop"

$script:PromoRoot   = Split-Path -Parent $PSScriptRoot          # ...\promo
$script:RemotionDir = Join-Path $script:PromoRoot "remotion"
$script:PublicDir   = Join-Path $script:RemotionDir "public"
$script:TmpDir      = Join-Path $PSScriptRoot ".tmp"

function Get-RemotionChrome {
    if ($env:REMOTION_BROWSER) {
        if (Test-Path $env:REMOTION_BROWSER) { return (Resolve-Path $env:REMOTION_BROWSER).Path }
        throw "环境变量 REMOTION_BROWSER 指向的文件不存在：$env:REMOTION_BROWSER"
    }
    $cands = @(
        (Join-Path $env:LOCALAPPDATA "Google\Chrome\Application\chrome.exe"),
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    )
    foreach ($c in $cands) { if (Test-Path $c) { return $c } }
    throw "找不到 Chrome/Edge。请设置 `$env:REMOTION_BROWSER 指向 chrome.exe 后重试。"
}

function Assert-BgmFile {
    param([Parameter(Mandatory = $true)][string]$BgmFile)
    if ([string]::IsNullOrWhiteSpace($BgmFile)) { throw "-BgmFile 不能为空。" }
    if ($BgmFile -match '^[A-Za-z]:') {
        throw "-BgmFile 必须是相对 remotion/public/ 的 posix 路径（如 audio/bgm/bgm-v2.wav），不能是绝对路径：$BgmFile"
    }
    $rel  = ($BgmFile -replace '\\', '/').TrimStart('/')
    $full = Join-Path $script:PublicDir ($rel -replace '/', '\')
    if (-not (Test-Path $full)) {
        throw "BGM 文件不存在：$full`n  → -BgmFile '$BgmFile' 必须相对 promo/remotion/public/ 且真实存在。"
    }
    if ([IO.Path]::GetExtension($full).ToLower() -ne '.wav') {
        throw "BGM 必须是 .wav（当前：$full）。"
    }
    return $rel
}

function Assert-Volume {
    param([Parameter(Mandatory = $true)][double]$Volume)
    if ($Volume -lt 0 -or $Volume -gt 1) { throw "-Volume 必须在 0..1 之间，收到：$Volume" }
    return $Volume
}

function Resolve-OutputPath {
    param([Parameter(Mandatory = $true)][string]$Out)
    if ([IO.Path]::IsPathRooted($Out)) { $abs = $Out } else { $abs = Join-Path $script:PromoRoot $Out }
    $dir = Split-Path -Parent $abs
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return $abs
}

function Write-PropsFile {
    param([hashtable]$Props)
    New-Item -ItemType Directory -Force -Path $script:TmpDir | Out-Null
    $file = Join-Path $script:TmpDir ("props-" + [guid]::NewGuid().ToString("N").Substring(0, 8) + ".json")
    $json = $Props | ConvertTo-Json -Compress -Depth 4
    # 无 BOM 写出：Remotion 用 JSON.parse 读这个文件，BOM 会让它报错
    [System.IO.File]::WriteAllText($file, $json, (New-Object System.Text.UTF8Encoding($false)))
    return $file
}

function Invoke-RemotionRender {
    param(
        [Parameter(Mandatory = $true)][string]$Composition,
        [Parameter(Mandatory = $true)][string]$OutAbs,
        [Parameter(Mandatory = $true)][string]$PropsFile,
        [string]$Frames = "",
        [int]$Concurrency = 4
    )

    $chrome = Get-RemotionChrome
    New-Item -ItemType Directory -Force -Path $script:TmpDir | Out-Null
    $log = Join-Path $script:TmpDir ("render-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

    $parts = @(
        "remotion", "render", "src/index.ts", $Composition, "`"$OutAbs`"",
        "--props=`"$PropsFile`"",
        "--concurrency=$Concurrency",
        "--browser-executable=`"$chrome`"",
        "--log=info"
    )
    if ($Frames) { $parts += "--frames=$Frames" }
    $cmd = "npx.cmd " + ($parts -join " ")

    Push-Location $script:RemotionDir
    try {
        Write-Host "[render] $cmd" -ForegroundColor DarkGray
        $output = & cmd /c $cmd 2>&1
        $code = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    $output | Set-Content -Path $log -Encoding UTF8
    $output | Select-Object -Last 6 | ForEach-Object { Write-Host "  $_" }

    if ($code -ne 0) { throw "remotion render 失败（exit $code）。完整日志：$log" }
    if (-not (Test-Path $OutAbs)) { throw "渲染结束但产物不存在：$OutAbs（日志：$log）" }

    $audioWarn = $output | Where-Object { $_ -match "(?i)audio|sound|wav|codec" -and $_ -match "(?i)warn|error|fail" }
    if ($audioWarn) {
        Write-Warning "渲染日志里出现音频相关告警："
        $audioWarn | ForEach-Object { Write-Warning "  $_" }
    }
    else {
        Write-Host "[render] 日志中无音频相关告警" -ForegroundColor Green
    }

    $size = (Get-Item $OutAbs).Length
    Write-Host ("[render] OK  {0}  ({1:N2} MB)  log={2}" -f $OutAbs, ($size / 1MB), $log) -ForegroundColor Green
    return $OutAbs
}
