# 课程表 · 40s 宣传片 BGM（07-bgm）

> 交付人：`bgm-composer`（音频专职）。本文件只描述音频交付与混音建议，
> 未改动视频源码 / App / 版本号，未发布。
>
> **验收状态：未经人耳试听。** 本机没有音频输出设备，也没有 ffmpeg/ffprobe，
> 因此全部结论均为**文件级数值 + 频谱/波形图校验**，不是听感结论。
> 建议在发布前由人耳在手机外放 + 耳机各听一遍（见 §7）。

## 1. 交付物与冻结版本

| 文件 | 说明 | 大小 |
|---|---|---|
| `promo/audio/bgm.wav` | **主交付**：48 kHz / 16-bit PCM / 立体声 / 40.000 s | 7,680,044 B |
| `promo/audio/cues.json` | 7 镜头 + 80 拍网格 + 29 个重音/切点，含每段电平 | 21,749 B |
| `promo/audio/bgm.mp3` | 可选预览版：192 kbps CBR / 48 kHz / 立体声 / 40.032 s（MP3 帧粒度） | 960,768 B |
| `promo/audio/make-bgm.mjs` | 合成脚本（唯一声音来源，可重跑） | — |
| `promo/audio/analyze-wav.mjs` | 峰值 / RMS / LUFS-I / 直流 / 削波 / 声道相关分析 | — |
| `promo/audio/spectral-report.mjs` | 倍频程频段与频谱质心报告 | — |
| `promo/audio/visualize-bgm.mjs` | 波形 + 对数频谱图（`analysis/bgm-spectrogram.png`） | — |

**冻结校验（视频混音请以此为准）**

```
bgm.wav  SHA-256 C854C62494F57BF27BA5AC5EBC41E30373439E4F58B97BB844340203E7A66CC1
cues.json SHA-256 A11718E437EB31D64A191D41FB60B99105F6496CD4C820E70A16645A76B118CC
```

`bgm.wav` 最后一次写入为 2026-11-02 16:21:55，**此后再未改动**。若后续重跑
脚本导致哈希变化，必须通知 Lead 与 `promo-video` 重混，不能当作同一素材。

`bgm.mp3` 只是方便在无 WAV 解码器的环境里预览；**成片混音只用 `bgm.wav`**，
不要用 MP3（有编码延迟/帧粒度，40.032 s ≠ 40.000 s）。

## 2. 来源与许可

- **100% 原创合成**：全部声音由 `promo/audio/make-bgm.mjs` 用数学方式实时合成，
  没有采样包、没有下载音频、没有第三方旋律/和弦进行、没有网络请求。
- **许可：CC0-1.0**（与工程内 `scripts/make-audio.mjs` 的拟音同一政策：
  自制并随工程 CC0 奉献）。不引入任何第三方版权或署名义务。
- **可复现**：只用固定种子 `mulberry32`；无 `Date`、无 `Math.random()`、无外部输入。
  同一脚本 + 同一常数 → 同一样本序列。
- 与产品的关系：BGM 不采样 App 内任何音频（App 本身没有音频素材）。

## 3. 音乐结构

- **120 BPM，4/4，D 大调（带 Bm7 / F#m7 / A7sus4 的调式色彩），20 小节 = 80 拍 = 40.000 s。**
- 选 120 BPM 的原因：30 fps 下 **1 拍 = 15 帧**，7 个镜头切点 150/390/540/750/930/1080/1200
  全部落在拍点上，1200 帧正好 80 拍，不需要任何非整数偏移。仍在要求的 118–124 内。
- 器乐编制（全部合成）：felt piano（毡槌钢琴）、warm pad（14 次谐波加法波表 + 一阶低通）、
  plucked bass、低音弦乐长音、soft kick、brush shaker、wood tick（钟摆/木鱼）、
  timpani（定音鼓）、glass / music-box 高音、1.5 s 暗色卷积混响（合成脉冲响应）。
- 和声进行（每小节 2 s）：

```
bar 1  Dmaj9      bar 6  Gmaj7     bar 11 A7        bar 16 Gmaj7
bar 2  Bm7        bar 7  A7sus4    bar 12 F#m7      bar 17 A7sus4
bar 3  Gmaj7      bar 8  Dmaj9/F#  bar 13 Bm7       bar 18 A7      ← 收尾上升
bar 4  A7sus4     bar 9  Bm7       bar 14 Em7       bar 19 Dmaj9   ← 解决
bar 5  F#m7       bar 10 Gmaj7     bar 15 A7sus4    bar 20 = 19 的延续
```

