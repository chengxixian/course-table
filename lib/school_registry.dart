import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_meta.dart';
import 'schools.dart';

class SchoolRegistry {
  static final ValueNotifier<List<SchoolPreset>> schools = ValueNotifier<List<SchoolPreset>>(List.unmodifiable(kSchoolPresets));
  static bool _localLoaded = false;
  static bool _remoteLoaded = false;

  static Future<void> refresh() async {
    if (!_localLoaded) {
      _localLoaded = true;
      try {
        final body = await rootBundle.loadString('assets/schools.json');
        final list = _parse(body);
        if (list != null && list.isNotEmpty) {
          schools.value = List.unmodifiable(list);
        }
      } catch (_) {}
    }
    if (_remoteLoaded) return;
    const urls = [
      'https://cdn.jsdelivr.net/gh/chengxixian/course-table@main/schools/index.json?v=350',
      'https://fastly.jsdelivr.net/gh/chengxixian/course-table@main/schools/index.json?v=350',
      'https://raw.githubusercontent.com/chengxixian/course-table/main/schools/index.json?v=350',
    ];
    for (final url in urls) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      try {
        final req = await client.getUrl(Uri.parse(url));
        req.headers.set(HttpHeaders.userAgentHeader, 'course-table/${AppMeta.version}');
        final res = await req.close().timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;
        final body = await res.transform(utf8.decoder).join();
        final list = _parse(body);
        if (list == null || list.isEmpty) continue;
        if (list.length < schools.value.length) continue;
        schools.value = List.unmodifiable(list);
        _remoteLoaded = true;
        return;
      } catch (_) {} finally {
        client.close(force: true);
      }
    }
  }

  static List<SchoolPreset>? _parse(String body) {
    try {
      final data = jsonDecode(body);
      final raw = data is Map ? data['schools'] : null;
      if (raw is! List) return null;
      final list = raw.whereType<Map>().map((m) {
        return SchoolPreset(
          name: (m['name'] ?? '').toString().trim(),
          loginUrl: (m['loginUrl'] ?? '').toString().trim(),
          native: m['native'] == true,
          note: (m['note'] ?? '').toString().trim(),
          aliases: (m['aliases'] is List) ? (m['aliases'] as List).map((e) => e.toString()).toList() : const [],
          type: (m['type'] ?? '').toString(),
        );
      }).where((s) => s.name.isNotEmpty && s.loginUrl.isNotEmpty).toList();
      if (list.isEmpty) return null;
      final hsu = kSchoolPresets.first;
      list.removeWhere((s) => s.name == hsu.name);
      list.insert(0, hsu);
      return list;
    } catch (_) {
      return null;
    }
  }
}
