<div align="center">

<img src="assets/icon.png" width="88" alt="课程表图标" />

# 课程表

**Material 3 课程表 · Android**

为黄山学院打造，也支持网页导入、文件导入与 AI 兜底适配其他学校。

[![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Material 3](https://img.shields.io/badge/Material%203-Expressive-6750A4?logo=materialdesign&logoColor=white)](https://m3.material.io)
[![Android](https://img.shields.io/badge/Android-8.0%2B-3DDC84?logo=android&logoColor=white)](https://www.android.com)
[![License](https://img.shields.io/badge/License-GPL--3.0-0B57D0.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/chengxixian/course-table?label=下载&color=0B57D0)](https://github.com/chengxixian/course-table/releases/latest)

**一次同步，整学期课表；一次导入，全部课程进系统日历。**

[下载 APK](https://github.com/chengxixian/course-table/releases/latest) · [更新记录](https://github.com/chengxixian/course-table/releases) · [问题反馈](https://github.com/chengxixian/course-table/issues) · [隐私政策](docs/PRIVACY.md) · [SDK 清单](docs/SDK.md)

</div>

---

## 功能

| 功能 | 说明 |
|---|---|
| **黄山学院原生同步** | 信息门户登录，抓取课程、教师、教室、周次、调课与冲突；整学期一次同步 |
| **350 所高校预设** | 学校库可搜索；黄山学院保留原生流程，其他学校打开对应登录页 |
| **网页导入** | 应用内 WebView 登录并操作到课表页，读取 HTML 导入 |
| **AI 兜底** | 本地解析缺字段时，发送脱敏页面文本到 Cloudflare Pages，再调用智谱 `glm-4-flash` |
| **文件导入** | ICS / CSV / 纯文本 / Excel / PDF / 手动添加；Excel 和 PDF 先转文字再解析 |
| **整学期** | 网页导入会尝试自动翻周、采集并合并整学期 |
| **系统日历** | 列出设备上所有可写日历（Google、华为、小米、Outlook、本地等），选择后一键写入整学期 |
| **桌面小组件** | 4×3 今日、2×2 今日·小、4×2 两日、4×4 本周 |
| **手动编辑** | 手动添加课程；长按课程拖动到目标星期/节次，松手先写数据再吸附 |
| **外观** | Material 3、动态取色、多套配色、仿宋/Times 风格开源字体、像素字体可选 |
| **自动更新** | GitHub Releases API / jsDelivr 多源检查；App 内下载，失败自动切镜像 |

---

## 导入说明

### 已适配高校

- **黄山学院**：点击进入原生门户登录，走原生同步，不经过通用解析
- 其他预设学校：打开对应登录页，使用网页/AI 导入
- 设置页可按学校名、别名搜索

### 未适配高校

1. 输入学校课表网页完整地址
2. 在应用内登录并操作到课表页
3. 点「读取当前页面并导入」
4. 本地解析优先；失败或缺字段时 AI 兜底
5. AI 自动判断「下一周」控件，逐周采集并合并
6. 导入成功后可选择是否上传学校名/网址，由维护者审核

### 文件导入

**设置 → 文件导入课表**

- **ICS**：日历事件文本
- **CSV**：逗号分隔表格
- **Excel**：`.xlsx` / `.xls`
- **PDF**：先用 Android PDFBox 提取文字；扫描图片版不支持
- **纯文本**：粘贴课表文字
- **手动**：表单录入课程、星期、节次、周次

文件和原始内容不会上传；AI 只接收解析所需的文本。

### AI 边界

- 服务端固定模型：**GLM-4-Flash**
- Key 只在 Cloudflare Pages 环境变量，不进 APK
- 缺教室、缺时间、周次异常的结果拒绝导入
- 页面没有可点击的「下一周」控件、Canvas 课表或加密接口时，无法自动翻周
- Classy 的 Kotlin 解析器目前只移植了 `zf_new`，其他类型仍走通用网页/AI

---

## 小组件

| 尺寸 | 内容 |
|---|---|
| **4×3** | 今日课程（仅上午） |
| **2×2** | 今日 3 节 + 日期 |
| **4×2** | 今天 / 明天两列 |
| **4×4** | 周一至周五周课表网格 |

字体跟随 App 设置；深色模式使用独立 `layout-night`。已放置的旧尺寸小组件需要删除后重新添加。

---

## 下载

- [最新 Release](https://github.com/chengxixian/course-table/releases/latest)
- Android 8.0+
- 首次安装不预置任何学号或课表
- 赞赏二维码只在应用内「关于」页展示

## 构建

```bash
flutter pub get
flutter build apk --release
```

技术栈：

`Flutter 3.47` · `Dart 3.13` · `Material 3` · `dynamic_color` · `home_widget` · `workmanager` · `webview_flutter` · `m3e_core` · `flutoryx` · `PDFBox-Android`

## 目录

```text
lib/
  ui/                         Material 3 页面、拖动与动效
  schedule_overlays.dart      手动课程 / 移动覆盖的纯函数合成
  classy_parser.dart          Classy zf_new 解析器 Dart 移植
  generic_html_parser.dart    通用网页课表解析
  file_import_service.dart    ICS/CSV/Excel/PDF/文本导入
  ai_import_service.dart      AI 解析兜底
  ai_nav_service.dart         AI 周次导航
  update_service.dart         多源更新 + App 内下载
  sync_service.dart           教务同步 + 小组件
android/                      原生小组件、系统日历、PDFBox、FileProvider
cloudflare/flow-pages/        Pages 中转（流程上传 / AI）
docs/                         隐私政策、SDK、架构与任务计划
```

## 隐私

- 不收集、不上传课表、账号或使用数据
- 登录凭据本机加密保存；网页导入保存地址与 Cookie
- AI 导入会发送排版文本到 Cloudflare，再转交智谱；不发送 Cookie/密码
- 上传流程会公开学校名与课表网址，请勿上传含会话令牌的地址
- 详见 [隐私政策](docs/PRIVACY.md) 与 [SDK 清单](docs/SDK.md)

## 已知限制

- 扫描版 PDF 无法提取文字
- 部分学校教务系统仅校园网/VPN 可访问
- 文件导入依赖 AI，不是完全离线
- Classy 解析器覆盖不完整
- APK 更新是 App 内下载后交给系统安装器，不是静默安装

## 致谢

感谢 **茨畔耕夫**、**润泽江海**、**Yearn Justly**、**曼你个der啊** 对项目的帮助与支持。

学校预设数据来自 [Classy](https://github.com/IMSX3D/Classy)（GPL-3.0）；`zf_new` 解析器已移植为 Dart。名单由 [`acknowledgements.json`](acknowledgements.json) 动态维护。

也感谢 Flutter、Material 3、`dynamic_color`、`home_widget`、`webview_flutter`、`m3e_core`、`flutoryx`、PDFBox 及所有开源作者。

## 许可

源代码以 [GNU General Public License v3.0](LICENSE) 发布，Copyright (C) 2026 chengxixian。

字体使用 **FandolFang**（GPL-3.0 + 字体例外）与 **Liberation Serif**（SIL OFL 1.1）；赞赏二维码属于作者个人标识，不随 GPL-3.0 源代码许可授权。第三方说明见 [docs/THIRD_PARTY_NOTICES.md](docs/THIRD_PARTY_NOTICES.md)。

> 非官方个人工具，与黄山学院无隶属关系。
