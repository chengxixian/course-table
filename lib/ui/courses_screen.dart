import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import 'components.dart';
import '../pixel_icons.dart';

class CoursesScreen extends StatefulWidget {
  final AppController controller;
  const CoursesScreen({super.key, required this.controller});
  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final schedule = widget.controller.schedule!;
    final scheme = Theme.of(context).colorScheme;
    final courses = schedule.courses.where((c) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return [c.name, c.teacher, c.roomsText, c.code, c.type].any((v) => v.toLowerCase().contains(q));
    }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        PageHeader(
          kicker: '${schedule.semester.academicYear} · ${schedule.semester.name.split('· ').last}',
          title: '我的课程',
          subtitle: '${schedule.courses.length} 门课程 · ${schedule.meetings.length} 个上课安排',
        ),
        const SizedBox(height: 15),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: '搜索课程、老师或教室',
            prefixIcon: Icon(PixelIcons.search, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () => setState(() => _query = ''),
                    icon: Icon(PixelIcons.close, size: 17),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        if (courses.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 45),
            child: Column(children: [
              Icon(PixelIcons.search_off, size: 34, color: scheme.primary),
              const SizedBox(height: 8),
              const Text('没有找到相关课程', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('试试课程名称、任课教师或教室号。', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
            ]),
          )
        else
          ...courses.map((c) => _CourseCard(course: c, schedule: schedule, controller: widget.controller)),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final Schedule schedule;
  final AppController controller;
  const _CourseCard({required this.course, required this.schedule, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = CoursePalette.of(course.colorIndex, context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border(
                left: BorderSide(color: palette.accent, width: 4),
                top: BorderSide(color: scheme.outlineVariant),
                right: BorderSide(color: scheme.outlineVariant),
                bottom: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(15, 14, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: palette.container, borderRadius: BorderRadius.circular(12)),
                  child: Icon(courseIcon(course.colorIndex), color: palette.ink, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(course.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15.5)),
                  const SizedBox(height: 2),
                  Text('${course.teacher.isEmpty ? '—' : course.teacher}${course.credits == null ? '' : ' · ${course.credits} 学分'}',
                      style: TextStyle(fontSize: 9.5, color: scheme.onSurfaceVariant)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: palette.container, borderRadius: BorderRadius.circular(6)),
                  child: Text(course.weeksText, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: palette.ink)),
                ),
              ]),
              const SizedBox(height: 10),
              _MetaRow(icon: PixelIcons.calendar_today_outlined, text: course.scheduleText),
              const SizedBox(height: 4),
              _MetaRow(icon: PixelIcons.place_outlined, text: course.roomsText.isEmpty ? '地点待定' : course.roomsText),
              const SizedBox(height: 8),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 7),
              Row(children: [
                Text('${course.meetings.length} 个上课时段${course.adjusted ? ' · 含调课' : ''}', style: TextStyle(fontSize: 8.5, color: scheme.onSurfaceVariant)),
                const Spacer(),
                Text('${course.meetings.length} 个时段', style: TextStyle(fontSize: 8.5, color: scheme.onSurfaceVariant)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  _MetaRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 5),
      Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9.5, color: Theme.of(context).colorScheme.onSurfaceVariant))),
    ]);
  }
}
