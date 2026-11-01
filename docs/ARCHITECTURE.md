# 架构说明

> 快照：2026-11-01 17:25（Asia/Shanghai），对应 `2.0.37+39`。
> 仓库当时存在并行改动（字体替换、小组件字体、第三方声明），本文只描述该时点的代码事实；引用行号以该快照为准。
> 项目整体许可以根目录 `LICENSE`（GPL-3.0）为准；Classy 学校数据与 `lib/classy_parser.dart` 同为 GPL-3.0。

## 1. 分层

```text
┌──────────────────────────────────────────────────────────────┐
│ 表现层 lib/ui/                                                │
│  HomeShell（导航） Today / Week / Courses / Settings / About   │
│  components.dart（课程块、详情浮层、登录面板）                  │
│  import_web_screen.dart（WebView 导入） manual_course_dialog   │
└───────────────▲──────────────────────────────┬───────────────┘
                │ AnimatedBuilder / setState    │ 用户意图
┌───────────────┴──────────────────────────────▼───────────────┐
│ 状态编排 AppController（ChangeNotifier，唯一可变状态）          │
│  schedule（派生） / _baseSchedule（基底）                       │
│  _manualCourses、_meetingMoves（叠加层，持久化）                │
└───────┬───────────────┬───────────────┬──────────────┬───────┘
        │               │               │              │
┌───────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐ ┌─────▼──────┐
│ 同步/导入     │ │ 解析          │ │ 注册表/更新  │ │ 小组件      │
│ SyncService  │ │ parser.dart   │ │ SchoolRegistry│ │ WidgetBridge│
│ PortalClient │ │ generic_html  │ │ UpdateService │ │ home_widget │
│ Imported...  │ │ classy_parser │ │ AppMeta       │ │             │
│ AiImport     │ │ models.dart   │ │               │ │             │
└───────┬──────┘ └──────┬──────┘ └──────┬──────┘ └─────┬──────┘
        │               │               │              │
┌───────▼───────────────▼───────────────▼──────────────▼───────┐
│ 存储 / 平台 lib/storage.dart、credential_vault.dart            │
│ SharedPreferences（明文业务数据） · AES-GCM 凭据 · WebView Cookie│
│ Android：AppWidget / WorkManager / MethodChannel(install)      │
│ Windows：window_manager / ICS 导出 / 外部浏览器                 │
└───────────────────────────┬──────────────────────────────────┘
                            │
┌───────────────────────────▼──────────────────────────────────┐
│ 外部服务（不可信边界）                                         │
│ 黄山学院 mwx/jwxt · Cloudflare Pages+GLM-4-Flash · GitHub      │
│ jsDelivr/Fastly/Gcore/ghproxy · 各学校课表站点 · Google 日历    │
└──────────────────────────────────────────────────────────────┘
```

要点：

- 只有 `AppController` 持有可变课表；UI 不直接改 `Schedule`。
- 两套数据源互斥：`source_mode = native`（黄山学院）或 `imported`（网页导入）。切换写入同一 `schedule` 字段。
- 解析器只负责产出 `Schedule`；展示、小组件、日历导出共用同一模型。

## 2. 课表叠加模型

### 2.1 数据

| 层 | 类型/键 | 来源 | 持久化 |
| --- | --- | --- | --- |
| 基底 | `Schedule`（`_baseSchedule`） | 原生抓取 `raw_scrape` 经 `ScheduleParser.build`；或 `imported_source.html` 经 `parseImportedHtml` | 原始 JSON/HTML |
| 调课 | `MeetingMove{meetingId, day, startPeriod, endPeriod}` | 长按拖动原生课程 | `meeting_moves` |
| 手动课 | `ManualCourseEntry` | 手动添加对话框 | `manual_courses` |
| 派生 | `schedule` | `_withManual(base)` | 不落盘 |

### 2.2 合成顺序（`_withManual`）

1. 以 `meetingId` 建索引，替换基底的 `day/startPeriod/endPeriod`；
2. 按 `courseId` 重建每门课的 `meetings` 列表（保持 `week/weeksText` 等字段）；
3. 把手动课合成为 `Course + Meeting`，ID 命名空间为 `manual_<entry.id>`，`kind = 'manual'`，周次为空时默认全学期；
4. 重新计算 `Schedule`，但 `conflicts` 直接沿用基底——**叠加层不会重新做冲突检测**。

