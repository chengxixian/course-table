import 'package:flutter_test/flutter_test.dart';
import 'package:hsu_schedule/app_meta.dart';
import 'package:hsu_schedule/html_compactor.dart';

void main() {
  group('compactHtml', () {
    test('strips script, style, comments and base64 payloads', () {
      final b64 = 'A' * 100;
      final html = '<html><head><style>body{color:red}</style>'
          '<script>var x = 1; // huge\n</script><!-- note -->'
          '</head><body><table><tr><td>高等数学</td></tr></table>'
          '<img src="data:image/png;base64,$b64"></body></html>';
      final out = compactHtml(html);
      expect(out, isNot(contains('color:red')));
      expect(out, isNot(contains('var x')));
      expect(out, isNot(contains('note')));
      expect(out, isNot(contains('base64')));
      expect(out, contains('高等数学'));
      expect(out, contains('<table>'));
    });

    test('keeps table structure intact', () {
      const html = '<table><tr><th>周一</th></tr><tr><td>10:00-11:30 大学物理</td></tr></table>';
      expect(compactHtml(html), html);
    });

    test('shrinks a portal-sized page overwhelmingly', () {
      final big = '<script>${'x' * (8 * 1024 * 1024)}</script>'
          '<table><tr><td>第1节 高等数学 文渊1201</td></tr></table>';
      final out = compactHtml(big);
      expect(out.length, lessThan(1024));
      expect(out, contains('高等数学'));
    });
  });

  group('pickTimetableText', () {
    test('returns short text untouched', () {
      const text = '第1节 08:00-09:40 高等数学';
      expect(pickTimetableText(text, limit: 1000), text);
    });

    test('picks the window containing the grid, not the page header', () {
      final noise = '导航 菜单 广告 '.repeat(4000); // ~32k chars of chrome
      final grid = List.generate(60, (i) => '周${i % 7 + 1} 第${i % 10 + 1}节 10:0${i % 9}:00-11:30 课程$i 教室$i').join('\n');
      final tail = '页脚版权 '.repeat(2000);
      final text = '$noise$grid$tail';
      final picked = pickTimetableText(text, limit: 20000);
      expect(picked.length, lessThanOrEqualTo(20000));
      expect(picked, contains('课程12'));
      expect(picked, isNot(contains('导航 菜单 广告'.repeat(4000))));
    });

    test('handles limit larger than text', () {
      const text = 'abc';
      expect(pickTimetableText(text, limit: 30000), text);
    });
  });

  group('decodeUtf8Tolerant', () {
    test('replaces malformed bytes instead of throwing', () {
      final bytes = <int>[0xE8, 0xAF, 0xBE, 0xFF, 0x41]; // 课 + bad byte + 'A'
      final out = decodeUtf8Tolerant(bytes);
      expect(out, contains('课'));
      expect(out, contains('A'));
    });
  });

  group('AppMeta runtime version', () {
    test('applyPackageInfo overrides the bundled fallback', () {
      AppMeta.applyPackageInfo(version: '9.9.9', buildNumber: '123');
      expect(AppMeta.version, '9.9.9');
      expect(AppMeta.build, 123);
    });

    test('version URLs carry a time buster, not the frozen build number', () {
      // The old `?b=<build>` let CDNs serve stale manifests forever, because
      // the build only changes after an update. Guard the new format.
      expect(AppMeta.versionUrl, contains('?t='));
      expect(AppMeta.versionUrl, isNot(contains('?b=')));
      expect(AppMeta.versionUrlFallback, contains('?t='));
      expect(AppMeta.versionUrlMirror, contains('?t='));
    });

    test('ignores empty or unparsable values', () {
      AppMeta.applyPackageInfo(version: '9.9.9', buildNumber: '123');
      AppMeta.applyPackageInfo(version: '  ', buildNumber: 'oops');
      expect(AppMeta.version, '9.9.9');
      expect(AppMeta.build, 123);
    });
  });
}

extension on String {
  String repeat(int n) => List.filled(n, this).join();
}
