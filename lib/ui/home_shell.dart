import 'dart:io';

import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:flutoryx/flutoryx.dart';
import 'package:window_manager/window_manager.dart';

import '../app_controller.dart';
import '../update_service.dart';
import 'components.dart';
import 'motion.dart';
import 'courses_screen.dart';
import 'compact_widget.dart';
import 'settings_screen.dart';
import 'today_screen.dart';
import 'week_screen.dart';
import '../pixel_icons.dart';

class HomeShell extends StatefulWidget {
  final AppController controller;
  const HomeShell({super.key, required this.controller});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  int? _selectedWeek;
  bool _loginOpen = false;

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowLogin();
      UpdateService.maybeCheck(context);
    });
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.reloadSchedule();
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (controller.showLogin && !_loginOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowLogin();
      UpdateService.maybeCheck(context);
    });
    }
    setState(() {});
  }

  Future<void> _maybeShowLogin({bool force = false}) async {
    if (force) {
      await controller.useNativeSource();
      controller.openLogin();
    }
    if (!mounted || _loginOpen || !controller.showLogin) return;
    _loginOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AnimatedBuilder(
        animation: controller,
        builder: (_, __) => LoginSheet(controller: controller),
      ),
    );
    _loginOpen = false;
    if (controller.showLogin) {
      await controller.dismissLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows && controller.compactMode) {
      return CompactWidget(controller: controller);
    }
    if (controller.schedule == null) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 52,
          title: const SizedBox.shrink(),
          actions: [
            IconButton(
              onPressed: controller.syncing ? null : () => controller.sync(),
              icon: controller.syncing
                  ? const M3ELoadingIndicator(constraints: BoxConstraints.tightFor(width: 18, height: 18))
                  : Icon(PixelIcons.sync),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: AppEmptyState(
          icon: Icons.event_available_outlined,
          title: '还没有课表数据',
          subtitle: '请登录信息门户并同步一次课表。',
          actionLabel: '登录并同步',
          onActionPressed: _maybeShowLogin,
        ),
      );
    }
    final currentWeek = controller.schedule!.currentWeek();
    final baseWeek = currentWeek <= 0 ? 1 : currentWeek;
    final selectedWeek = (_selectedWeek ?? baseWeek).clamp(1, controller.schedule!.semester.totalWeeks);
    final screens = [
      WeekScreen(
        controller: controller,
        week: selectedWeek,
        onWeekChange: (w) => setState(() => _selectedWeek = w),
      ),
      TodayScreen(controller: controller),
      CoursesScreen(controller: controller),
      SettingsScreen(controller: controller, onLogin: () => _maybeShowLogin(force: true)),
    ];
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    if (isDesktop) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            trailing: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: IconButton(
                onPressed: controller.syncing ? null : () => controller.sync(),
                tooltip: '立即同步',
                icon: controller.syncing
                    ? const M3ELoadingIndicator(constraints: BoxConstraints.tightFor(width: 18, height: 18))
                    : Icon(PixelIcons.sync),
              ),
            ),
            destinations: [
              NavigationRailDestination(icon: Icon(PixelIcons.calendar_view_week_outlined), selectedIcon: Icon(PixelIcons.calendar_view_week), label: Text('课表')),
              NavigationRailDestination(icon: Icon(PixelIcons.today_outlined), selectedIcon: Icon(PixelIcons.today), label: Text('今天')),
              NavigationRailDestination(icon: Icon(PixelIcons.menu_book_outlined), selectedIcon: Icon(PixelIcons.menu_book), label: Text('课程')),
              NavigationRailDestination(icon: Icon(PixelIcons.tune_outlined), selectedIcon: Icon(PixelIcons.tune), label: Text('设置')),
            ],
          ),
          Expanded(
            child: Column(children: [
              _DesktopTitleBar(controller: controller),
              Expanded(child: AnimatedPageSwitcher(child: KeyedSubtree(key: ValueKey(_tab), child: screens[_tab]))),
            ]),
          ),
        ]),
      );
    }
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        titleSpacing: 8,
        title: _tab == 0 && controller.schedule != null
            ? _TopWeekSwitcher(
                week: selectedWeek,
                total: controller.schedule!.semester.totalWeeks,
                onPrev: selectedWeek > 1 ? () => setState(() => _selectedWeek = selectedWeek - 1) : null,
                onNext: selectedWeek < controller.schedule!.semester.totalWeeks
                    ? () => setState(() => _selectedWeek = selectedWeek + 1)
                    : null,
                onCurrent: () => setState(() => _selectedWeek = baseWeek),
              )
            : const SizedBox.shrink(),
        actions: [
          IconButton(
            onPressed: controller.syncing ? null : () => controller.sync(),
            tooltip: '刷新课表',
            icon: controller.syncing
                ? const M3ELoadingIndicator(constraints: BoxConstraints.tightFor(width: 18, height: 18))
                : Icon(PixelIcons.sync, size: 21),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedPageSwitcher(child: KeyedSubtree(key: ValueKey(_tab), child: screens[_tab])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: Icon(PixelIcons.calendar_view_week_outlined), selectedIcon: Icon(PixelIcons.calendar_view_week), label: '课表'),
          NavigationDestination(icon: Icon(PixelIcons.today_outlined), selectedIcon: Icon(PixelIcons.today), label: '今天'),
          NavigationDestination(icon: Icon(PixelIcons.menu_book_outlined), selectedIcon: Icon(PixelIcons.menu_book), label: '课程'),
          NavigationDestination(icon: Icon(PixelIcons.tune_outlined), selectedIcon: Icon(PixelIcons.tune), label: '设置'),
        ],
      ),
    );
  }
}

class _TopWeekSwitcher extends StatelessWidget {
  final int week;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onCurrent;
  const _TopWeekSwitcher({
    required this.week,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.onCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        onPressed: onPrev,
        icon: Icon(PixelIcons.chevron_left, size: 20),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        tooltip: '上一周',
      ),
      TextButton(
        onPressed: onCurrent,
        style: TextButton.styleFrom(
          minimumSize: const Size(52, 34),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: scheme.surfaceContainer,
          shape: const StadiumBorder(),
        ),
        child: Text('本周', style: TextStyle(fontSize: 11, color: scheme.onSurface, fontWeight: FontWeight.w600)),
      ),
      IconButton(
        onPressed: onNext,
        icon: Icon(PixelIcons.chevron_right, size: 20),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        tooltip: '下一周',
      ),
    ]);
  }
}

class _DesktopTitleBar extends StatelessWidget {
  final AppController controller;
  const _DesktopTitleBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 46,
        padding: const EdgeInsets.only(left: 16, right: 6),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Row(children: [
          const Spacer(),
          IconButton(
            onPressed: controller.syncing ? null : () => controller.sync(),
            icon: controller.syncing
                ? const M3ELoadingIndicator(constraints: BoxConstraints.tightFor(width: 15, height: 15))
                : Icon(PixelIcons.sync, size: 17),
            tooltip: '立即同步',
          ),
          const SizedBox(width: 2),
          _WindowButton(icon: PixelIcons.remove, onTap: () => windowManager.minimize()),
          _WindowButton(icon: PixelIcons.crop_square, onTap: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          }),
          _WindowButton(icon: PixelIcons.close, onTap: () => windowManager.close(), hoverColor: scheme.error),
        ]),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;
  const _WindowButton({required this.icon, required this.onTap, this.hoverColor});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: 34, height: 30,
        child: Icon(icon, size: 14, color: hoverColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

