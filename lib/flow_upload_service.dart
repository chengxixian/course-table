import 'dart:convert';
import 'dart:io';

import 'app_meta.dart';
import 'imported_source.dart';

class FlowUploadService {
  static Future<String?> upload({required String school, required ImportedSource source}) async {
    final endpoint = AppMeta.flowUploadUrl.trim();
    if (endpoint.isEmpty) {
      throw StateError('上传通道未配置');
    }
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'school': school,
        'url': source.url,
        'savedAt': source.savedAt.toIso8601String(),
        'appVersion': AppMeta.version,
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('上传失败（HTTP ${response.statusCode}）：$body');
      }
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded['pr']?.toString() : null;
    } finally {
      client.close(force: true);
    }
  }
}
