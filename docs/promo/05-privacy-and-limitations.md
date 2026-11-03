# 数据合规自查 / 已知限制

## 1. 结论

成片不含任何真实个人数据。所有姓名、学号、课程、教师、教室、成绩均为虚构示例；
没有使用仓库里已有的、可能含个人信息的截图作为画面素材。

## 2. 片中出现的全部「身份类」内容

| 类型 | 成片中的值 | 性质 |
|---|---|---|
| 学生姓名 | 不出现 | — |
| 学号 | 不出现（登录页/设置页均未入镜） | — |
| 课程名 | 高等数学 A1、机械制图 A、大学物理、数据结构、英语听说、中国近现代史纲要、体育（篮球）、机械工程导论 | 虚构示例（常见课程名，不对应任何真实课表） |
| 教师名 | 陈景行、褚明远、林知远、苏映雪、沈砚秋、罗一楠、韩川、葛小乐 | **虚构**（非真实教师） |
| 教室 | 文渊 1201、文津 4508、明理 2102、信息楼 302、外语楼 205、文澜 305、东区球场、文渊 1105 | 虚构楼名+房号 |
| 学校 | 黄山学院 / 铜陵学院 / 安庆师范大学 | 真实**公立机构名**，取自 App 公开的 `assets/schools.json`（350 条注册表），不含个人信息 |
| 日期 | 2026-10-19 – 2026-10-25，第 8 教学周 | 虚构学期位置 |
| 事件数 | 「42 个事件」 | 演示数字，非真实导出结果 |

自查方法：`grep -rn` 遍历 `src/` 中的中文字符串（见 §5 命令），逐条对照上表；
`src/data.ts` 中的课程/教师/教室是唯一数据源，组件不硬编码任何其它人名。

## 3. 与「真实截图」路线的偏离（重要限制）

**本机没有可运行的 App 实例**：`flutter`、`adb` 均不在 PATH，没有 Android
Studio / AVD，`python` 不可用，因此无法用模拟器截取真实界面，也无法运行
`capture-template.mjs` 那套「起 dev server → 2x 全页截图 + 元素切图 + layout.json」
的流程。

据 video-shotcraft Q1「复刻既有页面必须用真实截图」，本片属于**有记录的例外**：
手机内界面是按 `lib/` 源码逐值复刻的合成 UI（Remotion React 组件），
复用 App 自己的字体文件、色板、间距、圆角与全部真实字符串。取舍与风险：

- ✅ 不会泄露任何真实数据（截图路线反而有风险）
- ✅ 字体/色彩/栅格与源码一致，不是"另造一套宣传片皮肤"
- ⚠️ 与真机像素级细节（字体渲染 hinting、原生阴影、状态栏信号图标）存在差异
- ⚠️ 真实 App 的深浅色由 `dynamic_color` 取系统壁纸，片中的青瓷/山茶粉是按
  `paletteSeeds` 推算的近似 M3 角色色，**不是**真机取色的色值

如果有真机/模拟器，正确做法是：装 `promo/` 外的 debug APK → 截图周课表、
课程详情弹层、网页导入页 → 替换 `src/ui/*` 组件。工程结构已为此预留
（所有 App 画面集中在 `src/ui/WeekScreen.tsx`、`src/ui/CoursePopup.tsx`、
`src/ui/Widgets.tsx`，替换为 `<Img>` 即可）。

## 4. 其它限制

1. **无 ffmpeg / ffprobe**：环境里没有 ffmpeg，只有 Remotion 自带编码链路；
   抽帧、contact sheet 用 Remotion 静帧渲染实现，未做「渲后抽音轨回测切点误差」
   （music-beat-sync §5b），因为本片没有强拍 BGM。
2. **无独立终检 subagent**：当前委派深度为 1（已达上限），无法再派干净上下文的
   subagent 做 final-review；改为按 `final-review.md` 逐项自检（见 `06-qa-report.md`），
   并明确标注这是**制作者自检**，存在确认偏差。
3. **副字幕字号 52px = 2.7%**，略低于 aesthetic-rules Q11 的 3% 辅助文字线；
   主句 78px = 4.06% 达标。副字幕只补充"7 种格式/多源导入"，删掉不影响主信息。
4. 仓库里 `week.png`、`today.png` 等历史截图中界面为深色 + Noto Sans 观感，
   与本片采用的 FangSong（`pubspec.yaml` 里的 `FangSongCN → FandolFang`）不同；
   本片以 `pubspec.yaml` + `ui_theme.dart` 为准，未复刻旧截图观感。

## 5. 复核命令

```powershell
# 片中所有中文字符串（人工过一遍）
Select-String -Path "D:\hsu_flutter\promo\remotion\src\*.ts*","D:\hsu_flutter\promo\remotion\src\**\*.tsx" -Pattern "[\u4e00-\u9fa5]{2,}" |
  ForEach-Object { $_.Line.Trim() } | Sort-Object -Unique

# 确认没有引用仓库里可能含个人数据的图片
Select-String -Path "D:\hsu_flutter\promo\remotion\src\**\*.*" -Pattern "\.png|\.jpg" # 仅 remotion 内部资源
```
