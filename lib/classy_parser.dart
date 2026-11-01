/*
 * Adapted from Classy (https://github.com/IMSX3D/Classy), commit 8a2499d.
 * Copyright (C) IMSX3D and contributors.
 * Licensed under GNU GPL v3.0; see LICENSE and NOTICE.
 * Modified for course-table integration.
 */
import 'dart:convert';

/// Minimal Dart port of Classy's zf_new parser.
/// Source: https://github.com/IMSX3D/Classy (GPL-3.0), JwNewZfParser.kt.
class ClassyParser {
  static String? parseToHtml(String html, String type) {
    if (!type.startsWith('zf')) return null;
    final courses = _parseZfNew(html);
    if (courses.isEmpty) return null;
    return _toTable(courses);
  }

  static List<_Course> _parseZfNew(String source) {
    final out = <_Course>[];
    for (final marker in ['"kbList"', '"xskbcx_json"', '"kbxx"']) {
      final start = _findJsonStart(source, marker);
      if (start == null) continue;
      final raw = _balanced(source, start);
      if (raw == null) continue;
      out.addAll(_coursesFromJson(raw));
      if (out.isNotEmpty) return out;
    }
    for (final name in ['kbList', 'xskbcx_json', 'kbxx']) {
      final idx = source.indexOf('var $name');
      if (idx < 0) continue;
      var p = idx + 'var $name'.length;
      while (p < source.length && source[p].trim().isEmpty) { p++; }
      if (p >= source.length || source[p] != '=') continue;
      p++;
      while (p < source.length && source[p].trim().isEmpty) { p++; }
      if (p >= source.length || (source[p] != '[' && source[p] != '{')) continue;
      final raw = _balanced(source, p);
      if (raw == null) continue;
      out.addAll(_coursesFromJson(raw));
      if (out.isNotEmpty) return out;
    }
    final trim = source.trim();
    if (trim.startsWith('{') || trim.startsWith('[')) {
      out.addAll(_coursesFromJson(trim));
    }
    return out;
  }

  static int? _findJsonStart(String s, String marker) {
    var from = 0;
    while (true) {
      final idx = s.indexOf(marker, from);
      if (idx < 0) return null;
      var p = idx + marker.length;
      while (p < s.length && s[p].trim().isEmpty) { p++; }
      if (p < s.length && s[p] == ':') {
        p++;
        while (p < s.length && s[p].trim().isEmpty) { p++; }
      }
      if (p < s.length && (s[p] == '[' || s[p] == '{')) return p;
      from = idx + 1;
    }
  }

  static String? _balanced(String s, int start) {
    if (start >= s.length) return null;
    final open = s[start];
    final close = open == '[' ? ']' : '}';
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < s.length; i++) {
      final c = s[i];
      if (escaped) { escaped = false; continue; }
      if (c == r'\') { escaped = true; continue; }
      if (c == '"') { inString = !inString; continue; }
      if (inString) continue;
      if (c == open) depth++;
      if (c == close) {
        depth--;
        if (depth == 0) return s.substring(start, i + 1);
      }
    }
    return null;
  }

