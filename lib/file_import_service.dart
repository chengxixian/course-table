import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import 'ai_import_service.dart';
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
    if (name.endsWith('.ics')) return _ai(text, 'https://local.import/${Uri.encodeComponent(file.name)}', 'ICS');
    if (name.endsWith('.csv')) return _ai(text, 'https://local.import/${Uri.encodeComponent(file.name)}', 'CSV');
    if (name.endsWith('.txt')) return _ai(text, 'https://local.import/${Uri.encodeComponent(file.name)}', '文本');
    throw const FormatException('不支持的文件类型');
  }

  static Future<ImportedSource> fromPastedText(String text) => _ai(text, 'https://local.import/pasted-text', '文本');

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
