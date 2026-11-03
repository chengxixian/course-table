# 声音与素材来源

## 1. 声音构成

| 层 | 内容 | 来源 | 许可 |
|---|---|---|---|
| **BGM** | 40.000s 原创曲，120 BPM / 4/4 / D 大调，20 小节；4 小节 hook + counter-melody + bass + 13 轨鼓组；REAPER 15 轨工程 | `promo/reaper/` 手写 MIDI → REAPER 离线渲染 → `promo/audio/bgm-v2.wav` | CC0-1.0（自创作曲，无第三方采样） |
| **Foley SFX** | 9 个样本：`swish` / `paper-slide` / `stamp` / `pop` / `snap` / `key` / `riser` / `impact` / `chime` | **本工程合成**（`scripts/make-audio.mjs` 的确定性合成，按画面语义逐个调过） | CC0（自制） |

BGM 指纹（已核对，与作曲者交付一致）：

```
文件     promo/audio/bgm-v2.wav
SHA-256  6F7D680D2B682F092BBD72744CDF5137D481B1C922036AA9135C131133DFB5B0
格式     48 kHz / 24-bit / stereo / 40.000000 s / 1,920,000 帧
电平     peak −4.50 dBFS / true peak −4.50 dBFS / RMS −19.82 dBFS / −17.9 LUFS-I
宽度     side − mid = −12.4 dB / L-R 相关 0.894
```

工程内固定文件：`promo/remotion/public/audio/bgm/bgm-v2.wav`（同哈希），
`cues-v2.json` 一并入库；渲染只读本地文件，不联网。

### 1.1 为什么 chime 是合成的（E5 音准）

`chime.wav` 按 **660 Hz（E5）** 合成，正好与片尾 BGM 的 E 大调和弦同音。
曾评测 `fs:452379 Small Bell #2`（CC0，↓2235 ★4.8(39)），它是很好的小铃，但基频落在
**A#3**——A# 是 E 大调的降七级，贴上去会当场打架。为了"换成实录"而制造音准冲突不划算。

### 1.2 实录替换为什么被回退（重要判例）

2026-11 曾把 8 个拟音换成 Freesound CC0 实录（`fs:71852` / `464302` / `555545` / `733264` /
`478197` / `701113` / `511872` / `511883`），**已全部回退**。用户反馈"音效好奇怪、声音过大"。

Lead 用 `sfx-analyze.mjs` 对两套逐条做频谱比对，结论是**声音设计语义不匹配，不是素材质量问题**：

| cue | 实测差异（实录 vs 合成） | 听感后果 |
|---|---|---|
| `stamp` | 低频 **−29.2 dB**、临场 +21.7 dB、f0 B6 → **F4** | 木块是纯音高的"嗒"，没有体积感；连续 8 下像敲木鱼 |
| `riser` | 低频 **+16.4 dB**、空气感 −19 dB | 变成低频轰鸣，糊住 BGM 低音 |
| `pop` | f0 **393 → 787 Hz**（高八度）、临场 +10.2 | 气泡声，还跳了一个八度 |
| `impact` | body +14.4、临场 +20.2、f0 → 417 Hz | 中频偏厚且带音高，像电影预告片撞击 |
| `swish` | 临场 −14、空气感 −20.5 | 闷的低频 whoosh，不清亮 |
| `key` | 低频 +13.7 | 带桌面共鸣，像机械键盘 |

**判例**：UI 宣传片的拟音是"设计过的、克制的"声音事件，不是把风格无关的真实录音拼起来。
合成集每个音都按画面语义（纸滑/落版/木块/气泡/落槽）单独调过，语义是对的；
"更真实"不等于"更合适"。若将来再换实录，先按上表逐条量频谱差异，并优先保证
**同一语义族**（例如纸类仍取纸类），而不是取"听起来很酷"的单品。

原合成集与实录集都留档：`promo/audio/sfx-synth-v1/`（现行）、`.work/sfx-final/`（已弃用）。

## 2. 混音（实测，不是估算）

