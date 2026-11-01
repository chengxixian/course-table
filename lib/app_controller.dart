import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import 'calendar_export.dart';
import 'generic_html_parser.dart';
import 'imported_schedule_service.dart';
import 'imported_source.dart';
import 'manual_course.dart';
import 'schedule_overlays.dart';
import 'models.dart';
import 'storage.dart';
import 'school_registry.dart';
import 'sync_service.dart';

class AppController extends ChangeNotifier {
  AppStorage? _storage;
  Schedule? schedule;
  Schedule? _baseSchedule;
  List<ManualCourseEntry> _manualCourses = [];
  List<MeetingMove> _meetingMoves = [];
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
    _baseSchedule = schedule;
    _manualCourses = _storage!.loadManualCourses();
    _meetingMoves = _storage!.loadMeetingMoves();
    if (schedule != null) schedule = _withManual(schedule!);
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
    if (storage.sourceMode != 'imported' && !credentialsSaved) {
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
      _baseSchedule = next;
      schedule = _withManual(next);
      settings = storage.settings;
      lastSync = settings.lastSync;
      credentialsSaved = (await storage.readCredentials()) != null;
      await _publishEffective();
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
    _manualCourses = storage.loadManualCourses();
    _meetingMoves = storage.loadMeetingMoves();
    _baseSchedule = _loadBase(storage);
    schedule = _baseSchedule == null ? null : _withManual(_baseSchedule!);
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
    _baseSchedule = parsed;
    schedule = _withManual(parsed);
    settings = storage.settings;
    lastSync = DateTime.now();
    credentialsSaved = false;
    showLogin = false;
    error = null;
    await _publishEffective();
    notifyListeners();
  }

  Future<void> clearImportedSource() async => useNativeSource();

  Future<void> useNativeSource() async {
    final storage = _storage;
    if (storage == null) return;
    await storage.clearImportedSource();
    credentialsSaved = (await storage.readCredentials()) != null;
    _baseSchedule = _loadBase(storage);
    schedule = _baseSchedule == null ? null : _withManual(_baseSchedule!);
    error = null;
    notifyListeners();
    await _publishEffective();
  }

  Future<void> moveMeeting(Meeting meeting, int day, int startPeriod) async {
    final storage = _storage;
    final base = _baseSchedule;
    if (storage == null || base == null) throw StateError('当前没有可编辑的课表');
    if (day < 1 || day > 7) throw ArgumentError('星期超出范围');
    final range = ScheduleOverlays.destination(base, startPeriod, meeting.periodCount);
    final oldManual = _manualCourses;
    final oldMoves = _meetingMoves;
    final oldSchedule = schedule;
    final manual = meeting.id.startsWith('manual_');
    if (manual) {
      final id = meeting.id.substring('manual_'.length);
      _manualCourses = _manualCourses.map((e) => e.id == id ? ManualCourseEntry(
        id: e.id, name: e.name, teacher: e.teacher, room: e.room, day: day,
        startPeriod: range.$1, endPeriod: range.$2,
        weeksText: e.weeksText, weeks: e.weeks, colorIndex: e.colorIndex,
      ) : e).toList();
    } else {
      _meetingMoves = [..._meetingMoves.where((m) => m.meetingId != meeting.id),
        MeetingMove(meetingId: meeting.id, day: day, startPeriod: range.$1, endPeriod: range.$2)];
    }
    // Commit effective coordinates synchronously, before the snap animation starts.
    schedule = _withManual(base);
    notifyListeners();
    try {
      if (manual) {
        await storage.saveManualCourses(_manualCourses);
      } else {
        await storage.saveMeetingMoves(_meetingMoves);
      }
    } catch (_) {
      _manualCourses = oldManual;
      _meetingMoves = oldMoves;
      schedule = oldSchedule;
      notifyListeners();
      rethrow;
    }
    unawaited(_publishEffective());
  }

  Future<void> resetMeetingMoves() async {
    final storage = _storage;
    if (storage == null) return;
    await storage.clearMeetingMoves();
    _meetingMoves = [];
    final base = _baseSchedule;
    if (base != null) schedule = _withManual(base);
    notifyListeners();
    await _publishEffective();
  }

  Future<void> addManualCourse(ManualCourseEntry entry) async {
    final storage = _storage;
    if (storage == null) return;
    _manualCourses = [..._manualCourses, entry];
    await storage.saveManualCourses(_manualCourses);
    final base = _baseSchedule;
    if (base != null) schedule = _withManual(base);
    notifyListeners();
    await _publishEffective();
  }

  Future<void> removeManualCourse(String id) async {
    final storage = _storage;
    if (storage == null) return;
    _manualCourses = _manualCourses.where((e) => e.id != id).toList();
    await storage.saveManualCourses(_manualCourses);
    final base = _baseSchedule;
    if (base != null) schedule = _withManual(base);
    notifyListeners();
    await _publishEffective();
  }

  List<ManualCourseEntry> get manualCourses => List.unmodifiable(_manualCourses);

  Schedule _withManual(Schedule base) => ScheduleOverlays.compose(base, _manualCourses, _meetingMoves);

  Schedule? _loadBase(AppStorage storage) {
    if (storage.sourceMode == 'imported') {
      final source = storage.loadImportedSource();
      return source == null ? null : ImportedScheduleService.parse(source);
    }
    return storage.loadSchedule();
  }

  Future<void> _publishEffective() async {
    try {
      if (schedule == null) {
        await WidgetBridge.clear();
      } else {
        await WidgetBridge.update(schedule!, settings);
      }
    } catch (e) {
      debugPrint('widget publication failed: $e');
    }
  }

  Future<void> clearAllCourses() async {
    final storage = _storage;
    if (storage == null) return;
    await storage.clearCourses();
    await storage.clearManualCourses();
    _manualCourses = [];
    _meetingMoves = [];
    _baseSchedule = null;
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

  Future<void> requestPinTwoDayWidget() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.requestPinWidget(
      androidName: 'TwoDayWidgetProvider',
      qualifiedAndroidName: 'com.hsu.hsu_schedule.TwoDayWidgetProvider',
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

