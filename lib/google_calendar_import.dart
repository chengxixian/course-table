import 'dart:io';

import 'package:flutter/services.dart';

import 'models.dart';

class CalendarImportResult {
  final int inserted;
  final int skipped;
  final String calendarName;
  final String accountType;
  const CalendarImportResult({
    required this.inserted,
    required this.skipped,
    required this.calendarName,
    required this.accountType,
  });
}

class CalendarPermissionException implements Exception {
  final String message;
  const CalendarPermissionException(this.message);
  @override
  String toString() => message;
}

class NoWritableCalendarException implements Exception {
  final String message;
  const NoWritableCalendarException(this.message);
  @override
  String toString() => message;
}

class CalendarTargetInfo {
  final int id;
  final String name;
  final String accountName;
  final String accountType;
  const CalendarTargetInfo({required this.id, required this.name, required this.accountName, required this.accountType});
}

class GoogleCalendarImport {
  static const _channel = MethodChannel('com.hsu.hsu_schedule/calendar');

  static Future<List<CalendarTargetInfo>> listCalendars() async {
    if (!Platform.isAndroid) return const [];
    try {
      final list = await _channel.invokeListMethod<dynamic>('listCalendars');
      return (list ?? const []).whereType<Map>().map((m) => CalendarTargetInfo(
        id: (m['id'] as num?)?.toInt() ?? 0,
        name: m['name']?.toString() ?? '日历',
        accountName: m['accountName']?.toString() ?? '',
        accountType: m['accountType']?.toString() ?? '',
      )).where((c) => c.id > 0).toList();
    } on PlatformException catch (e) {
      throw CalendarPermissionException(e.message ?? '读取系统日历失败');
    } on MissingPluginException {
      return const [];
    }
  }

  static Future<CalendarImportResult> importAll(Schedule schedule, String mode, {int? calendarId}) async {
    if (!Platform.isAndroid) {
      throw const CalendarPermissionException('当前平台不支持直接写入日历');
    }
    final events = buildEvents(schedule, mode);
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('insertEvents', {'events': events, 'calendarId': calendarId});
      if (result == null) throw const CalendarPermissionException('日历导入没有返回结果');
      return CalendarImportResult(
        inserted: (result['inserted'] as num?)?.toInt() ?? 0,
        skipped: (result['skipped'] as num?)?.toInt() ?? 0,
        calendarName: result['calendarName']?.toString() ?? '系统日历',
        accountType: result['accountType']?.toString() ?? '',
      );
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') throw CalendarPermissionException(e.message ?? '没有日历权限');
      if (e.code == 'NO_CALENDAR') throw NoWritableCalendarException(e.message ?? '没有可写入的日历');
      throw CalendarPermissionException(e.message ?? '写入日历失败');
    } on MissingPluginException {
      throw const CalendarPermissionException('日历功能不可用，请重新安装应用');
    }
  }

  static List<Map<String, dynamic>> buildEvents(Schedule schedule, String mode) {
    final list = <Map<String, dynamic>>[];
    var date = schedule.semester.startDate;
    while (!date.isAfter(schedule.semester.endDate)) {
      final week = schedule.currentWeek(date);
      if (week > 0) {
        for (final m in schedule.meetingsFor(week, date.weekday)) {
          final start = Schedule.parseMinutes(m.startTime);
          final end = Schedule.parseMinutes(m.endTime(mode));
          if (start == null || end == null) continue;
          final startAt = DateTime(date.year, date.month, date.day, start ~/ 60, start % 60);
          final endAt = DateTime(date.year, date.month, date.day, end ~/ 60, end % 60);
          list.add({
            'uid': '${m.id}-${date.year}-${date.month}-${date.day}',
            'title': m.courseName,
            'description': _description(m, mode),
            'location': [m.room, m.campus].where((e) => e.isNotEmpty).join(' · '),
            'start': startAt.millisecondsSinceEpoch,
            'end': endAt.millisecondsSinceEpoch,
          });
        }
      }
      date = date.add(const Duration(days: 1));
    }
    return list;
  }

  static String _description(Meeting m, String mode) {
    final lines = [
      '任课教师：${m.teacher.isEmpty ? '—' : m.teacher}',
      '上课地点：${m.room.isEmpty ? '—' : m.room}${m.campus.isEmpty ? '' : '（${m.campus}）'}',
      '上课周次：${m.weeksText}',
      '节次：第${m.startPeriod}-${m.endPeriod}节',
      '上课时间：${m.startTime}–${m.endTime(mode)}（北京时间）',
      if (m.credits != null) '学分：${m.credits}',
      if (m.adjusted && m.adjustNote.isNotEmpty) '调课说明：${m.adjustNote}',
      '来源：黄山学院教务管理系统 · 课程表',
    ];
    return lines.join('\n');
  }
}
