# REAPER 离线流水线（本地生产路径）

上游 `music-produce` 默认走 Replicate 云端生成。这支片子走的是**纯本地**路线：旋律和鼓手写成 MIDI，REAPER 用自带乐器与自制采样演奏，headless 渲染成 48 kHz / 24-bit 立体声 WAV，然后逐项量测。

产物：`promo/audio/bgm-v2.wav` —— 40.000 s、120 BPM、4/4、15 轨工程、13 个分轨 MIDI。

## 目录

| 文件 | 作用 |
|---|---|
| `scripts/compose-v2.mjs` | **作曲数据源**：20 小节和声、4 小节 hook、counter、bass、鼓组；同时生成 `midi/*.mid`、`build-data.lua`、`cues-v2.json` |
| `scripts/make-samples.mjs` | 合成鼓组一击采样（kick / snare / clap / hat / openhat / tom / crash / clock），无第三方采样 |
| `scripts/build-data.lua` | 由 compose 生成的数据表（每轨音符、音量、声像、音色） |
| `scripts/build-v2.lua` | ReaScript：建 15 轨、塞 MIDI item、挂 ReaSynth / RSaumplOmatic5000、设 render 参数、调 action 42230 |
| `scripts/render-v2.ps1` | 一条命令渲染：装 `__startup.lua` → 启动 REAPER → 等 wav 稳定 → 关实例 → 还原启动脚本 → 打印 SHA-256 |
| `scripts/bgm-v2.rpp` | 渲染后的完整工程（15 轨，可直接在 REAPER 里打开继续改） |
| `scripts/analyze-v2.mjs` | 总轨 + 逐镜头的 LUFS / peak / side−mid / crest / 旋律存在性，写 `analysis-v2.json` |
| `scripts/finalize-v2.mjs` | 把实测值回写进 `cues-v2.json` |
| `scripts/analyze-wav.mjs` | 无依赖 WAV 检查器：格式、时长、peak / true peak / RMS / LUFS-I / DC / 削波数 / L-R 相关 |
| `scripts/spectral-report.mjs` | 频段能量分布，用来确认没有某个频段失控 |
| `scripts/visualize-bgm.mjs` | 零依赖画波形 + 对数频谱图（PNG），无耳朵时的结构检查 |
| `scripts/analysis-v2.json` | 成品实测数据（交付存档） |
| `SKILL-addendum.original.md` | 本项目给技能加的约束原文（旋律优先、鼓更强、40 s / 120 BPM、交付四件套） |
| `legacy/make-bgm.mjs` | **第一版方案**：Node 纯合成 pad 床，被否掉。保留作反面参照 |

## 一条命令渲染

```powershell
# 先关闭 REAPER
powershell -NoProfile -ExecutionPolicy Bypass -File promo\reaper\render-v2.ps1
```

它做的事：

1. 备份 `%APPDATA%\REAPER\Scripts\__startup.lua`（若有），把 `build-v2.lua` 装上去；
2. `reaper.exe -new -nosplash` 启动一个**离线**实例（不需要声卡）；
3. ReaScript 建 15 轨、写 MIDI、挂乐器、设 render 参数，调 **action 42230**（Render project, using most recent render settings, auto-close）；
4. 轮询输出 wav 直到大小稳定（连续两次相同且 > 1 MB）；
5. 无论成功失败：关掉**它启动的那个**实例、还原 `__startup.lua`；
6. 打印路径、SHA-256、字节数。

这个"备份—安装—还原"的写法是关键：直接往 `__startup.lua` 里写脚本来驱动 REAPER 很方便，但如果不还原，用户下次手动开 REAPER 会被脚本劫持。

## 完整复现

```bash
node promo/reaper/compose-v2.mjs          # MIDI + build-data.lua + cues-v2.json
node promo/reaper/make-samples.mjs        # 自制鼓采样（一次性）
powershell -NoProfile -ExecutionPolicy Bypass -File promo/reaper/render-v2.ps1
node promo/audio/analyze-wav.mjs          promo/audio/bgm-v2.wav      # 总轨电平
node promo/reaper/analyze-v2.mjs          promo/audio/bgm-v2.wav      # 逐镜头 + 旋律存在性
node promo/reaper/finalize-v2.mjs                                      # 实测值回写 cues
node promo/reaper/visualize-bgm.mjs promo/audio/bgm-v2.wav out.png     # 波形 + 频谱图
```

