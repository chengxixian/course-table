# 课程表 · 40s 宣传片 BGM v2（旋律主导 + 更强鼓组，REAPER 版）

> 交付人：`bgm-composer`。本文件描述 **v2**，v1 `promo/audio/bgm.wav` **未被覆盖**。
> 未改动视频源码 / App / 版本号，未发布。
>
> **验收状态：未经人耳试听。** 本机没有音频输出；以下为文件级数值 + 频谱 + 音高存在性校验。
> 立体声宽度已按 Lead 的独立复测意见重做（见 §4），请 Lead 复测。

## 1. 交付物与冻结校验

| 文件 | 说明 |
|---|---|
| `promo/audio/bgm-v2.wav` | **主交付**：48 kHz / **24-bit** / 立体声 / **40.000000 s**（1,920,000 帧） |
| `promo/audio/cues-v2.json` | 120 BPM 拍网格、7 镜头、重音/切点、旋律动机分析、实测电平 |
| `promo/reaper/bgm-v2.rpp` | REAPER 7.82 工程（15 轨，MIDI item + ReaSynth/RS5K + 混响） |
| `promo/reaper/midi/*.mid` | 13 个分轨 MIDI（LEAD / LEAD DBL / COUNTER / PAD / BASS / 鼓组） |
| `promo/reaper/build-v2.lua` | 生成工程 + 离线渲染的 ReaScript |
| `promo/reaper/render-v2.ps1` | **一条命令重渲染**（见 §7） |
| `promo/reaper/compose-v2.mjs` | 作曲/编曲数据源（同时生成 MIDI、Lua 数据、cues） |
| `docs/promo/08-bgm-v2.md` | 本文件 |

```
bgm-v2.wav  SHA-256 6F7D680D2B682F092BBD72744CDF5137D481B1C922036AA9135C131133DFB5B0
            bytes   11,520,690
cues-v2.json SHA-256 83D38633E2DDFBAD5C3D5F817F2B2AA97E6798F92BD1F3BDE094765949A3703D
bgm.wav(v1) SHA-256 C854C62494F57BF27BA5AC5EBC41E30373439E4F58B97BB844340203E7A66CC1  ← 未改动
```

`bgm-v2.wav` 最后一次写入：**2026-11-02 17:23:12**。若重跑脚本导致哈希变化，必须重新告知 Lead / `promo-video`。

## 2. 来源与许可

- **原创**：旋律、counter-melody、bass、鼓组全部由 `compose-v2.mjs` 以 MIDI 写成；
  音色为 REAPER 自带 **ReaSynth**（合成器）与 **ReaSamplOmatic5000**（自制的 kick/snare/
  clap/hat/crash/tom 一击采样，由 `promo/reaper/make-samples.mjs` 合成）。
- **无第三方采样/旋律/循环**；没有网络下载；没有 Replicate/生成模型。
- **许可：CC0-1.0**（与工程内 `scripts/make-audio.mjs`、v1 BGM 同一政策：自制并随工程 CC0 奉献）。
- 工程内的 MIDI 是唯一旋律来源；`.rpp` 里是 MIDI item + 内置乐器，不是音频拼贴。

## 3. 作曲与编曲（旋律先行）

### 3.1 4 小节 hook（全曲的记忆点）

D 大调，120 BPM，16 拍（8 s）。首句 8 拍、答句 8 拍：

```
bar 1  A4  A4  D5 | C#5 B4 A4       （两下同音起拍 → 上行纯四度 → 级进下行）
bar 2  F#4 A4  B4 | D5              （低音区起，级进上行到 D5）
bar 3  D5  E5  F#5 | E5  D5  B4     （全曲最高点 F#5，然后下行）
bar 4  C#5 B4  A4 | F#4 A4          （属和弦上的终止式，回到 A）
```

- 音域 **F#4–F#5（12 个半音）**，音程以级进为主（61% ≤ 2 半音），方向改变 6 次，
  轮廓为“拱形”：起 → 升 → 顶 → 落。可哼唱，节奏有“两下同音 + 四度跳进”的识别点。
- **回归**：A1 在第 1–4 小节（0–8 s）完整呈示；A3 在第 10–13 小节（18–26 s）**全编制回归**
  （lead + unison double + counter + 强鼓）；A5 在第 19 小节（36–38 s）**上移 2 个半音到 E 大调**
  回归（B4 B4 E5 D#5 C#5 B4），接 E 大调解决。
