# 第三方 SDK、依赖与数据处理清单

> 本清单用于说明「课程表」实际使用的 Flutter/Dart 依赖、Android 系统组件、网络服务与字体素材，以及它们各自可能接触的数据。它是 [`PRIVACY.md`](PRIVACY.md) 的技术附件，不替代各上游项目的许可证原文。

| 项目 | 内容 |
| --- | --- |
| 应用名称 | 课程表 |
| Android 包名 | `com.hsu.hsu_schedule` |
| 当前版本 | 3.0.0（build 30，`pubspec.yaml` 为 `3.0.0+30`） |
| 适用平台 | Android 24+（targetSdk 36）、Windows 桌面版 |
| 代码基线 | 2026-11-01 仓库快照 |
| 最后更新 | 2026-11-01 |
| 维护者 | chengxixian |
| 相关文档 | [隐私政策](PRIVACY.md) · [第三方声明](THIRD_PARTY_NOTICES.md) |

---

## 一、范围与口径

- 本清单覆盖三类内容：
  1. `pubspec.yaml` 中声明的 Flutter/Dart 直接依赖；
  2. 应用直接调用的 Android 系统 API 与由 Flutter/插件带入的关键 AndroidX 组件；
  3. 应用直接请求的网络服务、API 与随包分发的字体/素材。
- 版本以 `pubspec.lock` 在 2026-11-01 的锁定结果为准；`pubspec.yaml` 使用 `^` 约束，重新执行 `flutter pub get` 可能解析到更新的兼容版本。
- 传递依赖（如 `webview_flutter_android`、`shared_preferences_android`、`screen_retriever` 等）不逐一展开；完整列表以 `pubspec.lock`、`dart pub deps` 与应用内“开源许可”页为准。
- `flutter_lints`、`flutter_test` 仅为开发依赖，不随安装包分发。
- **本应用没有接入任何统计分析、广告、崩溃上报、推送、归因或设备指纹 SDK**；详见第八节。

---

## 二、运行时与 Android 系统组件

| 组件 | 版本 / 来源 | 用途 | 涉及数据 | 许可证 | 链接 |
| --- | --- | --- | --- | --- | --- |
| Flutter SDK / Dart 运行时 | 构建环境记录为 3.47.5 | UI 渲染、Dart 运行时、平台通道 | 无（本地运行） | BSD-3-Clause | https://flutter.dev/ |
| AndroidX（core、activity、lifecycle、work、webkit 等） | 由 Flutter 引擎与插件间接引入 | 兼容层、后台任务、WebView、文件共享 | 无（系统级） | Apache-2.0 | https://developer.android.com/jetpack/androidx |
| Android `CalendarContract` | Android 平台 API | 查询可写日历、写入课程事件与提醒 | 课程名、教师、教室、时间、周次、学分、调课说明 | Android/AOSP（Apache-2.0） | https://developer.android.com/reference/android/provider/CalendarContract |
| Android System WebView | 系统组件（Chrome/WebView 提供方） | 渲染学校课表网页、执行页面 JavaScript | 用户访问的网页、Cookie、页面内容 | Android/Chromium 各自许可 | https://developer.android.com/guide/webapps/webview |
| Android AppWidget / RemoteViews | Android 平台 API | 桌面小组件渲染与点击 | 课表摘要（本地） | Android/AOSP（Apache-2.0） | https://developer.android.com/develop/ui/views/appwidgets |
| AndroidX WorkManager | 由 `workmanager` 插件引入 | 每日后台同步、网络约束、开机恢复 | 本地设置/凭据；按配置发起网络请求 | Apache-2.0 | https://developer.android.com/topic/libraries/architecture/workmanager |
| `FileProvider` / `PackageInstaller` | AndroidX Core / Android 平台 | 把 APK 交给系统安装器；分享 ICS | APK 文件、ICS 文件 | Apache-2.0 / Android/AOSP | https://developer.android.com/reference/androidx/core/content/FileProvider |