真值表（当前实现）：

| 有手动课 | 有调课 | 结果 |
| --- | --- | --- |
| 否 | 否 | 返回基底，正确 |
| 是 | 是/否 | 调课 + 手动课，正确 |
| **否** | **是** | **提前 `return base`，调课被丢弃（缺陷）** |

缺陷位置：`app_controller.dart` 的 `_withManual` 在应用调课前判断 `if (_manualCourses.isEmpty) return base;`。因此“只拖动原生课程、从未添加手动课”的用户松手后看到的是原位。

### 2.3 不变量

- 基底不可变；任何写操作只改叠加层并重新派生。
- 手动课 ID 稳定；调课只保留每个 `meetingId` 的最后一次（`moveMeeting` 先删后加）。
- 调课键依赖基底 meeting ID。原生 ID 是 `courseId|section|teacher|room|day|startPeriod|endPeriod|weeks` 的 FNV-1a 哈希（`parser.dart:106`），任一项变化都会使旧调课成为孤儿（仍存盘、永不命中）。
- 派生必须幂等：同一 `base + 叠加层` 反复计算结果一致。

### 2.4 已知状态缺陷

- `reloadSchedule()`（`app_controller.dart:191`）在 App 回到前台时调用，只读 `raw_scrape`，**不判断 `source_mode`、不重放叠加层**。导入源用户可能被切回旧的原生课表，手动课/调课暂时消失。
- `clearAllCourses()` 未删除 `meeting_moves` 键（`_meetingMoves` 只清内存），且重复调用 `clearCourses()` 两次。
- 叠加层冲突不重算，手动课可能与原生课重叠而界面不提示。

## 3. 拖动坐标算法

### 3.1 网格常量（`week_screen.dart`）

| 常量 | 值 | 说明 |
| --- | --- | --- |
| `dayWidth` | 88 | 每天列宽；网格总宽 616 |
| `timeWidth` | 48 | 左侧节次栏，位于 `gridKey` 之外 |
| `rowHeight` | 56 | 每节高度 |
| `breakHeight` | 4 | 节间空隙 |
| 网格高 | `N*56 + (N-1)*4` | 原生 11 节为 656 |
| 行步长 | 60 | `rowHeight + breakHeight` |

### 3.2 手势与浮层

```text
LongPressStart → 记录 globalPosition，dragging=true（横向 physics 置为 NeverScrollable）
              → OverlayEntry 插入：left = dx - w/2, top = dy - h/2
LongPressMove  → 更新 _position，_entry.markNeedsBuild()
LongPressEnd   → 移除浮层，dragging=false，按坐标落位
Cancel/Dispose → 移除浮层（必须对称）
```

- 浮层放在根 `Overlay`，以指针为中心，`IgnorePointer` 防止自己命中。
- 横向滚动锁定靠 `SingleChildScrollView.physics` 切换，不改 `ScrollController`、不重建兄弟子树。
- 纵向仍由外层 `ListView` 负责；长按赢得手势竞技场后纵向拖动不再滚动。

### 3.3 落位

```dart
final box = gridKey.currentContext!.findRenderObject() as RenderBox;
final local = box.globalToLocal(pointerGlobal);
final day   = (local.dx / 88).floor().clamp(0, 6) + 1;
final start = (local.dy / 60).floor().clamp(0, 30) + 1;
controller.moveMeeting(meeting, day, start);   // 内部再 clamp 到 1..N
```

坐标契约：

- `gridKey` 必须挂在“7 列 × N 行”网格容器上，不含 48px 表头与时间栏，否则整体偏移；
- 网格在外层滚动容器内，`globalToLocal` 自动吸收滚动偏移，**不要**手写 `scrollOffset` 修正；
- 列：`dx ∈ [0,616)`；行（原生 11 节）：`dy ∈ [0,656)`；表头/时间栏/网格外都应视为“取消”，当前实现会 clamp 到周一或末行；
- 落点语义应是“被拖动块左上角所在格”，而浮层以指针为中心：抓取块中部松手会让课程向下跳约半块（待修）；
- `start` 应 clamp 到 `N - duration + 1`，让越界落点整块上移或直接取消；当前 `start+duration-1` 被截断，2 节连堂可能变成 1 节。

