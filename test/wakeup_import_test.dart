import 'package:flutter_test/flutter_test.dart';
import '../lib/file_import_service.dart';

void main() {
  test('WakeUp share JSON imports locally without AI', () async {
    const json = '{"name":"2026 秋","startDate":"2026-08-31","courses":['
        '{"name":"高等数学","teacher":"张三","position":"A101","day":1,"startNode":1,"step":2,"startWeek":1,"endWeek":16,"type":0},'
        '{"name":"大学英语","teacher":"李四","position":"B202","day":3,"startNode":3,"step":2,"startWeek":2,"endWeek":8,"type":2}]}';
    final source = await FileImportService.fromPastedText(json);
    expect(source.url, contains('wakeup'));
    expect(source.html, contains('高等数学'));
    expect(source.html, contains('@A101'));
    expect(source.html, contains('1-16周'));
    expect(source.html, contains('2-8双周'));
    expect(source.html, contains('<th>周三</th>'));
  });
}