> 说明：`CalendarContract`、`AppWidget`、`PackageInstaller` 属于 Android 系统 API，不是随 APK 打包的第三方 SDK；它们的行为由设备系统实现。`WebView` 的网页内容由对应网站及其第三方资源提供，适用该网站的政策。

---

## 三、Flutter / Dart 直接依赖

| 依赖 | 锁定版本 | 用途 | 涉及数据 | 许可证 | 链接 |
| --- | --- | --- | --- | --- | --- |
| `flutter_localizations` | Flutter SDK | 中文本地化、Material/Cupertino 文案 | 无 | BSD-3-Clause | https://flutter.dev/ |
| `shared_preferences` | 2.5.6 | 本地键值存储 | 设置、课表原文、网页导入源、凭据密文、小组件 JSON | BSD-3-Clause | https://pub.dev/packages/shared_preferences |
| `pointycastle` | 4.0.0 | AES-256-GCM 本地加密 | 学号/密码（仅内存与加密后的 blob） | Bouncy Castle License（MIT 风格） | https://pub.dev/packages/pointycastle |
| `path_provider` | 2.1.6 | 获取临时/下载/文档目录 | APK 临时文件、导出的 `.ics` | BSD-3-Clause | https://pub.dev/packages/path_provider |
| `share_plus` | 13.3.1 | 调起系统分享面板 | `.ics` 内容交给用户选择的目标应用 | BSD-3-Clause | https://pub.dev/packages/share_plus |
| `url_launcher` | 6.3.3 | 打开外部浏览器/应用 | 目标 URL 交给系统或对应应用 | BSD-3-Clause | https://pub.dev/packages/url_launcher |
| `window_manager` | 0.5.2 | Windows 窗口尺寸、无边框、悬浮小组件模式 | 窗口状态（不持久化个人数据） | MIT | https://pub.dev/packages/window_manager |
| `workmanager` | 0.10.10 | Android 每日后台同步调度 | 读取本地设置/凭据，按数据来源发起网络请求 | MIT | https://pub.dev/packages/workmanager |
| `home_widget` | 0.10.0 | Flutter 与 Android 桌面小组件的数据桥 | 课表摘要写入应用私有 `SharedPreferences` | BSD-3-Clause | https://pub.dev/packages/home_widget |
| `dynamic_color` | 1.9.0 | 读取系统动态配色（Material You） | 系统配色，不离开设备 | Apache-2.0 | https://pub.dev/packages/dynamic_color |
| `m3e_core` | 1.1.5 | Material 3 Expressive 组件（加载指示器、卡片等） | 无；其 Android 插件清单声明 `VIBRATE`（触感反馈相关） | MIT | https://pub.dev/packages/m3e_core |
| `flutoryx` | 1.7.0 | Material 3 UI 组件/动画 | 无 | MIT | https://pub.dev/packages/flutoryx |
| `webview_flutter` | 4.14.1 | 内置浏览器导入网页课表 | 用户输入的网址、页面内容、站点 Cookie | BSD-3-Clause | https://pub.dev/packages/webview_flutter |
| `intl` | 0.20.3 | 日期/时间格式化 | 无 | BSD-3-Clause | https://pub.dev/packages/intl |
| `package_info_plus` | 10.2.2 | 读取应用版本信息 | 当前代码未引用 | BSD-3-Clause | https://pub.dev/packages/package_info_plus |
| `cupertino_icons` | 1.0.9 | Cupertino 图标字体资源 | 当前代码未引用 | MIT | https://pub.dev/packages/cupertino_icons |
| `material_ui` | 1.3.0（`dependency_overrides`） | `m3e_core` 依赖的 Material 组件库 | 无 | BSD-3-Clause | https://pub.dev/packages/material_ui |

**版本与覆盖说明**：

- `pubspec.yaml` 声明 `m3e_core: ^1.1.4`，锁定到 1.1.5；`webview_flutter: ^4.13.0`，锁定到 4.14.1；`dynamic_color: ^1.8.1`，锁定到 1.9.0。
- `dependency_overrides` 固定了 `material_ui: 1.3.0`、`shared_preferences_android: 2.4.28`、`path_provider_android: 2.2.23`。仓库未注明固定版本的详细原因；这些覆盖不改变数据处理范围。
- `package_info_plus` 与 `cupertino_icons` 虽在 `pubspec.yaml` 中声明，但当前 `lib/` 未引用；保留它们不会产生网络或数据行为，建议后续清理或在文档中注明用途。

