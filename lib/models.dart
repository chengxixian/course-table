import 'package:intl/intl.dart';

const List<String> kWeekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
const List<String> kWeekdaysFull = ['', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

class Period {
  final int index;
  final String start;
  final String end;
  final String section;
  const Period(this.index, this.start, this.end, [this.section = '']);

  factory Period.fromJson(Map<String, dynamic> json) => Period(
        int.tryParse(json['jcmc']?.toString() ?? '') ?? 0,
        json['qssj']?.toString() ?? '',
        json['jssj']?.toString() ?? '',
        json['rsdmc']?.toString() ?? '',
      );
}

class Student {
  final String name;
  final String id;
  final String className;
  final String major;
  final String college;
  const Student({this.name = '', this.id = '', this.className = '', this.major = '', this.college = ''});
}

class Semester {
  final String academicYear;
  final int term;
  final String start;
  final String end;
  final String name;
  final int totalWeeks;
  const Semester({
    required this.academicYear,
    required this.term,
    required this.start,
    required this.end,
    required this.name,
    required this.totalWeeks,
  });

  DateTime get startDate => DateTime.parse(start);
  DateTime get endDate => DateTime.parse(end);
}

class Meeting {
  final String id;
  final String courseId;
  final String courseName;
  final String sectionName;
  final String teacher;
  final String room;
  final String campus;
  final int day;
  final int startPeriod;
  final int endPeriod;
  final List<int> weeks;
  final String weeksText;
  final String startTime;
  final String endTime45;
  final String endTimeActual;
  final double? credits;
  final String courseCode;
  final String courseType;
  final String category;
  final String kind;
  final bool adjusted;
  final String adjustNote;

  const Meeting({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.sectionName,
    required this.teacher,
    required this.room,
    required this.campus,
    required this.day,
    required this.startPeriod,
    required this.endPeriod,
    required this.weeks,
    required this.weeksText,
    required this.startTime,
    required this.endTime45,
    required this.endTimeActual,
    required this.credits,
    required this.courseCode,
    required this.courseType,
    required this.category,
    required this.kind,
    this.adjusted = false,
    this.adjustNote = '',
  });

  String get dayName => day >= 1 && day <= 7 ? kWeekdays[day] : '';
  int get periodCount => endPeriod - startPeriod + 1;
  String endTime(String mode) => mode == 'actual' ? (endTimeActual.isNotEmpty ? endTimeActual : endTime45) : (endTime45.isNotEmpty ? endTime45 : endTimeActual);

  Meeting copyWith({int? day, int? startPeriod, int? endPeriod, String? startTime, String? endTime45, String? endTimeActual}) => Meeting(
        id: id,
        courseId: courseId,
        courseName: courseName,
        sectionName: sectionName,
        teacher: teacher,
        room: room,
        campus: campus,
        day: day ?? this.day,
        startPeriod: startPeriod ?? this.startPeriod,
        endPeriod: endPeriod ?? this.endPeriod,
        weeks: weeks,
        weeksText: weeksText,
        startTime: startTime ?? this.startTime,
        endTime45: endTime45 ?? this.endTime45,
        endTimeActual: endTimeActual ?? this.endTimeActual,
        credits: credits,
        courseCode: courseCode,
        courseType: courseType,
        category: category,
        kind: kind,
        adjusted: adjusted,
        adjustNote: adjustNote,
      );
}

class Course {
  final String id;
  final String code;
  final String name;
  final String teacher;
  final List<String> teachers;
  final List<String> rooms;
  final double? credits;
  final String type;
  final String category;
  final String kind;
  final List<Meeting> meetings;
  final List<int> weeks;
  final String weeksText;
  final String roomsText;
  final int colorIndex;
  final bool adjusted;

  const Course({
    required this.id,
    required this.code,
    required this.name,
    required this.teacher,
    required this.teachers,
    required this.rooms,
    required this.credits,
    required this.type,
    required this.category,
    required this.kind,
    required this.meetings,
    required this.weeks,
    required this.weeksText,
    required this.roomsText,
    required this.colorIndex,
    required this.adjusted,
  });

  String get scheduleText => (meetings..sort((a, b) => a.day == b.day ? a.startPeriod - b.startPeriod : a.day - b.day))
      .map((m) => '${m.dayName} ${m.startPeriod}-${m.endPeriod}节')
      .join(' · ');
}

class Conflict {
  final int week;
  final int day;
  final int startPeriod;
  final int endPeriod;
  final List<String> meetingIds;
  final List<String> courseNames;
  const Conflict({required this.week, required this.day, required this.startPeriod, required this.endPeriod, required this.meetingIds, required this.courseNames});
}

class WeekStats {
  final int courses;
  final int periods;
  final int conflicts;
  const WeekStats(this.courses, this.periods, this.conflicts);
}

class NextClass {
  final Meeting meeting;
  final DateTime date;
  final int week;
  final bool ongoing;
  final DateTime startAt;
  final DateTime endAt;
  const NextClass({required this.meeting, required this.date, required this.week, required this.ongoing, required this.startAt, required this.endAt});
}

class Schedule {
  final Student student;
  final Semester semester;
  final List<Period> periods;
  final List<Course> courses;
  final List<Meeting> meetings;
  final List<Conflict> conflicts;
  final DateTime fetchedAt;
  final String source;

  const Schedule({
    required this.student,
    required this.semester,
    required this.periods,
    required this.courses,
    required this.meetings,
    required this.conflicts,
    required this.fetchedAt,
    this.source = '黄山学院教务管理系统',
  });

  int currentWeek([DateTime? date]) {
    final d = _dateOnly(date ?? DateTime.now());
    if (d.isBefore(semester.startDate)) return 0;
    final days = d.difference(semester.startDate).inDays;
    return ((days ~/ 7) + 1).clamp(0, semester.totalWeeks);
  }

  List<Meeting> meetingsFor(int week, int day) => meetings
      .where((m) => m.day == day && m.weeks.contains(week))
      .toList()
    ..sort((a, b) => a.startPeriod == b.startPeriod ? a.endPeriod - b.endPeriod : a.startPeriod - b.startPeriod);

  List<Meeting> todayMeetings([DateTime? date]) {
    final d = date ?? DateTime.now();
    final week = currentWeek(d);
    if (week <= 0) return [];
    return meetingsFor(week, d.weekday);
  }

  List<Meeting> weekMeetings(int week) => meetings.where((m) => m.weeks.contains(week)).toList();

  Course? courseById(String id) => courses.where((c) => c.id == id).firstOrNull;

  Meeting? meetingById(String id) => meetings.where((m) => m.id == id).firstOrNull;

  DateTime dateForWeekDay(int week, int day) =>
      semester.startDate.add(Duration(days: (week - 1) * 7 + (day - 1)));

  WeekStats statsForWeek(int week) {
    final list = weekMeetings(week);
    return WeekStats(
      list.map((m) => m.courseId).toSet().length,
      list.fold(0, (sum, m) => sum + m.periodCount),
      conflicts.where((c) => c.week == week).length,
    );
  }

  NextClass? nextClass({DateTime? now, String mode = '45'}) {
    final n = now ?? DateTime.now();
    final today = _dateOnly(n);
    final nowMin = n.hour * 60 + n.minute;
    for (var offset = 0; offset < 15; offset++) {
      final date = today.add(Duration(days: offset));
      final week = currentWeek(date);
      if (week <= 0) continue;
      final list = meetingsFor(week, date.weekday);
      for (final m in list) {
        final start = _minutes(m.startTime);
        final end = _minutes(m.endTime(mode));
        if (start == null || end == null) continue;
        if (offset == 0 && nowMin >= end) continue;
        final startAt = DateTime(date.year, date.month, date.day, start ~/ 60, start % 60);
        final endAt = DateTime(date.year, date.month, date.day, end ~/ 60, end % 60);
        return NextClass(
          meeting: m,
          date: date,
          week: week,
          ongoing: offset == 0 && nowMin >= start && nowMin < end,
          startAt: startAt,
          endAt: endAt,
        );
      }
    }
    return null;
  }

  NextClass? nextOccurrence(Meeting meeting, {DateTime? now, String mode = '45'}) {
    final n = now ?? DateTime.now();
    final today = _dateOnly(n);
    for (var offset = 0; offset < 140; offset++) {
      final date = today.add(Duration(days: offset));
      final week = currentWeek(date);
      if (week <= 0 || !meeting.weeks.contains(week) || date.weekday != meeting.day) continue;
      final start = _minutes(meeting.startTime);
      final end = _minutes(meeting.endTime(mode));
      if (start == null || end == null) continue;
      final startAt = DateTime(date.year, date.month, date.day, start ~/ 60, start % 60);
      final endAt = DateTime(date.year, date.month, date.day, end ~/ 60, end % 60);
      if (endAt.isBefore(n)) continue;
      return NextClass(
        meeting: meeting,
        date: date,
        week: week,
        ongoing: n.isAfter(startAt) && n.isBefore(endAt),
        startAt: startAt,
        endAt: endAt,
      );
    }
    return null;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int? parseMinutes(String clock) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(clock);
    if (m == null) return null;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  static int? _minutes(String clock) => parseMinutes(clock);

  static String formatMinutes(int minutes) => '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}

class PortalInfo {
  final String name;
  final String className;
  final String id;
  final String college;
  const PortalInfo({this.name = '', this.className = '', this.id = '', this.college = ''});

  Map<String, dynamic> toJson() => {'name': name, 'className': className, 'id': id, 'college': college};
}

class RawScrape {
  final Map<String, dynamic> rawSchedule;
  final List<dynamic> rawPeriods;
  final String semesterText;
  final PortalInfo? portalInfo;
  final DateTime scrapedAt;
  const RawScrape({
    required this.rawSchedule,
    required this.rawPeriods,
    required this.semesterText,
    this.portalInfo,
    required this.scrapedAt,
  });

  Map<String, dynamic> toJson() => {
        'rawSchedule': rawSchedule,
        'rawPeriods': rawPeriods,
        'semesterText': semesterText,
        'portalInfo': portalInfo?.toJson(),
        'scrapedAt': scrapedAt.toIso8601String(),
      };

  static RawScrape fromJson(Map<String, dynamic> json) => RawScrape(
        rawSchedule: (json['rawSchedule'] as Map).cast<String, dynamic>(),
        rawPeriods: (json['rawPeriods'] as List?) ?? [],
        semesterText: json['semesterText']?.toString() ?? '',
        portalInfo: json['portalInfo'] is Map
            ? PortalInfo(
                name: json['portalInfo']['name']?.toString() ?? '',
                className: json['portalInfo']['className']?.toString() ?? '',
                id: json['portalInfo']['id']?.toString() ?? '',
                college: json['portalInfo']['college']?.toString() ?? '',
              )
            : null,
        scrapedAt: DateTime.tryParse(json['scrapedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class Credentials {
  final String username;
  final String password;
  const Credentials(this.username, this.password);
}

class AppSettings {
  final bool autoSync;
  final String refreshTime;
  final String theme;
  final String palette;
  final String fontStyle;
  final String iconStyle;
  final String durationMode;
  final bool strongAi;
  final DateTime? lastSync;
  final String username;
  const AppSettings({
    this.autoSync = true,
    this.refreshTime = '07:30',
    this.theme = 'system',
    this.palette = 'system',
    this.fontStyle = 'fangsoong',
    this.iconStyle = 'material',
    this.durationMode = '45',
    this.strongAi = false,
    this.lastSync,
    this.username = '',
  });

  AppSettings copyWith({
    bool? autoSync,
    String? refreshTime,
    String? theme,
    String? palette,
    String? fontStyle,
    String? iconStyle,
    String? durationMode,
    bool? strongAi,
    DateTime? lastSync,
    String? username,
  }) =>
      AppSettings(
        autoSync: autoSync ?? this.autoSync,
        refreshTime: refreshTime ?? this.refreshTime,
        theme: theme ?? this.theme,
        palette: palette ?? this.palette,
        fontStyle: fontStyle ?? this.fontStyle,
        iconStyle: iconStyle ?? this.iconStyle,
        durationMode: durationMode ?? this.durationMode,
        strongAi: strongAi ?? this.strongAi,
        lastSync: lastSync ?? this.lastSync,
        username: username ?? this.username,
      );
}

String formatDateCN(DateTime d) => '${d.month}月${d.day}日';
String formatFullDateCN(DateTime d) => '${formatDateCN(d)} · ${kWeekdaysFull[d.weekday]}';
String formatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String formatLastSync(DateTime? d) =>
    d == null ? '尚未同步' : '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String formatRangeCN(DateTime a, DateTime b) {
  if (a.year == b.year && a.month == b.month) {
    return '${a.month}月${a.day}日 — ${b.day}日';
  }
  return '${a.month}月${a.day}日 — ${b.month}月${b.day}日';
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
