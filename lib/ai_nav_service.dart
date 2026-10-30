import 'dart:convert';
import 'dart:io';
import 'app_meta.dart';

class AiNavService {
  static Future<int> nextIndex({required String text, required List<Map<String, dynamic>> controls}) async {
    if (controls.isEmpty) return -1;
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(AppMeta.aiNavUrl));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'text': text, 'controls': controls.take(80).toList()}));
      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) return -1;
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body);
      if (data is Map) {
        final n = int.tryParse('${data['index']}') ?? -1;
        if (n >= 0 && n < controls.length) return n;
      }
    } catch (_) {} finally { client.close(force: true); }
    return -1;
  }
}
