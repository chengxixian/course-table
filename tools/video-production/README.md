# 视频制作工作流（video-shotcraft）

把产品做成一支有电影感的宣传片：先定规格和分镜，再用 Remotion 逐镜头实现，最后混音、母带、出片、验收。

本目录是 [video-shotcraft](https://github.com/Vincentwei1021/video-shotcraft)（Apache-2.0）的完整技能包（裁掉了纯媒体文件），加上本仓库这支宣传片真正跑通的渲染与母带脚本。

## 目录

| 路径 | 内容 | 什么时候看 |
|---|---|---|
| `skill/SKILL.md` | 技能主文档：任务范围判断、四种用法、核心理念、工作流、文件索引 | **先读这个** |
| `skill/references/pipeline.md` | 阶段 0–7 的完整流水线 | 从零开始做一支片 |
| `skill/references/guided-free-creation.md` | 共同创作模式下阶段 0–3 的确认清单 | 需要用户参与定方向时 |
| `skill/references/aesthetic-rules.md` | 审美硬规则（27 KB，最值得反复读的一份） | 每次自发检查、验收前 |
| `skill/references/shots/` | **125 张镜头卡**，按 camera / data / effects / interaction / opening / outro / rhythm / transition / typography / ui-entrance 十类分 | 选镜头 |
| `skill/references/sequences/promo-energy-arc.md` | 全片能量曲线骨架 | 排分镜顺序 |
| `skill/references/sound-design.md` · `sfx-sourcing.md` | 声音设计与拟音取材 | 做 SFX |
| `skill/references/music-beat-sync.md` | 卡点片：先分析 BGM 再分镜 | 已有 BGM |
| `skill/references/final-review.md` | 验收 checklist（要求独立 subagent 执行） | 出片前 |
| `skill/references/workbench.md` | 动效工作台：成片拆成多轨可视化调 | 需要给用户改片 |
| `skill/references/jianying-export.md` · `publish-upload-post.md` | 剪映工程导出 / 社交平台发布 | 用户明确要求时 |
| `skill/demos/` | **181 个可运行镜头示例**，与 shots 同分类 | 看镜头实际长什么样 |
| `skill/template/` | Remotion 起手工程（含 `themes/` 配色与 `aifl/` 参考实现） | 开新项目 |
| `skill/workbench/` | 镜头预览工作台（本地 5198 端口） | 调片 |
| `skill/shot-polish/` | 逐镜头打磨笔记 | 卡在某个镜头的细节上 |
| `skill/assets/lib/` | 可复制进项目的组件：PageCam / ClipCard / DigitRoll / FlashCut / Caption / FlatPanel / VerticalTicker | 写镜头时 |
| `recipe/` | **本项目的渲染与母带 harness** | 要出片了 |

## 工作流（本项目实际走的顺序）

### 0. 先写死规格，再去画

这一步不写代码，只写文档。本项目产出的是 `docs/promo/` 下的五份：

| 文档 | 定什么 |
|---|---|
| `01-design-spec.md` | 尺寸、帧率、时长、字体、色板、安全区、字号阶梯 |
| `02-storyboard.md` | 镜头表：每镜的起止帧、内容、文案、转场、运动意图 |
| `03-captions.md` | 所有屏上文字（逐字校对，避免"四件小组件"这种错） |
| `04-audio-and-assets.md` | BGM 规格、SFX 清单与音量、混音与母带目标 |
| `05-privacy-and-limitations.md` | 哪些是合成 UI、哪些数据是虚构、已知限制 |

规格一旦定下，后面每一轮返工都对着它改。

### 1. 分镜：用镜头卡而不是拍脑袋

从 `skill/references/shots/` 按能量曲线选卡，从 `skill/references/sequences/promo-energy-arc.md` 拿全片骨架。每张镜头卡有 frontmatter（能量、时长、适用场景）和"参考实现"指向 `demos/` 里可直接跑的源码——**选卡之后要读该卡全文 + 对应 demo 源码全文**，不要只看名字猜效果。

本项目最终 7 个镜头（作者帧，30fps 计）：

| 镜头 | 起 | 长 | 内容 | 主要动效 |
|---|---|---|---|---|
| open | 0 | 150 | 08:00 时钟与品牌字标 | 数字滚动、字标遮罩升起 |
| week | 150 | 240 | 周课表 | 视差推近、网格扫描 |
| detail | 390 | 150 | 课程弹层 | spring 锚定放大 |
| import | 540 | 210 | 350 所学校 / 7 种格式 | 卡片 flock 入列 |
| drag | 750 | 180 | 拖动改课 | ghost trail + 目标格 pulse |
| widgets | 930 | 150 | 四种小组件 | cascade 依次落位 |
| outro | 1080 | 120 | 动态取色 + 品牌落版 | 色板 morph |

### 2. 代码：把 App UI 重绘成合成 UI

本项目的做法是按 `lib/` 里的设计 token、字体、圆角、阴影 1:1 重绘界面组件（`promo/remotion/src/ui/`），而不是截模拟器。好处是可以在任意分辨率、任意帧精确控制每个像素；代价是**界面会和真实 App 有细微出入**，这条必须写进限制说明，不要假装是截图。

### 3. 60fps 交付、30fps 创作

一个很省事的技巧：镜头运动曲线全部按 30fps 的"拍"来写，交付时把当前帧除以 2 再喂给曲线。

```ts
export const FPS = 60;
export const FS = FPS / 30;                  // 2
export const DURATION = 1200 * FS;           // 2400 帧 = 40s
// 每个 Sequence: from={SHOTS.week.from * FS} durationInFrames={SHOTS.week.dur * FS}
// 镜头内部: const local = useCurrentFrame() / FS;
```

时间轴只有一个真源（`src/timeline.ts`），分镜表改一处，画面和音效同时跟着走。

### 4. 声音：拟音跟着画面走，BGM 是可以换的参数

- SFX 层是一张 cue 表：`{from, src, volume, note}`，`from` 用作者帧写，渲染时乘 `FS`。
- BGM 不做成硬编码文件，而是 Composition 的 prop（`bgmFile` / `bgmVolume`），这样一个工程能同时出"有 BGM / 无 BGM / 换一版 BGM"三种片，不用改代码。
- 混音平衡用**母带前**的峰值差判定（本项目要求 BGM 峰值比 SFX 峰值低 ≥4 dB），响度用**母带后**的 LUFS 判定，两件事分开测，不要混成一个指标。

### 5. 渲染 / 母带 / 验收

见 [`recipe/README.md`](recipe/README.md)。

## 踩过的坑（都会让你白跑一轮）

1. **Remotion 自带的 ffmpeg 是被裁过的**。没有 `alimiter`（`No such filter: 'alimiter'`）、没有默认的 `-f null` 视频编码器（量音频必须加 `-vn`）、没有 `f32le` muxer（要 PCM 就输出 `pcm_s16le` 的 wav）。母带只能用自写的 JS 限幅器，见 `recipe/scripts/master-audio.mjs`。
2. **props 文件不能带 BOM**。Remotion 用 `JSON.parse` 读，BOM 会让它直接报错，而且报错信息不指向 BOM。
3. **`staticFile()` 的路径是相对 `public/` 的 posix 路径**，不是文件系统路径。
4. **AAC 编码会有过冲**。本项目实测 ceiling 0.794（−2.0 dBFS）时，AAC 成片的 true peak 是 −1.42，越过了 −1.5 的线；把 ceiling 降到 0.75 后才稳在 −2.27。
5. **母带只加增益会毁掉片尾**。硬限制器会把所有削减堆在最响的那一击上；本项目因此把全片最响点从片尾 37.5s 挪到了中段 13.0s。正确做法是先做软拐点总线压缩把削减摊开，再用斜坡限制器收顶，并且**母带后要复测"最响的那半秒还在不在原位"**。
6. **`-c:v copy` 是否真的没重编码，要用哈希证明**，不能看命令就信：
   ```powershell
   ffmpeg -i raw.mp4   -an -c:v copy -f h264 -y a.264
   ffmpeg -i final.mp4 -an -c:v copy -f h264 -y b.264
   # 两个文件 SHA-256 相同，才算画面没被动过
   ```
   这条可以直接省掉重新生成封面、关键帧、contact sheet 的一整轮。
7. **PowerShell 脚本存成无 BOM 的 UTF-8 会被 5.1 读错**，中文注释会把下一行吃掉，报出来的错还指向别处。`.ps1` 要么纯 ASCII，要么带 BOM。

## 未包含 / 未使用

- 上游的示例音频（23.5 MB）、README 截图（5 MB）、网页画廊（2 MB）没有打包，需要时从上游仓库取。
- 上游 SKILL.md 里讲的**动效工作台、剪映工程导出、社交平台发布**三个收尾动作，本项目都没用（成片直接在本地交付），所以 `workbench/`、`jianying-export/`、`publish/` 只作为能力保留，没有验证记录。
- 上游要求"验收由独立 subagent 执行"。本项目**没有做独立终检**，QA 由制作方自测 + Lead 复核，这条是已知缺口，不要当成已满足。

## 许可

- 技能包：Apache-2.0，见 [`skill/LICENSE`](skill/LICENSE)。
- 渲染引擎 Remotion 有独立许可：个人与小团队免费，**公司使用可能需要付费**，商用前自行确认。
- 本项目的 `recipe/` 随本仓库（GPL-3.0）。
