import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/app_controller.dart';
import '../lib/credential_vault.dart';
import '../lib/imported_source.dart';
import '../lib/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('home_widget'), (_) async => true);
  test('real controller saves native-free imported move, resumes without resetting and clears it', () async {
    SharedPreferences.setMockInitialValues({'auto_sync': false});
    final storage = await AppStorage.create();
    final html = '<table><tr><th>节次</th><th>周一</th><th>周二</th><th>周三</th></tr>'
      '<tr><td>第1-2节</td><td>高等数学<br>@A101<br>张老师</td><td></td><td></td></tr>'
      '<tr><td>第3-4节</td><td></td><td></td><td></td></tr></table>';
    await storage.saveImportedSource(ImportedSource(url: 'https://example.edu/timetable', cookies: const {}, html: html, savedAt: DateTime.now()));
    final controller = AppController();
    await controller.initialize();
    expect(controller.schedule, isNotNull);
    expect(controller.manualCourses, isEmpty);
    final source = controller.schedule!.meetings.first;
    final pendingSave = controller.moveMeeting(source, 4, 5);
    expect(controller.schedule!.meetingById(source.id)!.day, 4,
      reason: 'in-memory coordinates committed synchronously before persistence awaits');
    await pendingSave;
    expect(controller.storage.loadMeetingMoves(), hasLength(1));
    expect(controller.schedule!.meetingById(source.id)!.startTime, '14:00');
    await controller.reloadSchedule();
    expect(controller.schedule!.meetingById(source.id)!.day, 4);
    expect(controller.schedule!.meetingById(source.id)!.startPeriod, 5);
    expect(controller.usingImportedSource, isTrue);
    await controller.clearAllCourses();
    expect(controller.schedule, isNull);
    expect(controller.storage.loadMeetingMoves(), isEmpty);
    controller.dispose();
  });
}
