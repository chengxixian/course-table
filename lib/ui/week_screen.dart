import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import 'components.dart';
import 'motion.dart';
import '../pixel_icons.dart';

class WeekScreen extends StatefulWidget {
  final AppController controller;
  final int week;
  final ValueChanged<int> onWeekChange;
  const WeekScreen({super.key, required this.controller, required this.week, required this.onWeekChange});
  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  final ScrollController _horizontal = ScrollController();
  bool _initialScrollDone = false;

  Schedule get schedule => widget.controller.schedule!;

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  int get week {
    final total = schedule.semester.totalWeeks;
    return widget.week.clamp(1, total);
  }

  @override
  Widget build(BuildContext context) {
    final currentWeek = schedule.currentWeek();
    final w = week;
    if (!_initialScrollDone) {
      _initialScrollDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        FadeSlideIn(delay: const Duration(milliseconds: 20), child: WeekHero(schedule: schedule, week: w)),
        const SizedBox(height: 12),
        const SizedBox(height: 10),
        FadeSlideIn(delay: const Duration(milliseconds: 90), child: _Timetable(
          schedule: schedule,
          week: w,
          horizontal: _horizontal,
          durationMode: widget.controller.settings.durationMode,
          onCourseTap: (course, rect) => showCourseDetail(context, widget.controller, course, anchor: rect),
        )),
        const SizedBox(height: 10),
        Row(children: [
          Icon(PixelIcons.info_outline, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Expanded(child: Text('课程时间以教务系统节次为准；日历默认按每节 45 分钟生成，不含课间。',
              style: TextStyle(fontSize: 9.5, height: 1.4, color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ]),
      ],
    );
  }

  void _scrollToToday() {
    if (!_horizontal.hasClients) return;
    final weekday = DateTime.now().weekday;
    final target = (weekday - 1) * (_Timetable.dayWidth) - 80;
    _horizontal.jumpTo(target.clamp(0, _horizontal.position.maxScrollExtent));
  }
}

class _Timetable extends StatelessWidget {
  static const double dayWidth = 88;
  static const double timeWidth = 48;
  static const double rowHeight = 56;
  static const double breakHeight = 4;

  final Schedule schedule;
  final int week;
  final ScrollController horizontal;
  final String durationMode;
  final void Function(Course course, Rect rect) onCourseTap;

  const _Timetable({
    required this.schedule,
    required this.week,
    required this.horizontal,
    required this.durationMode,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final periods = schedule.periods.isEmpty ? ScheduleParserProxy.periods : schedule.periods;
    final currentWeek = schedule.currentWeek();
    final today = DateTime.now();
    final height = periods.length * rowHeight + (periods.length - 1) * breakHeight;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timeWidth,
            child: Column(children: [
              SizedBox(
                height: 48,
                child: Center(child: Text('节', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant))),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              for (final p in periods) ...[
                SizedBox(
                  height: rowHeight,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${p.index}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                    Text('${p.start}–${p.end}', style: TextStyle(fontSize: 6.5, color: scheme.outline, height: 1.1)),
                  ]),
                ),
                if (p.index != periods.last.index) SizedBox(height: breakHeight),
              ],
            ]),
          ),
          VerticalDivider(width: 1, thickness: 1, color: scheme.outlineVariant),
          Expanded(
            child: SingleChildScrollView(
              controller: horizontal,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: dayWidth * 7,
                child: Column(children: [
                  Row(children: [
                    for (var day = 1; day <= 7; day++)
                      _DayHeader(
                        day: day,
                        date: schedule.dateForWeekDay(week, day),
                        isToday: _isSameDate(schedule.dateForWeekDay(week, day), today),
                        width: dayWidth,
                      ),
                  ]),
                  Divider(height: 1, color: scheme.outlineVariant),
                  SizedBox(
                    height: height,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          _DayColumn(
                            schedule: schedule,
                            week: week,
                            day: day,
                            width: dayWidth,
                            height: height,
                            rowHeight: rowHeight,
                            periodCount: periods.length,
                            durationMode: durationMode,
                            isToday: currentWeek == week && day == today.weekday,
                            isWeekend: day >= 6,
                            onCourseTap: onCourseTap,
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayHeader extends StatelessWidget {
  final int day;
  final DateTime date;
  final bool isToday;
  final double width;
  const _DayHeader({required this.day, required this.date, required this.isToday, required this.width});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        color: isToday ? scheme.primaryContainer.withValues(alpha: 0.24) : null,
        border: Border(left: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(kWeekdays[day], style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: isToday ? scheme.primary : scheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: isToday ? BoxDecoration(color: scheme.primary, shape: BoxShape.circle) : null,
          child: Text('${date.day}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isToday ? scheme.onPrimary : scheme.onSurface)),
        ),
      ]),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final Schedule schedule;
  final int week;
  final int day;
  final double width;
  final double height;
  final double rowHeight;
  final int periodCount;
  final String durationMode;
  final bool isToday;
  final bool isWeekend;
  final void Function(Course course, Rect rect) onCourseTap;

  const _DayColumn({
    required this.schedule,
    required this.week,
    required this.day,
    required this.width,
    required this.height,
    required this.rowHeight,
    required this.periodCount,
    required this.durationMode,
    required this.isToday,
    required this.isWeekend,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meetings = schedule.meetingsFor(week, day);
    final placements = _place(meetings);
    final nowTop = _nowTop();
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isToday ? scheme.primaryContainer.withValues(alpha: 0.07) : (isWeekend ? scheme.surfaceContainerLow : null),
        border: Border(left: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Stack(children: [
        Column(children: [
          for (var i = 0; i < periodCount; i++) ...[
            Container(height: rowHeight, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.28))))),
            if (i != periodCount - 1) const SizedBox(height: _Timetable.breakHeight),
          ],
        ]),
        for (final p in placements)
          Positioned(
            top: (p.meeting.startPeriod - 1) * (rowHeight + _Timetable.breakHeight) + 2,
            left: p.lane * (width / p.lanes) + 2,
            width: (width / p.lanes) - 4,
            height: p.meeting.periodCount * rowHeight + (p.meeting.periodCount - 1) * _Timetable.breakHeight - 4,
            child: CourseBlock(
              meeting: p.meeting,
              course: schedule.courseById(p.meeting.courseId)!,
              conflict: schedule.conflicts.any((c) => c.week == week && c.meetingIds.contains(p.meeting.id)),
              compact: p.meeting.periodCount == 1,
              mode: durationMode,
              onTap: () => onCourseTap(schedule.courseById(p.meeting.courseId)!, Rect.zero),
              onTapRect: (rect) => onCourseTap(schedule.courseById(p.meeting.courseId)!, rect),
            ),
          ),
        if (isToday && nowTop != null)
          Positioned(
            top: nowTop,
            left: 0,
            right: 0,
            child: Container(height: 1.5, color: scheme.error, child: Align(alignment: Alignment.centerLeft, child: Container(width: 5, height: 5, decoration: BoxDecoration(color: scheme.error, shape: BoxShape.circle)))),
          ),
      ]),
    );
  }

  double? _nowTop() {
    if (!isToday) return null;
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    for (final p in schedule.periods) {
      final start = Schedule.parseMinutes(p.start);
      final end = Schedule.parseMinutes(p.end);
      if (start == null || end == null) continue;
      if (minutes < start) return ((p.index - 1) * (rowHeight + _Timetable.breakHeight)).toDouble();
      if (minutes <= end) {
        return (p.index - 1) * (rowHeight + _Timetable.breakHeight) + ((minutes - start) / (end - start)) * rowHeight;
      }
    }
    return (periodCount * (rowHeight + _Timetable.breakHeight) - _Timetable.breakHeight).toDouble();
  }

  List<_Placement> _place(List<Meeting> meetings) {
    if (meetings.isEmpty) return [];
    final sorted = [...meetings]..sort((a, b) => a.startPeriod == b.startPeriod ? a.endPeriod - b.endPeriod : a.startPeriod - b.startPeriod);
    final clusters = <List<Meeting>>[];
    var current = <Meeting>[];
    var clusterEnd = -1;
    for (final m in sorted) {
      if (current.isNotEmpty && m.startPeriod > clusterEnd) {
        clusters.add(current);
        current = [];
        clusterEnd = -1;
      }
      current.add(m);
      if (m.endPeriod > clusterEnd) clusterEnd = m.endPeriod;
    }
    if (current.isNotEmpty) clusters.add(current);
    final out = <_Placement>[];
    for (final group in clusters) {
      final laneEnds = <int>[];
      final groupPlacements = <_Placement>[];
      for (final m in group) {
        var lane = 0;
        while (lane < laneEnds.length && laneEnds[lane] >= m.startPeriod) {
          lane++;
        }
        if (lane == laneEnds.length) {
          laneEnds.add(m.endPeriod);
        } else {
          laneEnds[lane] = m.endPeriod;
        }
        groupPlacements.add(_Placement(m, lane));
      }
      for (final p in groupPlacements) {
        out.add(_Placement(p.meeting, p.lane, laneEnds.length));
      }
    }
    return out;
  }
}

class _Placement {
  final Meeting meeting;
  final int lane;
  final int lanes;
  const _Placement(this.meeting, this.lane, [this.lanes = 1]);
}

// Keeps a reference to the fallback periods without importing parser.dart into
// every widget file.
class ScheduleParserProxy {
  static const periods = [
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
}
