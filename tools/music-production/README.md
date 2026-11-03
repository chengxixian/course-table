# 音乐制作工作流

给一支 40 秒宣传片写原创配乐：先在 MIDI 里把旋律和鼓写死，再用 REAPER 离线渲染成分轨总混，最后用**数值门槛**验收，而不是靠"听起来还行"。

本目录是 [music-production-skills](https://github.com/sb-dev/music-production-skills)（MIT）的四个子技能，加上本仓库这支片子真正跑通的 REAPER 流水线。

## 目录

| 路径 | 内容 |
|---|---|
| `skill/SKILL.md` · `skill/README.md` | 上游总说明 |
| `skill/music-compose/` | 作曲 / 编曲 / 动机 / 和声 / 律动 / 结构 / MIDI 草稿 / 方案比较 |
| `skill/music-produce/` | 把已批准的创作方向做成音频（上游默认走 Replicate 生成） |
| `skill/music-evaluate/` | 按生命周期评审：草稿比较、意图与编曲评价、技术 QC、失败归因、最小修复建议 |
| `skill/music-pack-author/` | 自定义音色 / 风格扩展包 |
| `reaper/` | **本项目实际用的本地生产路径**：MIDI → REAPER 离线渲染 → 分析与交付 |

上游那三个技能（compose / produce / evaluate）的质量很高，但 `music-produce` 的主路径是 Replicate 云端生成。本项目**没有用任何云端生成**：旋律、和声、bass、鼓组全部手写在 MIDI 里，音色是 REAPER 自带的 ReaSynth 与自制采样。这条本地路径写在 [`reaper/README.md`](reaper/README.md)。

## 工作流

### 1. 先定"音乐要证明什么"

不是"来点好听的"，而是逐条写下功能：开场要多克制、哪一秒鼓必须进来、拖动那一击落在哪一帧、结尾留多少衰减。本项目把它写成了镜头—音乐事件对照表（`docs/promo/08-bgm-v2.md` §3.4），每个镜头对应一个小节的音乐事件。

### 2. 旋律先行，4 小节动机

这是第一次交付被否掉后学到的：**铺底 pad 不叫配乐**。可用的结构是：

- 一个 4 小节、能被哼出来的动机（本项目：D 大调，音域 F#4–F#5，以级进为主，带"两下同音 + 四度跳进"的识别点，轮廓是拱形）
- 动机必须**回归**，而且回归要有升级：全编制加倍一次、移调再来一次
- 一条反向进行的 counter-melody、一条切分的 bass，pad 只做和声底
- 鼓要真的写：kick / snare / clap / hat / openhat / tom / crash 分轨写音符，段落边界给 fill

### 3. MIDI → REAPER → 一个可重跑的渲染命令

全部写成脚本：`compose-v2.mjs` 生成 13 个分轨 MIDI + 工程生成数据 + 拍点表，`build-v2.lua` 在 REAPER 里建 15 轨并离线渲染，`render-v2.ps1` 一条命令跑完。细节见 [`reaper/README.md`](reaper/README.md)。

### 4. 没有耳朵也要能验收

本机没有音频输出，所以验收全部做成可算的指标：

| 维度 | 怎么量 | 本项目达到 |
|---|---|---|
| 响度 | BS.1770-4 积分响度 | −17.9 LUFS |
| 峰值 | 采样峰值 + 4× 插值 true peak | −4.50 / −4.50 dBFS，0 削波 |
| 立体声宽度 | mid/side 能量差 + L/R 相关系数 | side−mid −12.4 dB，相关 0.894 |
| 旋律是否真的存在 | 对每个书写音高做 Goertzel，与上下半音比能量 | 动机五次呈示 20/21、9/10、21/21、10/10、6/6 |
| 动机是否回归 | 2 拍粒度的音高指纹，找重复子序列 | 同一动机在开场 / 全编制回归 / 移调收尾三次出现 |
| 段落是否各有内容 | 逐镜头短时 LUFS / 峰值 / 频谱图 | 见 `docs/promo/08-bgm-v2.md` §5.1 |

这套指标挡住过两次真问题：一次是**整条 BGM 其实是单声道**（side 只比 mid 低 21.7 dB，比上一版还窄），一次是 ReaSynth 的 detune 参数把旋律整体拉低了约 48 cents。

### 5. 交付给混音

交付物固定四件：`bgm.wav`（48 kHz / 24-bit / 时长精确到毫秒）、`cues.json`（拍点 + 镜头切点 + 重音帧）、工程文件（`.rpp` + 分轨 MIDI，必须可复现）、以及一份写清测量方法的说明文档。

混音平衡与母带不在这一层做，交给视频侧的 `tools/video-production/recipe/`。

## 几句实话

- **没有人耳试听过**这支 BGM。上表所有结论都来自数值、频谱和音高存在性分析。数值能挡住"单声道""跑调""没旋律""削波"，挡不住"难听"。
- 第一版是 Node 纯合成的 pad 床，被否掉（"这个 BGM 不好听"）。第二版改 REAPER + MIDI 后才成立。`reaper/legacy/make-bgm.mjs` 保留了那版代码，作为"哪些做法不该再走一遍"的参照。
- `music-produce` 的 Replicate 路径本项目完全没验证过，只用了 compose / evaluate 里的方法论。

## 许可

- 技能包：MIT，见 [`skill/LICENSE`](skill/LICENSE)。
- 本项目的 `reaper/` 随本仓库（GPL-3.0）。所有旋律、和声、鼓组均为手写 MIDI，鼓采样由 `make-samples.mjs` 合成，**没有使用任何第三方采样或循环**。
- REAPER 7.82 在本机是 evaluation license，正式商用发布前需自行处理 DAW 许可。