---

## 四、只在开发期使用、不随包分发

| 依赖 | 版本 | 用途 | 是否打包 |
| --- | --- | --- | --- |
| `flutter_test` | Flutter SDK | 单元/Widget 测试 | 否 |
| `flutter_lints` | 6.0.0 | 静态检查规则 | 否 |

---

## 五、网络服务与 API（非 SDK）

以下服务不是随 APK 打包的代码库，但应用会直接请求它们。表中“发送内容”只列应用代码实际写入请求体的字段；请求头中的 IP、时间、User-Agent 由网络协议自然产生。其中 Cloudflare 部分为部署在 `course-table-flow.pages.dev` 的 Pages Functions / Workers 边缘代码。

| 服务 | 端点 / 用途 | 触发场景 | 应用发送的内容 | 主要区域 | 链接 |
| --- | --- | --- | --- | --- | --- |
| 黄山学院统一身份认证 | `https://mwx.hsu.edu.cn/sso/*`；登录 | 原生同步、用户登录 | 学号、按门户要求前端加密后的密码、登录表单字段 | 中国境内 | https://mwx.hsu.edu.cn/ |
| 黄山学院教务系统 | `https://jwxt.hsu.edu.cn/...`；课表/节次接口 | 原生同步 | 会话 Cookie、学期参数；不再次发送密码 | 中国境内 | https://jwxt.hsu.edu.cn/ |
| Cloudflare 边缘函数 | `https://course-table-flow.pages.dev/ai-parse`；AI 解析 | 网页导入本地解析失败/无本地解析器 | 页面可见文本（最多约 30,000 字符） | 美国及全球节点 | https://pages.cloudflare.com/ |
| Cloudflare 边缘函数 | `https://course-table-flow.pages.dev/ai-nav`；翻周导航 | 整学期导入逐周翻页 | 页面文本 + 最多 80 个控件的标签/文字/aria/title；边缘函数截取前约 12,000 字符 | 美国及全球节点 | https://pages.cloudflare.com/ |
| Cloudflare 边缘函数 | `https://course-table-flow.pages.dev/`；创建 PR | 用户主动“上传导入流程” | 学校名、课表 URL、导入时间、应用版本 | 美国及全球节点 | https://workers.cloudflare.com/ |
| 智谱 AI 开放平台 | `https://open.bigmodel.cn/api/paas/v4/chat/completions`；模型 `glm-4-flash` | 由 Cloudflare 边缘函数调用 | 经脱敏/截断的页面文本与提示词 | 中国境内 | https://open.bigmodel.cn/ |
| GitHub REST API | `https://api.github.com/repos/chengxixian/course-table/releases/latest`；更新检查 | 应用启动/手动检查 | 无请求体；IP、UA | 美国 | https://docs.github.com/en/rest |
| GitHub | `https://github.com/chengxixian/course-table`；Release 资产、PR | 更新下载、查看项目、上传流程 | 下载请求；PR 内容（学校名+URL） | 美国 | https://github.com/ |
| jsDelivr（Cloudflare/Fastly/Gcore） | `cdn.jsdelivr.net`、`fastly.jsdelivr.net`、`gcore.jsdelivr.net`；`version.json`、学校列表、致谢 | 更新检查后备、学校列表、致谢名单 | 无请求体；IP、UA、路径 | 全球 | https://www.jsdelivr.com/ |
| GitHub Raw | `raw.githubusercontent.com`；`version.json`、学校列表、致谢 | 同上 | 无请求体；IP、UA、路径 | 全球 | https://github.com/ |
| ghproxy 等公共镜像 | `ghproxy.net`、`gh-proxy.com`、`mirror.ghproxy.com`、`github.moeyy.xyz`；APK/版本文件下载 | 更新下载失败后的镜像重试 | 目标 URL、IP、UA | 运营方未在仓库中说明 | https://ghproxy.net/ |
| Google 日历 | `https://calendar.google.com/...`；导入页、TEMPLATE 链接 | Windows 导出、打开导入页、添加单节课 | 课程名、时间、地点、描述（可能出现在 URL 中） | 美国及全球 | https://calendar.google.com/ |

