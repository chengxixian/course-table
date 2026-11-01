String buildTimetableHtml(List<Map<String, dynamic>> courses) {
  final maxPeriod = courses
      .map((c) => (c['endPeriod'] as num?)?.toInt() ?? 1)
      .fold(1, (a, b) => a > b ? a : b)
      .clamp(1, 20);
  final buffer = StringBuffer('<table><tr><th>节次</th>');
  const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  for (final d in days) {
    buffer.write('<th>$d</th>');
  }
  buffer.write('</tr>');
  for (var p = 1; p <= maxPeriod; p++) {
    buffer.write('<tr><td>第$p节</td>');
    for (var d = 1; d <= 7; d++) {
      buffer.write('<td>');
      final list = courses.where((c) =>
          (c['day'] as num?)?.toInt() == d && (c['startPeriod'] as num?)?.toInt() == p);
      if (list.isNotEmpty) {
        buffer.write(list.map((c) {
          final name = c['name']?.toString() ?? '';
          final room = c['room']?.toString() ?? '';
          final teacher = c['teacher']?.toString() ?? '';
          final start = (c['startPeriod'] as num?)?.toInt() ?? p;
          final end = (c['endPeriod'] as num?)?.toInt() ?? start;
          final weeks = c['weeks']?.toString() ?? '';
          final parts = <String>[name];
          if (room.isNotEmpty) parts.add('@$room');
          parts.add('第$start-$end节');
          if (weeks.isNotEmpty) parts.add(weeks);
          if (teacher.isNotEmpty) parts.add('$teacher老师');
          return parts.map(_escape).join('<br>');
        }).join('<hr>'));
      }
      buffer.write('</td>');
    }
    buffer.write('</tr>');
  }
  buffer.write('</table>');
  return buffer.toString();
}

String _escape(String value) =>
    value.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
