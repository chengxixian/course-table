# qa/ — 验收用的小工具

这些脚本不是给 App 用的，是**做验收判断**用的：改完之后拿客观数字说话，而不是"看着还行"。都是在 Windows + Node 24 上跑过的独立脚本，零第三方依赖。

## 什么时候用哪个

| 脚本 | 回答什么问题 | 用法 |
|---|---|---|
| `png-diff.mjs` | 两次渲染的画面**到底变没变**？ | `node tools/qa/png-diff.mjs a.png b.png` |
| `side-mid.mjs` | 这段音频是立体声还是伪装成立体声的**单声道**？ | `node tools/qa/side-mid.mjs file.wav` |
| `compare-sfx.mjs` | 换了一套音效之后，**音色**变了多少？ | 见下 |
| `bgm-report.mjs` | BGM 的**结构和旋律**对不对（分段电平、动机是否回归）？ | `node tools/qa/bgm-report.mjs bgm.wav` |

## png-diff.mjs

跨两次编码比画面，**不能比文件哈希**——x264 不是逐比特可复现的，同一份源连渲两次也不一样。正确的判据是解码后比像素：

```
meanAbsDiff 0.2154   maxAbsDiff 25   pctChannelsOver2Levels 3.011%
```

平均绝对差 < 1 级（满量程 255）就认定画面未变；如果真改了文案或布局，平均值会到几十级。本项目就是靠它确认"重渲了一次但画面没动"，从而省掉重新生成关键帧和封面。

自带一个 PNG 解码器（zlib + 反滤波），因为这边的 ffmpeg 是被裁剪过的，没有 `psnr`/`ssim` 滤镜，也没有 rawvideo muxer。

## side-mid.mjs

```
mid -19.15 dB   side -40.84 dB   side_minus_mid -21.7 dB
```

`side − mid` 低于 −20 dB 基本就是单声道。健康的立体声宣传片大概在 −12 ~ −15 dB，L/R 相关 0.80–0.90。本项目有一版 BGM 就是栽在这里：峰值、时长、响度全部合格，唯独整条是单声道。

## compare-sfx.mjs

先各自 profile，再比：

```bash
node promo/scripts/sfx-analyze.mjs a/*.wav > old.json
node promo/scripts/sfx-analyze.mjs b/*.wav > new.json
node tools/qa/compare-sfx.mjs old.json new.json
```

输出逐条的时长变化和四个频段（low / body / presence / air）的差值。**峰值对齐不等于听感一致**——本项目换成实录那一版，峰值都对齐了，但临场感普遍高 10–20 dB，结果就是"听着变吵了、音色也怪"。

## bgm-report.mjs

```
## 2 s windows: rms / low / melody / high
## shot segments
## transients
## melodic pitch track (strongest bin per 2 beats, MIDI note)
## recurring 8-beat motifs (>=2 occurrences)
```

没有耳朵的时候，用三件事判断一段 BGM 成不成立：**每个段落都有内容**（不能有空段）、**动机真的回来了**（重复子序列）、**鼓真的进来了**（高频段能量跃升）。本项目当初就是靠"动机在 2 拍索引 0/18/31 三次出现"确认旋律成立的。

## 共同原则

1. **先定判据再动手**。写完再想"怎么算通过"，一定会挑一个刚好能过的标准。
2. **判据要能区分好和坏**。如果换个实现它还是"通过"，这个指标就没有意义（比如拿文件哈希当画面判据）。
3. **数字和感受冲突时，先怀疑数字。** 本项目有一次母带"全部达标"，但用户一句话就否了。
