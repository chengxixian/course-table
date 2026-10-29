import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';

class CalendarExport {
  static String buildIcs(Schedule schedule, String mode) {
    final out = StringBuffer();
    final stamp = _stamp(DateTime.now().toUtc());
    out.write('BEGIN:VCALENDAR\r\n');
    out.write('VERSION:2.0\r\n');
    out.write('PRODID:-//Course Table//Material 3//CN\r\n');
    out.write('CALSCALE:GREGORIAN\r\n');
    out.write('METHOD:PUBLISH\r\n');
    out.write('X-WR-CALNAME:黄山学院课程表\r\n');
    out.write('X-WR-TIMEZONE:Asia/Shanghai\r\n');
    final events = _events(schedule, mode);
    for (final event in events) {
      final m = event.meeting;
      final summary = m.adjusted && m.weeks.length == 1 ? '${m.courseName}（调课）' : m.courseName;
      out.write('BEGIN:VEVENT\r\n');
      out.write('UID:${m.id}-${_dateKey(event.date)}@course-table.local\r\n');
      out.write('DTSTAMP:$stamp\r\n');
      out.write('DTSTART:${_stamp(event.startAt.toUtc())}\r\n');
      out.write('DTEND:${_stamp(event.endAt.toUtc())}\r\n');
      out.write('SUMMARY:${_escape(summary)}\r\n');
      out.write('DESCRIPTION:${_escape(_description(m, mode))}\r\n');
      out.write('LOCATION:${_escape([m.room, m.campus].where((e) => e.isNotEmpty).join(' · '))}\r\n');
      out.write('TRANSP:OPAQUE\r\n');
      out.write('STATUS:CONFIRMED\r\n');
      out.write('CATEGORIES:课程表\r\n');
      out.write('BEGIN:VALARM\r\n');
      out.write('ACTION:DISPLAY\r\n');
      out.write('DESCRIPTION:${_escape(summary)}\r\n');
      out.write('TRIGGER:-PT10M\r\n');
      out.write('END:VALARM\r\n');
      out.write('END:VEVENT\r\n');
    }
    out.write('END:VCALENDAR\r\n');
    return out.toString();
  }

  static Future<int> shareAll(Schedule schedule, String mode) async {
    final ics = buildIcs(schedule, mode);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/黄山学院全部课程.ics');
    await file.writeAsString(ics);
    final count = _events(schedule, mode).length;
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/calendar')],
      subject: '黄山学院课程表（全部课程）',
      text: '已生成 $count 个课程事件，包含本学期全部课程。请选择 Google 日历导入。',
    ));
    return count;
  }

  static Future<String> saveIcs(Schedule schedule, String mode) async {
    final ics = buildIcs(schedule, mode);
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/课程表_全部课程.ics');
    await file.writeAsString(ics);
    return file.path;
  }

  static Future<void> openGoogleImport() async {
    final uri = Uri.parse('https://calendar.google.com/calendar/u/0/r/settings/import');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('无法打开 Google 日历');
    }
  }

  static Future<bool> addNextToGoogle(Schedule schedule, String mode) async {
    final next = schedule.nextClass(mode: mode);
    if (next == null) return false;
    final m = next.meeting;
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': m.courseName,
      'dates': '${_stamp(next.startAt.toUtc())}/${_stamp(next.endAt.toUtc())}',
      'details': _description(m, mode),
      'location': [m.room, m.campus].where((e) => e.isNotEmpty).join(' · '),
      'ctz': 'Asia/Shanghai',
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> addCourseToGoogle(Schedule schedule, String courseId, String mode) async {
    final course = schedule.courseById(courseId);
    if (course == null) return false;
    final occurrences = course.meetings.map((m) => schedule.nextOccurrence(m, mode: mode)).whereType<NextClass>().toList();
    if (occurrences.isEmpty) return false;
    occurrences.sort((a, b) => a.startAt.compareTo(b.startAt));
    final next = occurrences.first;
    final m = next.meeting;
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': m.courseName,
      'dates': '${_stamp(next.startAt.toUtc())}/${_stamp(next.endAt.toUtc())}',
      'details': _description(m, mode),
      'location': [m.room, m.campus].where((e) => e.isNotEmpty).join(' · '),
      'ctz': 'Asia/Shanghai',
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static List<_Event> _events(Schedule schedule, String mode) {
    final list = <_Event>[];
    var date = schedule.semester.startDate;
    while (!date.isAfter(schedule.semester.endDate)) {
      final week = schedule.currentWeek(date);
      if (week > 0) {
        for (final m in schedule.meetingsFor(week, date.weekday)) {
          final sm = Schedule.parseMinutes(m.startTime);
          final em = Schedule.parseMinutes(m.endTime(mode));
          if (sm == null || em == null) continue;
          list.add(_Event(
            m,
            date,
            DateTime(date.year, date.month, date.day, sm ~/ 60, sm % 60),
            DateTime(date.year, date.month, date.day, em ~/ 60, em % 60),
          ));
        }
      }
      date = date.add(const Duration(days: 1));
    }
    list.sort((a, b) => a.startAt.compareTo(b.startAt));
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

  static String _escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,');

  static String _stamp(DateTime utc) {
    String p(int v) => v.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}${p(utc.month)}${p(utc.day)}T${p(utc.hour)}${p(utc.minute)}${p(utc.second)}Z';
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _Event {
  final Meeting meeting;
  final DateTime date;
  final DateTime startAt;
  final DateTime endAt;
  const _Event(this.meeting, this.date, this.startAt, this.endAt);
}
