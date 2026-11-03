# 课程表 · 宣传片设计 spec（自主自由创作）

- 创作模式：**自主自由创作**（video-shotcraft `references/pipeline.md` 阶段 0–3 由 Agent 自主定案并记录，不逐阶段等待确认）
- 影片：`课程表` 产品宣传片，30–45s，竖版 1080×1920 为主，另出 16:9 1920×1080
- 工程：`D:\hsu_flutter\promo\remotion`（Remotion 4.0.484 + React 19，30fps）
- 素材来源：**无真实设备截图**。本机没有 Flutter SDK / adb / 模拟器（详见 `05-privacy-and-limitations.md`），因此 App 画面是按 `lib/` 源码 1:1 复刻的「合成 App UI」，不是截图。片中所有校名、学生、课程、教师、教室为虚构。

---

## 阶段 0 · 产品简报

| 项 | 内容 |
|---|---|
| 产品 | 课程表（`hsu_schedule`，检查时为 v3.1.4+49；**片中不出现版本号**），Material 3 课程表与桌面小组件 |
| 平台 | Android（本片只讲 Android；产品另支持 Windows，片中不出现） |
| 许可 | GPL-3.0（开源、免费、无广告） |
| 目标用户 | 中国高校学生：想在一屏里看清本周课、懒于手动抄课表 |
| 核心卖点 | ① HSU 原生同步 ② 350 所学校可搜索 ③ 网页导入 + AI 兜底 ④ 七种文件/手动导入 ⑤ 系统日历写入 ⑥ 四种尺寸桌面小组件 ⑦ 长按拖动改课 ⑧ 跟随系统动态取色 |
| 用途 | 社交平台竖版传播（小红书/抖音/B 站竖版），另出 16:9 供嵌入 |
| 时长/画幅/语言 | 40.0s · 1080×1920@30fps（+ 1920×1080）· 简体中文文案 |
| 数据口径 | 课程/教师/教室/校名全部虚构；**不出现姓名、学号、真实课程**；不出现真实个人信息截图 |
| 音频 | 自建音效 + 自制极简环境底噪（见 `04-audio-and-assets.md`）。不启用 Mixkit BGM 备选，理由见 §6 |

### 需求 → 执行决策表

| 需求 | 执行决策 |
|---|---|
| 30–45s | 40.0s / 1200f，7 个镜头 |
| 竖版优先 | 母版 1080×1920；同一时间线用 `layout` prop 渲染 16:9 |
| 真实 App UI | 按 `lib/ui/week_screen.dart`、`components.dart`、`ui_theme.dart` 的像素参数复刻（88dp 日列 / 56dp 节次行 / 4dp 课间 / 12dp 圆角 / 3dp 左侧色条） |
| 不泄露个人数据 | 虚构课表 + 不渲染学号 + 隐私自查清单 |
| 不虚假宣传 | 只用可核验事实：350 所（`assets/schools.json` 实测 350 条）、七种导入来源（代码枚举）、AI 只作「兜底」表述、不宣称解析器万能 |
| 有 BGM | 不套用版权/BPM 不明曲目；自制环境层，规避强拍 BGM 的逐拍卡点义务（同为质量选择，见 §6） |

---

## 阶段 1 · 视觉方向

### 1.1 三个文字方向（只记录，取其一）

1. **纸本课表（选定）**——把 App 的印刷感推到画面层：纸白底、发丝分隔线、FangSong 标题 + Liberation Serif 数字、课程色块当油墨。动效像排版落版，不像 App 广告。
2. **像素工具**——用 App 自带的 Pixelarticons / FusionPixel 做像素化转场。取舍：会放大「工具感」，与产品偏学院气的气质冲突；且像素字与 FangSong 混用是两套嗓音。弃用。
3. **深色流光**——截图里的深色 + 动态色（青瓷）确有高级感。取舍：竖版信息密度下深色更糊、更难读；且深色把「纸」这一产品独有气质抹掉，退化为通用科技风。仅保留为 S6 动态色的一个瞬间。

### 1.2 选定方向的依据

产品自己的排版语言已经很强：`PageHeader` 有 22×2px primary 短横 + 9px/1.5 letter-spacing 的 kicker；`WeekHero` 是 5×44px 竖色条 + 24px 负字距标题；课块是 12px 圆角 + 3px 左色条 + 8.5/11/8 三级字号；栅格是 88/56/4 的硬栅格。全部来自 `lib/ui/*.dart` 的真实数值，影片只需把它们放大到海报尺度，不需要发明「宣传片皮肤」。