### 3.4 稳定性约束

- `gridKey` 现在是 `_Timetable.build` 内的局部 `GlobalKey()`（`week_screen.dart:113`）。父级任何重建都会换 key，导致网格子树（含正在拖动的 `_DraggableCourse` State）被卸载，手势丢失。必须提升到 `State` 字段或使用稳定 `ValueKey`。
- 长按开始后不得 `setState` 重建手势组件；只允许 `ValueNotifier` 驱动局部重建。
- 同一时刻只允许一个拖动会话；`onLongPressStart` 应检查 `_entry == null`。
- 松手落点与原地相同应直接取消，避免无意义写盘与小组件刷新。

### 3.5 已知交互缺口

- 拖动过程无边缘自动滚动：手机可见约 3.5 天，拖到周末前必须先滚到周末。
- 无目标格高亮/预览，只有浮层；落点是否合法没有视觉反馈。
- 不能跨周拖动（`meeting.weeks` 不变），也不能拖动手动课以外的“调课周次”。
- 没有撤销；一次误拖只能再拖回。

## 4. 导入管线

```text
                 ┌─ 当前页导入（未适配高校）
WebView 页面 ────┤    outerHTML ─→ parseImportedHtml ──成功且教室齐全──→ 预览确认
                 │         │失败/缺教室（非 hsu.edu.cn）
                 │         └─→ innerText ─→ Cloudflare /ai-parse ─→ 表格 HTML ─→ 解析
                 │
                 └─ 整学期导入
                      schoolType 为 zf* ─→ ClassyParser.parseToHtml（本地，不上传）
                               │成功      └─→ 预览确认 ─→ 导入
                               │取消/失败
                               └─→ 逐周 innerText（最多 20 周，AI 导航点“下一周”）
                                     └─→ Cloudflare /ai-parse 合并 ─→ 表格 HTML ─→ 解析
```

共同收口：

- 所有解析器最终都要产出 `generic_html_parser` 能吃的 `<table>`，或直接产出 `Schedule`；
- 导入前强制：`host` 含 `hsu.edu.cn` 直接拒绝（必须走原生同步）；任一时段缺教室则整体拒绝，避免覆盖旧课表；
- 成功后保存 `ImportedSource{url, cookies, html, savedAt}`（**明文**），刷新时带 Cookie GET 原 URL；
- 刷新失败保留旧数据并抛 `ImportException`，不清空。

缺口：ICS/CSV/XLSX/PDF 文件导入尚未实现（`pubspec.yaml` 无文件选择/表格/PDF 依赖；历史依赖被移除）。新增时应复用同一收口，而不是再写一套 `Schedule` 组装。

## 5. 解析器注册表

现状是“函数 + 类型前缀”：

```dart
ClassyParser.parseToHtml(html, schoolType)  // 仅 type.startsWith('zf') 生效
```

- `ClassyParser` 移植自 Classy `JwNewZfParser.kt`：从 `kbList`/`xskbcx_json`/`kbxx` JSON 或 `var` 赋值中提取课程，再转 HTML 表格。
- 覆盖：`zf_new` 123 + `zf` 13 + `zf_1` 1 = **137/349 ≈ 39%**；`qz` 67、`chaoxing` 43、`wisedu` 27、`classic_eams` 19、`cf` 11、`urp` 6、`urp_new` 5、`eams5` 3 等 212 所没有本地解析器，直接落到逐周 AI。
- 逐周 AI 是“最贵、最慢、最可能触发风控”的路径：20 次翻周 + 1 次合并，任一步失败即整学期退化为当前页。

建议注册表契约（尚未实现）：

```dart
abstract class ParserAdapter {
  String get type;
  bool canParse(String html);
  String? toTableHtml(String html);   // 失败返回 null，不抛异常
}
// registry[type] ?? null；null 时才允许 AI 回退
```

规则：本地成功且用户确认 → 绝不上传；本地失败 → 明确提示将上传页面文本；每个适配器附固定样例与 golden 输出。

## 6. AI 代理

