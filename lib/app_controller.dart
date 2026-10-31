import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import 'calendar_export.dart';
import 'generic_html_parser.dart';
import 'imported_schedule_service.dart';
import 'imported_source.dart';
import 'models.dart';
import 'storage.dart';
import 'school_registry.dart';
import 'sync_service.dart';

class AppController extends ChangeNotifier {
  AppStorage? _storage;
  Schedule? schedule;
  AppSettings settings = const AppSettings();
  bool credentialsSaved = false;
  bool syncing = false;
  String? error;
  bool showLogin = false;
  bool loginBusy = false;
  bool compactMode = false;
  bool initialized = false;
  DateTime? lastSync;

  Timer? _desktopTimer;
  bool _syncing = false;

  AppStorage get storage => _storage!;

  Future<void> initialize() async {
    _storage = await AppStorage.create();
    settings = _storage!.settings;
    lastSync = settings.lastSync;
    compactMode = _storage!.compactWidget;
    credentialsSaved = (await _storage!.readCredentials()) != null;
    final imported = _storage!.loadImportedSource();
    if (_storage!.sourceMode == 'imported' && imported != null) {
      schedule = ImportedScheduleService.parse(imported);
    } else {
      schedule = _storage!.loadSchedule();
    }
    if (schedule != null) {
      try {
        await WidgetBridge.update(schedule!, settings);
      } catch (e) {
        debugPrint('widget init update failed: $e');
      }
    }
    showLogin = false;
    unawaited(SchoolRegistry.refresh());
    initialized = true;
    notifyListeners();
    try {
      if (settings.autoSync) {
        if (Platform.isAndroid) {
          await WorkScheduler.scheduleDaily(settings);
        } else {
          _startDesktopTimer();
        }
      }
      if (credentialsSaved && settings.autoSync && _needsTodaySync) {
        unawaited(sync(silent: true));
      }
    } catch (e) {
      debugPrint('background init failed: $e');
    }
  }

  bool get _needsTodaySync {
    final last = lastSync;
    if (last == null) return true;
    final now = DateTime.now();
    return last.year != now.year || last.month != now.month || last.day != now.day;
  }

  Future<void> sync({bool silent = false}) async {
    if (_syncing) return;
    final storage = _storage;
    if (storage == null) return;
    if (!credentialsSaved) {
      showLogin = true;
      notifyListeners();
      return;
    }
    _syncing = true;
    syncing = true;
    error = null;
    notifyListeners();
    try {
      final next = storage.sourceMode == 'imported'
          ? await ImportedScheduleService.refresh(storage)
          : await SyncService.sync(storage);
      if (storage.sourceMode == 'imported') {
        await WidgetBridge.update(next, settings);
      }
      schedule = next;
      settings = storage.settings;
      lastSync = settings.lastSync;
      credentialsSaved = true;
      error = null;
    } catch (e) {
      error = _messageFor(e);
      if (e is NoCredentialsException) {
        credentialsSaved = false;
        showLogin = true;
      }
      if (!silent) {
        // The UI shows the error in a snackbar / account card.
      }
    } finally {
      _syncing = false;
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> saveCredentials(String username, String password) async {
    final storage = _storage;
    if (storage == null) return;
    loginBusy = true;
    error = null;
    notifyListeners();
    try {
      await storage.writeCredentials(Credentials(username.trim(), password));
      await storage.setSourceMode('native');
      await storage.clearImportedSource();
      await storage.setLoginDismissed(false);
      credentialsSaved = true;
      showLogin = false;
      settings = storage.settings.copyWith(username: username.trim());
      loginBusy = false;
      notifyListeners();
      await sync();
    } catch (e) {
      loginBusy = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> dismissLogin() async {
    showLogin = false;
    await _storage?.setLoginDismissed(true);
    notifyListeners();
  }

  void openLogin() {
    showLogin = true;
    notifyListeners();
  }

  Future<void> clearCredentials() async {
    await _storage?.clearCredentials();
    credentialsSaved = false;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings next) async {
    settings = await _storage!.saveSettings(next);
    if (Platform.isAndroid) {
      await WorkScheduler.scheduleDaily(settings);
    } else if (settings.autoSync) {
      _startDesktopTimer();
    } else {
      _desktopTimer?.cancel();
    }
    if (schedule != null) await WidgetBridge.update(schedule!, settings);
    notifyListeners();
  }

  Future<void> setCompactMode(bool value) async {
    compactMode = value;
    await _storage?.setCompactWidget(value);
    notifyListeners();
  }

  Future<void> reloadSchedule() async {
    final storage = _storage;
    if (storage == null) return;
    settings = storage.settings;
    lastSync = settings.lastSync;
    final loaded = storage.loadSchedule();
    if (loaded != null) schedule = loaded;
    notifyListeners();
  }

  bool get usingImportedSource => _storage?.sourceMode == 'imported';

  ImportedSource? get currentImportedSource => _storage?.loadImportedSource();

  Future<void> applyImportedSource(ImportedSource source) async {
    final storage = _storage;
    if (storage == null) return;
    final host = Uri.tryParse(source.url)?.host ?? '';
    if (host.contains('hsu.edu.cn')) {
      throw const ImportException('黄山学院请使用“已适配高校”里的黄山学院入口登录同步，不要从未适配网页导入。');
    }
    final parsed = ImportedScheduleService.parse(source);
    if (parsed == null) {
      throw ImportException(lastParseError ?? '没有识别到课表，请确认当前页面显示了完整课程表');
    }
    final missingRoom = parsed.meetings.where((m) => m.room.trim().isEmpty).length;
    if (missingRoom > 0) {
      throw ImportException('识别到 $missingRoom 个上课时段缺少教室，已拒绝导入，避免覆盖原课表。请确认页面显示完整教室后再导入。');
    }
    await storage.saveImportedSource(source);
    schedule = parsed;
    settings = storage.settings;
    lastSync = DateTime.now();
    credentialsSaved = false;
    showLogin = false;
    error = null;
    await WidgetBridge.update(parsed, settings);
    notifyListeners();
  }

  Future<void> clearImportedSource() async {
    await _storage?.clearImportedSource();
    schedule = _storage?.loadSchedule();
    notifyListeners();
  }

  Future<void> useNativeSource() async {
    final storage = _storage;
    if (storage == null) return;
    await storage.setSourceMode('native');
    await storage.clearImportedSource();
    schedule = storage.loadSchedule();
    notifyListeners();
  }

  Future<void> clearAllCourses() async {
    final storage = _storage;
    if (storage == null) return;
    await storage.clearCourses();
    schedule = null;
    lastSync = null;
    settings = storage.settings.copyWith(lastSync: null);
    await WidgetBridge.clear();
    notifyListeners();
  }

  Future<int> exportAllCalendar() async {
    if (schedule == null) return 0;
    return CalendarExport.shareAll(schedule!, settings.durationMode);
  }

  Future<bool> addNextToGoogle() async {
    if (schedule == null) return false;
    return CalendarExport.addNextToGoogle(schedule!, settings.durationMode);
  }

  Future<bool> addCourseToGoogle(String courseId) async {
    if (schedule == null) return false;
    return CalendarExport.addCourseToGoogle(schedule!, courseId, settings.durationMode);
  }

  Future<void> requestPinWidget() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.requestPinWidget(
      androidName: 'ScheduleWidgetProvider',
      qualifiedAndroidName: 'com.hsu.hsu_schedule.ScheduleWidgetProvider',
    );
  }

  Future<void> requestPinNextWidget() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.requestPinWidget(
      androidName: 'NextClassWidgetProvider',
      qualifiedAndroidName: 'com.hsu.hsu_schedule.NextClassWidgetProvider',
    );
  }

  Future<void> requestPinTodayWidget() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.requestPinWidget(
      androidName: 'TodayWidgetProvider',
      qualifiedAndroidName: 'com.hsu.hsu_schedule.TodayWidgetProvider',
    );
  }

  Future<void> requestPinWeekWidget() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.requestPinWidget(
      androidName: 'WeekGridWidgetProvider',
      qualifiedAndroidName: 'com.hsu.hsu_schedule.WeekGridWidgetProvider',
    );
  }

  void _startDesktopTimer() {
    _desktopTimer?.cancel();
    _desktopTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!settings.autoSync || _syncing) return;
      final target = _targetToday();
      if (DateTime.now().isBefore(target)) return;
      if (!_needsTodaySync) return;
      unawaited(sync(silent: true));
    });
  }

  DateTime _targetToday() {
    final parts = settings.refreshTime.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 7;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 30;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour.clamp(0, 23), minute.clamp(0, 59));
  }

  @override
  void dispose() {
    _desktopTimer?.cancel();
    super.dispose();
  }

  static String _messageFor(Object e) {
    final text = e.toString();
    if (text.startsWith('Exception: ')) return text.substring(11);
    return text;
  }
}

