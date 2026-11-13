import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_meta.dart';

class UpdateInfo {
  final String version;
  final int build;
  final String notes;
  final String apkUrl;
  final String pageUrl;
  const UpdateInfo({
    required this.version,
    required this.build,
    required this.notes,
    required this.apkUrl,
    required this.pageUrl,
  });
}

class UpdateCheckException implements Exception {
  final String message;
  const UpdateCheckException(this.message);
  @override
  String toString() => message;
}

class UpdateService {
  static const _lastCheckKey = 'last_update_check';

  static Future<UpdateInfo?> check({bool force = false}) async {
    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final last = DateTime.tryParse(prefs.getString(_lastCheckKey) ?? '');
      if (last != null && DateTime.now().difference(last) < const Duration(hours: 20)) {
        return null;
      }
    }
    Object? lastError;
    try {
      final body = await _get(AppMeta.versionApiUrl);
      final data = jsonDecode(body) as Map<String, dynamic>;
      final tag = data['tag_name']?.toString() ?? '';
      final version = tag.replaceFirst(RegExp(r'^v'), '');
      if (version.isNotEmpty) {
        final assets = data['assets'];
        String apk = '${AppMeta.releasesUrl}/latest';
        String page = data['html_url']?.toString() ?? AppMeta.releasesUrl;
        if (assets is List) {
          for (final a in assets) {
            if (a is Map && a['name']?.toString() == 'course-table.apk') {
              apk = a['browser_download_url']?.toString() ?? apk;
            }
          }
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
        if (_isNewer(version, 0)) {
          return UpdateInfo(
            version: version,
            build: 0,
            notes: data['body']?.toString() ?? '',
            apkUrl: apk,
            pageUrl: page,
          );
        }
        return null;
      }
    } catch (e) {
      lastError = e;
    }
    // Collect from every manifest source and take the newest answer.
    // A single stale CDN must not mask a newer version: jsdelivr keys its
    // branch cache by path and ignores query strings, so the `?t=` buster does
    // not force it fresh — a poisoned edge can serve an old snapshot for
    // hours, which is exactly how a 3.1.6 install was told 3.1.5 was latest.
    // raw.githubusercontent (5-minute TTL) leads the list; the rest are
    // CN-reachable fallbacks.
    String? bestVersion;
    int bestBuild = 0;
    String bestNotes = '';
    String bestApk = '${AppMeta.releasesUrl}/latest';
    String bestPage = AppMeta.releasesUrl;
    var anySuccess = false;
    for (final url in [AppMeta.versionUrlFallback, AppMeta.versionUrl, AppMeta.versionUrlFastly, AppMeta.versionUrlGcore, AppMeta.versionUrlMirror]) {
      try {
        final body = await _get(url);
        final data = jsonDecode(body) as Map<String, dynamic>;
        final version = data['version']?.toString() ?? '';
        if (version.isEmpty) continue;
        anySuccess = true;
        final build = (data['build'] as num?)?.toInt() ?? 0;
        if (_versionIsNewer(version, build, bestVersion, bestBuild)) {
          bestVersion = version;
          bestBuild = build;
          bestNotes = data['notes']?.toString() ?? '';
          bestApk = data['apk']?.toString() ?? bestApk;
          bestPage = data['page']?.toString() ?? bestPage;
        }
      } catch (e) {
        lastError = e;
      }
    }
    if (anySuccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
      if (bestVersion != null && _isNewer(bestVersion, bestBuild)) {
        return UpdateInfo(version: bestVersion, build: bestBuild, notes: bestNotes, apkUrl: bestApk, pageUrl: bestPage);
      }
      return null;
    }
    debugPrint('update check failed: $lastError');
    throw UpdateCheckException('无法连接更新服务器，请检查网络后重试');
  }

