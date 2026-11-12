| 严重度 | 文件:行号 | 一句话问题 | 触发场景 |
|---|---|---|---|
| Crash | `lib/app_controller.dart:101` | `WorkScheduler.scheduleDaily(settings)` 前没有调用 `WorkScheduler.initialize(callbackDispatcher)`，WorkManager 未初始化时注册定时任务会抛异常 | Android 首次启动、`settings.autoSync=true`，且外部未提前初始化 WorkManager |
| 卡死 | `lib/update_service.dart:132` | `_get()` 只对 `request.close()` 加 12 秒超时，后续 `response.transform(utf8.decoder).join()` 没有超时 | 服务器连接成功但响应体传输极慢或挂起时，更新检查永久等待 |
| 卡死 | `lib/update_service.dart:226` | `_downloadApk()` 只对 `request.close()` 加 20 秒超时，后续 `await for (final chunk in response)` 没有超时 | APK 下载中途服务器挂起时，下载对话框一直显示且无法取消 |
| Crash | `lib/update_service.dart:182` | `_downloadAndInstall()` 下载成功后先 `Navigator.pop()`，再调用安装 MethodChannel；若安装抛非 `PlatformException` 异常，后续 fallback dialog 可能再次使用已关闭的 `context` | 下载成功但安装器抛普通异常，且 dialog 已关闭、页面已切换 |
| 轻微 | `lib/update_service.dart:182` | `_downloadAndInstall()` 下载成功后若 `context.mounted` 为 false，不会关闭下载 dialog，但随后仍继续调用安装 | 下载期间页面被销毁，dialog 可能残留 |
| 轻微 | `lib/update_service.dart:190` | `PlatformException` 分支中先关闭 dialog，再检查 `context.mounted`；若 context 已失效仍尝试 `ScaffoldMessenger.of(context)` 前已有 `context.mounted` 检查，但逻辑顺序依赖 dialogOpen 状态 | 下载失败同时页面被销毁 |
| 轻微 | `lib/update_service.dart:203` | 下载失败 fallback dialog 使用 `context` 跨 await 后未再次检查 `context.mounted` | 下载失败后用户切换页面，fallback dialog 打开时 context 已失效 |
| 轻微 | `lib/update_service.dart:212` | fallback dialog 返回后直接 `launchUrl()`，没有检查 `context.mounted` | 用户在 fallback dialog 期间页面被销毁 |
| 轻微 | `lib/update_service.dart:218` | `maybeCheck()` 中 `await check()` 后只检查一次 `context.mounted`，但 `showDialogFor()` 内部还会跨 await 使用 context | 更新检查期间页面被销毁，后续 dialog 或下载可能使用失效 context |
| 轻微 | `lib/update_service.dart: