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
    for (final url in [AppMeta.versionUrl, AppMeta.versionUrlFastly, AppMeta.versionUrlGcore, AppMeta.versionUrlFallback, AppMeta.versionUrlMirror]) {
      try {
        final body = await _get(url);
        final data = jsonDecode(body) as Map<String, dynamic>;
        final version = data['version']?.toString() ?? '';
        final build = (data['build'] as num?)?.toInt() ?? 0;
        final notes = data['notes']?.toString() ?? '';
        final apk = data['apk']?.toString() ?? '${AppMeta.releasesUrl}/latest';
        final page = data['page']?.toString() ?? AppMeta.releasesUrl;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
        if (_isNewer(version, build)) {
          return UpdateInfo(version: version, build: build, notes: notes, apkUrl: apk, pageUrl: page);
        }
        return null;
      } catch (e) {
        lastError = e;
      }
    }
    debugPrint('update check failed: $lastError');
    throw UpdateCheckException('无法连接更新服务器，请检查网络后重试');
  }

  static Future<String> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'course-table-updater/2.0');
      final response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
      final body = await response.transform(utf8.decoder).join();
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

  static Future<void> showDialogFor(BuildContext context, UpdateInfo info) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('发现新版本 ${info.version}'),
        content: SingleChildScrollView(
          child: Text(info.notes.isEmpty ? '修复问题并改进体验。' : info.notes, style: const TextStyle(height: 1.5)),
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

  static const _mirrors = <String>[
    'https://ghproxy.net/',
    'https://gh-proxy.com/',
    'https://mirror.ghproxy.com/',
    'https://github.moeyy.xyz/',
  ];

  static Future<void> _downloadAndInstall(BuildContext context, UpdateInfo info) async {
    final progress = ValueNotifier<double>(0);
    var dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('正在下载 ${info.version}'),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (_, value, __) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            LinearProgressIndicator(value: value <= 0 ? null : value, minHeight: 6),
            const SizedBox(height: 10),
            Text(value <= 0 ? '正在连接下载源…' : '${(value * 100).toStringAsFixed(0)}% · GitHub 源失败会自动切换镜像', style: const TextStyle(fontSize: 11)),
          ]),
        ),
      ),
    );
    try {
      final file = await _downloadApk(info, progress);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      await const MethodChannel('com.hsu.hsu_schedule/install').invokeMethod('installApk', {'path': file.path});
    } on PlatformException catch (e) {
      if (dialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? '无法启动安装器')));
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
          content: Text('$e\n\n可以改用浏览器打开下载页。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('打开下载页')),
          ],
        ),
      );
      if (fallback == true) {
        await launchUrl(Uri.parse(info.pageUrl), mode: LaunchMode.externalApplication);
      }
    } finally {
      progress.dispose();
    }
  }

  static Future<File> _downloadApk(UpdateInfo info, ValueNotifier<double> progress) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/course-table-${info.version}.apk');
    if (await file.exists()) await file.delete();
    final urls = <String>[info.apkUrl];
    for (final mirror in _mirrors) {
      if (!info.apkUrl.startsWith(mirror)) urls.add('$mirror${info.apkUrl}');
    }
    Object? lastError;
    for (final url in urls) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
      try {
        final request = await client.getUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.userAgentHeader, 'course-table-updater/2.0');
        final response = await request.close().timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
        final total = response.contentLength;
        final sink = file.openWrite();
        var received = 0;
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) progress.value = (received / total).clamp(0.0, 1.0);
        }
        await sink.close();
        final length = await file.length();
        if (length < 1024 * 1024) throw const FormatException('安装包大小异常');
        progress.value = 1;
        return file;
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
    final info = await check();
    if (info == null || !context.mounted) return;
    await showDialogFor(context, info);
  }
}