- **B 段对比**：第 7–9 小节（12–18 s）是下行三和弦（B–G–D / E–B–G / A–C#–E），
  长音、低音区、级进；与 A 段的跳进/高音区形成明确 A/B 区分。
- **B'**：第 14–15 小节（27–30 s）是 B 段的缩短答句，接 S6 的 A4 变奏。

### 3.2 counter-melody 与 bass 对位

- **Counter**：hook 下方三度/六度，反向进行（lead 上行时它下行）；A2/A3/A4 各出现一次；
  B 段改为长音 A4→B4→C#5；B' 用 D5/F#4/B4 作答。轨 `COUNTER` 硬左（−0.75）。
- **Bass**：以根音/五度/八度写“根-八度-五度-根”的切分；A1/B 段用长音；
  S4/S6 用八分推进（`push` 型）；最后一小节落 E。低频轨保持中置。
- **Pad**：每小节 4 个和弦音，慢起音；**v2 修复为真正的立体声 pad**（见 §4）。
- **鼓**：kick 0 / 1.75 / 2.5 拍，snare+clap 反拍 1/3 拍，8 分/16 分 hats，
  段落边界有 fill；5.0 s（S2）、18.0 s（S4）、31.0 s（S6）、36.0 s（S7）有 crash；
  26.667 s snap、37.533 s impact 有重音。鼓组音符数：kick 52 / snare 88 / hat 137 / clap 28 /
  tom 16 / crash 7 / openhat 4 / clock 5。

### 3.3 20 小节和声

```
D | Bm7 | G | A7 | D | Bm7 | G | Em7 | A7 | D | Bm7 | G | A7 | Bm7 | G | D | Bm7 | G | B7 | E
```

第 19–20 小节转 **E 大调**：B7（37.533 s impact）→ E（38.067 s 解决）。
片尾 `chime.wav` 的 660 Hz（E5）正是 E 大调主音，BGM 的收束 E5 与它同音。

### 3.4 镜头 / 段落映射

| 镜头 | 帧 / 秒 | 音乐事件 |
|---|---|---|
| S1 OPEN | 0–150 / 0–5 | 时钟脉冲、pad、hook A1 第 1 句（0 s 起）；5.0 s crash + 鼓组进入 |
| S2 WEEK | 150–390 / 5–13 | hook A1 第 2 句完成；8.0 s A2 + counter；鼓组全开 |
| S3 DETAIL | 390–540 / 13–18 | B 段下行三和弦；鼓组 13.0 s 退出，14–17 s 保留安静 16 分 hat roll |
| S4 IMPORT | 540–750 / 18–25 | **hook A3 全编制回归 + doubled**；强 groove；25.0 s 鼓组抽空 |
| S5 DRAG | 750–930 / 25–31 | hook 终止句留在旋律上；26.667 s **snap**（B4 + crash/kick/chord）；B' |
| S6 WIDGETS | 930–1080 / 31–36 | hook A4（前 8 拍）+ 16 分 hat / fill |
| S7 OUTRO | 1080–1200 / 36–40 | **转 E，hook A5 移调回归**；37.533 s impact；38.067 s E 解决；39.0 s 后自然衰减 |

## 4. 立体声宽度（本次修复的核心）

Lead 复测 v2 初版：mid −19.15 dB / side −40.84 dB（side 仅低 21.7 dB，≈单声道）。
**原因**：不是 pan 没写进 RPP（已核对 `VOLPAN` 行），而是**中置的 kick/bass/lead 能量远大于
被打宽的 pad/counter/hats**；初版 pad 只有 0.11×2、±0.5 pan，solo 时 mid 仅 −42 dB，
对整轨 side 的贡献可以忽略。

**修复（真实立体声，非相位造假）**：

1. **Pad 拆成两轨**：`PAD L` / `PAD R`，各自 **hard pan −1.0 / +1.0**，
   同一 MIDI，`PAD R` 整体延后 **20 ms**（Haas），两轨再分别 ±1.2 cents detune；
   两轨电平各 0.19×2.1。这样 pad 的 mid 与 side 都真实存在，且 mid 仍远低于 lead。
2. **counter** 硬左 −0.75、**hats** 右 +0.75、**openhat** 左 −0.75、**tom** 左 −0.7、
   **crash** 右 +0.7、**clap** 右 +0.65、**lead double** 左 −0.65。