### 5.1 AI 请求的具体字段

- `ai-parse` 请求体：`{"text": "<页面可见文本>"}`；客户端截断到约 30,000 字符。
- 边缘函数处理：去除 `<script>`/`<style>`/HTML 标签 → 将 `[0-9]{10,12}` 替换为 `[学号已脱敏]` → 截断到约 26,000 字符 → 作为提示词的一部分发给智谱。
- `ai-nav` 请求体：`{"text": "<页面文本>", "controls": [{tag, type, text, aria, title}, ...]}`；控件最多 80 个；边缘函数截取页面文本前约 12,000 字符。
- **不包含**：Cookie、账号、密码、页面 URL、设备标识。
- 当前边缘函数只配置 `glm-4-flash` 一个模型；它读取 `preferStrong` 字段，但应用的 `ai-parse` 请求体只发送 `text`，未携带该字段，模型列表也不会因它变化。

### 5.2 上传导入流程的具体字段

- 请求体：`{"school": "...", "url": "...", "savedAt": "ISO8601", "appVersion": "..."}`。
- 边缘函数校验后，用服务端 GitHub Token 创建分支、写入 `schools/pending/*.json`、创建公开 PR；应用不接触该 Token。
- 若部署时绑定了可选 KV `FLOW_RATE_LIMIT`，边缘函数会以来源 IP 为键保存约 120 秒的限流时间戳；仓库默认 `wrangler.toml` 中该绑定是注释状态。
- **不包含**：Cookie、HTML、账号、密码。
- 构建时可用 `--dart-define=FLOW_UPLOAD_URL=...` 覆盖上传端点；AI 端点（`ai-parse` / `ai-nav`）目前硬编码在 `lib/app_meta.dart`。

### 5.3 更新检查顺序

1. `https://api.github.com/repos/chengxixian/course-table/releases/latest`
2. `https://cdn.jsdelivr.net/gh/chengxixian/course-table@main/version.json`
3. `https://fastly.jsdelivr.net/...`
4. `https://gcore.jsdelivr.net/...`
5. `https://raw.githubusercontent.com/...`
6. `https://ghproxy.net/https://raw.githubusercontent.com/...`

APK 下载优先使用 Release 中的 `course-table.apk` 资产，失败后依次拼接 `ghproxy.net`、`gh-proxy.com`、`mirror.ghproxy.com`、`github.moeyy.xyz`。下载仅检查大小（>1 MB），**没有哈希/签名校验**；最终由 Android 安装器校验 APK 签名。

### 5.4 不会发送给第三方的数据

- 黄山学院密码：只发给 `mwx.hsu.edu.cn`；
- 网页导入 Cookie：只发给保存时的原站点（刷新时），不发给 Cloudflare、智谱或 GitHub；
- 本地课表、设置、小组件 JSON：不主动上传；仅在通用网页导入时，页面文本可能进入 AI 流程。

---

## 六、字体、图标与素材