- 曲子以 D 大调（第 20 小节是 Dmaj9：D–A–C#–E–F#）收束；1142 帧的收束和弦是
  D–A–D–F#，片尾 `chime.wav` 的 660 Hz 是它的 **9 音 E5**，不冲突；BGM 在 1160 帧
  补一个 E5，把 Dmaj9 补全。

### 3.1 分镜对照表（电平为实测）

| 镜头 | 帧 | 秒 | 小节 | 音乐内容 | 峰值 dBFS | RMS dBFS | 短时 LUFS |
|---|---|---|---|---|---|---|---|
| S1 OPEN | 0–150 | 0–5.0 | 1–2.5 | 暗色 pad 起音；毡槌钢琴 5 音；0.5–5.5 s 钟摆 tick（1560/1080 Hz 交替）；低音 D2/A2 铺底 | −8.82 | −21.36 | −19.0 |
| S2 WEEK | 150–390 | 5.0–13.0 | 2.5–6.5 | 5.0 s 切点换 Gmaj7；8.0 s 起 shaker + 软 bass，10.0 s 起轻 kick；钢琴动机上行；6.0–7.6 s 的 8 次 stamp 期间**不加重击** | −6.60 | −21.08 | −19.0 |
| S3 DETAIL | 390–540 | 13.0–18.0 | 6.5–9 | 鼓组全部退出；低音弦乐 F#2 长音；钢琴旋律放宽；13.3 s pop 与 13.8 s 纸滑前后留白 | −6.19 | −20.17 | −18.2 |
| S4 IMPORT | 540–750 | 18.0–25.0 | 9–12.5 | 完整轻律动：kick 1/3 拍、8 分 shaker、bass 切分；19.0–20.4 s 打字期间旋律让位；20.5 s 后旋律回来 | −5.66 | −18.72 | −17.0 |
| S5 DRAG | 750–930 | 25.0–31.0 | 12.5–15.5 | 25.0–26.6 s 抽空鼓组 + 噪声 suck；**800 帧 snap 重音**；806 帧 settle；27 s 律动回归 | −5.22 | −18.86 | −17.1 |
| S6 WIDGETS | 930–1080 | 31.0–36.0 | 15.5–18 | 轻快精密律动 + 高音 glass 上升动机；32.75 s 后加 16 分 shaker 碎点；四张小组件落位处旋律避让 | −5.76 | −18.85 | −17.1 |
| S7 OUTRO | 1080–1200 | 36.0–40.0 | 18–20 | 鼓组停止；A2 长音 + 定音鼓滚奏 36.45–37.4 s；**1126 帧 impact**；**1142 帧 Dmaj9 解决**；38.86–39.89 s 余弦淡出，39.89 s 后数字静音 | −3.61 | −17.88 | −15.1 |

能量曲线与 `02-storyboard.md` 一致：低 → 中 → 中 → 中高 → 中 → 中高 → 峰值。
S1–S3 的短时 LUFS 比较接近，是因为持续 pad 承担了大部分响度、而这几个镜头没有鼓；
S5 的平均值也接近 S4，但段落内部有 25.0–26.6 s 的明显落差。真正的“呼吸”靠
**配器进出**（S3 鼓组退出、S5 开头抽空）而不是靠硬压电平。

## 4. 节拍 / 重音表（`cues.json`）

- 网格：80 拍，每拍 15 帧（30 fps 作者帧），每小节 4 拍 / 60 帧。
- `cues.json` 的 `frame` 是**作者帧（30 fps）**，与 `timeline.ts` 的 `SHOTS` 同口径。
  Remotion 成片是 60 fps，使用时乘 `FS=2`（与 `src/audio.tsx` 的 SFX 表做法一致）。
- 29 个重音/切点中，音乐层自己打的点只有三个：