3. **kick / bass / lead 主旋律 / snare 保持中置**（低频与主唱式旋律必须 mono 兼容）。
4. 没有再使用整体 Haas / 相位反转 / 假立体声插件。

**实测结果（整轨）**：

| 指标 | v2 初版 | **v2 修复后** | 目标 |
|---|---|---|---|
| mid RMS | −19.15 dB | **−20.07 dB** | — |
| side RMS | −40.84 dB | **−32.45 dB** | — |
| **side − mid** | **−21.7 dB** | **−12.4 dB** | **−12…−15 dB** ✓ |
| **L/R correlation** | 0.987 | **0.894** | **0.80…0.90** ✓ |
| L / R RMS | −19.07 / −19.17 | −19.48 / −20.19 | 轻微偏左，可接受 |
| mono 兼容 | 好 | 好（lead/bass/kick 中置，pad 20 ms 仅作宽度） | 不反相 |

S4–S7 的 side−mid 在 **−11.1…−12.4 dB**，S1–S3 在 **−12.8…−13.6 dB**；
最宽处 −11.1 dB（未超过“−10 dB 会显虚”的界限）。

## 5. 电平与校验（实测，非估算）

| 指标 | 数值 |
|---|---|
| 时长 / 格式 | 40.000000 s / 48 kHz / 24-bit / stereo / 1,920,000 帧 |
| 采样峰值 | **−4.50 dBFS** |
| true peak（4× 插值） | **−4.50 dBFS** |
| headroom | **4.50 dB**（≥4 dB ✓） |
| RMS | **−19.82 dBFS** |
| Integrated loudness | **−17.9 LUFS-I**（BS.1770-4 K 加权 + 门限） |
| clipped samples | **0** |
| 直流偏移 | −80.2 dBFS |
| mid / side RMS | −20.07 / −32.45 dB（side−mid −12.4 dB） |
| L/R correlation | **0.894** |
| 尾音 | 38.0 s 起自然衰减，39.75 s 峰值 −21.1 dB / RMS −32.5 dB，**无 40.000 s 硬切** |

### 5.1 逐镜头（短时 LUFS / peak）

| 镜头 | 秒 | LUFS | peak dBFS | side−mid dB |
|---|---|---|---|---|
| S1 | 0–5 | −18.8 | −8.84 | −13.6 |
| S2 | 5–13 | −18.0 | −7.07 | −13.2 |
| S3 | 13–18 | −18.8 | −6.64 | −12.8 |
| S4 | 18–25 | **−16.9** | **−4.50** | −11.8 |
| S5 | 25–31 | −18.4 | −6.34 | −12.4 |
| S6 | 31–36 | −17.4 | −6.50 | −12.3 |
| S7 | 36–40 | −17.9 | −6.98 | −11.1 |

S4（hook 全编制回归）是整轨最响段；S1/S3 为低/呼吸段；S7 的峰值在 37.53 s 的 impact，
但整段含 1.5 s 自然衰减，短时 LUFS 因此低于 S4。这与 Lead 已批准的“结构/鼓密度/电平”一致。

### 5.2 旋律存在性校验（无法试听时的替代验证）

方法：对 hook 每次出现的每个书写音高，在 onset +20 ms 起取 180 ms 窗，用 Goertzel 比较
**该音高**与**上下各 1 个半音**的能量；若书写音高占优（≥1.5×）记为 present。

| 呈示 | 位置 | present |
|---|---|---|
| A1 | 0–8 s | **20 / 21** |
| A2 | 8–12 s | **9 / 10** |
| A3 | 18–26 s | **21 / 21** |
| A4 | 31–35 s | **10 / 10** |
| A5（+2 半音） | 36–38 s | **6 / 6** |

配合 Lead 的独立 2 拍粒度音高指纹（同一动机在拍索引 0/18/31 出现）与音域 A2–E5，
可以确认：**hook 在开篇、S4、S7 都实际存在且音准正确**（v2 初版曾因 ReaSynth 的
“Global detune”是 ±2400 cents 的音高偏移而被拉低约 48 cents，已修为 0.5 中位）。

## 6. 与 SFX 的关系