## 编曲要点（决定"好不好听"的部分）

- **4 小节 hook**：`A4 A4 D5 | C#5 B4 A4 / F#4 A4 B4 | D5 / D5 E5 F#5 | E5 D5 B4 / C#5 B4 A4 | F#4 A4`，D 大调，音域 F#4–F#5，61% 的音程 ≤ 2 半音，方向改变 6 次，轮廓是"起—升—顶—落"。
- **回归三次**：0–8 s 呈示、18–26 s 全编制加倍、36–38 s 移高 2 个半音到 E 大调收束（E 与片尾 `chime.wav` 的 660 Hz 同音）。
- **和声**：`D | Bm7 | G | A7 | D | Bm7 | G | Em7 | A7 | D | Bm7 | G | A7 | Bm7 | G | D | Bm7 | G | B7 | E`，最后转 E 大调。
- **对位**：counter 走 hook 下方三度/六度且反向进行；bass 写"根-八度-五度-根"的切分；pad 每小节 4 个和弦音慢起。
- **鼓**：kick 52 / snare 88 / hat 161 / clap 28 / tom 16 / crash 7 / openhat 4 个音符；5.0 s 进鼓，段落边界 fill，26.667 s 的 snap 与 37.533 s 的 impact 由音乐和拟音共同落点。

## 立体声宽度：一次真实的返工

第一次渲染出来**整条基本是单声道**：

| | 初版 | 修复后 |
|---|---|---|
| mid RMS | −19.15 dB | −20.07 dB |
| side RMS | −40.84 dB | −32.45 dB |
| side − mid | −21.7 dB（≈单声道） | **−12.4 dB** |
| L/R 相关 | 0.987 | **0.894** |

原因不是声像没写进工程，而是**中置的 kick / bass / 主旋律能量远大于被推宽的 pad 和 hat**，solo 一下 pad 的 mid 只有 −42 dB，对整轨 side 的贡献可以忽略。

修复手法（真立体声，不是相位造假）：

1. **pad 拆成两轨**，hard pan ±1.0，右轨整体延后 20 ms（Haas），两轨再各 ±1.2 cents detune；
2. counter 硬左 −0.75、hat +0.75、openhat −0.75、tom −0.7、crash +0.7、clap +0.65、lead double −0.65；
3. kick / bass / 主旋律 / snare **保持中置**（低频和主体旋律必须单声道兼容）。

## 两个只有量了才会发现的坑

1. **ReaSynth 的 "Global detune" 量程是 ±2400 cents**，随手填会被整体拉低约 48 cents（接近半个半音）。本项目是靠 Goertzel 逐个音高比对才发现的。
2. **旋律"写对了"不等于"渲染对了"**。验收要做的是：对每个书写音高，在 onset+20 ms 起取 180 ms 窗，比较该音高与上下各 1 个半音的能量，书写音高占优（≥1.5×）才记为 present。本项目五次呈示分别是 20/21、9/10、21/21、10/10、6/6。

## 环境假设

- REAPER 装在 `C:\Program Files\REAPER (x64)\reaper.exe`（7.82，本机为 evaluation license）。换机器要改 `render-v2.ps1` 顶部的 `$Reaper`。
- `render-v2.ps1` 里 `$Root` 写死为 `D:\hsu_flutter`，输出到 `promo\audio\bgm-v2.wav`；换项目要一起改。
- 完整跑一次约 1–3 分钟（离线渲染，不用声卡）。

## 未验证项

- **没有人耳试听**。本机无音频输出，所有结论来自数值、频谱与音高存在性分析。
- 24-bit WAV 是 REAPER 默认；若下游链路只吃 16-bit 需转码（Remotion / Chromium 可直接解码 24-bit）。
- 混音与母带不在这里做，见 `tools/video-production/recipe/`。
