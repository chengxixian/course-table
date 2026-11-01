# 项目计划（课程表 2.x）

> 快照：2026-11-01 17:25（Asia/Shanghai），版本 `2.0.37+39`。
> **发版处于用户要求的暂停状态**：本计划中的“发布”只做清单与验证，不创建 release、不推送 tag、不发布 APK。
> 许可：GPL-3.0。所有新增代码/解析移植必须保持 GPL-3.0 兼容，并同步第三方声明。

## 1. 当前状态

### 1.1 已完成（有代码证据）

| 能力 | 证据 | 备注 |
| --- | --- | --- |
| Material 3 主题/动态取色/多配色 | `lib/ui_theme.dart`、`main.dart` | 全局 1.15 文字缩放 |
| 黄山学院原生同步 | `lib/portal_client.dart`、`lib/sync_service.dart` | 门户 Cookie 仅内存；原始 JSON 明文落盘 |
| 350 所内置学校 + 黄山学院原生入口 | `assets/schools.json`（350） | 含铜陵学院；远端仅内存覆盖 |
| 通用网页导入（HTML 表格） | `lib/ui/import_web_screen.dart`、`lib/generic_html_parser.dart` | 缺教室整体拒绝 |
| AI 回退（Cloudflare + GLM-4-Flash） | `lib/ai_import_service.dart`、`cloudflare/flow-worker/src.js` | 逐周最多 20 周 |
| 手动添加课程 | `lib/ui/manual_course_dialog.dart`、`lib/manual_course.dart` | 与同步共存 |
| 4 个桌面小组件 | 4 个 `*WidgetProvider.kt` + `SyncService.WidgetBridge` | 周课表仅周一至周五 |
| App 内更新下载 | `lib/update_service.dart` + `MethodChannel install` | 仅大小校验 |
| Classy `zf*` 解析器移植 | `lib/classy_parser.dart` | 覆盖 137/349 |
| 开源字体替换（代码层） | `pubspec.yaml`、`assets/fonts_ofl/`、各 Kotlin Provider | FandolFang + Liberation Serif；旧字体已从工作树移除 |

### 1.2 进行中

| 事项 | 现状 | 还差什么 |
| --- | --- | --- |
| 长按拖动稳定化 | 2.0.37 用 Overlay + 网格坐标 + 拖动期间锁横向滚动 | 见 P0-1：叠加层提前返回、`gridKey` 每帧新建、落点半块偏移、末行截断 |
| 字体替换收尾 | 资源/声明/小组件已切到 Fandol/Liberation | 删除 `assets/_fangsong_cjk.ttf`、`assets/_times_latin.ttf`；真机字重/行高/生僻字 QA；APK 内容核对 |
| 文档与代码对齐 | `SDK.md`/`THIRD_PARTY_NOTICES.md` 已更新字体与解析器 | `PRIVACY.md` 版本表仍是 2.0.28；Classy 段落仍称“未复制 Kotlin 代码” |

### 1.3 未开始

文件导入（ICS/CSV/XLSX/PDF）、`zf*` 之外的解析器移植、应用内隐私政策入口、学校注册表绝对下限、更新完整性校验、自动化测试（当前 `test/widget_test.dart` 只是占位）。

## 2. 优先级总表

| ID | 优先级 | 事项 | 体量 | 依赖 |
| --- | --- | --- | --- | --- |
| P0-1 | P0 | 拖动与叠加层正确性 | 硬 / 2–3 天 | 无 |
| P0-2 | P0 | 学校名单绝对“只增不减” | 中 / 0.5 天 | 无 |
| P0-3 | P0 | 更新元数据与 CDN 一致性 | 中 / 0.5 天 | 发布流程 |
| P0-4 | P0 | 字体合规收尾 | 简 / 0.5 天 | 字体替换 |
| P1-1 | P1 | 文件导入（ICS→CSV→XLSX→PDF） | 硬 / 3–5 天 | 统一导入收口 |
| P1-2 | P1 | Classy 解析器扩展（按学校数排序） | 硬 / 每类 0.5–1 天 | 注册表 |
| P1-3 | P1 | 4 个小组件 QA 与 7 天周视图 | 中 / 1 天 | 字体、payload |
| P1-4 | P1 | 隐私/SDK 应用内集成与版本同步 | 简 / 0.5 天 | 无 |
| P2-1 | P2 | 手动课表单响应式/校验 | 中 / 0.5 天 | P0-1 |
| P2-2 | P2 | 无障碍与文字缩放 | 中 / 1 天 | P2-1 |
| P2-3 | P2 | 性能与列表搜索 | 简 / 0.5 天 | 无 |
| P2-4 | P2 | CI（analyze/test/build） | 中 / 0.5 天 | 测试用例 |
| P2-5 | P2 | Windows 端一致性与发布脚本 | 中 / 1 天 | P0-4 |

