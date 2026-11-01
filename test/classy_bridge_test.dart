import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/classy_bridge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.hsu.hsu_schedule/classy_parser');

  test('Kotlin bridge result is converted to an importable timetable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'parse');
      expect(call.arguments['type'], 'zf_new');
      return [
        {'name': '高等数学', 'room': 'A101', 'teacher': '张三', 'day': 1, 'startPeriod': 1, 'endPeriod': 2, 'startWeek': 1, 'endWeek': 16, 'weekType': 0},
        {'name': '大学英语', 'room': 'B202', 'teacher': '李四', 'day': 3, 'startPeriod': 3, 'endPeriod': 4, 'startWeek': 2, 'endWeek': 8, 'weekType': 2},
      ];
    });
    final source = await ClassyBridgeService.parse(html: '<html></html>', type: 'zf_new', url: 'https://example.edu', cookies: const {});
    expect(source, isNotNull);
    expect(source!.html, contains('高等数学'));
    expect(source.html, contains('第1-2节'));
    expect(source.html, contains('1-16周'));
    expect(source.html, contains('2-8双周'));
    expect(source.html, contains('<th>周三</th>'));
  });
}