`scripts/check-mix.mjs` 用与 `src/audio.tsx` **同一张 SFX 表**（把 TSX 打包后在 Node 里跑）
重建整条音频总线：BGM 按 24 帧淡入到目标音量，40 条拟音按帧偏移叠加，再统计峰值/RMS/削波。
支持 16/24-bit PCM；`--bgm / --volume / --sfxGain` 即可对任意候选做 A/B。

### 2.1 SFX 电平与「≥4 dB 峰值差」判定线的废止

`src/audio.tsx` 里只有一个总线常量 `SFX_GAIN`（现为 **1.00**，曾一度提到 1.45），以及每条拟音的 `volume`。
它不改变单条拟音之间的相对比例、不改帧位、不改音色。

**旧判定线 `BGM↔SFX 峰值差 ≥4 dB` 已废止。** 它是为了提高音乐可闻度自己发明的代理指标，
实际效果是把整条 SFX 总线往上推，最后用户听到的结论是"声音过大"。
现行口径：**SFX 峰值可以只比 BGM 峰值高 1–2 dB**，真正的护栏是
**「全片最响的 0.5 s 必须落在片尾 37.5s 的 impact，不能落在中段的连续敲击上」**。

### 2.2 平衡实测（母带之前，BGM 0.50 档）

| 指标 | 值 | 期望 |
|---|---|---|
| BGM 有效峰值 | −10.53 dBFS | ✓ |
| SFX 峰值 | −9.10 dBFS | ✓ |
| 峰值差（SFX − BGM） | **+1.43 dB** | 1–2 dB ✓ |
| 混音峰值 | −5.35 dBFS | 0 削波 ✓ |
| **最响 0.5s 位置** | **37.5 s** | 必须在片尾 ✓ |

上一版（实录集 + SFX_GAIN 1.45）最响点是 **6.0 s**——S2 那串课块敲击比片尾 impact 还响，
这就是"太吵"的根源；回退合成集 + 降电平后回到 37.5 s。
### 2.2b 母带为什么从「硬限制」改成「压缩 + 平滑限制」

旧链路是「静态增益 + 瞬时压下的前瞻限制器」，能量削减全部集中在极少数峰值上。实测伤害：

- 母带前全片最响的 0.5s 在 **37.50 s**（尾卡 impact），母带后漂移到 **13.00 s**（detail 段）——
  片子的落点被抹平；
- 37.5s 的 impact 相对前 5s RMS 的 crest 从 **21.30 dB** 掉到约 16.3 dB，而主体被抬高 6.60 dB、
  冲击只抬高 1.51 dB，"鼓点变软"。

现在的两级：

| 级 | 参数 | 作用 |
|---|---|---|
| 1 软拐点总线压缩 | 立体声链接、RMS 检测；threshold **−24 dBFS**、ratio **2.5:1**、knee **8 dB**、attack **15 ms**、release **150 ms**、makeup 0 | 把削减摊到全片主体，而不是只砍两个峰 |
| 2 斜坡前瞻限制器 | look **4 ms**、ceiling **0.75**（−2.5 dBFS，吸收 AAC +0.47 dB 过冲）、release **150 ms**；增益在**整个 lookahead 内线性斜降**，峰值到达时正好到位 | 去掉"瞬跳 attack"造成的硬折角，冲击前沿不再被削平 |

增益在**压缩之后**施加（压缩器工作在节目原始电平上，−24 dBFS 的阈值才有意义），
随后由限制器兜住峰值；响度用实测 I 迭代收敛。
### 2.3 响度判定（母带之后）

母带用 `scripts/_master.ps1` 三遍：`loudnorm` 量测 → 静态增益 + 前瞻限制器 → 复测。
视频流 `-c:v copy`（已用 h264 裸流 SHA-256 验证两侧完全一致，视频没有重编码）。

目标常量写死：`TARGET_I = -16.0`、`TARGET_TP = -1.5`。

**为什么不是 −14**：本片混音是打击乐主导，母带前 crest（TP−I）约 19 dB；
拉到 −14 需要再削 3 dB 以上的瞬态，会把刚做强的鼓压平、把 impact 打薄。
−16 LUFS-I 是短视频平台"正常音量"区间，且保留瞬态。

