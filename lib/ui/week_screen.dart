import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _WeekScreenState extends State<WeekScreen> with SingleTickerProviderStateMixin {
  final ScrollController _horizontal = ScrollController();
  final ValueNotifier<bool> _dragging = ValueNotifier(false);
  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();
  final ScrollController _vertical = ScrollController();
  late final _DragCoordinator _dragCoordinator;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    _dragCoordinator = _DragCoordinator(this, _dragging);
    _dragging.addListener(_dragStateChanged);
  }

  void _dragStateChanged() {
    if (_dragging.value) {
      if (_horizontal.hasClients) _horizontal.jumpTo(_horizontal.offset);
      if (_vertical.hasClients) _vertical.jumpTo(_vertical.offset);
    }
    if (mounted) setState(() {});
  }

  Schedule get schedule => widget.controller.schedule!;

  @override
  void dispose() {
    _dragging.removeListener(_dragStateChanged);
    _dragCoordinator.dispose();
    _vertical.dispose();
    _horizontal.dispose();
    _dragging.dispose();
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
      controller: _vertical,
      physics: _dragging.value ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        FadeSlideIn(delay: const Duration(milliseconds: 20), child: WeekHero(schedule: schedule, week: w)),
        const SizedBox(height: 12),
        const SizedBox(height: 10),
        FadeSlideIn(delay: const Duration(milliseconds: 90), child: _Timetable(
          schedule: schedule,
          week: w,
          horizontal: _horizontal,
          dragging: _dragging,
          gridKey: _gridKey,
          viewportKey: _viewportKey,
          coordinator: _dragCoordinator,
          durationMode: widget.controller.settings.durationMode,
          onCourseTap: (course, rect) => showCourseDetail(context, widget.controller, course, anchor: rect),
          onMoveMeeting: (meeting, day, start) => widget.controller.moveMeeting(meeting, day, start),
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
  final ValueNotifier<bool> dragging;
  final String durationMode;
  final void Function(Course course, Rect rect) onCourseTap;
  final Future<void> Function(Meeting meeting, int day, int start) onMoveMeeting;
  final GlobalKey gridKey;
  final GlobalKey viewportKey;
  final _DragCoordinator coordinator;

  const _Timetable({
    required this.schedule,
    required this.week,
    required this.horizontal,
    required this.dragging,
    required this.durationMode,
    required this.onCourseTap,
    required this.onMoveMeeting,
    required this.gridKey,
    required this.viewportKey,
    required this.coordinator,
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
            child: ValueListenableBuilder<bool>(
              valueListenable: dragging,
              builder: (_, active, child) => SingleChildScrollView(
              key: viewportKey,
              controller: horizontal,
              physics: active ? const NeverScrollableScrollPhysics() : null,
              scrollDirection: Axis.horizontal,
              child: child,
              ),
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
                    key: gridKey,
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
                            onMoveMeeting: onMoveMeeting,
                            gridKey: gridKey,
                            viewportKey: viewportKey,
                            coordinator: coordinator,
                            dragging: dragging,
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
  final Future<void> Function(Meeting meeting, int day, int start) onMoveMeeting;
  final GlobalKey gridKey;
  final GlobalKey viewportKey;
  final ValueNotifier<bool> dragging;
  final _DragCoordinator coordinator;

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
    required this.onMoveMeeting,
    required this.gridKey,
    required this.viewportKey,
    required this.dragging,
    required this.coordinator,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meetings = schedule.meetingsFor(week, day);
    final placements = _place(meetings);
    final nowTop = _nowTop();
    Widget block(Meeting m, {bool feedback = false}) {
      final course = schedule.courseById(m.courseId)!;
      return CourseBlock(
        meeting: m,
        course: course,
        conflict: schedule.conflicts.any((c) => c.week == week && c.meetingIds.contains(m.id)),
        compact: m.periodCount == 1,
        mode: durationMode,
        onTap: () {
          if (!feedback) onCourseTap(course, Rect.zero);
        },
        onTapRect: (rect) {
          if (!feedback) onCourseTap(course, rect);
        },
      );
    }
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
            child: _DraggableCourse(
              key: ValueKey('course-drag-${p.meeting.id}'),
              meeting: p.meeting,
              course: schedule.courseById(p.meeting.courseId)!,
              width: (width / p.lanes) - 4,
              height: p.meeting.periodCount * rowHeight + (p.meeting.periodCount - 1) * _Timetable.breakHeight - 4,
              gridKey: gridKey,
              viewportKey: viewportKey,
              dragging: dragging,
              dayWidth: _Timetable.dayWidth,
              rowHeight: rowHeight,
              breakHeight: _Timetable.breakHeight,
              onMove: onMoveMeeting,
              coordinator: coordinator,
              periodCount: periodCount,
              child: block(p.meeting),
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

class _DropCell {
  final int day;
  final int start;
  final Rect rect;
  const _DropCell(this.day, this.start, this.rect);
}

/// Parent-owned transaction: commit first, snap second, cleanup last.
class _DragCoordinator {
  final ValueNotifier<bool> dragging;
  final ValueNotifier<String?> activeId = ValueNotifier(null);
  late final AnimationController _snap;
  OverlayEntry? _entry;
  RenderBox? _overlayBox;
  GlobalKey? _gridKey;
  GlobalKey? _viewportKey;
  Meeting? _meeting;
  Widget? _child;
  Rect _source = Rect.zero;
  Rect _floating = Rect.zero;
  Rect _snapFrom = Rect.zero;
  Rect _snapTo = Rect.zero;
  Offset _grab = Offset.zero;
  _DropCell? _target;
  int _periodCount = 0;
  double _dayWidth = 88, _rowHeight = 56, _breakHeight = 4;
  bool _finishing = false;
  bool _disposed = false;

  _DragCoordinator(TickerProvider ticker, this.dragging) {
    _snap = AnimationController(vsync: ticker, duration: const Duration(milliseconds: 200))
      ..addListener(() => _entry?.markNeedsBuild());
  }

  Rect _overlayRect(Rect global) => global.shift(-(_overlayBox?.localToGlobal(Offset.zero) ?? Offset.zero));

  void start({required BuildContext context, required Meeting meeting, required Widget child,
      required Rect sourceRect, required Offset pointer, required GlobalKey gridKey,
      required GlobalKey viewportKey, required int periodCount, required double dayWidth,
      required double rowHeight, required double breakHeight}) {
    if (_disposed || _entry != null) return;
    _meeting = meeting;
    _gridKey = gridKey;
    _viewportKey = viewportKey;
    _periodCount = periodCount;
    _dayWidth = dayWidth;
    _rowHeight = rowHeight;
    _breakHeight = breakHeight;
    _source = sourceRect;
    _floating = sourceRect;
    _grab = pointer - sourceRect.topLeft;
    _child = InheritedTheme.captureAll(context, child);
    _finishing = false;
    _target = null;
    final overlay = Overlay.of(context, rootOverlay: true);
    _overlayBox = overlay.context.findRenderObject() as RenderBox?;
    _entry = OverlayEntry(builder: (_) {
      final rect = _finishing
          ? Rect.lerp(_snapFrom, _snapTo, Curves.easeOutCubic.transform(_snap.value))!
          : _floating;
      return IgnorePointer(child: Stack(children: [
        if (_target != null && !_finishing)
          Positioned.fromRect(rect: _overlayRect(_target!.rect), child: DecoratedBox(
            key: const ValueKey('course-drop-highlight'),
            decoration: BoxDecoration(color: const Color(0x334285F4),
              border: Border.all(color: const Color(0xFF4285F4), width: 2),
              borderRadius: BorderRadius.circular(12)),
          )),
        Positioned.fromRect(rect: _overlayRect(rect), child: Material(
          key: const ValueKey('course-drag-feedback'),
          color: Colors.transparent, elevation: 10, borderRadius: BorderRadius.circular(12),
          child: _child,
        )),
      ]));
    });
    overlay.insert(_entry!);
    activeId.value = meeting.id;
    dragging.value = true;
    move(pointer);
  }

  _DropCell? _hit(Offset pointer) {
    final box = _gridKey?.currentContext?.findRenderObject() as RenderBox?;
    final viewport = _viewportKey?.currentContext?.findRenderObject() as RenderBox?;
    final meeting = _meeting;
    if (box == null || viewport == null || meeting == null || meeting.periodCount > _periodCount) return null;
    final gridRect = box.localToGlobal(Offset.zero) & box.size;
    final visible = gridRect.intersect(viewport.localToGlobal(Offset.zero) & viewport.size);
    if (!visible.contains(pointer)) return null;
    final local = box.globalToLocal(pointer);
    final day = (local.dx / _dayWidth).floor() + 1;
    final rawStart = (local.dy / (_rowHeight + _breakHeight)).floor() + 1;
    if (day < 1 || day > 7 || rawStart < 1 || rawStart > _periodCount) return null;
    final start = rawStart.clamp(1, _periodCount - meeting.periodCount + 1);
    final topLeft = box.localToGlobal(Offset((day - 1) * _dayWidth + 2,
      (start - 1) * (_rowHeight + _breakHeight) + 2));
    return _DropCell(day, start, topLeft & Size(_dayWidth - 4,
      meeting.periodCount * _rowHeight + (meeting.periodCount - 1) * _breakHeight - 4));
  }

  void move(Offset pointer) {
    if (_entry == null || _finishing) return;
    _floating = (pointer - _grab) & _source.size;
    _target = _hit(pointer);
    _entry?.markNeedsBuild();
  }

  Future<void> finish({required Offset pointer, required Future<void> Function(Meeting, int, int) onMove,
      required bool reducedMotion, required void Function(Object) onError}) async {
    if (_entry == null || _finishing || _meeting == null) return;
    move(pointer);
    final target = _target;
    final meeting = _meeting!;
    _finishing = true;
    _snapFrom = _floating;
    _snapTo = target?.rect ?? _source;
    try {
      if (target != null) {
        // This updates effective grid data immediately. No overlay cleanup until persistence succeeds.
        await onMove(meeting, target.day, target.start);
      }
    } catch (e) {
      _snapTo = _source;
      onError(e);
    }
    if (_disposed) return;
    _snap.duration = reducedMotion ? Duration.zero : const Duration(milliseconds: 200);
    try { await _snap.forward(from: 0).orCancel; } on TickerCanceled { return; }
    if (!_disposed) _cleanup();
  }

  void cancel() {
    if (_finishing) return;
    _cleanup();
  }

  void _cleanup() {
    _entry?.remove();
    _entry = null;
    _meeting = null;
    _child = null;
    _target = null;
    _finishing = false;
    activeId.value = null;
    dragging.value = false;
  }

  void dispose() {
    _disposed = true;
    _entry?.remove();
    _entry = null;
    _snap.dispose();
    activeId.dispose();
  }
}

class _DraggableCourse extends StatefulWidget {
  final Meeting meeting;
  final Course course;
  final double width;
  final double height;
  final GlobalKey gridKey;
  final GlobalKey viewportKey;
  final ValueNotifier<bool> dragging;
  final double dayWidth;
  final double rowHeight;
  final double breakHeight;
  final int periodCount;
  final Future<void> Function(Meeting, int, int) onMove;
  final Widget child;
  final _DragCoordinator coordinator;
  const _DraggableCourse({super.key, required this.meeting, required this.course,
    required this.width, required this.height, required this.gridKey, required this.viewportKey,
    required this.dragging, required this.dayWidth, required this.rowHeight, required this.breakHeight,
    required this.periodCount, required this.onMove, required this.child, required this.coordinator});
  @override
  State<_DraggableCourse> createState() => _DraggableCourseState();
}

class _DraggableCourseState extends State<_DraggableCourse> {
  bool _started = false;
  void _start(LongPressStartDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    _started = true;
    HapticFeedback.mediumImpact();
    widget.coordinator.start(context: context, meeting: widget.meeting, child: widget.child,
      sourceRect: box.localToGlobal(Offset.zero) & box.size, pointer: d.globalPosition,
      gridKey: widget.gridKey, viewportKey: widget.viewportKey, periodCount: widget.periodCount,
      dayWidth: widget.dayWidth, rowHeight: widget.rowHeight, breakHeight: widget.breakHeight);
  }
  void _move(LongPressMoveUpdateDetails d) { if (_started) widget.coordinator.move(d.globalPosition); }
  void _end(LongPressEndDetails d) {
    if (!_started) return;
    _started = false;
    final messenger = ScaffoldMessenger.maybeOf(context);
    unawaited(widget.coordinator.finish(pointer: d.globalPosition, onMove: widget.onMove,
      reducedMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      onError: (e) => messenger?.showSnackBar(SnackBar(content: Text('移动失败：$e')))));
  }
  void _cancel() {
    if (!_started) return;
    _started = false;
    widget.coordinator.cancel();
  }
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque, onLongPressStart: _start, onLongPressMoveUpdate: _move,
    onLongPressEnd: _end, onLongPressCancel: _cancel,
    child: ValueListenableBuilder<String?>(valueListenable: widget.coordinator.activeId,
      builder: (_, active, child) => Opacity(opacity: active == widget.meeting.id ? 0 : 1, child: child),
      child: widget.child),
  );
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