| 文件 / 内容 | 用途 | 来源 / 作者 | 许可证 | 备注 |
| --- | --- | --- | --- | --- |
| `assets/fonts_ofl/FandolFang-Regular.otf` | 正文仿宋字体（继续沿用 `FangSongCN` 字体族名） | Fandol team（Clerk Ma、Jie Su），Fandol v1.300，CTAN `fandol` 包 | **GPL-3.0 + GPL 字体例外（font exception）** | 上游 https://ctan.org/pkg/fandol；许可全文 `assets/fonts_ofl/Fandol-COPYING.txt`；文件与 CTAN `fandol.zip` 内 `fandol/FandolFang-Regular.otf` 的 SHA-256 完全一致（`D838AD32…48D5BC9`） |
| `assets/fonts_ofl/LiberationSerif-Regular.ttf` | 西文衬线字体（继续沿用 `TimesNewRoman` 字体族名） | Liberation Fonts 2.1.5，Ascender / Red Hat，基于 Steve Matteson 的 Tinos | **SIL OFL 1.1**（保留字体名 Liberation、Arimo、Tinos、Cousine） | 与 Times New Roman 度量兼容（upem 2048；ascent/descent/lineGap 与抽样 77 个字符的字宽逐一致）；上游 https://github.com/liberationfonts/liberation-fonts ；许可全文 `assets/fonts_ofl/LiberationSerif-OFL.txt`；二进制取自 Debian `fonts-liberation` 2.1.5-3 包（上游 Release 只提供 `.sfd` 源码，需 FontForge 自行编译） |
| `assets/FusionPixel12.ttf` | 像素字体（`FusionPixel` 字体族） | TakWolf，Fusion Pixel 12px，2026.08.11 | **SIL Open Font License（OFL）**；上游仓库同时含 `LICENSE-OFL` 与 `LICENSE-MIT` | https://github.com/TakWolf/fusion-pixel-font；再分发需保留 OFL 声明；若做子集化/修改，需遵守 OFL 的名称与声明要求 |
| `assets/Pixelarticons.ttf` | 像素图标字体（`PixelIcons` 字体族） | Gerrit Halfmann / halfmage，pixelart-icons-font 1.0 | **MIT** | https://github.com/halfmage/pixelarticons；需保留版权与许可声明 |
| `flutoryx` 包内 `Mulish-*.ttf`（16 个字重） | 该 UI 库组件使用的西文字体 | flutoryx / Google Fonts Mulish | **SIL OFL 1.1**（字体 name 表） | 随 `flutoryx` 插件资源打包；再分发需保留 OFL 声明 |
| `assets/icon.png`、`assets/icon_pixel.png`、`assets/icon_pixel.ico` | 应用图标（`icon.png` 随包；`icon_pixel.*` 为 Windows/像素图标构建素材） | 项目作者 | 项目自有素材 | 按 `docs/DONATE.md`，图标/名称不随 GPL-3.0 源代码许可授权 |
| `assets/donate_wechat.png`、`assets/donate_alipay.jpg` | “关于”页赞赏二维码 | 项目作者个人收款码 | 不随 GPL-3.0 授权 | 见 [`DONATE.md`](DONATE.md)；不得替换、裁剪或用于衍生分发 |
| `assets/schools.json`、`schools/index.json` | 349 所高校的登录入口预设 | Classy（IMSX3D），`app/src/main/assets/schools.json` 转换而来 | **GPL-3.0** | 见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)；仅使用学校预设数据 |
| `lib/classy_parser.dart` | `zf_new` 等课表 JSON 的本地解析（Dart 移植） | Classy 的 `JwNewZfParser.kt`（GPL-3.0） | **GPL-3.0** | 与项目整体 GPL-3.0 兼容；说明文字见文件头 |
| `font_subsets/*.woff2` | 仓库内的字体子集文件（代码未引用） | Fusion Pixel 等上游字体 | 随上游 | 未在 `pubspec.yaml` 的 `assets` 中声明，**不随应用打包** |

**字体风险提示（重要）**：

