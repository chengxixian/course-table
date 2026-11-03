# android-emulator/ — 用模拟器量真实帧时间

`lib/ui/frame_stats.dart` 打点只在真机或模拟器上出数字（widget test 里 `FrameTiming` 根本不产生）。这个目录把"从零到能出数字"的过程脚本化。

## 为什么用 ATD 镜像

用 `system-images;android-35;aosp_atd;x86_64`（ATD = Automated Test Device）：为自动化裁剪过，**启动约 30 秒**，没有 Play 服务，跑起来比标准镜像轻。它是 userdebug 镜像，`adb root` 可用——这点很关键，见下面的喂数据。

## 三步

```powershell
$env:ANDROID_HOME = "D:\tool\sdk"      # 或你自己的 SDK 路径
$env:JAVA_HOME     = "D:\tool\jdk"

# 1. 装 emulator + 镜像 + 建 AVD（幂等，已装会跳过）
powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\setup.ps1

# 2. 无窗口启动，等开机完成
powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\run.ps1

# 3. 装包并喂一份示意课表，然后量
powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\seed.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\android-emulator\measure.ps1 -Scenario all
```

`measure.ps1` 支持 `-Scenario week|popup|drag|all`、`-Repeat N`、`-Cold`（冷启动、不做预热）。坐标是屏幕比例，换 AVD 档位也能用。

## 喂数据这件事

App 第一次起来只有"还没有课表数据"的引导页，周视图是空的，没东西可拖。`seed.ps1` 的做法是直接写 SharedPreferences：

- `seed.mjs` 把 `demo-schedule.json` 转成 App 认识的 `RawScrape` JSON（`rawSchedule.kbList`，字段名沿用黄山学院门户的 `kcmc` / `xqj` / `jc` / `zcd` / `cdmc` / `xm`）；
- 包进 `<string name="flutter.raw_scrape">`，写成 `FlutterSharedPreferences.xml`（旧版 SharedPreferences API 在 Android 上用的就是这份 XML，key 带 `flutter.` 前缀）；
- `adb root` 后推进 `/data/data/<pkg>/shared_prefs/`，`chown` + `restorecon`，重启 App。

课程名、教师、教室都是虚构的示意数据，不含任何真实个人信息。

## 怎么读结果

App 在 debug/profile 构建里会把每个交互打一行：

```
course-drag: 47 frames  build p50 0.6 p95 0.9 max 3.5ms  raster p50 2.3 p95 3.6 max 4.0ms  jank 0/47 (0%, budget 16.7ms)
```

- **build 高** → 重建太多（`setState`、缺少 `const`、大子树被标记脏），改结构；
- **raster 高** → 画得太贵（阴影、模糊、裁剪、大图、shader），改画法；
- 两条线要分开优化，混在一起谈"卡"没有意义。

## 必须知道的边界

- **模拟器不是真机**：桌面 CPU + 宿主 GPU，没有温控降频，绝对值偏乐观。它适合做**相对比较和回归**（同一台模拟器、同一份 APK，改前改后对比可信），不适合拿来宣称"在手机上能跑多少帧"。
- **冷启动有一次性成本**：启动后第一次开弹层/切周会出现 30–40% 的掉帧，那是 Impeller 的 shader 编译和字形首次栅格化，预热之后就没了。`measure.ps1` 默认先做 warm-up 再测，就是为了不把它算进稳态数据；要看冷启动就加 `-Cold`。
- ATD 镜像没有 Play 服务。本项目不需要；将来要测推送、地图、Google 登录就得换 `google_apis` 镜像。
- 拖拽测试会把课块拖到别的格子并**持久化**，量完想恢复原状就重跑一次 `seed.ps1`。
