import 'manual_course.dart';
import 'models.dart';

/// Pure composition: base timetable is never mutated by local edits.
class ScheduleOverlays {
  static List<Period> periodsFor(Schedule base) {
    final map = <int, Period>{for (final p in base.periods) if (p.index > 0) p.index: p};
    final periods = map.values.toList()..sort((a, b) => a.index.compareTo(b.index));
    return periods.isNotEmpty ? periods : const [
      Period(1, '08:00', '08:45'), Period(2, '08:55', '09:40'),
      Period(3, '10:00', '10:45'), Period(4, '10:55', '11:40'),
      Period(5, '14:00', '14:45'), Period(6, '14:55', '15:40'),
      Period(7, '16:00', '16:45'), Period(8, '16:55', '17:40'),
      Period(9, '19:00', '19:45'), Period(10, '19:55', '20:40'),
    ];
  }

  static (int, int) destination(Schedule base, int requested, int duration) {
    final periods = periodsFor(base);
    final max = periods.last.index;
    final count = duration.clamp(1, max);
    final candidates = periods.where((p) => p.index + count - 1 <= max &&
      List.generate(count, (i) => p.index + i).every((index) => periods.any((v) => v.index == index))).toList();
    if (candidates.isEmpty) throw StateError('作息表没有容纳该连堂课程的连续节次');
    candidates.sort((a, b) => (a.index - requested).abs().compareTo((b.index - requested).abs()));
    final start = candidates.first.index;
    return (start, start + count - 1);
  }

  static Meeting relocate(Schedule base, Meeting m, int day, int requested) {
    final range = destination(base, requested, m.periodCount);
    final periods = periodsFor(base);
    final start = periods.firstWhere((p) => p.index == range.$1).start;
    final actual = periods.firstWhere((p) => p.index == range.$2).end;
    final minutes = Schedule.parseMinutes(start);
    return m.copyWith(
      day: day.clamp(1, 7), startPeriod: range.$1, endPeriod: range.$2,
      startTime: start,
      endTime45: minutes == null ? actual : Schedule.formatMinutes(minutes + m.periodCount * 45),
      endTimeActual: actual,
    );
  }

  static Schedule compose(Schedule base, List<ManualCourseEntry> manual, List<MeetingMove> moves) {
    if (manual.isEmpty && moves.isEmpty) return base;
    final moved = {for (final m in moves) m.meetingId: m};
    final meetings = base.meetings.map((m) {
      final move = moved[m.id];
      if (move == null) return m;
      try { return relocate(base, m, move.day, move.startPeriod); } catch (_) { return m; }
    }).toList();
    final courses = base.courses.map((c) => _course(c, meetings.where((m) => m.courseId == c.id).toList())).toList();
    for (final entry in manual) {
      final range = destination(base, entry.startPeriod, entry.endPeriod - entry.startPeriod + 1);
      final periods = periodsFor(base);
      final startTime = periods.firstWhere((p) => p.index == range.$1).start;
      final endActual = periods.firstWhere((p) => p.index == range.$2).end;
      final minutes = Schedule.parseMinutes(startTime);
      final weeks = entry.weeks.isEmpty ? List.generate(base.semester.totalWeeks, (i) => i + 1) : entry.weeks;
      final id = 'manual_${entry.id}';
      final m = Meeting(
        id: id, courseId: id, courseName: entry.name, sectionName: '手动添加',
        teacher: entry.teacher, room: entry.room, campus: '', day: entry.day.clamp(1, 7),
        startPeriod: range.$1, endPeriod: range.$2, weeks: weeks,
        weeksText: entry.weeksText.isEmpty ? '1-${base.semester.totalWeeks}' : entry.weeksText,
        startTime: startTime,
        endTime45: minutes == null ? endActual : Schedule.formatMinutes(minutes + (range.$2 - range.$1 + 1) * 45),
        endTimeActual: endActual, credits: null, courseCode: '', courseType: '手动', category: '手动', kind: 'manual',
      );
      meetings.add(m);
      courses.add(Course(id: id, code: '', name: entry.name, teacher: entry.teacher,
        teachers: entry.teacher.isEmpty ? const [] : [entry.teacher], rooms: entry.room.isEmpty ? const [] : [entry.room],
        credits: null, type: '手动', category: '手动', kind: 'manual', meetings: [m], weeks: weeks,
        weeksText: m.weeksText, roomsText: entry.room, colorIndex: entry.colorIndex % 7, adjusted: false));
    }
    final conflicts = <Conflict>[];
    for (var i = 0; i < meetings.length; i++) {
      final a = meetings[i];
      for (var j = i + 1; j < meetings.length; j++) {
        final b = meetings[j];
        if (a.day != b.day || a.endPeriod < b.startPeriod || b.endPeriod < a.startPeriod) continue;
        for (final week in a.weeks.toSet().intersection(b.weeks.toSet())) {
          conflicts.add(Conflict(week: week, day: a.day,
            startPeriod: a.startPeriod > b.startPeriod ? a.startPeriod : b.startPeriod,
            endPeriod: a.endPeriod < b.endPeriod ? a.endPeriod : b.endPeriod,
            meetingIds: [a.id, b.id], courseNames: [a.courseName, b.courseName]));
        }
      }
    }
    return Schedule(student: base.student, semester: base.semester, periods: periodsFor(base),
      courses: courses, meetings: meetings, conflicts: conflicts, fetchedAt: base.fetchedAt, source: base.source);
  }

  static Course _course(Course c, List<Meeting> meetings) => Course(
    id: c.id, code: c.code, name: c.name, teacher: c.teacher, teachers: c.teachers, rooms: c.rooms,
    credits: c.credits, type: c.type, category: c.category, kind: c.kind, meetings: meetings,
    weeks: c.weeks, weeksText: c.weeksText, roomsText: c.roomsText, colorIndex: c.colorIndex, adjusted: c.adjusted);
}