### 2.4 与原始母带指令的四处偏差（均为实测所迫，已报 Lead）

1. **没有 `alimiter`**：本工程 ffmpeg 是 Remotion 的裁剪构建（实测 `No such filter: 'alimiter'`，
   可用滤镜只有 loudnorm / volume 等）。改用 `scripts/master-audio.mjs` 实现语义等价的
   前瞻限制器：attack 4 ms、release 80 ms、ceiling 可调、峰值前视 4 ms。
2. **增益上限 6 → 8 dB**：实测 `TARGET_I - input_i = 6.54 dB`，封顶 6 dB 时成品只有 −16.85，
   落在窗口外；放开到 8 后收敛（v2 母带为 −16.02）。
3. **ceiling 0.794 → 0.75**：AAC 编码过冲实测 +0.47 dB，0.794 时成品 TP 为 −1.42（超 −1.5）；
   降到 0.75 后 TP = −2.33，安全。
4. **增加一次增益收敛迭代**：限制器会吃掉能量，首轮增益后响度仍偏低（−16.37 / −18.70），
   用实测差再修正一次增益（±0.3 dB 容差），第二遍收敛。

**限幅量**：旧版 v1 为 6.09 dB；v2 引入压缩后降到 **4.21 dB**（BGM 版）。剩余削减仍来自素材 crest：
19.2 dB 的节目 crest 要装进 14.5 dB 的目标窗口，差值必须由压缩+限幅吃掉。这条已由 Lead 复核并按修订后的判定线接受（见 `06-qa-report.md` 表 B′）。

### 2.5 母带实测（成品）

（下表为 **母带 v2 / master2**，已采纳并覆盖到 `promo/`；旧版 v1 母带数值见 `06-qa-report.md` 的"母带 v1 → v2 的差异"。）

| 文件 | 目标 I | pass1 I / TP | 增益 | 压缩 max/avg | 最大压限 | pass3 I | pass3 TP | pass3 LRA |
|---|---|---|---|---|---|---|---|---|
| hsu-promo-vertical.mp4 | −16 | −22.54 / −3.31 | +8.32 dB | 8.68 / 1.09 dB | 4.21 dB | **−16.02** | **−2.27** | 1.70 LU |
| hsu-promo-wide.mp4 | −16 | −22.54 / −3.31 | +8.32 dB | 8.68 / 1.09 dB | 4.21 dB | **−16.02** | **−2.27** | 1.70 LU |
| hsu-promo-vertical-nobgm.mp4 | −18 | −23.49 / −5.10 | +8.10 dB | 7.98 / 0.65 dB | 4.42 dB | **−18.14** | **−2.15** | 8.90 LU |

无 BGM 版目标放到 −18 是刻意的：它没有音乐垫底，若强行拉到 −16 会把拟音的呼吸感压没；
两支响度不同是有意为之，不是漏混。

### 2.6 当前 `promo/*.mp4` 状态

三支均为 **v2 BGM + 母带后**成品，与仓库源码一致，可复现（`render-*.ps1` → `_master.ps1`）。
v1 BGM 保留在 `public/audio/bgm/bgm-final.wav`，只作对照，不参与交付。
## 3. 声画对位

- SFX 全部由 `SHOTS.*` 派生（`src/audio.tsx` 的 `SFX` 表），30fps 作者帧 ×2 = 60fps 交付帧。
- BGM 的 `cues.json` 与本片 7 个镜头同网格：150/390/540/750/930/1080 处切点换和声；
  800 是 snap 重音、1126 是字标 impact、1142 收束；6.0–7.6s 与 19.0–20.4s
  刻意让位给 stamp / 打字 SFX。
- 本片没有口播，不需要 ducking；音乐留出的 SFX 区间由作曲者直接写在编曲里。

## 4. 视觉素材来源

