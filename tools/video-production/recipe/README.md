# 渲染与母带 harness

这支宣传片从"工程"到"能发的 mp4"这一步的全部脚本。核心思想：**每一步都能一条命令重跑，且输出可被机器校验。**

## 脚本清单

| 文件 | 作用 |
|---|---|
| `scripts/_render-common.ps1` | 公共逻辑：定位 Chrome、校验 BGM 存在且是 `.wav`、校验 `0≤volume≤1`、**无 BOM** 写 props、调 Remotion、落日志、扫音频告警 |
| `scripts/render-vertical-bgm.ps1` | 竖屏 1080×1920 带 BGM |
| `scripts/render-vertical-nobgm.ps1` | 竖屏仅 SFX（`bgm=false` 时完全不挂 Audio） |
| `scripts/render-wide.ps1` | 横屏 1920×1080 |
| `scripts/_master.ps1` | **旧版**母带：静态增益 + 瞬时压下限制器（已弃用，保留作对比） |
| `scripts/_master2.ps1` | **现行**母带：三遍 loudnorm 量测 → 软拐点压缩 → 斜坡限制器 → 复测 + crest 分析 |
| `scripts/master-audio.mjs` | `_master2.ps1` 调用的浮点压缩器 / 限幅器实现（ffmpeg 没有 `alimiter` 时的替代） |
| `scripts/analyze-crest.mjs` | 逐 0.5 s 窗口的 peak / RMS / crest 分析，用来判断"最响的那一击还在不在原处" |

## 渲染

```powershell
cd promo

# 正式出片（BGM 走参数，不硬编码文件）
.\scripts\render-vertical-bgm.ps1   -BgmFile audio/bgm/bgm-v2.wav -Volume 0.50 -Out hsu-promo-vertical.mp4
.\scripts\render-vertical-nobgm.ps1 -Out hsu-promo-vertical-nobgm.mp4
.\scripts\render-wide.ps1           -BgmFile audio/bgm/bgm-v2.wav -Volume 0.50 -Out hsu-promo-wide.mp4

# 只渲 10 秒验证管线（改片子时先跑这个，别一上来就等 20 分钟）
.\scripts\render-vertical-bgm.ps1 -BgmFile audio/bgm/bgm-v2.wav -Volume 0.46 -Out preview\check.mp4 -Frames 0-599
```

`-BgmFile` 是**相对 `public/` 的 posix 路径**（如 `audio/bgm/bgm-v2.wav`），不是文件系统路径。脚本会先校验文件存在，缺了直接 exit 1，不会静默回落到默认值。

## 母带

```powershell
.\scripts\_master2.ps1 -In .work\vertical-raw.mp4 -Name hsu-promo-vertical -TargetI -16.0
```

链路与默认值：

```
[裸渲染 mp4]
   ↓ loudnorm 量测（pass 1：input_i / input_tp / input_lra）
   ↓ 软拐点总线压缩：−24 dBFS / 2.5:1 / knee 8 dB / attack 15 ms / release 150 ms，立体声链接 RMS 检测
   ↓ 响度增益（按 pass 1 结果迭代收敛到目标 I）
   ↓ 斜坡限制器：4 ms look-ahead，增益在整个窗口内线性斜降，release 150 ms，ceiling 0.75
   ↓ 重新封装（-c:v copy，画面不重编码）
   ↓ loudnorm 复测（pass 3）+ crest 分析
```

为什么是这套参数，以及为什么 **ceiling 是 0.75 而不是 0.794**（AAC 实测过冲 +0.47 dB）、为什么 **目标响度选 −16 而不是平台常见的 −14**（打击乐主导，crest 19 dB，硬拉到 −14 要再削 3 dB 瞬态）——都写在 `docs/promo/04-audio-and-assets.md` 的 2.2b / 2.7 / 2.8 节。

### 母带不是"加个增益"

这是本项目最大的一次返工。同一份混音，两种母带差别巨大：

| 指标 | 母带前 | 硬限制（旧） | 压缩+斜坡限制（现行） |
|---|---|---|---|
| 全片最响的 0.5 s 在哪 | 37.5 s（片尾那一击） | **13.0 s（跑到中段去了）** | 37.5 s（回到第一梯队，与第 1 名差 0.20 dB） |
| 片尾 impact 相对主体的 crest | 21.06 dB | 14.87 dB | 15.31 dB |
| 主体区（5–33 s）最响半秒 RMS | — | −16.16 | −17.38 |

结论：**只做限幅会把片子最值钱的那一击削平**。压缩要把削减摊到全片，限制器只负责收最后 2～4 dB；母带做完必须重新量"最响点还在不在原位"。

## 出片后必须跑的三项校验

```powershell
# 1) 规格：帧数 / 帧率 / 时长 / 音轨
ffprobe -v error -show_entries "format=duration:stream=codec_name,width,height,r_frame_rate,nb_frames" -of default=noprint_wrappers=1 final.mp4

# 2) 响度（量的是成片里那条 AAC，不是中间的 wav）
ffmpeg -hide_banner -nostats -i final.mp4 -vn -af "loudnorm=I=-16:TP=-1.5:print_format=json" -f null -

# 3) 画面没被母带重编码：两个裸流的 SHA-256 必须相同
ffmpeg -i raw.mp4   -an -c:v copy -f h264 -y a.264
ffmpeg -i final.mp4 -an -c:v copy -f h264 -y b.264
Get-FileHash a.264, b.264 -Algorithm SHA256
```

第 3 条尤其值得做：本项目靠它确认画面未被重编码，从而省掉了重新生成 contact sheet、12 张关键帧和两张封面的整整一轮工作。

## 路径假设（重要）

这些脚本里的 `$PromoRoot` 取的是 `$PSScriptRoot` 的上一级，默认去找 `<PromoRoot>\remotion\node_modules\@remotion\compositor-win32-x64-msvc\ffmpeg.exe`，输出默认写到 `<PromoRoot>\.work\`。

所以它们**是为 `promo/` 这个布局写的**：

- 在 `promo/scripts/` 下直接跑，路径全对。
- 复制到别处跑，需要用环境变量覆盖：

  ```powershell
  $env:FFMPEG_PATH  = "C:\path\to\ffmpeg.exe"
  $env:FFPROBE_PATH = "C:\path\to\ffprobe.exe"
  ```

- 换项目时，改 `_render-common.ps1` 里的 `$PromoRoot` 与 `render-*.ps1` 里的 Composition 名（`HsuPromoVertical` / `HsuPromoWide`）即可。

这份是**归档副本**，正本在 `promo/scripts/`。改之前先改正本，再跑 `tools\_sync.ps1` 同步过来。

## 依赖

- Node 24 + Remotion 4.0.484（在 `promo/remotion/` 里 `npm i`）
- Chrome / Chromium（脚本会找；可用 `$env:REMOTION_BROWSER` 指定）
- ffmpeg / ffprobe：**用 Remotion 自带的那份即可**，但要知道它是裁剪版（没有 `alimiter`、没有 `f32le` muxer、量音频必须加 `-vn`）。