### 1.3 设计 tokens（全部取自产品，或由产品色阶克制扩展）

```ts
// lib/ui_theme.dart: seed 0xFF0B57D0 → M3 light 角色
surface #FBF9FF · surfaceContainerLowest #FFFFFF · surfaceContainerLow #F5F2FA
surfaceContainer #EFEDF4 · surfaceContainerHigh #E9E7EF
onSurface #1A1B20 · onSurfaceVariant #45464F · outlineVariant #C6C5D0
primary #0B57D0 · onPrimary #FFFFFF · primaryContainer #D8E2FF · onPrimaryContainer #001A41
secondaryContainer #D9E2F9 · error #BA1A1A
// lib/ui/components.dart: CoursePalette._light 8 色，原样使用
#006A60/#C9F5ED/#003731  #3D5F90/#D9E3F8/#0B2545  #6750A4/#EADCFF/#21005D  #8B5000/#FFDCC1/#2E1500
#3F6212/#D9E7B8/#1A2E00  #8E3B55/#FFD9E2/#3B0718  #455E91/#DDE6FF/#102347  #745B00/#FFE08A/#221B00
// pubspec.yaml 自带字体
中文标题/正文: FandolFang (FangSongCN) ; 拉丁与数字: Liberation Serif (TimesNewRoman)
// 圆角
12 课块 · 16 时间线项 · 22 WeekHero · 24 栅格卡 · 26 下一节课卡 · 28 弹层
```

**禁用**：霓虹色、玻璃拟态、渐变彩虹、游戏音色、无来由的辉光群发。

### 1.4 动效性格 tokens（产品代码里的真实曲线）

`lib/ui/motion.dart`：fast 180ms / medium 240ms / slow 320ms；enter `easeOutCubic`；exit `easeInCubic`；emphasized `cubic-bezier(0.05,0.7,0.1,1)`（Flutter `easeInOutCubicEmphasized`，也是 `components.dart` 锚定弹层的位移曲线）；`FadeSlideIn` 位移 12dp、stagger 45ms。
`week_screen.dart`：拖拽落槽 snap 200ms `easeOutCubic`；落点高亮 `#4285F4` 2px 描边 + `#334285F4` 填充。

影片级扩展（记录为取舍）：
- 镜头入场 24f `emphasized` + 40px 位移；比 App 内 240ms 慢，因为它是「镜头」不是「组件」。
- 落版（课块入格、小组件落位）10f `easeOutCubic`，允许 1.03 缩放过冲（物理落位）。
- 品牌字标落定后 hold 36f（≥1s，R1）；批量动效收尾 hold 15–20f。
- 全片整画面/相机层冲击：0 处（不配强拍 BGM，不做逐拍抖动）。

### 1.5 styleframe

以 `docs/promo/styleframes/` 下的 Remotion 静帧代替独立 HTML styleframe（同一套 tokens、同一套字体，少一层转译损耗）：
- `sf-a-open.png` 开场字标 + 发丝栅格
- `sf-b-week.png` 手机 + 周课表
- `sf-c-widgets.png` 四种小组件

---

## 阶段 2 · 功能 → 镜头映射

镜头卡来源说明：本片**没有逐卡复刻** `references/shots/` 里的具名配方卡。实际做法是读了卡片分类（opening / typography / interaction / data / outro 等目录）与 `sequences/promo-energy-arc.md` 的能量骨架，再按产品自身的曲线（`Motion.fast/medium/slow`、`easeInOutCubicEmphasized`、200ms snap）自建运动语法。因此下表的「运动语法」是自建描述，不是卡名还原；`06-qa-report.md` 的 S 项按此口径标记为不适用，而不是「已按卡还原」。

| 功能 | 镜头 | 运动语法 | 依据 |
|---|---|---|---|
| 品牌 / 定位 | S1 | 字标压印 + 发丝栅格自绘（typesetting 落版） | 开场只给一个主角，hold ≥1s |
| 周课表 / 节次栅格 | S2 | 课块逐格落版（stamp-in），栅格滑动展示周末 | 单主角完整动作弧 ≥3s |
| 课程详情 | S3 | 锚定弹层从课块原地放大（产品真实 400ms 弹层） | 直接复用产品交互曲线 |
| 350 校 / 网页 AI / 文件导入 | S4 | 输入框打字 + 结果行落位 + 来源 chips 逐个入列 | 信息密集镜头保持正视、可读 |
| 长按拖动 | S5 | 抬起（elevation+scale）→ 横移 → 落点高亮 → snap 归位 | 产品真实 200ms snap |
| 桌面小组件 | S6 | 四种尺寸的小组件按格位落版（4×3/2×2/4×2/4×4） | 落位到真实桌面格位（Q9） |
| 动态取色 + 品牌收尾 | S7 | 色板横扫 + 整屏色彩迁移 + 字标 | 全片唯一的整屏色变 |

