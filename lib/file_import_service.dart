import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import 'ai_import_service.dart';
import 'timetable_html.dart';
import 'imported_source.dart';

class FileImportService {
  static const _pdfChannel = MethodChannel('com.hsu.hsu_schedule/import');

  static Future<ImportedSource> importFile(PlatformFile file) async {
    final name = file.name.toLowerCase();
    final path = file.path;
    if (name.endsWith('.pdf')) {
      if (path == null) throw const FormatException('无法读取 PDF 路径');
      final text = await _pdfChannel.invokeMethod<String>('extractPdfText', {'path': path});
      if (text == null || text.trim().isEmpty) throw const FormatException('PDF 中没有可提取的文字，可能是扫描版图片');
      return _ai(text, 'https://local.import/${Uri.encodeComponent(file.name)}', 'PDF');
    }
    final bytes = path == null ? null : await File(path).readAsBytes();
    if (bytes == null) throw const FormatException('无法读取文件');
    if (name.endsWith('.xlsx') || name.endsWith('.xls')) {
      final excel = Excel.decodeBytes(bytes);
      final buffer = StringBuffer();
      for (final table in excel.tables.keys) {
        buffer.writeln('工作表：$table');
        for (final row in excel.tables[table]!.rows) {
          buffer.writeln(row.map((cell) => cell?.value?.toString() ?? '').join('\t'));
        }
      }
      return _ai(buffer.toString(), 'https://local.import/${Uri.encodeComponent(file.name)}', 'Excel');
    }
    final text = _decode(bytes);
    if (name.endsWith('.json')) return _wakeUp(text, 'https://local.import/${Uri.encodeComponent(file.name)}');
    if (name.endsWith('.ics')) return _ai(text, 'https://local.import/${Uri.encodeComponent(file.name)}', 'ICS');
    if (name.endsWith('.csv')) return _ai(text, 'https://local.import/${Uri.encodeComponent(file.name)}', 'CSV');
    if (name.endsWith('.txt')) return _looksWakeUp(text) ? _wakeUp(text, 'https://local.import/${Uri.encodeComponent(file.name)}') : _ai(text, 'https://local.import/${Uri.encodeComponent(file.name)}', '文本');
    throw const FormatException('不支持的文件类型');
  }

  static Future<ImportedSource> fromPastedText(String text) => _looksWakeUp(text) ? _wakeUp(text, 'https://local.import/wakeup-text') : _ai(text, 'https://local.import/pasted-text', '文本');

  static bool _looksWakeUp(String text) {
    final t = text.trim();
    return t.startsWith('{') && (t.contains('"courses"') || t.contains('"startDate"'));
  }

  static Future<ImportedSource> _wakeUp(String text, String url) async {
    dynamic root;
    try {
      root = jsonDecode(text);
    } catch (_) {
      final start = text.indexOf('{');
      if (start < 0) throw const FormatException('不是有效的 WakeUp JSON');
      root = jsonDecode(text.substring(start));
    }
    dynamic body = root;
    if (body is Map && body['courseDetailJson'] is String) {
      body = jsonDecode(body['courseDetailJson'] as String);
    }
    dynamic list;
    if (body is Map) list = body['courses'];
    if (list is! List) throw const FormatException('WakeUp 文件中没有 courses');
    final courses = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is! Map) continue;
      final startNode = (item['startNode'] ?? item['startPeriod'] ?? 1) as num?;
      final step = (item['step'] ?? 1) as num?;
      final startWeek = (item['startWeek'] ?? 1) as num?;
      final endWeek = (item['endWeek'] ?? 20) as num?;
      final parity = (item['type'] ?? 0) as num?;
      final start = startNode?.toInt() ?? 1;
      final end = start + (step?.toInt() ?? 1) - 1;
      final weeks = parity?.toInt() == 1
          ? '${startWeek?.toInt() ?? 1}-${endWeek?.toInt() ?? 20}单周'
          : parity?.toInt() == 2
              ? '${startWeek?.toInt() ?? 1}-${endWeek?.toInt() ?? 20}双周'
              : '${startWeek?.toInt() ?? 1}-${endWeek?.toInt() ?? 20}周';
      final day = (item['day'] as num?)?.toInt() ?? 0;
      final name = item['name']?.toString().trim() ?? '';
      if (name.isEmpty || day < 1 || day > 7) continue;
      courses.add({
        'name': name,
        'teacher': item['teacher']?.toString() ?? '',
        'room': (item['position'] ?? item['room'] ?? '').toString(),
        'day': day,
        'startPeriod': start,
        'endPeriod': end,
        'weeks': weeks,
      });
    }
    if (courses.isEmpty) throw const FormatException('WakeUp 文件中没有可导入课程');
    return ImportedSource(url: url, cookies: const {}, html: buildTimetableHtml(courses), savedAt: DateTime.now());
  }

  static Future<ImportedSource> _ai(String text, String url, String label) async {
    if (text.trim().length < 10) throw FormatException('$label 内容为空');
    return AiImportService.parse(text: text, url: url, cookies: const {});
  }

  static String _decode(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }
}
