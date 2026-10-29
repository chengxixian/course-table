import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../calendar_export.dart';
import '../models.dart';
import '../pixel_icons.dart';
import 'motion.dart';

class CoursePalette {
  final Color accent;
  final Color container;
  final Color ink;
  const CoursePalette(this.accent, this.container, this.ink);

  static const _light = [
    CoursePalette(Color(0xFF006A60), Color(0xFFC9F5ED), Color(0xFF003731)),
    CoursePalette(Color(0xFF3D5F90), Color(0xFFD9E3F8), Color(0xFF0B2545)),
    CoursePalette(Color(0xFF6750A4), Color(0xFFEADCFF), Color(0xFF21005D)),
    CoursePalette(Color(0xFF8B5000), Color(0xFFFFDCC1), Color(0xFF2E1500)),
    CoursePalette(Color(0xFF3F6212), Color(0xFFD9E7B8), Color(0xFF1A2E00)),
    CoursePalette(Color(0xFF8E3B55), Color(0xFFFFD9E2), Color(0xFF3B0718)),
    CoursePalette(Color(0xFF455E91), Color(0xFFDDE6FF), Color(0xFF102347)),
    CoursePalette(Color(0xFF745B00), Color(0xFFFFE08A), Color(0xFF221B00)),
  ];

  static const _dark = [
    CoursePalette(Color(0xFF54DBC9), Color(0xFF005048), Color(0xFF74F8E5)),
    CoursePalette(Color(0xFFADC6F8), Color(0xFF284669), Color(0xFFD9E3F8)),
    CoursePalette(Color(0xFFCFBCFF), Color(0xFF4C397A), Color(0xFFEADCFF)),
    CoursePalette(Color(0xFFFFB86C), Color(0xFF653D00), Color(0xFFFFDCC1)),
    CoursePalette(Color(0xFFB5D389), Color(0xFF364D0B), Color(0xFFD9E7B8)),
    CoursePalette(Color(0xFFFFB1C3), Color(0xFF6C2C42), Color(0xFFFFD9E2)),
    CoursePalette(Color(0xFFB6C6FF), Color(0xFF2C4778), Color(0xFFDDE6FF)),
    CoursePalette(Color(0xFFF0C940), Color(0xFF564500), Color(0xFFFFE08A)),
  ];

  static CoursePalette of(int index, BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final list = dark ? _dark : _light;
    return list[index % list.length];
  }
}

IconData courseIcon(int index) {
  final icons = [
    PixelIcons.calculate_outlined,
    PixelIcons.architecture_outlined,
    PixelIcons.sports_tennis_outlined,
    PixelIcons.computer_outlined,
    PixelIcons.precision_manufacturing_outlined,
    PixelIcons.translate_outlined,
    PixelIcons.balance_outlined,
    PixelIcons.explore_outlined,
  ];
  return icons[index % icons.length];
}

class CourseBlock extends StatelessWidget {
  final Meeting meeting;
  final Course course;
  final bool conflict;
  final VoidCallback onTap;
  final void Function(Rect rect)? onTapRect;
  final bool compact;
  final String mode;

  const CourseBlock({
    super.key,
    required this.meeting,
    required this.course,
    required this.conflict,
    required this.onTap,
    this.onTapRect,
    this.compact = false,
    this.mode = '45',
  });

