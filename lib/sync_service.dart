import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import 'models.dart';
import 'imported_schedule_service.dart';
import 'parser.dart';
import 'portal_client.dart';
import 'storage.dart';

class NoCredentialsException implements Exception {
  final String message;
  const NoCredentialsException([this.message = '尚未保存登录信息']);
  @override
  String toString() => message;
}

class SyncService {
  static Future<Schedule> sync(AppStorage storage) async {
    if (storage.sourceMode == 'imported') {
      final imported = await ImportedScheduleService.refresh(storage);
      await WidgetBridge.update(imported, storage.settings);
      return imported;
    }
    final credentials = await storage.readCredentials();
    if (credentials == null) throw const NoCredentialsException();
    final raw = await PortalClient().fetch(credentials);
    await storage.saveRaw(raw);
    final schedule = ScheduleParser.build(raw);
    await WidgetBridge.update(schedule, storage.settings);
    return schedule;
  }
}

class WidgetBridge {
  static const widgetDataKey = 'schedule_widget';

  static Future<void> update(Schedule schedule, AppSettings settings) async {
    if (!Platform.isAndroid) return;
    final payload = buildPayload(schedule, settings);
    await HomeWidget.saveWidgetData<String>(widgetDataKey, jsonEncode(payload));
    await HomeWidget.updateWidget(
      androidName: 'ScheduleWidgetProvider',
      qualifiedAndroidName: 'com.hsu.hsu_schedule.ScheduleWidgetProvider',
    );
    await HomeWidget.updateWidget(
      androidName: 'NextClassWidgetProvider',
      qualifiedAndroidName: 'com.hsu.hsu_schedule.NextClassWidgetProvider',
    );
    await HomeWidget.updateWidget(
      androidName: 'TodayWidgetProvider',
      qualifiedAndroidName: 'com.hsu.hsu_schedule.TodayWidgetProvider',
    );
    await HomeWidget.updateWidget(
      androidName: 'WeekGridWidgetProvider',
      qualifiedAndroidName: 'com.hsu.hsu_schedule.WeekGridWidgetProvider',
    );
  }

  static Map<String, dynamic> buildPayload(Schedule schedule, AppSettings settings) {
    final now = DateTime.now();
    final today = schedule.todayMeetings(now);
    final next = schedule.nextClass(now: now, mode: settings.durationMode);
    final week = schedule.currentWeek(now);
    final nowMin = now.hour * 60 + now.minute;
    final upcoming = today.where((m) {
      final end = Schedule.parseMinutes(m.endTime(settings.durationMode));
      return end != null && end >= nowMin;
    }).toList();
    final source = upcoming.isNotEmpty ? upcoming : today;
    final rows = source.take(3).map((m) {
      return {
        'time': m.startTime,
        'end': m.endTime(settings.durationMode),
        'name': m.courseName,
        'room': m.room.isEmpty ? (m.teacher.isEmpty ? '' : m.teacher) : m.room,
        'colorIndex': schedule.courseById(m.courseId)?.colorIndex ?? 0,
      };
    }).toList();
    String summary;
    if (next == null) {
      summary = week > 0 ? '今日课程已结束' : '假期中';
    } else if (next.ongoing) {
      summary = '正在上课 · ${next.meeting.courseName}';
    } else {
      final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      final sameDay = next.startAt.year == now.year && next.startAt.month == now.month && next.startAt.day == now.day;
      final prefix = sameDay
          ? ''
          : (next.startAt.year == tomorrow.year && next.startAt.month == tomorrow.month && next.startAt.day == tomorrow.day)
              ? '明天 '
              : '${next.startAt.month}月${next.startAt.day}日 ';
      summary = '下一节 $prefix${next.meeting.startTime}  ${next.meeting.courseName}';
    }
    final weekCourses = <Map<String, dynamic>>[];
    if (week > 0) {
      for (var day = 1; day <= 5; day++) {
        for (final m in schedule.meetingsFor(week, day)) {
          weekCourses.add({
            'day': day,
            'period': m.startPeriod,
            'span': m.periodCount,
            'name': m.courseName,
            'room': m.room,
            'colorIndex': schedule.courseById(m.courseId)?.colorIndex ?? 0,
          });
        }
      }
    }
    return {
      'week': week > 0 ? '第 $week 周' : '假期',
      'weekCourses': weekCourses,
      'periodCount': schedule.periods.length,
      'dateLabel': '${now.month}月${now.day}日 · ${kWeekdays[now.weekday]}',
      'fontStyle': settings.fontStyle,
      'nextSummary': summary,
      'nextCourse': next?.meeting.courseName ?? '',
      'nextStart': next?.meeting.startTime ?? '',
      'nextEnd': next == null ? '' : next.meeting.endTime(settings.durationMode),
      'nextRoom': next?.meeting.room ?? '',
      'nextTeacher': next?.meeting.teacher ?? '',
      'rows': rows,
      'footer': today.isEmpty ? '今天没有课 · 课程表' : '今日 ${today.length} 节 · 课程表',
      'updatedAt': now.toIso8601String(),
    };
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final storage = await AppStorage.create();
      await SyncService.sync(storage);
      return true;
    } catch (_) {
      return false;
    }
  });
}

class WorkScheduler {
  static const _periodicName = 'hsu-daily-sync';

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> scheduleDaily(AppSettings settings) async {
    if (!Platform.isAndroid) return;
    if (!settings.autoSync) {
      await Workmanager().cancelByUniqueName(_periodicName);
      return;
    }
    final delay = _delayUntil(settings.refreshTime);
    await Workmanager().registerPeriodicTask(
      _periodicName,
      'hsu-sync',
      frequency: const Duration(hours: 24),
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  static Duration _delayUntil(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 7;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 30;
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour.clamp(0, 23), minute.clamp(0, 59));
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
    return target.difference(now);
  }
}

