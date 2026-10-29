import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../calendar_export.dart';
import '../models.dart';
import 'components.dart';
import 'time_scene.dart';
import '../pixel_icons.dart';

class TodayScreen extends StatelessWidget {
  final AppController controller;
  const TodayScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final schedule = controller.schedule!;
    final now = DateTime.now();
    final week = schedule.currentWeek(now);
    final classes = schedule.todayMeetings(now);
    final next = schedule.nextClass(now: now, mode: controller.settings.durationMode);
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        PageHeader(
          kicker: week > 0 ? '第 $week 教学周 · ${schedule.semester.academicYear}' : '假期',
          title: '${formatDateCN(now)} · ${kWeekdays[now.weekday]}',
          subtitle: classes.isEmpty ? '今天没有课，享受属于自己的时间。' : '今天有 ${classes.map((m) => m.courseId).toSet().length} 门课程，第一节课 ${classes.first.startTime} 开始。',
          titleSize: 26,
          actions: [
            IconButton.filledTonal(
              onPressed: () async {
                final ok = await controller.addNextToGoogle();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '已打开 Google 日历（下一节课）' : '接下来没有课程')));
              },
              icon: Icon(PixelIcons.event_available_outlined),
              tooltip: '添加下一节课',
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              onPressed: () => exportAllCourses(context, controller),
              icon: Icon(PixelIcons.ios_share),
              tooltip: '导出全部课程',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TodayNextCard(next: next, schedule: schedule, controller: controller),
        const SizedBox(height: 14),
        Row(children: [
          Text('今日安排', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
          const Spacer(),
          Text('${classes.length} 节', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
        ]),
        const SizedBox(height: 8),
        if (classes.isEmpty)
          _EmptyToday(scheme: scheme)
        else
          ...classes.map((m) => _TimelineItem(meeting: m, schedule: schedule, controller: controller)),
        const SizedBox(height: 14),
        if (classes.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: [
            _SummaryPill(icon: PixelIcons.menu_book_outlined, title: '${classes.map((m) => m.courseId).toSet().length} 门课程', subtitle: '今天'),
            _SummaryPill(icon: PixelIcons.schedule, title: '${classes.first.startTime} – ${classes.last.endTime(controller.settings.durationMode)}', subtitle: '第一节到最后一节'),
            _SummaryPill(
              icon: PixelIcons.hourglass_bottom,
              title: '${classes.fold<int>(0, (sum, m) => sum + m.periodCount)} 节',
              subtitle: '共 ${(_classMinutes(classes, controller.settings.durationMode) / 60).toStringAsFixed(1)} 小时',
            ),
          ]),
      ],
    );
  }
}

class _TodayNextCard extends StatelessWidget {
  final NextClass? next;
  final Schedule schedule;
  final AppController controller;
  const _TodayNextCard({required this.next, required this.schedule, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (next == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(26), border: Border.all(color: scheme.outlineVariant)),
        child: Row(children: [
          Icon(PixelIcons.nightlight_round, color: scheme.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('今天的课已经结束', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface)),
            const SizedBox(height: 3),
            Text('把时间留给自己，或准备一下明天。', style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
          ])),
        ]),
      );
    }
    final nextClass = next!;
    final m = nextClass.meeting;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: TimeScene(time: DateTime.now(), blur: 14, scrimOpacity: 0.36),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(nextClass.ongoing ? PixelIcons.play_circle_outline : PixelIcons.auto_awesome, size: 14, color: Colors.white70),
          const SizedBox(width: 5),
          Text(nextClass.ongoing ? '正在上课' : '下一节课', style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
          const Spacer(),
          Text(nextClass.meeting.room, style: const TextStyle(fontSize: 9.5, color: Colors.white60)),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(nextClass.meeting.startTime, style: const TextStyle(fontSize: 42, height: 1, color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: -2)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('– ${m.endTime(controller.settings.durationMode)}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ),
          const Spacer(),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(courseIcon(schedule.courseById(m.courseId)?.colorIndex ?? 0), color: Colors.white, size: 20),
          ),
        ]),
        const SizedBox(height: 8),
        Text(m.courseName, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: -0.4)),
        const SizedBox(height: 3),
        Text('${m.teacher} · 第 ${m.startPeriod}-${m.endPeriod} 节', style: const TextStyle(fontSize: 10, color: Colors.white60)),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(PixelIcons.timer_outlined, size: 13, color: Colors.white.withValues(alpha: 0.75)),
            const SizedBox(width: 5),
            CountdownTicker(builder: (_, __) => Text(countdownLabel(next), style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600))),
            const Spacer(),
            TextButton.icon(
              onPressed: () => showCourseDetail(context, controller, schedule.courseById(m.courseId)!),
              style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: Icon(PixelIcons.open_in_new, size: 13),
              label: const Text('详情', style: TextStyle(fontSize: 9)),
            ),
          ]),
        ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Meeting meeting;
  final Schedule schedule;
  final AppController controller;
  const _TimelineItem({required this.meeting, required this.schedule, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final start = Schedule.parseMinutes(meeting.startTime) ?? 0;
    final end = Schedule.parseMinutes(meeting.endTime(controller.settings.durationMode)) ?? 0;
    final nowMin = now.hour * 60 + now.minute;
    final isPast = nowMin > end;
    final isNow = nowMin >= start && nowMin <= end;
    final palette = CoursePalette.of(schedule.courseById(meeting.courseId)?.colorIndex ?? 0, context);
    return InkWell(
      onTap: () => showCourseDetail(context, controller, schedule.courseById(meeting.courseId)!),
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isPast ? 0.5 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isNow ? scheme.primaryContainer : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: palette.accent, width: 3)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 42,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meeting.startTime, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isNow ? scheme.onPrimaryContainer : scheme.onSurface)),
                Text(meeting.endTime(controller.settings.durationMode), style: TextStyle(fontSize: 8, color: isNow ? scheme.onPrimaryContainer.withValues(alpha: 0.65) : scheme.onSurfaceVariant)),
              ]),
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(meeting.courseName, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: isNow ? scheme.onPrimaryContainer : scheme.onSurface))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: isNow ? Colors.black.withValues(alpha: 0.08) : scheme.surfaceContainer, borderRadius: BorderRadius.circular(5)),
                  child: Text(isPast ? '已结束' : (isNow ? '进行中' : '待开始'), style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: isNow ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)),
                ),
              ]),
              const SizedBox(height: 3),
              Text('${meeting.room} · ${meeting.teacher} · 第 ${meeting.startPeriod}-${meeting.endPeriod} 节',
                  style: TextStyle(fontSize: 9, color: isNow ? scheme.onPrimaryContainer.withValues(alpha: 0.7) : scheme.onSurfaceVariant)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  _SummaryPill({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(14), border: Border.all(color: scheme.outlineVariant)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 7),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(fontSize: 8, color: scheme.onSurfaceVariant)),
        ]),
      ]),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  final ColorScheme scheme;
  const _EmptyToday({required this.scheme});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34),
      decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(20), border: Border.all(color: scheme.outlineVariant)),
      child: Column(children: [
        Icon(PixelIcons.wb_sunny_outlined, size: 34, color: scheme.primary),
        const SizedBox(height: 8),
        const Text('今天没有课', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('去图书馆，或者去校园里走走。', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

int _classMinutes(List<Meeting> classes, String mode) {
  var total = 0;
  for (final m in classes) {
    final start = Schedule.parseMinutes(m.startTime) ?? 0;
    final end = Schedule.parseMinutes(m.endTime(mode)) ?? start;
    total += end - start;
  }
  return total;
}