## 3. P0 详情

### P0-1 拖动与叠加层正确性（硬）

**问题**

1. `AppController._withManual` 在 `_manualCourses.isEmpty` 时提前返回，导致“只调课、无手动课”的用户拖动无效。
2. `_Timetable.build` 内 `final gridKey = GlobalKey()` 每次重建换 key，拖动中父级重建会卸载手势子树。
3. 浮层以指针为中心，落位却把指针当起始格，抓块中部会下移半块。
4. 落点 `start` 上限 30 而 `moveMeeting` 截断 `end`，2 节连堂拖到末行变 1 节。
5. 拖到时间栏/网格外会被 clamp 到周一或末行，而不是取消。
6. `reloadSchedule` 不按 `source_mode` 重载、不重放叠加层。

**改法**

- `_withManual` 先应用 `_meetingMoves`，再判断是否有手动课；无手动课时也必须返回重建后的 `Schedule`。
- `gridKey` 提升到 `_WeekScreenState`（或 `_Timetable` 的 State），全生命周期唯一。
- 落点改为“抓取偏移”模型：`start = pointerCell - grabRowOffset`，或浮层左上角对齐指针；两种方案择一并在 UI 上一致。
- `start` clamp 到 `1..N-duration+1`；越界（整块放不下）直接取消并轻提示，不静默截断。
- 指针不在网格内（`dx<0 || dx>=616 || dy<0 || dy>=656`）→ 取消。
- 同格落点 → 取消，不写盘。
- `reloadSchedule` 按 `sourceMode` 选择基底并调用同一 `_rebuild()`。

**验收**

- [ ] 无手动课，拖动原生课到周三第 3 节，松手即落位；杀进程重开仍在。
- [ ] 有手动课时行为不变，手动课不被同步覆盖。
- [ ] 拖动过程中触发一次 `controller.notifyListeners()`（如设置变更），手势仍完成落位。
- [ ] 320dp 宽、1.0/1.15/2.0 文字缩放下，浮层不越界、网格不溢出。
- [ ] 拖到时间栏、表头、网格外均取消；拖到末行 2 节连堂不变 1 节。
- [ ] 导入源用户切后台再回前台，课表仍是导入源且叠加层完整。
- [ ] 点击课程仍打开详情浮层，不会与长按冲突。

**测试**：把坐标换算抽成纯函数 `cellFor(Offset local, {int periods, double dayWidth, double rowStep})`，单测边界（0、87.9、88、615.9、656）；Widget 测试用 `WidgetTester.startGesture` + `pump(kLongPressTimeout)` 覆盖成功/取消/重建中断。

### P0-2 学校名单绝对“只增不减”（中）

**问题**：守卫是 `list.length < schools.value.length`，基线取决于内存；本地资源加载失败时 2 条旧 JSON 即可通过。只校验数量，不校验结构。

**改法**

- 常量 `kMinSchoolCount = 350`；接受条件 `parsed.length >= max(kMinSchoolCount, current.length)`。
- 逐条校验：`name` 非空且唯一、`loginUrl` 为 http(s)、`type` 非空；非法条目丢弃后重新计数。
- 黄山学院始终置顶且 `native = true`；不信任远端同名条目。
- 记录最近一次成功来源与条目数（设置页调试行），不写远端原始文件。

**验收**

- [ ] 用 2 条、349 条、350 条、351 条、重名、`ftp://`、空名 fixtures 单测：2/349 被拒绝，350 与 351 均被接受且条目合法。
- [ ] 删除/改名 `assets/schools.json` 后冷启动，仍显示内置兜底且远端 2 条被拒绝。
- [ ] 离线启动列表为 350，搜索可用。

### P0-3 更新元数据与 CDN 一致性（中）

**问题**：`version.json` 版本 2.0.37 但 `apk/page` 指向 v2.0.26；`?b=39` 是客户端 build，不能刷新远端缓存；GitHub 路径 `build=0`，同版本号只升 build 检测不到；镜像“首个成功”可能返回旧文件。

**改法**

- 发布脚本一次生成：`pubspec.yaml`、`AppMeta.version/build`、`version.json`、文档版本表，四者必须相等。
- `version.json` 的 `apk/page` 与 `version` 同源生成；加 `sha256` 字段（可选校验）。
- CDN 刷新：改用内容相关参数（如 `?v=<version>-<build>`）或把 `version.json` 放到可设 `max-age=60` 的 Pages；不要用客户端 build 当缓存键。
- 镜像结果按“版本号最大者”选择，而不是首个 200；至少在同版本时优先 GitHub API。
- 同版本 build 递增也要能提示：GitHub 路径解析 `tag` 后，若资产名带 build 则读取，或统一走 version.json。

**验收**