  @override
  Widget build(BuildContext context) {
    final palette = CoursePalette.of(course.colorIndex, context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && onTapRect != null) {
            onTapRect!(box.localToGlobal(Offset.zero) & box.size);
          } else {
            onTap();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.fromLTRB(compact ? 6 : 7, compact ? 5 : 6, 5, compact ? 5 : 6),
          decoration: BoxDecoration(
            color: palette.container,
            borderRadius: BorderRadius.circular(12),
            border: conflict
                ? Border.all(color: Theme.of(context).colorScheme.error, width: 1.6)
                : Border(left: BorderSide(color: palette.accent, width: 3)),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${meeting.startTime}–${meeting.endTime(mode)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 7.5 : 8.5, height: 1.1, fontWeight: FontWeight.w700, color: palette.ink.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meeting.courseName,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 10 : 11, height: 1.2, fontWeight: FontWeight.w700, color: palette.ink, letterSpacing: -0.1),
                  ),
                  if (!compact && meeting.room.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meeting.room,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 8, height: 1.1, color: palette.ink.withValues(alpha: 0.72)),
                    ),
                  ],
                ],
              ),
              if (conflict)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(PixelIcons.warning_amber_rounded, size: 11, color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool warning;
  final VoidCallback? onTap;

  const StatChip({super.key, this.icon, required this.label, this.warning = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: warning ? scheme.tertiaryContainer : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: warning ? Colors.transparent : scheme.outlineVariant),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 14, color: warning ? scheme.onTertiaryContainer : scheme.onSurfaceVariant), const SizedBox(width: 5)],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: warning ? scheme.onTertiaryContainer : scheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class WeekHero extends StatelessWidget {
  final Schedule schedule;
  final int week;
  const WeekHero({super.key, required this.schedule, required this.week});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = schedule.dateForWeekDay(week, 1);
    final end = schedule.dateForWeekDay(week, 7);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 5,
          height: 44,
          decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(formatRangeCN(start, end), style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 3),
            Text('第 $week 周', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.7)),
          ]),
        ),
        Text('$week / ${schedule.semester.totalWeeks}', style: TextStyle(fontSize: 9.5, color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

class WeekSwitcher extends StatelessWidget {
  final int week;
  final int current;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onCurrent;
  const WeekSwitcher({super.key, required this.week, required this.current, required this.total, required this.onPrev, required this.onNext, required this.onCurrent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      IconButton.filledTonal(onPressed: week > 1 ? onPrev : null, icon: Icon(PixelIcons.chevron_left), tooltip: '上一周'),
      const SizedBox(width: 4),
      TextButton(
        onPressed: onCurrent,
        style: TextButton.styleFrom(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: const Text('本周', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 4),
      IconButton.filledTonal(onPressed: week < total ? onNext : null, icon: Icon(PixelIcons.chevron_right), tooltip: '下一周'),
      const Spacer(),
      Text('${week} / $total 周', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
    ]);
  }
}

class PageHeader extends StatelessWidget {
  final double? titleSize;
  final String kicker;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  const PageHeader({super.key, required this.kicker, required this.title, required this.subtitle, this.actions = const [], this.titleSize});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 22, height: 2, color: scheme.primary, margin: const EdgeInsets.only(right: 8)),
          Text(kicker, style: TextStyle(fontSize: 9, color: scheme.primary, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: titleSize ?? 30)),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
      ])),
      if (actions.isNotEmpty) ...[const SizedBox(width: 12), ...actions],
    ]);
  }
}

class SectionCard extends StatelessWidget {
  final String? kicker;
  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsets padding;
  const SectionCard({super.key, this.kicker, this.title, this.subtitle, required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (kicker != null) Text(kicker!, style: TextStyle(fontSize: 8.5, letterSpacing: 1.4, color: scheme.primary, fontWeight: FontWeight.w800)),
        if (title != null) ...[const SizedBox(height: 3), Text(title!, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18))],
        if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: TextStyle(fontSize: 10.5, height: 1.45, color: scheme.onSurfaceVariant))],
        if (kicker != null || title != null || subtitle != null) const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class SettingRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  const SettingRow({super.key, required this.title, required this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 9.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ])),
        const SizedBox(width: 12),
        trailing,
      ]),
    );
  }
}