  static List<_Course> _coursesFromJson(String raw) {
    try {
      dynamic data = jsonDecode(raw);
      dynamic list;
      if (data is List) {
        list = data;
      } else if (data is Map) {
        list = _findList(data);
      }
      if (list is! List) return const [];
      final out = <_Course>[];
      for (final item in list) {
        if (item is! Map) continue;
        if (item.containsKey('teaxms') || item.containsKey('jxcdmcs') || item.containsKey('jcdm2') || item.containsKey('zcs')) continue;
        final name = _first(item, ['kcmc', 'kcm', 'kc_mc', 'courseName', 'rlkcmc', 'jxbmc']);
        if (name.isEmpty) continue;
        final teacher = _first(item, ['xm', 'jsxm', 'teacher', 'attendClassTeacher', 'skjs']);
        final room = _first(item, ['cdmc', 'classroomName', 'jxcd', 'jsmc', 'jxlh', 'jasdm']);
        final day = _day(item);
        if (day == null) continue;
        final jc = _first(item, ['jcs', 'jc', 'classSessions', 'ksjcsd', 'ksjc']);
        if (jc.isEmpty) continue;
        final weeks = _first(item, ['zcd', 'kkzc', 'zc', 'classWeek', 'skzc']);
        for (final node in _sections(jc)) {
          out.add(_Course(name, teacher, room, day, node.$1, node.$2, weeks));
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static dynamic _findList(Map obj, [int depth = 0]) {
    if (depth > 4) return null;
    for (final key in ['kbList', 'kbxx', 'tmp_list']) {
      if (obj[key] is List) return obj[key];
    }
    for (final value in obj.values) {
      if (value is Map) {
        final found = _findList(value, depth + 1);
        if (found != null) return found;
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final found = _findList(item, depth + 1);
            if (found != null) return found;
          }
        }
      }
    }
    return null;
  }

  static String _first(Map m, List<String> keys) {
    for (final key in keys) {
      final value = m[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
    }
    return '';
  }

  static int? _day(Map m) {
    for (final key in ['xqj', 'kcxq', 'xq', 'classDay', 'skxq']) {
      final n = int.tryParse('${m[key] ?? ''}');
      if (n != null && n >= 1 && n <= 7) return n;
    }
    final text = '${m['xqjmc'] ?? ''}'.trim();
    const map = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7};
    for (final e in map.entries) {
      if (text.contains(e.key)) return e.value;
    }
    return null;
  }

  static List<(int, int)> _sections(String input) {
    final out = <(int, int)>[];
    for (final segment in input.split(RegExp(r'[,，;；]'))) {
      var t = segment.trim().replaceAll(RegExp(r'节$'), '').trim();
      if (t.isEmpty) continue;
      if (t.contains('-')) {
        final parts = t.split('-');
        final a = int.tryParse(parts.first.trim());
        final b = int.tryParse(parts.last.trim());
        if (a != null && b != null && a >= 1 && b <= 16) out.add((a, b));
        continue;
      }
      final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) continue;
      if (digits.length >= 2 && digits.length.isEven && digits.startsWith('0')) {
        final nums = <int>[];
        for (var i = 0; i + 1 < digits.length; i += 2) {
          final n = int.tryParse(digits.substring(i, i + 2));
          if (n == null || n < 1 || n > 16) break;
          nums.add(n);
        }
        for (var i = 0; i + 1 < nums.length; i += 2) {
          out.add((nums[i], nums[i + 1]));
        }
      } else {
        final n = int.tryParse(digits);
        if (n != null && n >= 1 && n <= 16) out.add((n, n));
      }
    }
    return out;
  }

  static String _toTable(List<_Course> courses) {
    final max = courses.map((c) => c.end).fold(1, (a, b) => a > b ? a : b).clamp(1, 20);
    final b = StringBuffer('<table><tr><th>节次</th>');
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    for (final d in days) { b.write('<th>$d</th>'); }
    b.write('</tr>');
    for (var p = 1; p <= max; p++) {
      b.write('<tr><td>第$p节</td>');
      for (var d = 1; d <= 7; d++) {
        b.write('<td>');
        final list = courses.where((c) => c.day == d && c.start == p).toList();
        if (list.isNotEmpty) {
          b.write(list.map((c) {
            final parts = <String>[c.name];
            if (c.room.isNotEmpty) parts.add('@${c.room}');
            parts.add('第${c.start}-${c.end}节');
            if (c.weeks.isNotEmpty) parts.add('${c.weeks}周');
            if (c.teacher.isNotEmpty) parts.add('${c.teacher}老师');
            return parts.map(_escape).join('<br>');
          }).join('<hr>'));
        }
        b.write('</td>');
      }
      b.write('</tr>');
    }
    b.write('</table>');
    return b.toString();
  }

  static String _escape(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

class _Course {
  final String name, teacher, room, weeks;
  final int day, start, end;
  const _Course(this.name, this.teacher, this.room, this.day, this.start, this.end, this.weeks);
}
