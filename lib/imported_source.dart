import 'dart:convert';

class ImportedSource {
  final String url;
  final Map<String, String> cookies;
  final String html;
  final DateTime savedAt;

  const ImportedSource({
    required this.url,
    required this.cookies,
    required this.html,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'cookies': cookies,
        'html': html,
        'savedAt': savedAt.toIso8601String(),
      };

  static ImportedSource? fromJson(Map<String, dynamic> json) {
    final url = json['url']?.toString() ?? '';
    if (url.isEmpty) return null;
    final cookies = <String, String>{};
    final raw = json['cookies'];
    if (raw is Map) {
      for (final e in raw.entries) {
        cookies[e.key.toString()] = e.value.toString();
      }
    }
    return ImportedSource(
      url: url,
      cookies: cookies,
      html: json['html']?.toString() ?? '',
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  ImportedSource copyWith({String? url, Map<String, String>? cookies, String? html, DateTime? savedAt}) =>
      ImportedSource(
        url: url ?? this.url,
        cookies: cookies ?? this.cookies,
        html: html ?? this.html,
        savedAt: savedAt ?? this.savedAt,
      );

  String cookieHeader() => cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  String encode() => jsonEncode(toJson());
}
