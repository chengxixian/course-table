import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/manual_course.dart';
import '../lib/models.dart';
import '../lib/schedule_overlays.dart';
import '../lib/storage.dart';

const periods = [
  Period(1, '08:00', '08:45'), Period(2, '08:55', '09:40'),
  Period(3, '10:00', '10:45'), Period(4, '10:55', '11:40'),
  Period(5, '14:00', '14:45'), Period(6, '14:55', '15:40'),
];
Meeting meeting(String id, int day, int start, int end) => Meeting(
  id: id, courseId: id, courseName: id, sectionName: '', teacher: 'Teacher', room: 'A101', campus: '',
  day: day, startPeriod: start, endPeriod: end, weeks: const [1, 2], weeksText: '1-2',
  startTime: '08:00', endTime45: '09:30', endTimeActual: '09:40', credits: null,
  courseCode: '', courseType: '', category: '', kind: '',
);
Schedule sample([List<Meeting>? list]) {
  final items = list ?? [meeting('native', 1, 1, 2)];
  return Schedule(student: const Student(),
    semester: const Semester(academicYear: '2026', term: 1, start: '2026-08-31', end: '2027-01-17', name: 'term', totalWeeks: 20),
    periods: periods,
    courses: items.map((m) => Course(id: m.courseId, code: '', name: m.courseName, teacher: m.teacher,
      teachers: [m.teacher], rooms: [m.room], credits: null, type: '', category: '', kind: '', meetings: [m],
      weeks: m.weeks, weeksText: m.weeksText, roomsText: m.room, colorIndex: 0, adjusted: false)).toList(),
    meetings: items, conflicts: const [], fetchedAt: DateTime(2026, 11, 1));
}

void main() {
  test('native drag works with zero manual courses, keeps one element and updates clocks', () {
    final base = sample();
    final result = ScheduleOverlays.compose(base, const [], const [MeetingMove(meetingId: 'native', day: 3, startPeriod: 5, endPeriod: 6)]);
    expect(result.meetings, hasLength(1));
    expect(result.meetings.single.day, 3);
    expect(result.meetings.single.startPeriod, 5);
    expect(result.meetings.single.startTime, '14:00');
    expect(result.meetings.single.endTime45, '15:30');
    expect(result.meetings.single.endTimeActual, '15:40');
    expect(result.courses.single.meetings.single, same(result.meetings.single));
    expect(base.meetings.single.day, 1, reason: 'base remains unchanged');
  });

  test('drop on last row preserves two-period span instead of truncating', () {
    expect(ScheduleOverlays.destination(sample(), 6, 2), (5, 6));
  });

  test('recomposing after reload retains move and recomputes conflicts', () {
    final base = sample([meeting('one', 1, 1, 2), meeting('two', 2, 5, 6)]);
    const moves = [MeetingMove(meetingId: 'one', day: 2, startPeriod: 5, endPeriod: 6)];
    final first = ScheduleOverlays.compose(base, const [], moves);
    final reloaded = ScheduleOverlays.compose(base, const [], moves);
    expect(reloaded.meetings.first.day, first.meetings.first.day);
    expect(reloaded.conflicts, hasLength(2));
  });

  test('manual entries and native moves coexist independently', () {
    final result = ScheduleOverlays.compose(sample(), const [ManualCourseEntry(id: 'm', name: 'Manual', day: 4, startPeriod: 3, endPeriod: 4)],
      const [MeetingMove(meetingId: 'native', day: 3, startPeriod: 5, endPeriod: 6)]);
    expect(result.meetings, hasLength(2));
    expect(result.meetings.first.day, 3);
    expect(result.meetings.last.day, 4);
    expect(result.meetings.last.endTime45, '11:30');
  });

  test('clear removes persisted move overrides so they cannot resurrect', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = AppStorage(await SharedPreferences.getInstance());
    await storage.saveMeetingMoves(const [MeetingMove(meetingId: 'native', day: 3, startPeriod: 5, endPeriod: 6)]);
    expect(storage.loadMeetingMoves(), hasLength(1));
    await storage.clearCourses();
    expect(storage.loadMeetingMoves(), isEmpty);
  });
}