- 5.0 s 起鼓组进入；6.0–7.6 s 的 8 次 stamp 期间鼓组密度不叠加（stamp 由 SFX 承担）。
- 19.0–20.4 s 打字期间 lead 旋律不安排在 2–4 kHz 的密集点；counter 在 18 s 后进入。
- 26.667 s snap：BGM 给 B4 + crash/kick/chord stab；中频木 click 留给 `snap.wav`。
- 37.533 s impact：BGM 给 B7 上的 hook 音 B4 + crash/kick/tom；sub 留给 `impact.wav`。
- 38.067 s 解决：E 大调 + E5，与 `chime.wav` 的 660 Hz 同音。
- 14–17 s 保留安静的 16 分 hat roll（Lead 的可选建议），pad 不再整体掉 2 dB。

## 7. 渲染方式（精确命令）

**一条命令重渲染**（先关闭 REAPER；脚本会备份/还原 `__startup.lua`，只停自己启动的实例）：

```powershell
powershell -ExecutionPolicy Bypass -File D:\hsu_flutter\promo\reaper\render-v2.ps1
```

内部流程：

1. 把 `promo/reaper/build-v2.lua` 安装为 REAPER 的 `%APPDATA%\REAPER\Scripts\__startup.lua`；
2. `reaper.exe -new -nosplash` 启动 REAPER 7.82（离屏/离线渲染，不需要声卡）；
3. ReaScript 建 15 轨、写 MIDI item、加 ReaSynth/RS5K/混响、设 render 参数；
4. 调 action **42230**（Render project, using most recent render settings, auto-close）渲染
   `promo/audio/bgm-v2.wav`（48 kHz / stereo / WAV）；
5. 等待文件稳定、关闭该 REAPER 实例、还原 `__startup.lua`。

本次实际渲染由同一脚本完成，产物 SHA-256 见 §1。
REAPER 为 **7.82 evaluation license**（本机安装状态）；这是内部交付，未发布。

## 8. 给 `promo-video` 的混音参数

- **用 v2 替换 v1**：`bgm-v2.wav`，offset 0，铺满 1200 帧。
- **volume ≈ 0.50**（范围 0.45–0.55）。0.50 时有效 **−23.9 LUFS / 峰值 −10.5 dBFS**，
  与 `impact.wav`（−10.2 dBFS）齐平；不要沿用 v1 的 0.45/0.30，也不要把 v1 与 v2 叠加。
- 若用 Remotion：把 `public/audio/bgm/bgm.wav` 指向本文件（或新增 `audio/bgm-v2.wav`），
  不要改 `src/audio.tsx` 的 SFX 表（BGM 是独立的 `<Audio>`）。
- 成片容器 40.064 s、本轨 40.000 s；Remotion 1200f 内播放，尾部 64 ms 为静音。
- 混完后请把 `cues-v2.json` 的实际 `volume` 与成片峰值记录到 QA。

## 9. 未验证项 / 取舍

1. **没有试听**：无音频输出。宽度、电平、音高存在性均为数值验证；音色主观判断仍需人耳。
2. **24-bit WAV**：REAPER 默认 render 格式；Remotion/Chromium 可解码。若交付链路只吃 16-bit，
   可在 REAPER Render 里改 16-bit，不影响内容。
3. **REAPER 7.82 evaluation license**：工程与脚本可复现；正式发布前请确认 DAW 许可状态。
4. **未做最终 A/B 混音回测**：本机无 ffmpeg，无法对“BGM+SFX+AAC”成片做解码复核；
   成片峰值/响度由 `promo-video` 负责。
5. **S7 的短时 LUFS 低于 S4**：因 S7 含 1.5 s 自然衰减；峰值 impact 仍在 37.53 s。
   这与 Lead 已批准的“结构/鼓密度/电平”一致，本轮只修宽度。
6. v1 `bgm.wav` 保持原样，未覆盖；本轮未修改视频源码/App/版本，未发布。

## 10. 复现

```bash
cd D:/hsu_flutter
node promo/reaper/compose-v2.mjs              # MIDI + build-data.lua + cues-v2.json
node promo/reaper/make-samples.mjs            # 自制鼓采样（一次性）
powershell -ExecutionPolicy Bypass -File promo/reaper/render-v2.ps1
node promo/audio/analyze-wav.mjs promo/audio/bgm-v2.wav
node promo/reaper/analyze-v2.mjs promo/audio/bgm-v2.wav   # 写 analysis-v2.json
node promo/reaper/finalize-v2.mjs             # 把实测值写回 cues-v2.json
```
