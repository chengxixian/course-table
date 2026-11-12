import 'dart:io';

import 'generic_html_parser.dart';
import 'html_compactor.dart';
import 'imported_source.dart';
import 'models.dart';
import 'storage.dart';

class ImportException implements Exception {
  final String message;
  const ImportException(this.message);
  @override
  String toString() => message;
}

class ImportedScheduleService {
  static Schedule? parse(ImportedSource source) {
    return parseImportedHtml(source.html, source.url);
  }

  static Future<Schedule> refresh(AppStorage storage) async {
    final source = storage.loadImportedSource();
    if (source == null) throw const ImportException('还没有导入过网页课表');
    final html = await fetch(source.url, source.cookies);
    final schedule = parseImportedHtml(html, source.url);
    if (schedule == null) {
      final reason = lastParseError ?? '页面里没有识别到课表';
      throw ImportException('刷新失败：$reason。请重新打开网页导入。');
    }
    await storage.saveImportedSource(source.copyWith(html: html, savedAt: DateTime.now()));
    return schedule;
  }

  static Future<String> fetch(String url, Map<String, String> cookies) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36');
      request.headers.set(HttpHeaders.acceptHeader, 'text/html,application/xhtml+xml');
      if (cookies.isNotEmpty) {
        request.headers.set(HttpHeaders.cookieHeader, cookies.entries.map((e) => '${e.key}=${e.value}').join('; '));
      }
      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ImportException('网页返回 HTTP ${response.statusCode}');
      }
      // Read raw bytes with a network ceiling, decode tolerantly (one bad byte
      // used to abort a whole import), then strip script/style/base64 before
      // the size test: a 20MB portal page usually compacts to under 2MB and
      // parses fine. The old hard throw at 6MB was the "网页内容过大" failure
      // users reported on large timetable pages.
      final buffered = BytesBuilder(copy: true);
      var size = 0;
      var overflow = false;
      await for (final chunk in response.cast<List<int>>()) {
        size += chunk.length;
        if (size > 48 * 1024 * 1024) {
          overflow = true;
          break;
        }
        buffered.add(chunk);
      }
      if (overflow) throw const ImportException('网页超过 48MB，可能不是课表页面，请用学校的课表打印页');
      final html = compactHtml(decodeUtf8Tolerant(buffered.takeBytes()));
      if (html.length > maxHtmlChars) throw const ImportException('网页正文过大，请改用课表打印页或已适配高校入口');
      if (html.trim().isEmpty) throw const ImportException('网页没有可解析的正文');
      return html;
    } on ImportException {
      rethrow;
    } catch (e) {
      throw ImportException('无法读取网页：$e');
    } finally {
      client.close(force: true);
    }
  }
}
