# tools/ — 视频、音乐与音效制作工作流

这个目录把本项目用过的**三套创作工作流**连同它们真正跑通过的脚本一起打包进来，方便下次做别的 App 宣传片时直接复用，而不是重新摸索一遍。

三套工作流都在本仓库的 [`promo/`](../promo/) 里实际跑完过一支 40 秒、7 镜头的宣传片（竖屏 1080×1920 / 横屏 1920×1080，60fps，原创 BGM + 设计拟音 + 母带），所以这里的每一份脚本都有对应的真实产物和实测数据，不是示例代码。

```
tools/
├── README.md                     ← 本文件
├── _sync.ps1                     ← 从 .skills/ 与 promo/ 重新同步本目录
├── _link-check.ps1               ← 校验本目录所有 README 里的相对链接是否都指向真实文件
├── video-production/
│   ├── README.md                 ← 视频工作流（怎么从 0 到成片）
│   ├── skill/                    ← 上游 video-shotcraft 技能包（Apache-2.0）
│   │   ├── SKILL.md              ← 技能主文档，先读这个
│   │   ├── references/           ← 125 条镜头配方 + 2 条序列配方
│   │   ├── demos/                ← 181 个可运行镜头示例（10 个分类）
│   │   ├── template/             ← Remotion 起手模板
│   │   ├── workbench/            ← 镜头预览工作台
│   │   └── shot-polish/          ← 逐镜头打磨笔记
│   └── recipe/                   ← 本项目沉淀的渲染 + 母带 harness
│       ├── README.md
│       └── scripts/              ← 渲染包装、两级母带、码流校验
├── music-production/
│   ├── README.md                 ← 音乐工作流（MIDI → REAPER → 数值验收）
│   ├── skill/                    ← 上游 music-production-skills（MIT）
│   │   ├── music-compose/        ← 作曲/编曲/MIDI
│   │   ├── music-produce/        ← 生产与交付
│   │   ├── music-evaluate/       ← 评审与 QC 规则
│   │   └── music-pack-author/    ← 自定义音色包
│   └── reaper/                   ← 本项目沉淀的 REAPER 离线流水线
│       ├── README.md
│       ├── SKILL-addendum.original.md
│       ├── scripts/              ← 作曲数据、工程生成、渲染驱动、分析
│       └── legacy/               ← 被否掉的 v1 方案（反面教材）
├── sound-effects/
│   ├── README.md                 ← 音效选材工作流 + 一次失败的回退复盘
│   └── skill/                    ← vibe-motion/sound（Freesound 搜索下载）
│       ├── SKILL.md              ← 已删掉上游的付费引流段
│       ├── SKILL.upstream.md     ← 上游原文，备查
│       ├── PATCHES.md            ← 本机三处改动（TLS 回退 curl、UTF-8、删引流）
│       └── scripts/sfx.py
├── android-emulator/             ← 用模拟器量真实帧时间（装 AVD、喂数据、跑测量）
│   ├── README.md
│   ├── setup.ps1  run.ps1  seed.ps1  seed.mjs  measure.ps1
│   └── demo-schedule.json
└── qa/                           ← 验收判断工具：像素差 / 立体声宽度 / 音色对比 / BGM 结构
    ├── README.md
    ├── png-diff.mjs  side-mid.mjs  compare-sfx.mjs  bgm-report.mjs
```

## 一分钟上手

**做视频**：先读 [`video-production/skill/SKILL.md`](video-production/skill/SKILL.md)，再从 `skill/template/` 复制一份 Remotion 工程；镜头从 `skill/references/shots/` 里挑，需要看效果就跑 `skill/demos/` 里对应分类。渲染与母带用 [`video-production/recipe/`](video-production/recipe/)。

**做音乐**：先读 [`music-production/skill/music-compose/SKILL.md`](music-production/skill/music-compose/SKILL.md) 定结构，按 [`music-production/reaper/README.md`](music-production/reaper/README.md) 在 REAPER 里用 MIDI 写分轨并离线渲染，交付前用同一份 README 里的数值门槛自检（不需要耳朵也能挡住大部分事故）。



**量性能**：`tools/android-emulator/` 里是一套可复现的模拟器测量流程（ATD 镜像 + 直接写 SharedPreferences 喂课表 + `adb input` 驱动手势）。App 里的 `lib/ui/frame_stats.dart` 会在拖拽/切周/开弹层后打一行 build+raster 的分位值。

**做验收**：`tools/qa/` 里是判断用的脚本——比两次渲染的像素差、测是否真是立体声、比换音效前后的频段差、看 BGM 的动机是否回归。它们回答的是"到底变没变"，不是"看起来对不对"。

**找音效**：读 [`sound-effects/README.md`](sound-effects/README.md)。那份文档的重点不是脚本，而是**一次真实的失败**：8 条下载量和评分都过关的实录，装上去之后被用户一句"好奇怪、声音也过大了"全部退回。里面写清了为什么——素材质量没问题，是声音设计的语义不匹配。