- [ ] 构造“CDN 返回旧 version.json + GitHub API 失败”的场景，客户端不会把旧版当最新。
- [ ] 构造“version.json 版本 2.0.37、apk 指向 2.0.26”，校验脚本直接失败。
- [ ] `2.0.37+39` 检测 `2.0.37+40` 能提示更新。

### P0-4 字体合规收尾（简）

- 删除 `assets/_fangsong_cjk.ttf`、`assets/_times_latin.ttf`（旧专有字体/子集残留）及 `tool/merge_fangsong*.py` 中不再需要的引用。
- `git ls-files | grep -iE 'fangsong|times'` 应无输出（新文件名 FandolFang/LiberationSerif 不含这些关键字）。
- APK 解包核对：手工字体仅 `FandolFang-Regular.otf`、`LiberationSerif-Regular.ttf`、`FusionPixel12.ttf`、`Pixelarticons.ttf`（另有 `flutoryx` 插件自带的 Mulish 字重，属其上游 OFL 资源）；无 `FangSongCN.ttf`/`FangSongGB.ttf`/`TimesNewRoman.ttf`。
- 真机检查：仿宋/像素两套字体、粗细、标点、数字、生僻字回退、行高 ±5% 是否引起截断。
- `THIRD_PARTY_NOTICES.md` 与 `assets/fonts_ofl/*` 许可文本随包/随仓库保留。

## 4. P1 详情

### P1-1 文件导入（硬）

顺序：**ICS → CSV → XLSX → PDF**。ICS 价值最高、解析本身无新依赖（文件选择仍需 `file_picker`）；PDF 最后（解析质量与包体风险最高）。

- 统一入口 `ImportAdapter`：`canHandle(name, bytes)`、`Future<Schedule> parse(...)`；MVP 可先把文件转成 HTML 表格复用 `parseImportedHtml`。
- ICS：解析 `VEVENT`，只取 `DTSTART/DTEND/SUMMARY/LOCATION/DESCRIPTION`，按 `RRULE` 或逐事件展开周次；跳过全天事件；时区固定 `Asia/Shanghai`；同名同开始时间去重。
- CSV：首行表头映射（课程/教师/教室/星期/节次/周次），支持中英文别名；缺列报错而非猜。
- XLSX：读首个含“星期/周一”表头的工作表，转表格 HTML。
- PDF：仅文本型 PDF；扫描件明确提示不支持。
- 依赖需重新评估（此前 `file_picker/excel/pdfx` 被移除）：优先 `file_picker` + 自写 CSV/ICS；XLSX/PDF 再议，避免包体和无维护依赖。

**验收**：固定样例各 3 个（正常/跨周/缺字段）；导入后课程数、时段数、周次与源文件一致；无网络请求；失败有具体原因且不改动现有课表。

### P1-2 解析器扩展（硬）

按覆盖排序：`qz` 67 → `chaoxing` 43 → `wisedu` 27 → `classic_eams` 19 → `cf` 11 → `urp` 6 + `urp_new` 5。每类一个 `ParserAdapter` + 3 份真实页面 fixture（脱敏）+ golden HTML。

规则：本地成功且确认 → 不上传；失败 → 明确提示 AI 路径；移植需在文件头与 `THIRD_PARTY_NOTICES.md` 注明 Classy 来源与 GPL-3.0 改编。目标：先覆盖 60% 学校，AI 调用量下降一个量级。

### P1-3 小组件（中）

- 周课表支持 5/7 天切换（当前硬编码周一至周五）；2x1/2x2/4x3 尺寸与深色模式截图核对。
- 空数据（`{}`）、假期、跨天、无教室、超长课程名不裁剪为乱码。
- 仿宋/像素字体、1.15/2.0 文字缩放、系统字体大小最大档不重叠。
- `WidgetBridge.update` 在同步/导入/设置变更/回前台后各触发一次，避免重复刷新。

### P1-4 隐私/SDK 应用内集成（简）

- 设置/关于页提供“隐私政策”“第三方 SDK 清单”入口：打包 Markdown 为 asset 或打开固定 Pages URL（二选一，离线可用优先）。
- `PRIVACY.md`、`SDK.md` 的版本表与本版 `pubspec.yaml` 一致；`Classy` 段落改为“包含 `JwNewZfParser.kt` 的 Dart 移植（GPL-3.0 改编）”。
- `DONATE.md` 的 “MIT 授权范围” 改为 GPL-3.0（素材除外）。
- `THIRD_PARTY_NOTICES.md` 补 `lib/classy_parser.dart` 条目。
- 明确 `allowBackup`、`usesCleartextTraffic` 的取舍并写入文档；若要加固，单开任务，不在本项偷改。

## 5. P2 详情