  /// Semver-ish compare used to pick the freshest manifest across sources.
  static bool _versionIsNewer(String version, int build, String? than, int thanBuild) {
    if (than == null) return true;
    final a = version.replaceAll('v', '').split('.').map((e) => int.tryParse(e.split('-').first) ?? 0).toList();
    final b = than.replaceAll('v', '').split('.').map((e) => int.tryParse(e.split('-').first) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return build > thanBuild;
  }

  static Future<String> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'course-table-updater/2.0');
      final response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
      // The body read needs its own deadline: a server that sends headers and
      // then stalls would otherwise hang the update check forever.
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 20));
      if (body.length > 1024 * 1024) throw const FormatException('version file too large');
      return body;
    } finally {
      client.close(force: true);
    }
  }

  static bool _isNewer(String version, int build) {
    final latest = version.replaceAll('v', '').split('.').map((e) => int.tryParse(e.split('-').first) ?? 0).toList();
    final current = AppMeta.version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final a = i < latest.length ? latest[i] : 0;
      final b = i < current.length ? current[i] : 0;
      if (a != b) return a > b;
    }
    return build > AppMeta.build;
  }

  /// Release bodies are Markdown; the dialog renders plain Text, so strip the
  /// markers instead of showing `##`/`**` to users.
  static String _plainNotes(String notes) {
    if (notes.isEmpty) return '修复问题并改进体验。';
    final lines = notes.split('\n').map((line) {
      var l = line.trimRight();
      l = l.replaceAll(RegExp(r'^#+\s*'), '').replaceAll('**', '');
      l = l.replaceAll('`', '');
      l = l.replaceFirst(RegExp(r'^[-*]\s+'), '• ');
      return l;
    }).where((l) => l.trim().isNotEmpty && !l.trim().startsWith('>')).join('\n');
    return lines;
  }

  static String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('Failed host lookup')) return '域名解析失败：请检查网络后重试（GitHub 与镜像均无法解析）';
    if (s.contains('Connection timed out') || s.contains('timed out')) return '下载超时：网络不稳定，建议稍后重试或用浏览器打开下载页';
    if (s.contains('SocketException')) return '网络连接中断：请检查网络后重试';
    return s.replaceFirst('Bad state: ', '').replaceFirst('Exception: ', '');
  }

  static Future<void> showDialogFor(BuildContext context, UpdateInfo info) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('发现新版本 ${info.version}'),
        content: SingleChildScrollView(
          child: Text(_plainNotes(info.notes), style: const TextStyle(height: 1.5)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('稍后')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(Platform.isAndroid ? '下载更新' : '前往下载'),
          ),
        ],
      ),
    );
    if (open != true) return;
    if (Platform.isAndroid) {
      await _downloadAndInstall(context, info);
      return;
    }
    final uri = Uri.parse(info.pageUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final mirror = Uri.parse('https://ghproxy.net/${info.pageUrl}');
      await launchUrl(mirror, mode: LaunchMode.externalApplication);
    }
  }

  // Ordered by measured throughput from CN mobile networks (2026-11):
  // gh-proxy.com ~900KB/s, ghfast.top ~430KB/s, ghproxy.net ~30KB/s.
  // mirror.ghproxy.com / github.moeyy.xyz / gh.llkk.cc were dead at test time.
  static const _mirrors = <String>[
    'https://gh-proxy.com/',
    'https://ghfast.top/',
    'https://ghproxy.net/',
  ];

  static Future<void> _downloadAndInstall(BuildContext context, UpdateInfo info) async {
    final progress = ValueNotifier<double>(0);
    final cancel = ValueNotifier(false);
    var dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('正在下载 ${info.version}'),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, value, __) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            LinearProgressIndicator(value: value <= 0 ? null : value, minHeight: 6),
            const SizedBox(height: 10),
            Text(value <= 0 ? '正在连接下载源…' : '${(value * 100).toStringAsFixed(0)}% · GitHub 源失败会自动切换镜像', style: const TextStyle(fontSize: 11)),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cancel.value = true;
              dialogOpen = false;
              Navigator.pop(dialogContext);
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
    try {
      final file = await _downloadApk(info, progress, cancel);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      final launched = await const MethodChannel('com.hsu.hsu_schedule/install').invokeMethod<bool>('installApk', {'path': file.path});
      if (launched == false && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下载完成；回到前台会自动打开安装器')));
      }
    } on PlatformException catch (e) {
      if (dialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? '无法启动安装器')));
    } on _DownloadCancelled {
      // User pressed 取消; the dialog closed itself. No failure UI.
    } catch (e) {
      if (dialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      if (!context.mounted) return;
      final fallback = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('下载失败'),
          content: Text('${_friendlyError(e)}\n\n可以改用浏览器打开下载页。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('打开下载页')),
          ],
        ),
      );
      if (fallback == true && context.mounted) {
        await launchUrl(Uri.parse(info.pageUrl), mode: LaunchMode.externalApplication);
      }
    } finally {
      progress.dispose();
      cancel.dispose();
    }
  }

  static Future<File> _downloadApk(UpdateInfo info, ValueNotifier<double> progress, ValueNotifier<bool> cancel) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/course-table-${info.version}.apk');
    if (await file.exists()) await file.delete();
    // Normalize: version.json may already hand us a mirror URL; strip known
    // prefixes so fallback variants are built from the canonical GitHub URL.
    var canonical = info.apkUrl;
    for (final m in _mirrors) {
      if (canonical.startsWith(m)) canonical = canonical.substring(m.length);
    }
    final urls = <String>[info.apkUrl];
    for (final mirror in _mirrors) {
      final variant = '$mirror$canonical';
      if (!urls.contains(variant)) urls.add(variant);
    }
    Object? lastError;
    for (final url in urls) {
      if (cancel.value) throw const _DownloadCancelled();
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      try {
        final request = await client.getUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.userAgentHeader, 'course-table-updater/2.0');
        final response = await request.close().timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
        final total = response.contentLength;
        final sink = file.openWrite();
        var received = 0;
        // Two fallback triggers, because a slow-but-alive connection never
        // hits the idle timeout: GitHub direct trickles ~85KB/s on CN mobile
        // (81MB in 16 minutes) while gh-proxy.com delivers ~900KB/s. The
        // watchdog aborts any source that has not moved 1.5MB within 20s.
        final watch = Stopwatch()..start();
        // Stream.timeout fires between chunks, not on the total: a stalled
        // connection aborts after 30s of silence and falls through to the next
        // mirror, while a slow-but-alive download continues indefinitely.
        // Without this the download dialog hung forever with no cancel path.
        await for (final chunk in response.timeout(const Duration(seconds: 30))) {
          if (cancel.value) {
            await sink.flush();
            await sink.close();
            throw const _DownloadCancelled();
          }
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) progress.value = (received / total).clamp(0.0, 1.0);
          if (watch.elapsed.inSeconds > 20 && received < 1500000) {
            await sink.flush();
            await sink.close();
            throw TimeoutException('源速度过慢，已切换');
          }
        }
        await sink.close();
        final length = await file.length();
        if (length < 1024 * 1024) throw const FormatException('安装包大小异常');
        progress.value = 1;
        return file;
      } on _DownloadCancelled {
        if (await file.exists()) await file.delete();
        rethrow;
      } catch (e) {
        lastError = e;
        if (await file.exists()) await file.delete();
      } finally {
        client.close(force: true);
      }
    }
    throw StateError('所有下载源均失败：$lastError');
  }

  static Future<void> maybeCheck(BuildContext context) async {
    // Startup check must never crash the app: every source timing out is a
    // normal outcome on flaky CN networks, and check() signals that with a
    // StateError. Manual checks (About page) surface the error to the user.
    UpdateInfo? info;
    try {
      info = await check();
    } catch (_) {
      return;
    }
    if (info == null || !context.mounted) return;
    await showDialogFor(context, info);
  }
}

/// Thrown internally when the user cancels the download dialog; distinct from
/// network failures so the catch chain can stay silent instead of showing the
/// "下载失败" fallback.
class _DownloadCancelled implements Exception {
  const _DownloadCancelled();
}
