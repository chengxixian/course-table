import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_meta.dart';
import 'schools.dart';

class SchoolRegistry {
  static final ValueNotifier<List<SchoolPreset>> schools = ValueNotifier<List<SchoolPreset>>(List.unmodifiable(kSchoolPresets));
  static bool _loaded = false;

  static Future<void> refresh() async {
    if (_loaded) return;
    const urls = [
      'https://cdn.jsdelivr.net/gh/chengxixian/course-table@main/schools/index.json',
      'https://fastly.jsdelivr.net/gh/chengxixian/course-table@main/schools/index.json',
      'https://raw.githubusercontent.com/chengxixian/course-table/main/schools/index.json',
    ];
    for (final url in urls) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      try {
        final req = await client.getUrl(Uri.parse(url));
        req.headers.set(HttpHeaders.userAgentHeader, 'course-table/${AppMeta.version}');
        final res = await req.close().timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) continue;
        final body = await res.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        final raw = data is Map ? data['schools'] : null;
        if (raw is! List) continue;
        final list = raw.whereType<Map>().map((m) {
          return SchoolPreset(
            name: (m['name'] ?? '').toString().trim(),
            loginUrl: (m['loginUrl'] ?? '').toString().trim(),
            native: m['native'] == true,
            note: (m['note'] ?? '').toString().trim(),
          );
        }).where((s) => s.name.isNotEmpty && s.loginUrl.isNotEmpty).toList();
        if (list.isEmpty) continue;
        final names = list.map((s) => s.name).toSet();
        if (!names.contains('黄山学院')) {
          list.insert(0, kSchoolPresets.first);
        }
        schools.value = List.unmodifiable(list);
        _loaded = true;
        return;
      } catch (_) {} finally {
        client.close(force: true);
      }
    }
  }
}