| 素材 | 来源 | 备注 |
|---|---|---|
| 字体 `FandolFang-Regular.otf` | `D:\hsu_flutter\assets\fonts_ofl\`（App 自带） | GPL-3.0 + 字体例外，见 `public/fonts/Fandol-COPYING.txt` |
| 字体 `LiberationSerif-Regular.ttf` | 同上（App 自带） | SIL OFL 1.1，见 `public/fonts/LiberationSerif-OFL.txt` |
| 学校注册表条目 | `assets/schools.json`（350 条） | 只取 3 条公开校名用于搜索卡 |
| 课程/教师/教室/日期 | 虚构 | 见 `05-privacy-and-limitations.md` |
| App 界面 | 按 `lib/` 源码复刻的合成 UI（Remotion React 组件） | 非截图，原因见 `05` |
| 图标 | `src/ui/Icon.tsx` 手绘线性图标 | 近似 Pixelarticons 风格，非原字体 |

## 5. 复现

```powershell
cd D:\hsu_flutter\promo\remotion
npm install
node scripts\check-mix.mjs                  # 混音/削波实测（读 public/audio 下固定文件）
$chrome = "C:\Users\<user>\AppData\Local\Google\Chrome\Application\chrome.exe"
npx remotion render src/index.ts HsuPromoVertical out\hsu-promo-vertical.mp4 --browser-executable="$chrome"
npx remotion render src/index.ts HsuPromoVertical out\hsu-promo-vertical-nobgm.mp4 --props=props-nobgm.json --browser-executable="$chrome"
npx remotion render src/index.ts HsuPromoWide out\hsu-promo-wide.mp4 --browser-executable="$chrome"
node scripts\keyframes.mjs
npx remotion still src/index.ts ContactSheet out\contact-sheet.png --browser-executable="$chrome"
```

> 若要替换 BGM：先核对 SHA-256，再覆盖 `public/audio/bgm/bgm-final.wav`，
> 重跑 `check-mix.mjs` 确认峰值与削波，然后重渲三件套。

### 2.7 四个选项与为什么选 A（Lead 决策）

母带 v2 落地时遇到一个硬冲突，实测前沿（同一链路，只改增益/压缩阈值）：

| 交付点 I | 37.5s crest | limiter max | LRA |
|---|---|---|---|
| **−16.02（采纳）** | 15.34 | 4.21 dB | 1.70 |
| −17.78 | 17.00 | 2.43 dB | 1.80 |
| −18.12 | 17.75 | 2.00 dB | 1.00 |
| −20.56 | 19.35 | 0.86 dB | 1.00 |

四个候选路径：

- **A 保响度（采纳）**：I=−16.02，接受 crest≈15.3、limiter≈4.2、LRA≈1.7。
- **B 保冲击**：BGM 版放到 ≈−18，crest≈17.8、limiter≈2.0，但整片小声 2 dB。
- **C 段落自动化**：只对 32.5–37.5s 额外压 2.4 dB，可同时满足 I=−16 与 crest 18——
  会在冲击前制造可闻凹陷，否决。
- **D 抬 TP 到 0 dBFS**：crest 可到 ≈18，但违反 TP≤−1.5，且 AAC 过冲必削波，否决。

**选 A 的理由**：平台侧归一化会用自己的压限器替我们做得更粗，交付到目标响度（−16）比
交一支 −18 的片子更可控。

### 2.8 接受了什么代价

I=−16 的交付点意味着片尾 impact 承受 **4.21 dB** 限幅，其相对主体的 crest 从
**21.06 dB 掉到 15.31 dB（−5.75 dB）**（Lead 独立测量；本文同口径 21.30 → 15.34）。
这是"响度正确"换"多留 2.7 dB crest"的主动取舍，不是遗漏。
缓解措施：限制器改为在整个 lookahead 内线性斜降（去掉了瞬跳 attack 造成的硬折角），
并把 37.5s 的 impact 从旧版"跌出最响前 5"拉回"与第 1 名并列前 4（差 0.20 dB）"。
> **SFX v2（实录替换）后的电平复核**：换源后重新跑了三档平衡——SFX 总线峰值仍为 **−5.87 dBFS**
> （impact 依旧主导），BGM 0.50 档峰值差 **4.66 dB**、混音峰值 −4.16 dBFS、0 削波，
> 因此 **BGM 音量沿用 0.50、SFX_GAIN 沿用 1.45，未做任何电平改动**。