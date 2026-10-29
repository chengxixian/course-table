import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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
    for (final url in [AppMeta.versionUrl, AppMeta.versionUrlFallback, AppMeta.versionUrlMirror]) {
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
    return null;
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
    final target = Platform.isAndroid ? info.apkUrl : info.pageUrl;
    final uri = Uri.parse(target);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final mirror = Uri.parse('https://ghproxy.net/$target');
      await launchUrl(mirror, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> maybeCheck(BuildContext context) async {
    final info = await check();
    if (info == null || !context.mounted) return;
    await showDialogFor(context, info);
  }
}