## 三套工作流的共同原则

这是这支宣传片真正学到的、比脚本更重要的东西：

1. **先定规格再动手**：帧率、时长、分辨率、响度目标、镜头切点表，全部先写成文档（本项目是 `docs/promo/01`–`05`），之后每一轮返工都对着这张表改，不靠感觉。
2. **数值可验证的，不要靠"看起来对"**：画面靠逐帧截图与解码像素比对，音频靠 LUFS / true peak / side-mid / crest / 最响半秒的位置。没有音频输出的时候，这套数值门槛是唯一能挡住"越改越差"的东西。
3. **改动要能一条命令重跑**：视频是 `render-*.ps1`，音乐是 `render-v2.ps1`，拟音是 `retrim-sfx.mjs`。任何"手工在 GUI 里点出来"的步骤都不算完成。
4. **不要用代理指标代替结果**：本项目为此付出过两次学费——一次是"BGM↔SFX 峰值差 ≥4 dB"，把拟音逼到过大；一次是"限制器 ≤3 dB"，差点用片尾的冲击去换一个数字。指标错的时候，正确做法是改指标并写清理由，不是想办法让数字好看。
5. **不要静默降级**：配乐被否、母带把冲击压平、立体声其实是单声道、实录拟音让全片最响点从 37.5s 漂到 6.0s——这些问题都是靠"先量、再判断"发现的。宁可写"未人耳试听"，也不要写"已完成"。

## 来源与许可

| 包 | 上游 | 许可 | 备注 |
|---|---|---|---|
| `video-production/skill/` | [video-shotcraft](https://github.com/Vincentwei1021/video-shotcraft) | Apache-2.0（见 `skill/LICENSE`） | 上游媒体文件按下方"未包含"清单裁掉，文字与代码原样保留 |
| `music-production/skill/` | [music-production-skills](https://github.com/sb-dev/music-production-skills) | MIT（见 `skill/LICENSE`） | 上游 4 个子技能原样保留 |
| `sound-effects/skill/` | [vibe-motion/sound](https://github.com/vibe-motion/sound) | **上游未声明许可** | 本地打了 3 处补丁（见 `skill/PATCHES.md`）；对外分发前需与作者确认 |
| `video-production/recipe/` | 本项目原创 | 随本仓库（GPL-3.0） | 为本片写的渲染与母带脚本 |
| `music-production/reaper/` | 本项目原创 | 随本仓库（GPL-3.0） | 为本片写的 REAPER 流水线 |

上游包里的第三方依赖（Remotion、Node 工具链）有各自的许可，**Remotion 对公司使用是付费许可**，商用前请自行确认。

## 未包含的内容（有意裁掉）

为了不让仓库膨胀，同步时排除了纯二进制媒体，需要时从上游重新获取：

- `video-production/skill/assets/audio/`（23.5 MB 上游示例 BGM）
- `video-production/skill/assets/readme/`（5 MB 截图）
- `video-production/skill/gallery/`（2 MB 网页画廊媒体）
- `sound-effects/skill/assets/`（168 KB 微信二维码，属于被删掉的付费引流段）

作品文件（成片、封面、关键帧、BGM、REAPER 工程）**不在本目录**，它们在 [`promo/`](../promo/) 里，那份才是交付物。

## 重新同步

`tools/` 里的 `skill/` 与 `recipe/scripts/` 都是从别处复制来的。**要改它们，请改源头再同步**，否则会出现两份互不一致的副本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\_sync.ps1
```

- `skill/` ← `.skills/music-production/`、`.skills/sound/`、`promo/_skilldl/video-shotcraft-main/`
- `recipe/scripts/` ← `promo/scripts/`、`promo/reaper/`、`promo/audio/`

脚本是幂等的：每次先删目标 `skill/` 再复制。`_sync.ps1` 本身是纯 ASCII——Windows PowerShell 5.1 读无 BOM 的非 ASCII `.ps1` 会把注释吃掉半行，这个坑在本项目里踩过两次（第二次直接毁了一份 README 的编码）。

同步后可以顺手校验文档里的相对链接：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools\_link-check.ps1
```

`tools/` 不被 Flutter 构建引用（不在 `lib/`、`assets/`、`android/` 里），加进仓库不影响打包产物。

## 已知限制

- 本机没有音频输出，**这支片子的音乐、拟音和母带从头到尾没有人耳试听过**，所有结论都来自数值与频谱。人的听感仍然需要一次试听来确认——实录拟音那一轮就是因为这个才走错，用户一听就否了。
- 视频里的 App 界面是按 `lib/` 里的设计 token 与字体 1:1 重绘的合成 UI，不是模拟器截图；这条限制写在 `docs/promo/05-privacy-and-limitations.md`。
- REAPER 7.82 在本机是 evaluation license，正式商用发布前要处理 DAW 许可。
- 本目录的脚本是在 Windows + PowerShell 5.1 + Node 24 上验证的，没有做跨平台适配。
