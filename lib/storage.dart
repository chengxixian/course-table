import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'credential_vault.dart';
import 'imported_source.dart';
import 'models.dart';
import 'manual_course.dart';
import 'parser.dart';

class AppStorage {
  static const _rawKey = 'raw_scrape';

  final SharedPreferences prefs;
  AppStorage(this.prefs);

  static Future<AppStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStorage(prefs);
  }

  Schedule? loadSchedule() {
    final rawText = prefs.getString(_rawKey);
    try {
      RawScrape raw;
      if (rawText != null && rawText.isNotEmpty) {
        raw = RawScrape.fromJson((jsonDecode(rawText) as Map).cast<String, dynamic>());
      } else {
        return null;
      }
      return ScheduleParser.build(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRaw(RawScrape raw) async {
    await prefs.setString(_rawKey, jsonEncode(raw.toJson()));
    await prefs.setString('last_sync', raw.scrapedAt.toIso8601String());
  }

  ImportedSource? loadImportedSource() {
    final text = prefs.getString('imported_source');
    if (text == null || text.isEmpty) return null;
    try {
      return ImportedSource.fromJson((jsonDecode(text) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<void> saveImportedSource(ImportedSource source) async {
    await prefs.setString('imported_source', source.encode());
    await prefs.setString('source_mode', 'imported');
    await prefs.setString('last_sync', DateTime.now().toIso8601String());
  }

  String get sourceMode => prefs.getString('source_mode') ?? 'native';

  Future<void> setSourceMode(String mode) async => prefs.setString('source_mode', mode);

  Future<void> clearImportedSource() async {
    await prefs.remove('imported_source');
    await prefs.remove('source_mode');
  }

  Future<void> clearCourses() async {
    await prefs.remove(_rawKey);
    await prefs.remove('imported_source');
    await prefs.remove('source_mode');
    await prefs.remove('last_sync');
    await prefs.remove('meeting_moves');
  }

  List<ManualCourseEntry> loadManualCourses() {
    final text = prefs.getString('manual_courses');
    if (text == null || text.isEmpty) return [];
    try {
      final list = jsonDecode(text);
      if (list is! List) return [];
      return list.whereType<Map>().map((m) => ManualCourseEntry.fromJson(m.cast<String, dynamic>())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveManualCourses(List<ManualCourseEntry> courses) async {
    await prefs.setString('manual_courses', jsonEncode(courses.map((e) => e.toJson()).toList()));
  }

  Future<void> clearManualCourses() async => prefs.remove('manual_courses');

  Future<void> clearMeetingMoves() async => prefs.remove('meeting_moves');

  List<MeetingMove> loadMeetingMoves() {
    final text = prefs.getString('meeting_moves');
    if (text == null || text.isEmpty) return [];
    try {
      final list = jsonDecode(text);
      if (list is! List) return [];
      return list.whereType<Map>().map((m) => MeetingMove.fromJson(m.cast<String, dynamic>())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMeetingMoves(List<MeetingMove> moves) async {
    await prefs.setString('meeting_moves', jsonEncode(moves.map((e) => e.toJson()).toList()));
  }

  DateTime? get lastSync {
    final text = prefs.getString('last_sync');
    return text == null ? null : DateTime.tryParse(text);
  }

  AppSettings get settings => AppSettings(
        autoSync: prefs.getBool('auto_sync') ?? true,
        refreshTime: prefs.getString('refresh_time') ?? '07:30',
        theme: prefs.getString('theme') ?? 'system',
        palette: prefs.getString('palette') ?? 'system',
        fontStyle: prefs.getString('font_style') ?? 'fangsoong',
        iconStyle: prefs.getString('icon_style') ?? 'material',
        durationMode: prefs.getString('duration_mode') ?? '45',
        strongAi: prefs.getBool('strong_ai') ?? false,
        lastSync: lastSync,
        username: prefs.getString('username') ?? '',
      );

  Future<AppSettings> saveSettings(AppSettings settings) async {
    await prefs.setBool('auto_sync', settings.autoSync);
    await prefs.setString('refresh_time', settings.refreshTime);
    await prefs.setString('theme', settings.theme);
    await prefs.setString('palette', settings.palette);
    await prefs.setString('font_style', settings.fontStyle);
    await prefs.setString('icon_style', settings.iconStyle);
    await prefs.setString('duration_mode', settings.durationMode);
    await prefs.setBool('strong_ai', settings.strongAi);
    await prefs.setString('username', settings.username);
    if (settings.lastSync != null) {
      await prefs.setString('last_sync', settings.lastSync!.toIso8601String());
    }
    return settings;
  }

  Future<Credentials?> readCredentials() async {
    return CredentialVault.read();
  }

  Future<void> writeCredentials(Credentials credentials) async {
    await CredentialVault.write(credentials);
    await prefs.setString('username', credentials.username);
  }

  Future<void> clearCredentials() async {
    await CredentialVault.clear();
    await prefs.remove('username');
  }

  bool get loginDismissed => prefs.getBool('login_dismissed') ?? false;
  Future<void> setLoginDismissed(bool value) async => prefs.setBool('login_dismissed', value);

  bool get compactWidget => prefs.getBool('compact_widget') ?? false;
  Future<void> setCompactWidget(bool value) async => prefs.setBool('compact_widget', value);
}
