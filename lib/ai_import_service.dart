import 'dart:convert';
import 'dart:io';

import 'app_meta.dart';
import 'imported_source.dart';

class AiImportService {
  static Future<ImportedSource> parse({
    required String text,
    required String url,
    required Map<String, String> cookies,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(AppMeta.aiParseUrl));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'text': text.length > 30000 ? text.substring(0, 30000) : text}));
      final response = await request.close().timeout(const Duration(seconds: 90));
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('AI 识别失败：${_error(body)}');
      }
      final data = jsonDecode(body);
      final rawCourses = data is Map ? data['courses'] : null;
      if (rawCourses is! List || rawCourses.isEmpty) {
        throw StateError('AI 没有识别到课程，请确认页面显示了完整课表');
      }
      final courses = rawCourses.whereType<Map>().map((m) => _AiCourse.fromJson(m.cast<String, dynamic>())).where((c) => c.name.isNotEmpty && c.day >= 1 && c.day <= 7 && c.startPeriod >= 1).toList();
      if (courses.isEmpty) throw StateError('AI 返回的课程不完整');
      final html = _buildTable(courses);
      return ImportedSource(url: url, cookies: cookies, html: html, savedAt: DateTime.now());
    } finally {
      client.close(force: true);
    }
  }

  static String _error(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) return (data['error'] ?? data['detail'] ?? '未知错误').toString();
    } catch (_) {}
    return body.length > 160 ? body.substring(0, 160) : body;
  }

  static String _buildTable(List<_AiCourse> courses) {
    final maxPeriod = courses.map((c) => c.endPeriod).fold(1, (a, b) => a > b ? a : b).clamp(1, 20);
    final buffer = StringBuffer('<table><tr><th>节次</th>');
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    for (final d in days) {
      buffer.write('<th>$d</th>');
    }
    buffer.write('</tr>');
    for (var p = 1; p <= maxPeriod; p++) {
      buffer.write('<tr><td>第$p节</td>');
      for (var day = 1; day <= 7; day++) {
        final inCell = courses.where((c) => c.day == day && c.startPeriod == p).toList();
        buffer.write('<td>');
        if (inCell.isNotEmpty) {
          buffer.write(inCell.map((c) {
            final parts = <String>[c.name];
            if (c.room.isNotEmpty) parts.add('@${c.room}');
            if (c.start.isNotEmpty && c.end.isNotEmpty) parts.add('${c.start}-${c.end}');
            parts.add('第${c.startPeriod}-${c.endPeriod}节');
            if (c.weeks.isNotEmpty) parts.add('${c.weeks}周');
            if (c.teacher.isNotEmpty) parts.add('${c.teacher}老师');
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

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

class _AiCourse {
  final String name, teacher, room, start, end, weeks;
  final int day, startPeriod, endPeriod;
  const _AiCourse(this.name, this.teacher, this.room, this.day, this.startPeriod, this.endPeriod, this.start, this.end, this.weeks);
  factory _AiCourse.fromJson(Map<String, dynamic> json) => _AiCourse(
        (json['name'] ?? '').toString().trim(),
        (json['teacher'] ?? '').toString().trim(),
        (json['room'] ?? '').toString().trim(),
        int.tryParse('${json['day'] ?? ''}') ?? 0,
        int.tryParse('${json['startPeriod'] ?? ''}') ?? 0,
        int.tryParse('${json['endPeriod'] ?? ''}') ?? 0,
        (json['start'] ?? '').toString().trim(),
        (json['end'] ?? '').toString().trim(),
        (json['weeks'] ?? '').toString().trim(),
      );
}