- 客户端：`AiImportService.parse` 只发送 `{"text": ...}`（截 30k），不带 URL/Cookie/账号；等待上限 90s。
- 边缘函数（`cloudflare/flow-worker/src.js`，与 `flow-pages/_worker.js` 同源）：
  - `/ai-parse`：`content-length > 45k` 拒绝；去 `script/style/标签`，`10–12` 位连续数字替换为 `[学号已脱敏]`，截 26k；
  - 提示词要求纯 JSON；`glm-4-flash`，`temperature 0.1`，`max_tokens 4096`，`response_format=json_object`；26s 超时；
  - 服务端清洗：`day 1..7`、`startPeriod >= 1`、`endPeriod >= startPeriod`；
  - `/ai-nav`：最多 80 个控件、页面文本 12k，返回 `{"index": n}`；失败返回 `-1` 让客户端走 DOM 文本兜底。
- `/`（上传流程）：校验学校名/URL，GitHub 建分支、写 `schools/pending/*.json`、开公开 PR；可选 KV 限流（默认未绑定）。
- 风险：接口无鉴权、无 Origin 校验，任何人可消耗 GLM 额度；提示词含未转义页面文本（提示注入只能影响“提取结果”，不能执行代码）；`preferStrong` 参数被忽略，服务端只配置 `glm-4-flash`；客户端 `strong` 也恒为 `false`。

## 7. 远端学校列表与“只增不减”

启动顺序：

1. `kSchoolPresets`（仅黄山学院）作为同步兜底；
2. `assets/schools.json`（350 条，含铜陵学院）覆盖内存；
3. 后台依次请求 jsDelivr、Fastly jsDelivr、raw.githubusercontent 的 `schools/index.json?v=350`；
4. `_parse` 过滤空名/空 URL，移除同名黄山学院后把内置黄山学院插回第 0 位；
5. **数量守卫**：`if (list.length < schools.value.length) continue;` 才接受。

问题：

- 守卫是“相对当前内存数量”，不是绝对下限。若 `assets/schools.json` 读取失败，基线变成 1，远端 2 条旧数据即可通过——这正是“350 变 2”的同类回归路径。
- 只校验数量，不校验条目结构/唯一性/协议；350 条垃圾数据也能通过。
- `?v=350` 是编译期常量，文件内容变化时 URL 不变，jsDelivr 对 `@main` 有较长缓存，会继续返回旧文件。
- 远端列表只存内存，冷启动离线时仍以 350 条内置数据为准（这是优点，应保留）。

正确不变量：`accepted = parsed.length >= max(kMinSchoolCount, current.length)`，其中 `kMinSchoolCount = 350`；并逐条校验 `name` 非空唯一、`loginUrl` 为 http(s)、`type` 为非空字符串（内置黄山学院以 `native = true` 例外）。

## 8. 更新流程

```text
启动/手动
  └─ GitHub Releases API（latest）
        ├─ 成功：取 tag_name + assets[course-table.apk] → 比较版本
        └─ 失败：依次 version.json（jsDelivr → Fastly → Gcore → raw → ghproxy）
              └─ 第一个 HTTP 200 且 JSON 可解析者即返回（不比较镜像新旧）
新版本 → Android：下载 apkUrl → 失败依次套 4 个 ghproxy 镜像 → 临时目录
        → 仅校验 >1MB → FileProvider → MethodChannel installApk → 系统安装器
Windows：打开 release 页面（失败套 ghproxy）
```

- 20 小时内不重复检查（`last_update_check`）。
- `_isNewer` 只比较前三段数字；GitHub 路径固定传 `build = 0`，**同版本号只升 build 的更新永远检测不到**。
- `version.json` 的 `apk/page` 当前仍指向 `v2.0.26`，而 `version` 是 `2.0.37`；旧客户端走镜像时会下载错版本。
- 无哈希/签名校验（仅依赖系统安装器）；镜像可返回任意 APK。
- `version.json?...&b=39` 的 `b` 是“当前客户端 build”，不是“远端内容版本”，不能起到刷新 CDN 的作用。应改为内容哈希/构建号参数，或把 version.json 放到可设短缓存的 Pages。

## 9. 字体与回退