- **专有字体已替换**：原先随包分发的 `assets/FangSongCN.ttf`（北京中易 FangSong，name 表标注 “Microsoft supplied font”/“Any other use is prohibited”）与 `assets/TimesNewRoman.ttf`（Monotype Times New Roman，同为 Microsoft supplied）已从工作树删除。正文改用 FandolFang（GPL-3.0 + 字体例外），西文改用 Liberation Serif（SIL OFL 1.1）；两者都与项目整体 GPL-3.0 兼容，可随 APK/Windows 构建再分发。
- **字体族名不变**：`pubspec.yaml` 仍以 `FangSongCN` / `TimesNewRoman` 两个族名声明新文件，`lib/ui_theme.dart` 与 Android 小组件的 `fontStyle` 分支都无需改动逻辑，仅资源路径变化。
- **字形覆盖与度量变化**：FandolFang 共 10,365 个字模（CJK 统一表意文字 7,942 个，约 GB2312 常用字规模，含全套中文标点），旧 FangSong 为 20,902 个；生僻字会回退系统字体。FandolFang 自带拉丁字形（旧 FangSong 的 cmap 不含 ASCII，正文拉丁原本走 Times 回退），因此正文中的数字/英文改由 FandolFang 渲染。垂直度量：旧字体 ascent/descent/lineGap = 0.859/0.141/0.141 em，FandolFang = 0.880/0.120/0.200 em；已显式设置 `height` 的文本样式（如 `bodyMedium: height 1.45`）不受影响，未设置的行高约增加 5%。
- **再分发义务**：FandolFang 随包提供 GPL-3.0 + 字体例外全文，Liberation Serif 保留 OFL 声明与保留字体名，文本均在 `assets/fonts_ofl/`。`FusionPixel12.ttf`、`Pixelarticons.ttf` 同样需保留各自声明；应用内 `showLicensePage` 只汇总 Flutter 包许可证，不会自动覆盖手工放入 `assets/` 的字体。
- **旧字体中间产物已清理**：早期合并脚本 `tool/merge_fangsong*.py` 会先拆出 `assets/_fangsong_cjk.ttf`（旧 FangSong 全量副本，与 `FangSongCN.ttf` 字节相同）和 `assets/_times_latin.ttf`（Times New Roman 的 377 字形子集）再合并成正文 TTF；这两个中间文件已随本次替换一并删除，仓库内不再保留任何 Microsoft/Monotype 字体数据。

**Classy 相关说明**：

- `assets/schools.json` 的学校预设来自 Classy（GPL-3.0），当前项目也是 GPL-3.0，许可证兼容；
- `lib/classy_parser.dart` 是 Classy `JwNewZfParser.kt` 的 Dart 移植，**这属于对 GPL-3.0 代码的改编**，应在第三方声明中补充；
- 现有 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)（截至 2026-11-01 快照）仍写着“No Kotlin/Compose source code was copied”，与当前新增的移植文件不一致，建议维护者更新该声明（本清单不改动该文件）。

---

## 七、许可证与分发合规

| 事项 | 说明 |
| --- | --- |
| 应用整体许可证 | GNU General Public License v3.0（仓库根 `LICENSE`） |
| 依赖许可证兼容性 | MIT、BSD-3-Clause、Apache-2.0、Bouncy Castle License、SIL OFL 通常可与 GPL-3.0 项目共存；分发时需保留各自的版权与许可文本，具体以各许可证原文为准 |
| 源码提供义务 | 以 GPL-3.0 分发 APK/Windows 构建时，需按 GPL 要求提供对应源代码 |
| 字体 | 正文 FandolFang（GPL-3.0 + 字体例外）、西文 Liberation Serif（SIL OFL 1.1），均可随 GPL-3.0 项目再分发，许可文本在 `assets/fonts_ofl/`；`FusionPixel12.ttf`、`Pixelarticons.ttf` 需保留 OFL/MIT 声明 |
| 学校数据 | `assets/schools.json` 来自 Classy（GPL-3.0），需保留来源与许可说明 |
| 解析器移植 | `lib/classy_parser.dart` 改编自 Classy（GPL-3.0），需在第三方声明中注明 |
| 图标 / 名称 / 赞赏码 | 不随 GPL-3.0 源代码许可授权，详见 [`DONATE.md`](DONATE.md) |
| 应用内许可页 | “关于 → 开源许可”调用 Flutter `showLicensePage`，汇总 `pubspec.lock` 中 Dart 包的许可证；不包含手工放入 assets 的字体与图片 |

> 本清单不是法律意见。公开分发前，建议由维护者确认 `assets/fonts_ofl/` 下的 GPL/OFL 文本随发行说明可见、更新 `THIRD_PARTY_NOTICES.md`，并确认所有 MIT/BSD/Apache 声明随包可见。

---

## 八、无分析、广告与追踪 SDK