class CourseDetailSheet extends StatelessWidget {
  final AppController controller;
  final Course course;
  const CourseDetailSheet({super.key, required this.controller, required this.course});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = CoursePalette.of(course.colorIndex, context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 2, 22, 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: palette.container, borderRadius: BorderRadius.circular(15), border: Border(left: BorderSide(color: palette.accent, width: 4))),
            child: Icon(courseIcon(course.colorIndex), color: palette.ink, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
            const SizedBox(height: 2),
            Text('${course.teacher} · ${course.type.isEmpty ? course.category : course.type}${course.credits == null ? '' : ' · ${course.credits} 学分'}',
                style: TextStyle(fontSize: 9.5, color: scheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outlineVariant)),
          child: Row(children: [
            Expanded(child: _DetailCell(label: '周次', value: course.weeksText)),
            Expanded(child: _DetailCell(label: '地点', value: course.roomsText.isEmpty ? '—' : course.roomsText)),
            Expanded(child: _DetailCell(label: '课程代码', value: course.code.isEmpty ? '—' : course.code)),
          ]),
        ),
        const SizedBox(height: 14),
        Text('时间安排', style: TextStyle(fontSize: 9, letterSpacing: 1.3, color: scheme.primary, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        ...course.meetings.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(11)),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text('${m.dayName} 第 ${m.startPeriod}-${m.endPeriod} 节  ${m.startTime}–${m.endTime(controller.settings.durationMode)}',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500))),
                Text(m.room, style: TextStyle(fontSize: 8, color: scheme.onSurfaceVariant)),
              ]),
            )),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await controller.addCourseToGoogle(course.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '已打开 Google 日历（下一节课）' : '暂时没有可添加的课程')));
              },
              icon: Icon(PixelIcons.event_available, size: 17),
              label: const Text('加入 Google 日历'),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ]),
        const SizedBox(height: 4),
        Text('提示：要一次导入全部课程，请在设置中使用「导入全部课程」。', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _DetailCell extends StatelessWidget {
  final String label;
  final String value;
  const _DetailCell({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 8.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
  }
}

class LoginSheet extends StatefulWidget {
  final AppController controller;
  const LoginSheet({super.key, required this.controller});
  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  late final TextEditingController _user;
  final _pass = TextEditingController();
  bool _obscure = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _user = TextEditingController(text: widget.controller.settings.username.isNotEmpty ? widget.controller.settings.username : (widget.controller.schedule?.student.id ?? ''));
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 0, 22, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: Icon(PixelIcons.lock_outline, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('同步课表', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            Text('登录信息门户，读取教务系统课表', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _user,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '学号', hintText: '请输入学号'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _pass,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: '信息门户密码',
            suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? PixelIcons.visibility_outlined : PixelIcons.visibility_off_outlined)),
          ),
        ),
        if (_localError != null || widget.controller.error != null) ...[
          const SizedBox(height: 8),
          Text(_localError ?? widget.controller.error!, style: TextStyle(fontSize: 10, color: scheme.error)),
        ],
        const SizedBox(height: 10),
        Text('密码使用 AES-GCM 加密保存在本机应用私有目录。应用不会上传你的信息。',
            style: TextStyle(fontSize: 9, height: 1.5, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('稍后'))),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: widget.controller.loginBusy
                  ? null
                  : () async {
                      final u = _user.text.trim();
                      final p = _pass.text;
                      if (!RegExp(r'^\d{6,20}$').hasMatch(u)) {
                        setState(() => _localError = '请输入正确的学号');
                        return;
                      }
                      if (p.isEmpty) {
                        setState(() => _localError = '请输入信息门户密码');
                        return;
                      }
                      setState(() => _localError = null);
                      await widget.controller.saveCredentials(u, p);
                      if (context.mounted) Navigator.pop(context);
                    },
              child: widget.controller.loginBusy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('登录并同步'),
            ),
          ),
        ]),
      ]),
    );
  }
}

