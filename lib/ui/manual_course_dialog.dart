import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../manual_course.dart';

Future<void> showManualCourseDialog(BuildContext context, AppController controller) async {
  final schedule = controller.schedule;
  if (schedule == null) return;
  final maxPeriod = schedule.periods.length;
  if (maxPeriod < 1) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('缺少节次信息，暂时无法手动添加课程')));
    return;
  }
  final totalWeeks = schedule.semester.totalWeeks > 0 ? schedule.semester.totalWeeks : 1;
  final name = TextEditingController();
  final teacher = TextEditingController();
  final room = TextEditingController();
  final weeks = TextEditingController(text: '1-$totalWeeks');
  var day = 1;
  var start = 1;
  var end = maxPeriod >= 2 ? 2 : 1;
  String? nameError;
  const fieldPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
        title: const Text('手动添加课程'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '课程名称',
                isDense: true,
                labelStyle: const TextStyle(fontSize: 12),
                errorText: nameError,
                errorStyle: const TextStyle(fontSize: 10),
              ),
              onChanged: (_) {
                if (nameError != null) setState(() => nameError = null);
              },
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: teacher, decoration: const InputDecoration(labelText: '教师', isDense: true, labelStyle: TextStyle(fontSize: 12)))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: room, decoration: const InputDecoration(labelText: '教室', isDense: true, labelStyle: TextStyle(fontSize: 12)))),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: day,
              isExpanded: true,
              dropdownColor: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              decoration: InputDecoration(labelText: '星期', isDense: true, contentPadding: fieldPadding, labelStyle: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              items: [for (var i = 1; i <= 7; i++) DropdownMenuItem(value: i, child: Text('周${['一','二','三','四','五','六','日'][i-1]}', style: TextStyle(color: scheme.onSurface)))],
              onChanged: (v) => setState(() => day = v ?? 1),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<int>(
                initialValue: start,
                isExpanded: true,
                dropdownColor: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
                decoration: InputDecoration(labelText: '开始', isDense: true, contentPadding: fieldPadding, labelStyle: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                items: [for (var i = 1; i <= maxPeriod; i++) DropdownMenuItem(value: i, child: Text('第 $i 节', style: TextStyle(color: scheme.onSurface)))],
                onChanged: (v) => setState(() { start = v ?? 1; if (end < start) end = start; }),
              )),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonFormField<int>(
                initialValue: end,
                isExpanded: true,
                dropdownColor: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(fontSize: 13, color: scheme.onSurface),
                decoration: InputDecoration(labelText: '结束', isDense: true, contentPadding: fieldPadding, labelStyle: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                items: [for (var i = start; i <= maxPeriod; i++) DropdownMenuItem(value: i, child: Text('第 $i 节', style: TextStyle(color: scheme.onSurface)))],
                onChanged: (v) => setState(() => end = v ?? start),
              )),
            ]),
            const SizedBox(height: 12),
            TextField(controller: weeks, decoration: const InputDecoration(labelText: '周次', hintText: '例如 1-16 或 1-8,10-16', isDense: true, labelStyle: TextStyle(fontSize: 12))),
            const SizedBox(height: 6),
            Text('手动课程会单独保存，教务同步不会覆盖。', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
          ]),
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final trimmed = name.text.trim();
              if (trimmed.isEmpty) {
                setState(() => nameError = '请输入课程名称');
                return;
              }
              final weekList = parseManualWeeks(weeks.text, totalWeeks);
              final entry = ManualCourseEntry(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                name: trimmed,
                teacher: teacher.text.trim(),
                room: room.text.trim(),
                day: day,
                startPeriod: start,
                endPeriod: end,
                weeks: weekList,
                weeksText: weeks.text.trim(),
                colorIndex: trimmed.codeUnits.fold(0, (a, b) => a + b) % 7,
              );
              Navigator.pop(ctx);
              controller.addManualCourse(entry);
            },
            child: const Text('添加'),
          ),
        ],
        );
      },
    ),
  );
  name.dispose();
  teacher.dispose();
  room.dispose();
  weeks.dispose();
}