| 类别 | 是否包含 | 说明 |
| --- | --- | --- |
| 统计分析 / 行为埋点 | **无** | 未接入 Google Analytics、Firebase Analytics、友盟、TalkingData 等 |
| 崩溃 / 性能上报 | **无** | 未接入 Crashlytics、Sentry、Bugly 等 |
| 广告 / 变现 | **无** | 未接入 AdMob、穿山甲、优量汇等 |
| 推送 | **无** | 未接入 FCM、JPush、个推等；WorkManager 的系统前台服务通知不属于推送 SDK |
| 社交 / 第三方登录 | **无** | 无微信/QQ/Google 登录；黄山学院登录是学校账号 |
| 安装归因 / 深链追踪 | **无** | 未接入 AppsFlyer、Adjust、Branch 等 |
| 热更新 / 动态代码下发 | **无** | 未接入 Shorebird 等；APK 更新走系统安装器 |
| 设备指纹 / 广告标识符 | **无** | 不读取 GAID/IDFA/Android ID/IMEI |
| 账号与云同步 | **无** | 开发者不运营账号系统或课表云存储 |
| Google Play Services / Firebase | **无** | 未集成；日历使用 Android 平台 `CalendarContract` |

> 说明：应用会请求 GitHub、Cloudflare、智谱、jsDelivr 等服务，这些请求会携带 IP、时间与 User-Agent，属于完成功能所必需的网络通信，不是分析/广告 SDK。

---

## 九、安全与隐私实现备注

| 事项 | 现状 | 影响 |
| --- | --- | --- |
| 凭据加密 | `lib/credential_vault.dart`：AES-256-GCM，12 字节随机 IV，128 位 tag，32 字节 `Random.secure()` 密钥 | 防止密码以明文直接出现在配置文件中 |
| 密钥存放 | 密钥与密文同在应用私有 `SharedPreferences`，未使用 Android Keystore/StrongBox | Root、调试备份、取证工具可同时取得密钥与密文 |
| 明文用户名 | `username` 键单独保存学号明文，用于界面显示 | 学号本身不是密码，但仍属于个人信息 |
| 网页导入源 | URL、Cookie、HTML 以明文 JSON 保存 | Cookie 可能等同于登录态，需保护设备与备份 |
| Android 系统备份 | 未设置 `allowBackup=false`，未提供备份规则 | 应用私有数据可能进入系统/云备份 |
| 传输 | HTTPS；未实现证书固定；`AndroidManifest.xml` 设置 `usesCleartextTraffic="true"` | 允许访问 `http://` 课表站点；依赖系统信任库，明文流量可能被同网段查看或篡改 |
| APK 下载 | 仅检查文件大小，无哈希/签名校验 | 依赖 Android 安装器的签名校验；公共镜像可靠性不受控 |
| 原生安全通道 | `MainActivity` 定义了 `com.hsu.hsu_schedule/secure` 的 AndroidKeyStore 通道，但当前 Dart 代码未调用 | 实际生效的是 `CredentialVault`；该原生通道目前是未使用代码 |
| 合并权限 | `m3e_core` 带入 `VIBRATE`；`workmanager_android` 带入 `POST_NOTIFICATIONS`、`FOREGROUND_SERVICE`、`FOREGROUND_SERVICE_SHORT_SERVICE`；WorkManager/AndroidX 带入 `WAKE_LOCK`、`RECEIVE_BOOT_COMPLETED` | 与源码声明的 5 项权限不同；详见 `PRIVACY.md` 第六节 |
| 网页内容 | WebView 开启 JavaScript，加载学校网站及其第三方资源 | 网站自身的脚本/统计由其隐私政策约束 |

更完整的用户侧说明见 [`PRIVACY.md`](PRIVACY.md)。

---

## 十、维护与核对方法

依赖或服务变更时，建议按以下步骤更新本清单：

1. 查看直接依赖与锁定版本：

   ```bash
   flutter pub deps --style=compact
   dart pub deps --json
   ```

2. 检查可升级版本：

   ```bash
   flutter pub outdated
   ```

3. 重新构建后核对合并权限：

   ```text
   build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
   ```

4. 在应用内打开“关于 → 开源许可”，核对 `showLicensePage` 汇总的包许可证。

