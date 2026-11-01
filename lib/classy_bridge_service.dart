import 'package:flutter/services.dart';

import 'imported_source.dart';

/// Flutter side of the Classy Kotlin parser bridge.
class ClassyBridgeService {
  static const _channel = MethodChannel('com.hsu.hsu_schedule/classy_parser');

  static Future<ImportedSource?> parse({
    required String html,
    required String type,
    required String url,
    required Map<String, String> cookies,
  }) async {
    if (type.isEmpty || type == 'community' || type == 'native') return null;
    final raw = await _channel.invokeListMethod<dynamic>('parse', {'html': html, 'type': type});
    if (raw == null || raw.isEmpty) return null;
    final courses = raw.whereType<Map>().map((m) => m.cast<String, dynamic>()).where((m) {
      return (m['name']?.toString() ?? '').isNotEmpty &&
          (m['day'] as num?) != null &&
          (m['startPeriod'] as num?) != null;
    }).toList();
    if (courses.isEmpty) return null;
    return ImportedSource(url: url, cookies: cookies, html: _table(courses), savedAt: DateTime.now());
  }

  static String _table(List<Map<String, dynamic>> courses) {
    final maxPeriod = courses.map((c) => (c['endPeriod'] as num?)?.toInt() ?? 1).fold(1, (a, b) => a > b ? a : b).clamp(1, 20);
    final buffer = StringBuffer('<table><tr><th>节次</th>');
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    for (final d in days) {
      buffer.write('<th>$d</th>');
    }
    buffer.write('</tr>');
    for (var p = 1; p <= maxPeriod; p++) {
      buffer.write('<tr><td>第$p节</td>');
      for (var d = 1; d <= 7; d++) {
        buffer.write('<td>');
        final list = courses.where((c) => (c['day'] as num?)?.toInt() == d && (c['startPeriod'] as num?)?.toInt() == p);
        if (list.isNotEmpty) {
          buffer.write(list.map((c) {
            final name = c['name']?.toString() ?? '';
            final room = c['room']?.toString() ?? '';
            final teacher = c['teacher']?.toString() ?? '';
            final start = (c['startPeriod'] as num?)?.toInt() ?? p;
            final end = (c['endPeriod'] as num?)?.toInt() ?? start;
            final sw = (c['startWeek'] as num?)?.toInt() ?? 1;
            final ew = (c['endWeek'] as num?)?.toInt() ?? 20;
            final wt = (c['weekType'] as num?)?.toInt() ?? 0;
            final weeks = wt == 1 ? '$sw-$ew单周' : wt == 2 ? '$sw-$ew双周' : '$sw-$ew周';
            final parts = <String>[name];
            if (room.isNotEmpty) parts.add('@$room');
            parts.add('第$start-$end节');
            parts.add(weeks);
            if (teacher.isNotEmpty) parts.add('$teacher老师');
            return parts.map(_escape).join('<br>');
          }).join('<hr>'));
        }
        buffer.write('</td>');
      }
      buffer.write('</tr>');
    }
    buffer.write('</table>');
    return buffer.toString();
  }

  static String _escape(String value) => value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}