- Flutter 侧族名保持不变，只换文件：`FangSongCN → assets/fonts_ofl/FandolFang-Regular.otf`（GPL-3.0 + 字体例外），`TimesNewRoman → assets/fonts_ofl/LiberationSerif-Regular.ttf`（SIL OFL 1.1，度量兼容）。
- `ui_theme.dart` 回退链：仿宋模式 `['TimesNewRoman', 'Microsoft YaHei UI', 'Noto Sans SC']`；像素模式 `['FangSongCN', 'TimesNewRoman', 'Microsoft YaHei UI']`。Windows 的 `Microsoft YaHei UI` 只作系统回退，不随包分发。
- Android 小组件自带一份 `android/app/src/main/assets/` 字体（FandolFang/Liberation/FusionPixel），与 Flutter assets 是两份拷贝；`Typeface.createFromAsset` 支持 OTF。
- 全局 `textScaler = 1.15`（`main.dart:81`），所有布局按 1.15 倍估算；表单/小组件需按 2.0 倍另测。
- 字形覆盖从旧字体约 20,902 降到 FandolFang 10,365，生僻字回退系统字体；未显式设 `height` 的文本行高约 +5%。

## 10. 关键不变量

| ID | 不变量 | 违反后果 |
| --- | --- | --- |
| INV-1 | 基底不可变，`schedule` 只由 `base + 叠加层` 派生 | 同步覆盖手动课/调课 |
| INV-2 | 叠加层重放不得依赖“是否存在手动课” | 调课静默丢失（当前已违反） |
| INV-3 | 所有导入解析器共用同一收口（HTML 表格或 `Schedule`） | 多套组装逻辑、字段漂移 |
| INV-4 | 本地解析成功且确认后不向 AI 发送页面 | 隐私声明失真 |
| INV-5 | 学校列表数量只增不减，且绝对下限 350 | 名单回退到 2 条 |
| INV-6 | 版本元数据（pubspec/AppMeta/version.json/文档）一致且严格递增 | 下载错包/检测不到更新 |
| INV-7 | 拖动：稳定 `gridKey`、单一手势所有者、滚动锁定、坐标纯函数、落点限界 | 松手不落位/重复/背景滚动 |
| INV-8 | 字体只包含可再分发许可，许可文本随包 | GPL/字体合规风险 |
| INV-9 | 页面文本仅在 AI 路径离开设备，文档与代码版本同步 | 隐私政策与实际不符 |
| INV-10 | GPL-3.0：每个发布 tag 可取得对应源码 | 许可证违约 |

## 11. 失败模式速查

| 场景 | 触发 | 症状 | 定位 |
| --- | --- | --- | --- |
| 调课无效 | 无手动课，仅拖动原生课 | 松手回原位 | `_withManual` 提前 return |
| 回前台丢叠加层 | 导入源 + 切后台再回 | 显示旧原生课表/手动课消失 | `reloadSchedule` 忽略 sourceMode |
| 拖动中断 | 拖动中 controller 通知/换周 | 浮层消失、手势丢失 | `gridKey` 每 build 新建 |
| 落点偏移 | 抓块中部松手 | 课程下移约半块 | 浮层中心 vs 起始格语义 |
| 末行截断 | 2 节连堂拖到最后一节 | 变 1 节 | `start` 未按 duration 限界 |
| 名单变 2 条 | 本地资源加载失败 + 远端旧 JSON | 设置页显示 2 所 | 相对数量守卫 |
| 名单不更新 | jsDelivr 缓存未过期 | 新学校看不到 | `?v=350` 常量 |
| 更新检测不到 | 仅 build +1 | 永远提示最新 | `_isNewer` 传 build=0 |
| 下载错版本 | 走 version.json 镜像 | 安装包版本与提示不符 | apk/page 指向 v2.0.26 |
| AI 超时 | 页面过长/上游 26s | 导入失败，无本地回退 | 无本地文本解析兜底 |
| 缺教室拒绝 | 页面教室列未渲染 | 无法导入，提示缺教室 | 故意保护，勿轻易放宽 |
| 小组件空白 | 字体/JSON 异常 | 桌面空白且仅日志 | Kotlin `runCatching` 吞异常 |

## 12. 相关文档

- [隐私政策](PRIVACY.md) · [SDK 与数据处理清单](SDK.md) · [第三方声明](THIRD_PARTY_NOTICES.md)
- [项目计划](PROJECT_PLAN.md) · [经验教训](LESSONS.md)