| 帧 | 秒 | 拍 | 事件 | 音乐处理 |
|---|---|---|---|---|
| **800** | 26.667 | 53.33 | **SNAP 重音** | 低音 kick + D add9 开放和声 + 玻璃高音；中频 click 留给 `snap.wav` |
| **1126** | 37.533 | 75.07 | **字标 impact** | 中低 A + A7 宽和声 + 高音 shimmer；sub 留给 `impact.wav` |
| **1142** | 38.067 | 76.13 | **收束解决** | Dmaj9；E5 与 `chime.wav` 660 Hz 同音 |
| 780 | 26.0 | 52.0 | 落点高亮 | 噪声 suck 渐强（340→2600 Hz） |
| 806 | 26.867 | 53.73 | 归位 stamp | 只加一个 1760 Hz settle tick，不与 SFX 抢 |
| 1185 | 39.5 | 79.0 | 字标 hold | 无新音符，只剩和弦尾音与淡出 |
| 1200 | 40.0 | 80.0 | 片尾 | 已到数字静音 |

其余 22 个点是与 SFX 对齐的切点/拟音点（2/48/70/150/180…/390/399/540/570…/750/756/930/938/964/972/980/1080/1105/1140），
JSON 里带 `layer: "sfx" | "bgm" | "both"` 与中文说明。

## 5. 电平报告（数值校验）

### 5.1 整轨

| 指标 | 数值 | 说明 |
|---|---|---|
| 时长 | **40.000000 s**（1,920,000 帧） | 精确 40 s，尾部 115.5 ms 数字静音 |
| 格式 | 48 kHz / 16-bit / 2 ch | 与工程其他音频一致 |
| 采样峰值 | **−3.61 dBFS** | 最大样本 0.660，无削波 |
| True peak（4× 插值估计） | **−3.60 dBFS** | 留 3.6 dB headroom |
| RMS | **−19.49 dBFS** | 峰值–RMS 差 15.9 dB |
| Integrated loudness | **−17.5 LUFS-I** | BS.1770-4 K 加权 + 门限，非估算 |
| 削波样本 | **0** | 全轨没有 ≥ 0.9999 的样本 |
| 直流偏移 | −99.3 dBFS | 可忽略 |
| L/R 相关度 | 0.85 | 单声道兼容良好，无相位抵消 |
| 淡入 | 12 ms 余弦 | 首样本前 7 ms 为 0，无起音 click |
| 淡出 | 38.86 → 39.89 s 余弦，之后为 0 | 为 S7 字标 hold 留呼吸 |

### 5.2 倍频程频段（整轨，dBFS 频段总能量）

| sub 20–63 | low 63–125 | lowmid 125–250 | mid 250–500 | mid2 0.5–1k | himid 1–2k | presence 2–4k | high 4–8k | air 8–16k | top 16–24k |
|---|---|---|---|---|---|---|---|---|---|
| −26.1 | −22.4 | **−21.7** | **−19.3** | −24.4 | −31.2 | −39.6 | −49.2 | −53.1 | −56.1 |

频谱质心 **328 Hz**，能量集中在 125–1000 Hz，2 kHz 以上快速滚降——这是刻意的
“温暖克制”：高频细节主要交给片中的纸滑/键盘/落版/收束拟音，BGM 不抢。

### 5.3 混音建议（与现有 SFX 的配平）

本轨比旧 `bed-paper-piano.wav` 更满、更有律动。注意旧 bed 虽然文件响度有 −16.5 LUFS，
但当时只给 0.30（有效约 −26.9 LUFS）；本轨建议 0.45（有效 −24.4 LUFS），
存在感比旧 bed 明确约 2.5 dB。不要沿用旧 bed 的 0.30，也不要两轨叠加（会糊、会重复和声）。

| Remotion `volume` | 有效 LUFS | 有效峰值 | 适用 |
|---|---|---|---|
| 0.42 | −25.0 | −11.2 dBFS | 拟音优先，BGM 只做底 |
| **0.45（建议）** | **−24.4** | **−10.6 dBFS** | 与 `impact.wav`（−10.2 dBFS）齐平，BGM 不压拟音 |
| 0.50 | −23.5 | −9.6 dBFS | BGM 更前置；仍不会削波 |

峰值预算（按 0.45）：BGM −10.6 dBFS + 最响 SFX impact −10.2 dBFS，
最坏相干叠加 ≈ −7.3 dBFS，仍有 7 dB 余量；正常叠加更小。**整条混音不会削波**，
但最终混音峰值需要 `promo-video` 在成片里复核（本机无 ffmpeg）。