---

## 阶段 3 · 分镜（帧级时间轴）

30fps，1200f = 40.0s。`SHOTS` 常量是唯一事实源（`src/timeline.ts`）。

| # | 镜头 | from | dur | 画面内容 | 关键动效 | 字幕 | 音频 |
|---|---|---|---|---|---|---|---|
| S1 | OPEN | 0 | 150 | 纸白底，发丝栅格自绘，巨型 `08:00` + 字标「课程表」 | 栅格线条 24f 绘制；字标 24f 升起落定；hold 36f | kicker `MATERIAL 3 · 课程表`；主 `08:00`；副「一学期的课，排成一张表。」 | paper-slide + soft thud |
| S2 | WEEK | 150 | 240 | 手机入画，周课表；8 个课块逐格落版；栅格横移露出周末 | 手机 24f 升起；课块 6f 间隔落版；横移 20f；hold 20f | kicker `周课表`；主「每天第几节，一眼对得上。」 | 8× stamp（音量递减）+ swish |
| S3 | DETAIL | 390 | 150 | 点「机械制图 A」→ 锚定弹层从课块放大 | 弹层 12f emphasized（产品 400ms）+ 12f settle | kicker `课程详情`；主「点开一节课，时间地点一次看清。」 | pop + 轻 tick |
| S4 | IMPORT | 540 | 210 | 网页导入页：搜索「云溪」→ 350 所结果 → 七种来源 chips 入列 → 日历写入 toast | 打字 30f；结果行 8f 落位；chips 45ms 递进；toast 10f | kicker `导入`；主「350 所学校，搜到就能导。」；副「HSU 原生同步 · 网页与 AI 兜底 · WakeUp/ICS/CSV/Excel/PDF/文本/手动」 | 键盘 6 击 + chips 轻响 + toast |
| S5 | DRAG | 750 | 180 | 课块抬起到另一格：高亮落点、松手归位 | 抬起 8f（elev 10, scale 1.03）→ 横移 36f → snap 8f | kicker `拖拽调整`；主「长按拖动，落槽即存。」 | lift whoosh + snap |
| S6 | WIDGETS | 930 | 150 | 桌面格位：4×4 主卡 + 4×3 / 4×2 / 2×2 三张规格卡落位 | 四张 10f 落位，间隔 8–9f；末 hold 20f | kicker `桌面小组件`；主「四种小组件，抬眼就是。」 | 4× paper drop（递减） |
| S7 | COLOR + OUTRO | 1080 | 120 | 全屏周课表被色板重新着色（湖蓝→青瓷→山茶粉），收拢为字标 | 色变 40f；字标 24f；hold 36f | kicker `动态色彩`；主「跟随系统的颜色。」；尾卡「课程表 · 跟随系统的颜色，也是你的颜色。 · Material 3 / Android / GPL-3.0」 | riser + impact + chime（收束句） |

**呼吸位**：S1 尾 36f、S2 尾 20f、S6 尾 20f、S7 尾 36f。字标 hold 合计 72f ≥ 1s。
**转场**：全部为硬切 + 元素层运动（无整画面 slam，R4 计数 0）。S7 的色板横扫是元素层 wipe，不计 slam。

---

## 附：60fps 与动效增强后的追加 tokens（task-3）

在原有 `Motion.fast/medium/slow + easeInOutCubicEmphasized + 200ms snap` 之上，
本片只用四个通用件，避免「炫技音色」：

| 件 | 参数 | 用在 |
|---|---|---|
| 阻尼弹簧 | `1 - e^(-5.6t)·cos(9.4t)` | S3 弹层收口 |
| 落位过冲 | `cubic-bezier(0.18,1.32,0.36,1)` | S6 小组件 cascade（物理落位允许过冲） |
| 滞后残影 | `lag(p, 0.22 / 0.42)`，透明度 0.20 / 0.11 | S5 拖拽 |
| 遮罩压印 | `clip-path: inset(0 0 (1-e)·100% 0)` | S1 数字 |

扫描线（S2）是全片唯一的光感元素：透明度 ≤0.18、被课表卡 24px 圆角裁切、
单次扫过，符合 aesthetic-rules Q4「单点、给主角、裁进圆角」。