5. 同步更新：
   - 本文件 `docs/SDK.md`；
   - [`PRIVACY.md`](PRIVACY.md) 的第三方处理者与权限表；
   - [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) 的素材/代码来源；
   - `pubspec.yaml` 中不再使用的依赖。

### 已知差异与待办

| 项目 | 说明 | 建议 |
| --- | --- | --- |
| Classy 声明过期 | `THIRD_PARTY_NOTICES.md`（截至 2026-11-01 快照）称未复制 Kotlin/Compose 代码，但 `lib/classy_parser.dart` 已是 `JwNewZfParser.kt` 的 Dart 移植 | 更新声明，注明 GPL-3.0 改编 |
| 文档许可证表述 | `DONATE.md` 提到“本项目 MIT 授权范围”，但与根 `LICENSE`（GPL-3.0）不一致 | 统一为 GPL-3.0 |
| 关于页文案 | “应用不收集、不上传课表与账号信息”过于笼统；通用网页导入会发送页面文本，上传流程会公开学校名+URL | 改为“不上传账号密码；部分导入功能会发送页面文本” |
| 未使用的依赖 | `package_info_plus`、`cupertino_icons` 已声明但未引用 | 移除，或注明保留原因 |
| “强 AI”开关 | `strong_ai` 设置可持久化，但当前没有 UI 路径把它传给导入页；应用请求体也未携带 `preferStrong`，边缘函数只配置 `glm-4-flash` | 移除该设置，或明确其效果 |
| `material_ui` 覆盖 | `dependency_overrides` 固定 1.3.0，仓库未注明原因 | 在构建说明中记录原因，避免后续升级踩坑 |
| 字体授权 | ✅ 已处理：正文改为 FandolFang（GPL-3.0 + 字体例外），西文改为 Liberation Serif（SIL OFL 1.1），Microsoft supplied 字体已从工作树移除 | 只需在发布时保留 `assets/fonts_ofl/` 下的许可文本 |
| 旧字体残留副本 | ✅ 已处理：`assets/_fangsong_cjk.ttf`、`assets/_times_latin.ttf` 已删除，仓库不再含旧字体数据 | `tool/merge_fangsong*.py`、`tool/font_wiring.py` 等历史一次性补丁脚本仍写着旧文件名（不参与构建、已不可运行），可按需归档删除 |
| 更新完整性 | APK 下载无哈希/签名校验 | 可考虑在 `version.json` 中提供 SHA-256，并在安装前校验 |

---

## 附录：按任务/功能划分的数据流速查

| 功能 | 主要依赖 / 服务 | 数据是否离开设备 |
| --- | --- | --- |
| 黄山学院原生同步 | `portal_client.dart`、`pointycastle`、WorkManager、`mwx/jwxt.hsu.edu.cn` | 学号/密码 → 黄山学院；课表结果留在本机 |
| 网页课表导入（Classy 本地解析成功并确认） | `webview_flutter`、`classy_parser.dart`、`generic_html_parser.dart` | 网页请求本身联网；解析不上传 |
| 网页课表导入（AI 回退） | `webview_flutter`、Cloudflare、智谱 | 页面文本 → Cloudflare → 智谱 |
| 导入流程上传 | `flow_upload_service.dart`、Cloudflare、GitHub | 学校名 + URL + 时间 + 版本 → 公开 PR |
| Google 日历（Android） | `CalendarContract` | 写入系统日历；账号同步由系统/Google 处理 |
| 日历导出（Windows） | `calendar_export.dart`、`share_plus`、`url_launcher` | ICS 交给用户选择的应用/Google |
| 桌面小组件 | `home_widget`、AppWidget | 仅本机 |
| 更新检查/下载 | `update_service.dart`、GitHub、jsDelivr、ghproxy | IP/UA；下载 APK |
| 学校列表/致谢 | `school_registry.dart`、`acknowledgements_service.dart`、jsDelivr/Raw | IP/UA/路径 |

---

**最后更新：2026-11-01** · 本清单随代码与依赖更新；如与 `pubspec.lock` 或应用内许可页不一致，以实际构建为准。