## 6. 与 SFX 的分工（为什么不是“两套声音打架”）

- **800 snap**：`snap.wav` 是 780 Hz 木质 click；BGM 只给低频身体 + 开放和声 + 高音，
  不重复中频 click。
- **1126 impact**：`impact.wav` 是 72→52 Hz sub；BGM 只给中低 A 与宽和声，
  不重复 sub。
- **1142 chime**：`chime.wav` 基频 660 Hz（E5）；BGM 解决到 Dmaj9，E5 在和弦内。
- **6.0–7.6 s 的 8 次 stamp**：BGM 在该区间没有鼓，shaker 从 8.0 s 才进。
- **19.0–20.4 s 打字**：BGM 旋律在 18.78 s 后停到 20.55 s，避免与 6 次 key 抢 2–4 kHz。
- **开场“打字机”**：BGM 只做钟摆 tick；真正打字/纸感由片中已有的 paper-slide/stamp 拟音承担。

## 7. 未验证项与已知取舍（必读）

1. **没有试听。** 本环境无音频输出，未做人工听感验收。已做的是：文件头/时长/声道/
   采样率、峰值/True peak/RMS/LUFS-I、削波样本、直流、L/R 相关、首尾静音、
   倍频程平衡、频谱图（`promo/audio/analysis/bgm-spectrogram.png`）逐段检查。
   这些能排除“削波/爆音/静音/相位抵消/频段失衡”，不能替代人耳判断“好不好听”。
2. **120 BPM 取在 118–124 的上沿**，原因是 30 fps 下 1 拍 = 15 帧，所有切点才能落在拍上。
3. **与 `04-audio-and-assets.md` 的原策略不同**：原文档写“不启用强拍 BGM、不做逐拍卡点”，
   本轨按 Lead 的最新要求加入了 120 BPM 轻律动与三个音乐重音。它不是 EDM 式强拍，
   但确实存在可感知的拍点；这是**有记录的需求变更**，不是遗漏。
4. **成片容器 40.064 s vs 本轨 40.000 s**：差 64 ms 来自 AAC priming。Remotion 内
   按 1200 帧时间线播放，尾部 64 ms 是静音，不会截断音乐。
5. **未在最终混音里复核**：本机无 ffmpeg，无法对“BGM + SFX + AAC”成片做解码回测；
   成片峰值/响度由 `promo-video` 负责最终确认。
6. 本曲**没有**逐拍卡点（beat-sync）到画面动作；只对齐镜头切点与三个重音，
   因此不需要逐帧微调；若后续改时间线，按 `cues.json` 的拍网格整体平移即可。

## 8. 集成方式（给 `promo-video`）

- **唯一推荐**：拿 `promo/audio/bgm.wav`，从 **0 帧 / 0.000 s** 起铺满 1200 帧，
  `volume ≈ 0.45`（范围 0.42–0.50）。
- 现有 `hsu-promo-vertical.mp4` 已混入旧环境 bed，**不能**在其上再加本轨；
  应使用无 BGM 版（保留 SFX）重新混，或在 Remotion 中把
  `<Audio src="audio/bgm/bed-paper-piano.wav">` 替换为
  `public/audio/bgm/bgm.wav`（即 `staticFile("audio/bgm/bgm.wav")`）。
- 若在 Remotion 内引用：`<Audio src={staticFile("audio/bgm/bgm.wav")} volume={0.45} />`，
  起始帧 0；它和 SFX 一样按 `Sequence` 从 0 开始，无需再减 offset。
- 混完后请把 `cues.json` 里的 `mix.recommendedVolume` 与最终实际值对齐（如不同），
  并在成片 QA 里记录实际峰值。
- 重跑脚本会覆盖 `promo/audio/bgm.wav` 与 `cues.json`；如需重跑，请先告知 Lead。

## 9. 复现

```bash
cd D:/hsu_flutter
node promo/audio/make-bgm.mjs                 # 重新合成 bgm.wav + cues.json
node promo/audio/analyze-wav.mjs promo/audio/bgm.wav
node promo/audio/spectral-report.mjs promo/audio/bgm.wav
node promo/audio/visualize-bgm.mjs promo/audio/bgm.wav promo/audio/analysis/bgm-spectrogram.png
```

`make-bgm.mjs` 只依赖 Node 内置模块与 `fs/path`，不需要 npm install。