- **P2-1 手动课表单**：`AlertDialog` 固定 420 宽在 320dp/2.0 缩放下会挤压；改为 `ConstrainedBox(maxWidth: 420)` + 自适应，三列下拉在窄屏改两行；周次输入实时校验；起止节次联动；支持编辑/删除。
- **P2-2 无障碍**：语义标签、对比度、200% 缩放、键盘/遥控焦点；课程块最小点击区域 48dp。
- **P2-3 性能**：周网格避免整树重建；350 条搜索去抖；`ListView.builder` 替代长 `Column`。
- **P2-4 CI**：`flutter analyze` + `flutter test` + `flutter build apk --debug`；缓存 pub；失败阻断合并。
- **P2-5 Windows**：更新/下载跳转、紧凑模式、字体回退、ICS 路径与分享一致性；构建脚本产出 zip + SHA-256。

## 6. 子代理分工建议

| 类型 | 适合任务 | 约束 |
| --- | --- | --- |
| 简单（单文件、低风险） | 文档版本同步、字体残留清理、声明补条目、文案/主题 token、小组件字体常量、测试脚手架 | 不改状态机；不动 `AppController`/`week_screen.dart`；提交前跑 analyze |
| 困难（跨文件、需 fixtures） | P0-1 拖动、P0-2 注册表、P1-1 文件导入、P1-2 解析器移植、更新链路 | 先写测试/样例再改实现；一个任务一个 owner |

协作规则（针对本仓库已出现的并行改动）：

1. **同一文件同一时间只允许一个写入者**；开工前声明文件所有权。
2. 先冻结 `lib/app_controller.dart`、`lib/ui/week_screen.dart` 再并行其他任务。
3. 禁止用 `tool/*.py` 的 `str.replace` 盲改源码；必须用可审查的编辑并校验替换次数。
4. 每个 PR 只做一件事，附验证命令与截图/测试输出。

## 7. 验证步骤

```bash
flutter pub get
flutter analyze                 # 0 issue
flutter test                    # 新增单测/Widget 测试全绿
dart run tool/test_classy.dart  # Classy 解析冒烟（现有手工脚本）
flutter build apk --release
flutter build windows
```

手工矩阵：

- 设备宽度 320 / 360 / 412dp；文字缩放 1.0 / 1.15 / 2.0；浅色/深色；仿宋/像素字体。
- 拖动：原生课、手动课、单节、连堂、末行、跨周末、拖动中重建、取消。
- 导入：黄山学院原生、`zf_new` 本地、无解析器学校 AI、逐周导入取消、缺教室拒绝、刷新失败保留旧数据。
- 名单：飞行模式冷启动、2 条旧 JSON、351 条新 JSON、搜索。
- 更新：旧 build 检查新 build、GitHub API 失败、镜像返回旧文件、APK 版本与提示一致。
- 字体：解包 APK 核对；生僻字/数字/标点截图。

## 8. 发布清单（**暂停，勿执行发布动作**）

仅当用户明确解除 hold 后，按序执行：

- [ ] 1. 版本四处一致：`pubspec.yaml`、`lib/app_meta.dart`、`version.json`、`PRIVACY.md`/`SDK.md` 版本表。
- [ ] 2. `version.json` 的 `version/build/apk/page` 指向本次 release，`apk` 为真实资产 URL。
- [ ] 3. `flutter analyze` 与 `flutter test` 全绿；CI 通过。
- [ ] 4. Android release 构建安装于 minSdk 24 与 targetSdk 36 设备；Windows 构建可启动。
- [ ] 5. P0-1 拖动验收 7 条全部通过；无回归（点击详情、周切换、同步）。
- [ ] 6. 导入冒烟：原生、Classy、本地 HTML、AI、刷新、拒绝路径。
- [ ] 7. 名单回归：旧 JSON 不覆盖；离线 350 条。
- [ ] 8. 更新自检：旧包能发现新包；镜像故障回退；无降级。
- [ ] 9. 字体/许可文件在包内；`THIRD_PARTY_NOTICES.md`、`assets/fonts_ofl/`、Classy 声明齐全。
- [ ] 10. 隐私政策可在应用内打开，内容与代码一致；无分析/广告 SDK。
- [ ] 11. 确认 `.secrets/`、Cloudflare token、签名文件未进入版本库或构建产物；`.gitignore` 核对。
- [ ] 12. 打 tag 并附源码归档（GPL-3.0 义务）；保留上一版 APK 与 `version.json` 以便回滚。
- [ ] 13. 发布说明只写用户可见变更，不写内部路径/密钥/隐私细节。

## 9. 建议的下一轮顺序

1. P0-1（拖动）→ 2. P0-2（名单）→ 3. P0-3（更新）→ 4. P0-4（字体）→ 5. P1-4（隐私文档，半天）→ 6. P1-1（ICS/CSV）→ 7. P1-2（解析器）。
