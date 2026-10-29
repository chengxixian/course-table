import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../app_controller.dart';
import '../models.dart';
import 'components.dart';
import '../pixel_icons.dart';

class CompactWidget extends StatelessWidget {
  final AppController controller;
  const CompactWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final schedule = controller.schedule;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (schedule == null) {
      return const Scaffold(body: Center(child: Text('暂无课表')));
    }
    final now = DateTime.now();
    final classes = schedule.todayMeetings(now);
    final next = schedule.nextClass(now: now, mode: controller.settings.durationMode);
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onPanStart: (_) {
            if (Platform.isWindows) windowManager.startDragging();
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('课程表 · 今天', style: TextStyle(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                const Spacer(),
                Text('第 ${schedule.currentWeek()} 周', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
              ]),
              const SizedBox(height: 10),
              Text('${now.month}月${now.day}日 · ${kWeekdays[now.weekday]}', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${classes.length} 节课', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 10),
              if (next != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(next.ongoing ? '正在上课' : '下一节课', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer.withValues(alpha: 0.7))),
                    const SizedBox(height: 3),
                    Text(next.meeting.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer)),
                    const SizedBox(height: 3),
                    Text('${next.meeting.startTime} · ${next.meeting.room}', style: TextStyle(fontSize: 10, color: scheme.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    CountdownTicker(builder: (_, __) => Text(countdownLabel(next), style: TextStyle(fontSize: 9, color: scheme.onPrimaryContainer))),
                  ]),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: classes.map((m) {
                    final color = CoursePalette.of(schedule.courseById(m.courseId)?.colorIndex ?? 0, context);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                      decoration: BoxDecoration(
                        color: color.container,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Text(m.startTime, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color.ink)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(m.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: color.ink))),
                      ]),
                    );
                  }).toList(),
                ),
              ),
              Row(children: [
                TextButton.icon(
                  onPressed: () async {
                    await controller.setCompactMode(false);
                    if (Platform.isWindows) {
                      await windowManager.setSize(const Size(1280, 840));
                      await windowManager.setAlwaysOnTop(false);
                      await windowManager.setSkipTaskbar(false);
                      await windowManager.setResizable(true);
                      await windowManager.center();
                    }
                  },
                  icon: Icon(PixelIcons.open_in_full, size: 15),
                  label: const Text('退出悬浮'),
                ),
                const Spacer(),
                IconButton(onPressed: controller.syncing ? null : () => controller.sync(), icon: Icon(PixelIcons.sync, size: 18)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