void showCourseDetail(BuildContext context, AppController controller, Course course, {Rect? anchor, bool animate = true}) {
  final media = MediaQuery.of(context);
  final screen = media.size;
  final safeTop = media.padding.top + 8;
  final safeBottom = screen.height - media.padding.bottom - 12;
  final popupWidth = (screen.width - 48).clamp(280.0, 320.0);
  final startRect = anchor ?? Rect.fromCenter(center: Offset(screen.width / 2, screen.height * 0.42), width: 120, height: 80);
  final popupHeight = (285.0 + course.meetings.length * 50.0).clamp(300.0, 540.0);
  final left = (startRect.center.dx - popupWidth / 2).clamp(16.0, screen.width - popupWidth - 16);
  final top = (startRect.center.dy - popupHeight / 2).clamp(safeTop, safeBottom - popupHeight);
  final targetRect = Rect.fromLTWH(left, top, popupWidth, popupHeight);
  final origin = Alignment(
    ((startRect.center.dx - targetRect.left) / popupWidth * 2 - 1).clamp(-1.0, 1.0),
    ((startRect.center.dy - targetRect.top) / popupHeight * 2 - 1).clamp(-1.0, 1.0),
  );
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '课程详情',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, _, __) => _AnchoredCoursePopup(
      startRect: startRect,
      targetRect: targetRect,
      origin: origin,
      animate: animate,
      child: MediaQuery(
        data: MediaQuery.of(dialogContext).copyWith(textScaler: TextScaler.linear(1.0)),
        child: _CoursePopupCard(controller: controller, course: course),
      ),
    ),
  );
}

class _CoursePopupCard extends StatelessWidget {
  final AppController controller;
  final Course course;
  const _CoursePopupCard({required this.controller, required this.course});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8),
        child: CourseDetailSheet(controller: controller, course: course),
      ),
    );
  }
}

class _AnchoredCoursePopup extends StatefulWidget {
  final Rect startRect;
  final Rect targetRect;
  final Alignment origin;
  final bool animate;
  final Widget child;
  const _AnchoredCoursePopup({required this.startRect, required this.targetRect, required this.origin, required this.animate, required this.child});

  @override
  State<_AnchoredCoursePopup> createState() => _AnchoredCoursePopupState();
}

class _AnchoredCoursePopupState extends State<_AnchoredCoursePopup> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> _position = CurvedAnimation(parent: _controller, curve: const Cubic(0.05, 0.7, 0.1, 1.0));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.50, end: 1.02).chain(CurveTween(curve: const Cubic(0.05, 0.7, 0.1, 1.0))), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.02, end: 1.0).chain(CurveTween(curve: const Cubic(0.30, 0.0, 0.33, 1.0))), weight: 50),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final rect = Rect.lerp(widget.startRect, widget.targetRect, _position.value)!;
        final opacity = (_controller.value / 0.21).clamp(0.0, 1.0);
        return Stack(children: [
          Positioned.fromRect(
            rect: rect,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(alignment: widget.origin, scale: _scale.value, child: widget.child),
            ),
          ),
        ]);
      },
    );
  }
}

Future<void> exportAllCourses(BuildContext context, AppController controller) async {
  final count = await controller.exportAllCalendar();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已生成 $count 个课程事件，选择 Google 日历完成一次性导入。')));
  }
}

String countdownLabel(NextClass? next) {
  if (next == null) return '—';
  final now = DateTime.now();
  final diff = next.ongoing ? next.endAt.difference(now) : next.startAt.difference(now);
  if (diff.isNegative) return '刚刚开始';
  final h = diff.inHours;
  final m = diff.inMinutes.remainder(60);
  final s = diff.inSeconds.remainder(60);
  if (next.ongoing) return '剩余 ${h > 0 ? '$h 小时 ' : ''}$m 分钟';
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String shortDate(DateTime d) => DateFormat('M月d日').format(d);

class MiniProgress extends StatelessWidget {
  final double value;
  final Color? color;
  const MiniProgress({super.key, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 4, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, color: color),
    );
  }
}

void copyToClipboard(String text) {
  Clipboard.setData(ClipboardData(text: text));
}

class CountdownTicker extends StatefulWidget {
  final Widget Function(BuildContext, DateTime) builder;
  const CountdownTicker({super.key, required this.builder});
  @override
  State<CountdownTicker> createState() => _CountdownTickerState();
}

class _CountdownTickerState extends State<CountdownTicker> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}



