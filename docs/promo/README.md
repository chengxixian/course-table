# 课程表 · 宣传片（video-shotcraft · 自主自由创作）

一句话：**40.0 秒 / 1080×1920 / 60fps** 的竖版产品片，另出 1920×1080 横版与竖/横两张封面；
用 App 自己的字体、色板与栅格，讲「一学期的课，排成一张表」，卖点是
**0 广告 · 流畅 · 简洁 · 美观 · 方便**。

> **已终混 + 母带 v2**：三件套均为 60fps + v2 原创 BGM（`SHA-256 6F7D680D…FDB5B0`，混音 0.50）。
> BGM/SFX 峰值差 4.66 dB（母带前），母带后 −16.03 LUFS-I / −2.33 dBTP（无 BGM 版 −18.13）；
> 0 削波。详见 `04-audio-and-assets.md` 与 `06-qa-report.md` 表 A/表 B。

## 交付物

| 文件 | 说明 |
|---|---|
| `promo/hsu-promo-vertical.mp4` | 竖版母版 1080×1920 · 60fps · 40.064s · v2 BGM + 母带 v2（−16.02 LUFS / −2.27 dBTP，7.82 MB） |
| `promo/hsu-promo-vertical-nobgm.mp4` | 同时间线 60fps · 仅 SFX · 母带 v2（−18.14 LUFS / −2.15 dBTP，7.19 MB） |
| `promo/hsu-promo-wide.mp4` | 横版 1920×1080 · 60fps · 40.064s · v2 BGM + 母带 v2（−16.02 LUFS / −2.27 dBTP，5.89 MB） |
| `promo/preview/hsu-promo-vertical-60fps-preview.mp4` | 动效增强阶段的 60fps 预览（历史留档） |
| `promo/cover-vertical.png` | **竖版封面** 1080×1920 |
| `promo/cover-wide.png` | **横版封面** 1920×1080 |
| `promo/contact-sheet.png` | 12 张关键帧 contact sheet（60fps 帧号） |
| `promo/keyframes/k01–k12.png` | 12 张 1080×1920 关键帧原图 |
| `promo/remotion/` | Remotion 工程（可逐帧复现；`scripts/check-mix.mjs` 可复算混音） |
| `docs/promo/01-design-spec.md` | 产品简报 / 执行决策 / 视觉与动效 tokens / 分镜 |
| `docs/promo/02-storyboard.md` | 分镜表、呼吸位、转场、动效清单 |
| `docs/promo/03-captions.md` | 逐帧字幕与文案，及事实边界 |
| `docs/promo/04-audio-and-assets.md` | 声音设计与素材来源、复现命令 |
| `docs/promo/05-privacy-and-limitations.md` | 数据合规自查与已知限制 |
| `docs/promo/06-qa-report.md` | 自检报告（逐项 + 帧号证据） |

## 封面

| 文件 | 构图 |
|---|---|
| `cover-vertical.png` | 纸白底 + 发丝周栅格；字标「课程表」280px；标语；卖点行「0 广告 · 流畅 · 简洁 · 美观 · 方便」；4×4 周视图小组件大图；页脚「开源 · GPL-3.0 · Android」 |
| `cover-wide.png` | 左：同一套字标与卖点；右：4×4 周视图小组件 |

封面与成片共用同一套 tokens（FandolFang / Liberation Serif、M3 surface 角色、周栅格），
不含任何姓名/学号/真实课表。

## 卖点怎么落片

| 卖点 | 落点 |
|---|---|
| **0 广告** | S1 卖点行首位（primary 加粗）+ 封面卖点行 + 尾卡 `GPL-3.0` |
| 流畅 | 60fps 交付；全片曲线的时值来自产品自身（180/240/320ms、200ms snap） |
| 简洁 | 每镜只有一条动作、一句话；无装饰光效 |
| 美观 | 纸白 + 发丝栅格 + 课程色块，全部取自产品色板 |
| 方便 | S3 课程详情、S4 八种导入 + 写入日历、S5 拖拽、S6 小组件 |

## 复现

```powershell
cd D:\hsu_flutter\promo\remotion
npm install
node scripts\make-audio.mjs                 # 合成 BGM + 9 个 SFX（确定性）
$chrome = "C:\Users\<user>\AppData\Local\Google\Chrome\Application\chrome.exe"
npx remotion render src/index.ts HsuPromoVertical out\hsu-promo-vertical.mp4 --browser-executable="$chrome"
npx remotion render src/index.ts HsuPromoVertical out\hsu-promo-vertical-nobgm.mp4 --props=props-nobgm.json --browser-executable="$chrome"
npx remotion render src/index.ts HsuPromoWide out\hsu-promo-wide.mp4 --browser-executable="$chrome"
npx remotion still src/index.ts HsuCoverVertical out\cover-vertical.png --browser-executable="$chrome"
npx remotion still src/index.ts HsuCoverWide out\cover-wide.png --browser-executable="$chrome"
node scripts\keyframes.mjs
npx remotion still src/index.ts ContactSheet out\contact-sheet.png --browser-executable="$chrome"
```

## 时间线（60fps 交付帧；镜头边界按 30fps authored frame 记录，×2 即交付帧）

| 镜头 | authored | 交付帧 | 时长 | 内容 |
|---|---|---|---|---|
| S1 | 0–150 | 0–300 | 5.0s | 字标遮罩压印开场 |
| S2 | 150–390 | 300–780 | 8.0s | 周课表落版 + 扫描线 + 视差 |
| S3 | 390–540 | 780–1080 | 5.0s | 弹层 spring 锚定 |
| S4 | 540–750 | 1080–1500 | 7.0s | 导入卡 flock + 350 计数 |
| S5 | 750–930 | 1500–1860 | 6.0s | 拖拽 ghost trail + 落点 pulse |
| S6 | 930–1080 | 1860–2160 | 5.0s | 小组件 cascade |
| S7 | 1080–1200 | 2160–2400 | 4.0s | 色彩 morph + 字标 hold 1.2s |

## 一句话看关键取舍

- **没有真机截图**：本机无 Flutter/adb/模拟器，App 画面是照 `lib/` 源码逐值复刻的
  合成 UI（同一套字体文件、色板、间距、真实字符串）。这是与 Q1「必须用真实截图」
  的有记录偏离，详见 `05-privacy-and-limitations.md`。
- **声音自制**：无 Freesound key，改为确定性合成环境层 + 拟音；task-4 会替换成原创 BGM。
- **数据全虚构**：课程/教师/教室/日期为虚构示例；不含姓名、学号；唯一真实实体是
  App 公开注册表里的公立校名。
