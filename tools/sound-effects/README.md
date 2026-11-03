# 音效选材工作流（sound skill）

给视频找**真实录音的音效**，而不是全靠合成。核心思路是：你听不到这些素材，那就依赖听过的人留下的证据——下载量、评分人数、上传者描述、时长，再用 ffmpeg 量一遍能量分布。

上游：[vibe-motion/sound](https://github.com/vibe-motion/sound)（未声明开源许可），本地按 `PATCHES.md` 打了三处补丁才能在 Windows 上跑。

## 目录

| 路径 | 内容 |
|---|---|
| `skill/SKILL.md` | 技能入口：怎么把画面动作翻成英文关键词、怎么读证据、许可证规则 |
| `skill/scripts/sfx.py` | Freesound 搜索与下载（仅标准库） |
| `skill/scripts/clash_freesound.py` | 上游作者的 ClashX 网络辅助脚本（macOS；本机没用） |
| `skill/references/local-setup.md` | 上游作者的本地网络配置参考 |
| `skill/PATCHES.md` | **本机的三处改动**，装到别的机器前先读 |
| `skill/SKILL.upstream.md` | 上游 SKILL.md 原文（含被删掉的付费引流段） |

## 用法

```powershell
$py = Join-Path $env:USERPROFILE ".dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe"
$S  = ".skills\sound\scripts\sfx.py"

# 搜（默认 3 页按下载量重排；--license cc0 只留 CC0）
& $py $S freesound "paper slide" --license cc0 -n 8 --pages 2

# 下（把所有 fs:id 塞进同一条命令，并行更快）
& $py $S get promo\.work\sfx-candidates "fs:464302" "fs:71852"
```

`--urls` 会额外打印试听链接，需要人工确认时很有用。

## 判断规则（比脚本更重要）

1. **优先选最符合画面、且下载量高的那条**，并说明依据：`★4.4(380)` 比 `★4.9(6)` 可信。
2. **描述是最接近试听的信息**。"built-in mic" / "made with my mouth" 意味着低保真；写清录音机型号和声源（"cork from a wine bottle"）意味着你能预期听到什么。**描述里的声源和你要的画面不一致时，再热门也别用。**
3. **热门 ≠ 合适**：一条下载量很高的 "thud" 可能是 3 秒的电影感轰鸣。先看时长，再用 ffmpeg 量（尾部多长、能量落在哪）。
4. **许可证**：CC0 随便用；BY 要给作者署名；BY-NC 商用场景一律避开（`--license cc0|by` 可过滤）。

## 本项目走过的弯路（最有价值的一节）

40 秒宣传片里 9 个拟音，**先换掉 8 个，后被用户全部退回**："音效还是好奇怪，声音也过大了"。

换掉的和退回的都是同一批素材：

| 成片文件 | Freesound | 许可 | 裁剪后 | 选它的理由 |
|---|---|---|---|---|
| `swish.wav` | fs:71852 digital_whoosh_soft | CC0 | 0.50s | ↓7698 ★4.5(61)，描述就是"柔和的数字 whoosh" |
| `paper-slide.wav` | fs:464302 PaperSlide | CC0 | 0.34s | ↓4560 ★4.9(37)，paper sliding across table |
| `stamp.wav` | fs:555545 wood_block | CC0 | 0.14s | ↓372 ★4.9(7)，木块一击 |
| `pop.wav` | fs:733264 Bubble_Pop | CC0 | 0.15s | ★4.9(41)，0.15s 的 UI 点按 |
| `snap.wav` | fs:478197 Click_1 | CC0 | 0.06s | ↓6463 ★4.8(77)，证据最强的干净 click |
| `key.wav` | fs:701113 Computer Keyboard Foley | CC0 | 0.08s | 单键一击 |
| `riser.wav` | fs:511872 Riser Hit sfx 025 | CC0 | 1.55s | 取文件尾部让峰值落在 impact |
| `impact.wav` | fs:511883 Impact sfx 017 | CC0 | 0.78s | 0.78s 短冲击 |
| `chime.wav` | 保留合成 | CC0 | 1.60s | 见下 |

**每一条的下载量和评分都过关，问题不在"素材好不好"，而在"这套声音和这支片子的语义不匹配"。**
用 `promo/scripts/sfx-analyze.mjs` 把新旧两套逐条量一遍，差异一目了然：

| cue | 实测差异（新 vs 旧） | 听感上变成了什么 |
|---|---|---|
| stamp | 低频 **−29.2 dB**、临场 +21.7 dB、f0 B6→**F4** | 纯音高的"嗒"，没有体积感；连敲 8 下像木鱼 |
| riser | 低频 **+16.4 dB**、空气感 −19 dB | 低频轰鸣，糊住 BGM 低音 |
| pop | f0 **393→787 Hz**（高八度）、临场 +10.2 | 气泡声，还跳了一个八度 |
| impact | body +14.4、临场 +20.2、f0→417 Hz | 中频偏厚且带音高，像预告片撞击 |
| swish | 临场 −14、空气感 −20.5 | 闷的低频 whoosh，不清亮 |
| key | 低频 +13.7 | 带桌面共鸣，像机械键盘 |

教训（比工具本身重要）：

1. **宣传片拟音是"声音设计"，不是"找个真实录音"**。UI 演示片需要一套克制的、彼此协调的声音；每一条单独看都不错，拼在一起就会互相打架。
2. **下载量只能证明"听起来干净"，证明不了"适合这个画面"**。wood_block 的 ★4.9(7) 是真实的，但它是一段带音高的木头，放在"课块落版"上就是错。
3. **电平不能只看峰值对齐**。这批素材峰值被对齐到原样本，但临场感（1.2–6 kHz）普遍高出 10–20 dB，所以听起来"更响"。频段差比峰值差更能预测"吵不吵"。
4. **换素材后必须查"全片最响的半秒还在不在原位"**。实录版把最响点从片尾 37.5s 挪到了 6.0s 的课块连敲——这是"太吵"最硬的证据，也是我回退的直接依据。

**为什么 chime 一开始就没换**：`fs:452379 Small Bell #2`（↓2235 ★4.8(39)，CC0）基频在 A#3，而片尾 BGM 已转到 E 大调并停在 E5，A# 是降七级、会打架。原合成 chime 是按 660 Hz（E5）做的，与片尾和弦同音。**为了"换成实录"而制造音准冲突不划算**——这类"素材很好但和音乐不在一个调上"的问题，是选材里最容易被忽略的。

## 裁剪与定电平

`promo/scripts/retrim-sfx.mjs` 做四件事，保证换素材后的回归可控：

1. 自动找起始点（`riser` 这类取尾部，让峰值落在重音帧）；
2. 按目标时长裁剪，25 ms 收尾淡出、3 ms 起始淡入（防止切点爆音）；
3. 按**原合成样本的峰值/响度**对齐电平；
4. 统一输出 48 kHz / 16-bit / 立体声 WAV。

⚠️ 第 3 步只能对齐电平，**对齐不了音色**——这次就是栽在音色上。换完之后除了重测平衡，还要对比 `sfx-analyze.mjs` 的频段分布，并确认 `check-mix.mjs` 的 `loudestHalfSecondAtSec` 没有跑位。

## 已知限制

- 下载到的是 **MP3 预览**（约 128 kbps），不是上传者原始文件。做拟音够用，不适合当母带素材。
- 我**没有人耳试听**：以上选择基于下载量、评分、描述、时长和频谱统计。听起来好不好，最终仍要人来判断。
- 本机到 `freesound.org` 的 TLS 会被断连，靠 `curl.exe` 绕；换网络环境可能就不需要这个补丁了。
- 上游未声明开源许可，随本仓库打包只是本地使用便利，**对外分发前请先与作者确认**。
