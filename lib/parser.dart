import 'dart:math' as math;
import 'models.dart';

class ScheduleParser {
  static const _termNames = {1: '第一学期', 2: '第二学期', 3: '第三学期'};

  static const fallbackPeriods = [
    Period(1, '08:00', '08:45', '上午'),
    Period(2, '08:55', '09:40', '上午'),
    Period(3, '10:00', '10:45', '上午'),
    Period(4, '10:55', '11:40', '上午'),
    Period(5, '14:00', '14:45', '下午'),
    Period(6, '14:55', '15:40', '下午'),
    Period(7, '16:00', '16:45', '下午'),
    Period(8, '16:55', '17:40', '下午'),
    Period(9, '19:00', '19:45', '晚上'),
    Period(10, '19:55', '20:40', '晚上'),
    Period(11, '20:50', '21:35', '晚上'),
  ];

  static Schedule build(RawScrape raw, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final root = raw.rawSchedule;
    final xsxx = (root['xsxx'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final periods = _normalizePeriods(raw.rawPeriods);
    final periodMap = {for (final p in periods) p.index: p};
    final semester = _parseSemester(raw.semesterText, current);
    final portal = raw.portalInfo;
    final student = Student(
      name: (portal?.name.isNotEmpty ?? false) ? portal!.name : (xsxx['XM']?.toString() ?? '同学'),
      id: (portal?.id.isNotEmpty ?? false) ? portal!.id : (xsxx['XH']?.toString() ?? xsxx['XH_ID']?.toString() ?? ''),
      className: (portal?.className.isNotEmpty ?? false) ? portal!.className : (xsxx['BJMC']?.toString() ?? ''),
      major: xsxx['ZYMC']?.toString() ?? '',
      college: portal?.college ?? '',
    );

    final rawMeetings = <_TempMeeting>[];
    final kb = (root['kbList'] as List?) ?? [];
    for (final item in kb) {
      if (item is! Map) continue;
      final r = item.cast<String, dynamic>();
      final range = parsePeriodRange(r['jc']?.toString() ?? r['jcor']?.toString() ?? '');
      final weeks = parseWeeks(r['zcd']?.toString() ?? '');
      final day = _int(r['xqj']);
      if (range == null || weeks.isEmpty || day <= 0) continue;
      final courseId = _str(r['kch_id']).isNotEmpty ? _str(r['kch_id']) : (_str(r['kch']).isNotEmpty ? _str(r['kch']) : _str(r['kcmc']));
      final teacher = _str(r['xm']);
      final room = _str(r['cdmc']);
      final rawWeeks = _str(r['zcd']);
      rawMeetings.add(_TempMeeting(
        courseId: courseId,
        courseName: _str(r['kcmc'], '未知课程'),
        sectionName: _str(r['jxbmc']),
        teacher: teacher,
        room: room,
        campus: _str(r['xqmc']),
        day: day,
        startPeriod: range.$1,
        endPeriod: range.$2,
        weeks: List<int>.from(weeks),
        rawWeeksText: rawWeeks,
        credits: _doubleOrNull(r['xf']),
        courseCode: _str(r['kch']),
        courseType: _str(r['kcxz']),
        category: _str(r['kcbj']),
        kind: _str(r['kclb']),
        rawKey: [courseId, _str(r['jxbmc']), teacher, room, day, range.$1, range.$2, rawWeeks].join('|'),
      ));
    }

    // Deduplicate exact rows.
    final seen = <String>{};
    final deduped = rawMeetings.where((m) => seen.add(m.rawKey)).toList();

    // A one-week extra slot from JWXT usually means a make-up session that
    // replaces the regular slot for that week.
    final groups = <String, List<_TempMeeting>>{};
    for (final m in deduped) {
      groups.putIfAbsent([m.courseId, m.day, m.teacher, m.room].join('|'), () => []).add(m);
    }
    for (final group in groups.values) {
      if (group.length < 2) continue;
      for (final single in group) {
        if (single.weeks.length != 1) continue;
        for (final other in group) {
          if (identical(single, other) || other.weeks.length < 2) continue;
          if (single.startPeriod == other.startPeriod && single.endPeriod == other.endPeriod) continue;
          final week = single.weeks.first;
          if (!other.weeks.contains(week)) continue;
          other.weeks = other.weeks.where((w) => w != week).toList();
          other.adjusted = true;
          other.adjustNote = '第${week}周调整至第${single.startPeriod}-${single.endPeriod}节';
          single.adjusted = true;
          single.adjustNote = '第${week}周由第${other.startPeriod}-${other.endPeriod}节调整而来';
        }
      }
    }

    final meetings = deduped.where((m) => m.weeks.isNotEmpty).map((t) {
      final startPeriod = periodMap[t.startPeriod];
      final endPeriod = periodMap[t.endPeriod];
      final startTime = startPeriod?.start ?? '';
      final endActual = endPeriod?.end ?? '';
      final startMin = _minutes(startTime);
      final end45 = startMin == null ? '' : Schedule.formatMinutes(startMin + t.periodCount * 45);
      final id = fnv1a([t.courseId, t.sectionName, t.teacher, t.room, t.day, t.startPeriod, t.endPeriod, t.weeks.join(',')].join('|'));
      return Meeting(
        id: id,
        courseId: t.courseId,
        courseName: t.courseName,
        sectionName: t.sectionName,
        teacher: t.teacher,
        room: t.room,
        campus: t.campus,
        day: t.day,
        startPeriod: t.startPeriod,
        endPeriod: t.endPeriod,
        weeks: t.weeks.toSet().toList()..sort(),
        weeksText: t.rawWeeksText,
        startTime: startTime,
        endTime45: end45,
        endTimeActual: endActual,
        credits: t.credits,
        courseCode: t.courseCode,
        courseType: t.courseType,
        category: t.category,
        kind: t.kind,
        adjusted: t.adjusted,
        adjustNote: t.adjustNote,
      );
    }).toList();

    final courseMap = <String, _MutableCourse>{};
    for (final m in meetings) {
      final c = courseMap.putIfAbsent(m.courseId, () => _MutableCourse(
            id: m.courseId,
            code: m.courseCode,
            name: m.courseName,
            credits: m.credits,
            type: m.courseType,
            category: m.category,
            kind: m.kind,
          ));
      c.meetings.add(m);
      if (m.teacher.isNotEmpty && !c.teachers.contains(m.teacher)) c.teachers.add(m.teacher);
      if (m.room.isNotEmpty && !c.rooms.contains(m.room)) c.rooms.add(m.room);
      c.adjusted = c.adjusted || m.adjusted;
      c.credits ??= m.credits;
    }
    final courses = <Course>[];
    var colorIndex = 0;
    for (final c in courseMap.values) {
      final weeks = c.meetings.expand((m) => m.weeks).toSet().toList()..sort();
      c.meetings.sort((a, b) => a.day == b.day ? a.startPeriod - b.startPeriod : a.day - b.day);
      courses.add(Course(
        id: c.id,
        code: c.code,
        name: c.name,
        teacher: c.teachers.isNotEmpty ? c.teachers.first : '',
        teachers: c.teachers,
        rooms: c.rooms,
        credits: c.credits,
        type: c.type,
        category: c.category,
        kind: c.kind,
        meetings: c.meetings,
        weeks: weeks,
        weeksText: formatWeeks(weeks),
        roomsText: c.rooms.join(' / '),
        colorIndex: colorIndex++ % 8,
        adjusted: c.adjusted,
      ));
    }

    final maxWeek = math.max(semester.totalWeeks, meetings.expand((m) => m.weeks).fold<int>(1, math.max));
    final conflicts = _findConflicts(meetings, maxWeek);
    return Schedule(
      student: student,
      semester: semester,
      periods: periods,
      courses: courses,
      meetings: meetings,
      conflicts: conflicts,
      fetchedAt: raw.scrapedAt,
    );
  }

  static List<Period> _normalizePeriods(List<dynamic> raw) {
    final list = raw.whereType<Map>().map((e) => Period.fromJson(e.cast<String, dynamic>())).where((p) => p.index > 0 && p.start.isNotEmpty).toList()
      ..sort((a, b) => a.index - b.index);
    return list.isEmpty ? fallbackPeriods : list;
  }

  static List<int> parseWeeks(String text) {
    if (text.trim().isEmpty) return [];
    final cleaned = text.replaceAll(RegExp(r'\s+'), '').replaceAll('第', '').replaceAll('周', '');
    final weeks = <int>{};
    for (final part in cleaned.split(RegExp(r'[,，;；、]'))) {
      if (part.isEmpty) continue;
      final m = RegExp(r'^(\d{1,2})(?:-(\d{1,2}))?(?:\((单|双)\))?$').firstMatch(part);
      if (m == null) continue;
      final a = int.parse(m.group(1)!);
      final b = m.group(2) == null ? a : int.parse(m.group(2)!);
      final parity = m.group(3);
      for (var w = math.min(a, b); w <= math.max(a, b); w++) {
        if (parity == '单' && w.isEven) continue;
        if (parity == '双' && w.isOdd) continue;
        if (w >= 1 && w < 60) weeks.add(w);
      }
    }
    return weeks.toList()..sort();
  }

  static (int, int)? parsePeriodRange(String text) {
    final nums = <int>[];
    for (final m in RegExp(r'(\d{1,2})(?:\s*-\s*(\d{1,2}))?').allMatches(text.replaceAll('节', ''))) {
      final a = int.tryParse(m.group(1)!) ?? 0;
      final b = m.group(2) == null ? a : int.parse(m.group(2)!);
      for (var i = math.min(a, b); i <= math.max(a, b); i++) {
        nums.add(i);
      }
    }
    if (nums.isEmpty) return null;
    return (nums.reduce(math.min), nums.reduce(math.max));
  }

  static String formatWeeks(List<int> weeks) {
    if (weeks.isEmpty) return '—';
    final sorted = weeks.toSet().toList()..sort();
    final out = <String>[];
    var start = sorted[0];
    var prev = sorted[0];
    for (var i = 1; i <= sorted.length; i++) {
      final w = i < sorted.length ? sorted[i] : null;
      if (w == prev + 1) {
        prev = w!;
        continue;
      }
      out.add(start == prev ? '$start' : '$start-$prev');
      if (w != null) {
        start = w;
        prev = w;
      }
    }
    return '${out.join(',')} 周';
  }

  static Semester _parseSemester(String text, DateTime now) {
    final m = RegExp(r'(\d{4})-(\d{4})学年\s*第?(\d)\s*学期\s*\(?(\d{4}-\d{2}-\d{2})\s*[至到\-~]\s*(\d{4}-\d{2}-\d{2})').firstMatch(text);
    String academicYear;
    int term;
    DateTime start;
    DateTime end;
    if (m != null) {
      academicYear = '${m.group(1)}-${m.group(2)}';
      term = int.tryParse(m.group(3)!) ?? 1;
      start = DateTime.parse(m.group(4)!);
      end = DateTime.parse(m.group(5)!);
    } else {
      term = (now.month >= 8 || now.month <= 1) ? 1 : 2;
      final startYear = now.month >= 8 ? now.year : now.year - 1;
      academicYear = '$startYear-${startYear + 1}';
      if (term == 2) {
        start = DateTime(startYear + 1, 2, 20);
        while (start.weekday != DateTime.monday) {
          start = start.subtract(const Duration(days: 1));
        }
      } else {
        start = DateTime(startYear, 9, 1);
        while (start.weekday != DateTime.monday) {
          start = start.subtract(const Duration(days: 1));
        }
      }
      end = start.add(const Duration(days: 19 * 7 + 6));
    }
    final total = ((end.difference(start).inDays + 1) / 7).ceil().clamp(1, 30);
    return Semester(
      academicYear: academicYear,
      term: term,
      start: _dateKey(start),
      end: _dateKey(end),
      name: '$academicYear 学年 · ${_termNames[term] ?? '第$term学期'}',
      totalWeeks: total,
    );
  }

  static List<Conflict> _findConflicts(List<Meeting> meetings, int maxWeek) {
    final out = <Conflict>[];
    final keys = <String>{};
    for (var week = 1; week <= maxWeek; week++) {
      for (var day = 1; day <= 7; day++) {
        final list = meetings.where((m) => m.day == day && m.weeks.contains(week)).toList();
        for (var i = 0; i < list.length; i++) {
          for (var j = i + 1; j < list.length; j++) {
            final a = list[i];
            final b = list[j];
            if (a.courseId == b.courseId) continue;
            if (a.startPeriod > b.endPeriod || b.startPeriod > a.endPeriod) continue;
            final key = '$week|$day|${a.courseId}|${b.courseId}';
            if (!keys.add(key)) continue;
            out.add(Conflict(
              week: week,
              day: day,
              startPeriod: math.max(a.startPeriod, b.startPeriod),
              endPeriod: math.min(a.endPeriod, b.endPeriod),
              meetingIds: [a.id, b.id],
              courseNames: [a.courseName, b.courseName],
            ));
          }
        }
      }
    }
    return out;
  }

  static int? _minutes(String clock) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(clock);
    return m == null ? null : int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  static int _int(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  static double? _doubleOrNull(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static String _str(dynamic v, [String fallback = '']) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? fallback : s;
  }

  static String _dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final b in value.codeUnits) {
      hash ^= b & 0xff;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(36);
  }
}

class _TempMeeting {
  final String courseId;
  final String courseName;
  final String sectionName;
  final String teacher;
  final String room;
  final String campus;
  final int day;
  final int startPeriod;
  final int endPeriod;
  List<int> weeks;
  final String rawWeeksText;
  final double? credits;
  final String courseCode;
  final String courseType;
  final String category;
  final String kind;
  final String rawKey;
  bool adjusted = false;
  String adjustNote = '';

  _TempMeeting({
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
    required this.rawWeeksText,
    required this.credits,
    required this.courseCode,
    required this.courseType,
    required this.category,
    required this.kind,
    required this.rawKey,
  });

  int get periodCount => endPeriod - startPeriod + 1;
}

class _MutableCourse {
  final String id;
  final String code;
  final String name;
  double? credits;
  final String type;
  final String category;
  final String kind;
  final List<String> teachers = [];
  final List<String> rooms = [];
  final List<Meeting> meetings = [];
  bool adjusted = false;

  _MutableCourse({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.type,
    required this.category,
    required this.kind,
  });
}
