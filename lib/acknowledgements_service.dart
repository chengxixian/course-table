import 'dart:convert';
import 'dart:io';

class AcknowledgementsService {
  static const fallback = <String>['茨畔耕夫', '润泽江海', 'Yearn Justly', '曼你个der啊'];
  static Future<List<String>>? _cached;

  static Future<List<String>> load() => _cached ??= _fetch();

  static Future<List<String>> _fetch() async {
    const urls = [
      'https://cdn.jsdelivr.net/gh/chengxixian/course-table@main/acknowledgements.json',
      'https://raw.githubusercontent.com/chengxixian/course-table/main/acknowledgements.json',
    ];
    for (final url in urls) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close().timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) continue;
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        final raw = data is Map ? data['names'] : null;
        if (raw is List) {
          final names = raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
          if (names.isNotEmpty) return names;
        }
      } catch (_) {} finally {
        client.close(force: true);
      }
    }
    return fallback;
  }
}
