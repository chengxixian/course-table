// Standalone, RegExp-based parser for imported school HTML timetables.
// It scans every <table>, keeps the timetable-looking table with the most
// courses, and never throws to the caller. Supported cell layouts:
//   高等数学 / @A101 / 张老师      (lines split by <br> or newlines)
//   高等数学 张老师 / @A101         (inline room and teacher)
//
// API:
//   Schedule? parseImportedHtml(String html, String sourceUrl, {DateTime? now})
//   String? lastParseError
//
// Only dart:math and models.dart are used.
import 'dart:math' as math;

import 'models.dart';

/// Reason for the most recent failed parse, or null after a successful parse.
String? lastParseError;

const List<Period> _standardPeriods = [
  Period(1, '08:00', '08:45', '上午'), Period(2, '08:55', '09:40', '上午'), Period(3, '10:00', '10:45', '上午'),
  Period(4, '10:55', '11:40', '上午'), Period(5, '14:00', '14:45', '下午'), Period(6, '14:55', '15:40', '下午'),
  Period(7, '16:00', '16:45', '下午'), Period(8, '16:55', '17:40', '下午'), Period(9, '19:00', '19:45', '晚上'),
  Period(10, '19:55', '20:40', '晚上'),
];
final Map<int, Period> _periodMap = {for (final period in _standardPeriods) period.index: period};

// All HTML handling is RegExp-based; no HTML package is used.
final RegExp _tableRe = RegExp(r'<table\b[^>]*>([\s\S]*?)</table\s*>', caseSensitive: false), _rowRe = RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr\s*>', caseSensitive: false), _cellRe = RegExp(r'<t([dh])\b[^>]*>([\s\S]*?)</t\1\s*>', caseSensitive: false);
final RegExp _brRe = RegExp(r'<br\b[^>]*>', caseSensitive: false), _hrRe = RegExp(r'<hr\b[^>]*>', caseSensitive: false);
final RegExp _blockEndRe = RegExp(r'</(?:p|div|li|tr|h[1-6]|ul|ol)\s*>', caseSensitive: false);
final RegExp _scriptRe = RegExp(r'<(script|style)\b[^>]*>[\s\S]*?</\1\s*>', caseSensitive: false);
final RegExp _commentRe = RegExp(r'<!--[\s\S]*?-->'), _tagRe = RegExp(r'<[^>]*>');
final RegExp _dayRe = RegExp(r'(?:周|星期|礼拜)\s*([一二三四五六日天])');
final RegExp _inlineRoomRe = RegExp(r'[@＠]\s*([^\s,，;；、]+)');
final RegExp _inlineTeacherRe = RegExp(r'(?:^|[\s,，;；、])([\u4e00-\u9fa5]{1,4})\s*老师');
final RegExp _clockRe = RegExp(r'(\d{1,2})\s*[:：]\s*(\d{2})');
final RegExp _timeLineRe = RegExp(r'^\s*\d{1,2}\s*[:：]\s*\d{2}(\s*[-–—~～至]\s*\d{1,2}\s*[:：]\s*\d{2})?\s*$');
final RegExp _periodLineRe = RegExp(r'^第?\s*\d{1,2}(\s*[-–—~～至]\s*\d{1,2})?\s*节$');
final RegExp _weekLineRe = RegExp(r'^第?\s*\d{1,2}(\s*[-–—~～至]\s*\d{1,2})?\s*周(\s*[（(]?\s*[单双]\s*[）)]?)?$');

const Map<String, int> _dayNumbers = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7};
const Set<String> _sectionWords = {'上午', '下午', '晚上', '中午', '午休', '课间', '早自习', '晚自习'};
const Set<String> _emptyCells = {'无', '暂无', '—', '-', '/', '空'};
const Set<String> _shortCourseWords = {'体育', '数学', '语文', '英语', '物理', '化学', '生物', '历史', '地理', '政治', '音乐', '美术', '书法', '劳动', '班会', '自习', '军训'};
const Set<String> _surnames = {'王', '李', '张', '刘', '陈', '杨', '黄', '赵', '吴', '周', '徐', '孙', '马', '朱', '胡', '郭', '何', '高', '林', '罗', '郑', '梁', '谢', '宋', '唐', '许', '韩', '冯', '邓', '曹', '彭', '曾', '肖', '田', '董', '袁', '潘', '于', '蒋', '蔡', '余', '杜', '叶', '程', '苏', '魏', '吕', '丁', '任', '沈', '姚', '卢', '姜', '崔', '钟', '谭', '陆', '汪', '范', '金', '石', '廖', '贾', '夏', '韦', '傅', '方', '白', '邹', '孟', '熊', '秦', '邱', '江', '尹', '薛', '闫', '段', '雷', '侯', '龙', '史', '陶', '黎', '贺', '顾', '毛', '郝', '龚', '邵', '万', '钱', '严', '赖', '覃', '洪', '武', '莫', '孔', '欧'};

/// Parses a timetable page. Returns null and fills [lastParseError] on failure.
Schedule? parseImportedHtml(String html, String sourceUrl, {DateTime? now}) {
  lastParseError = null;
  final moment = now ?? DateTime.now();
  try {
    if (html.trim().isEmpty) { lastParseError = '导入内容为空（$sourceUrl）'; return null; }
    final tables = _tableRe.allMatches(html).toList();
    if (tables.isEmpty) { lastParseError = '页面中未找到 <table> 课表（$sourceUrl）'; return null; }
    _TableScan? best;
    String? firstError;
    for (final table in tables) {
      final scan = _scanTable(table.group(1) ?? '');
      if (scan.meetings.isNotEmpty && (best == null || scan.meetings.length > best.meetings.length)) best = scan;
      if (scan.meetings.isEmpty && firstError == null && scan.error != null) firstError = scan.error;
    }
    if (best == null) { lastParseError = firstError ?? '未找到包含周一至周日表头的课表（$sourceUrl）'; return null; }
    return _buildSchedule(best.meetings, moment);
  } catch (error) {
    lastParseError = '解析失败：$error';
    return null;
  }
}

/// Extracts rows, finds a weekday header and turns every non-empty cell below
/// it into a temporary meeting.
_TableScan _scanTable(String body) {
  final rows = <List<String>>[];
  for (final rowMatch in _rowRe.allMatches(body)) {
    final cells = <String>[];
    for (final cellMatch in _cellRe.allMatches(rowMatch.group(1) ?? '')) {
      cells.add(_cleanCell(cellMatch.group(2) ?? ''));
    }
    if (cells.any((cell) => cell.isNotEmpty)) rows.add(cells);
  }
  if (rows.isEmpty) return (meetings: const <_TempMeeting>[], error: null);

  _Header? header;
  for (var r = 0; r < rows.length; r++) {
    final days = <int, int>{};
    for (var c = 0; c < rows[r].length; c++) {
      final day = _dayOf(rows[r][c]);
      if (day != null) days[c] = day;
    }
    if (days.values.toSet().length >= 3) { header = (index: r, dayByColumn: days); break; }
  }
  if (header == null) return (meetings: const <_TempMeeting>[], error: null);
  if (rows.length - header.index - 1 < 2) {
    return (meetings: const <_TempMeeting>[], error: '课表数据不足 2 行');
  }

  final firstDayColumn = header.dayByColumn.keys.reduce(math.min);
  final meetings = <_TempMeeting>[];
  final seen = <String>{};
  var ordinal = 0;
  for (var r = header.index + 1; r < rows.length; r++) {
    final cells = rows[r];
    if (cells.where((cell) => _dayOf(cell) != null).length >= 3) continue; // second header row
    if (_isSectionRow(cells)) continue;
    ordinal++;
    final rowTimes = _times(cells.take(firstDayColumn).join(' '));
    final rowPeriod = _periodFromRow(cells, firstDayColumn);
    final rowStart = rowPeriod?.$1 ?? ordinal, rowEnd = rowPeriod?.$2 ?? ordinal;
    for (final entry in header.dayByColumn.entries) {
      final text = entry.key < cells.length ? cells[entry.key] : '';
      if (text.isEmpty || _dayOf(text) != null) continue;
      for (final course in _coursesInCell(text)) {
        final start = course.startPeriod ?? rowStart, end = course.endPeriod ?? rowEnd;
        if (start < 1 || start > 20 || end < start) continue;
        final temp = _TempMeeting(course.name, course.teacher, course.rooms, entry.value, start, end,
            course.times.isNotEmpty ? course.times : rowTimes);
        if (seen.add(temp.key)) meetings.add(temp);
      }
    }
  }
  if (meetings.isEmpty) return (meetings: const <_TempMeeting>[], error: '课表中没有解析到课程');
  return (meetings: meetings, error: null);
}

/// Splits a cell into blocks when it contains several courses.
List<_CellCourse> _coursesInCell(String text) {
  if (_emptyCells.contains(text.trim())) return [];
  final cellTimes = _times(text);
  final cellPeriod = _parsePeriod(text, allowBare: false);
  final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
  final result = <_CellCourse>[];
  for (final block in _splitBlocks(lines)) {
    final parsed = _courseFromBlock(block);
    if (parsed == null) continue;
    final blockText = block.join(' ');
    final blockTimes = _times(blockText);
    final period = _parsePeriod(blockText, allowBare: false) ?? cellPeriod;
    final times = blockTimes.length >= 2 ? blockTimes : (cellTimes.length >= 2 ? cellTimes : (blockTimes.isNotEmpty ? blockTimes : cellTimes));
    result.add(_CellCourse(parsed.name, parsed.rooms, parsed.teacher, period?.$1, period?.$2, times));
  }
  return result;
}

List<List<String>> _splitBlocks(List<String> lines) {
  final blocks = <List<String>>[];
  var current = <String>[], sawRoom = false, sawTeacher = false;
  void flush() {
    if (current.isNotEmpty) blocks.add(current);
    current = <String>[];
    sawRoom = false;
    sawTeacher = false;
  }

  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line == '---') { flush(); continue; }
    if (_timeLineRe.hasMatch(line) || _periodLineRe.hasMatch(line) || _weekLineRe.hasMatch(line)) continue;
    if (_sectionWords.contains(line)) continue;
    final isRoom = _looksLikeRoom(line, first: current.isEmpty);
    final isTeacher = _looksLikeTeacher(line) || (current.isNotEmpty && _looksLikePlainTeacher(line));
    // A new name after a finished course (room/teacher seen) starts a new course.
    if (current.isNotEmpty && !isRoom && !isTeacher && (sawRoom || sawTeacher)) flush();
    current.add(line);
    sawRoom = sawRoom || isRoom;
    sawTeacher = sawTeacher || isTeacher;
  }
  flush();
  return blocks;
}

({String name, List<String> rooms, String teacher})? _courseFromBlock(List<String> block) {
  final rooms = <String>[], teachers = <String>[], names = <String>[];
  for (var i = 0; i < block.length; i++) {
    final line = block[i];
    for (final match in _inlineRoomRe.allMatches(line)) {
      final room = _cleanRoom(match.group(1) ?? '');
      if (room.isNotEmpty && !rooms.contains(room)) rooms.add(room);
    }
    var rest = line.replaceAll(_inlineRoomRe, ' ');

    final lineTeachers = <String>[];
    for (final match in _inlineTeacherRe.allMatches(line)) {
      final teacher = _cleanPerson('${match.group(1)!}老师');
      if (teacher.isNotEmpty && !lineTeachers.contains(teacher)) lineTeachers.add(teacher);
    }
    if (_looksLikeTeacher(line) && lineTeachers.isEmpty) {
      final teacher = _cleanPerson(line);
      if (teacher.isNotEmpty) lineTeachers.add(teacher);
    }
    rest = rest.replaceAll(_inlineTeacherRe, ' ').trim();
    if (lineTeachers.isNotEmpty) {
      teachers.addAll(lineTeachers);
      rest = rest.replaceAll(RegExp(r'[，,;；、]+$'), '').trim();
    }
    if (rest.isEmpty) continue;
    if (_looksLikeRoom(rest, first: i == 0)) {
      final room = _cleanRoom(rest);
      if (room.isNotEmpty && !rooms.contains(room)) rooms.add(room);
      continue;
    }
    final nextIsRoom = i + 1 < block.length && _looksLikeRoom(block[i + 1]);
    if (_looksLikePlainTeacher(rest) && i > 0 && (i == block.length - 1 || nextIsRoom)) {
      final teacher = _cleanPerson(rest);
      if (teacher.isNotEmpty && !teachers.contains(teacher)) teachers.add(teacher);
      continue;
    }
    if (_timeLineRe.hasMatch(rest) || _periodLineRe.hasMatch(rest)) continue;
    names.add(rest);
  }
  if (names.isEmpty) return null;
  var name = names.first.replaceAll(RegExp(r'^\s*\d+\s*[.、]\s*'), '');
  name = name.replaceAll(RegExp(r'^[\s·•●◇★☆\-—]+|[\s·•●◇★☆\-—]+$'), '').trim();
  if (name.isEmpty || _emptyCells.contains(name)) return null;
  return (name: name, rooms: rooms, teacher: teachers.isEmpty ? '' : teachers.last);
}

/// Builds the models.Schedule from parsed temporary meetings.
Schedule _buildSchedule(List<_TempMeeting> raw, DateTime now) {
  final byName = <String, List<_TempMeeting>>{};
  for (final meeting in raw) { byName.putIfAbsent(meeting.name, () => []).add(meeting); }
  final courses = <Course>[];
  final meetings = <Meeting>[];
  for (final entry in byName.entries) {
    final items = entry.value..sort((a, b) => a.day == b.day ? a.start - b.start : a.day - b.day);
    final teachers = <String>[], rooms = <String>[], courseMeetings = <Meeting>[];
    for (final item in items) {
      if (item.teacher.isNotEmpty && !teachers.contains(item.teacher)) teachers.add(item.teacher);
      for (final room in item.rooms) {
        if (room.isNotEmpty && !rooms.contains(room)) rooms.add(room);
      }
      final meeting = _toMeeting(item, entry.key);
      courseMeetings.add(meeting);
      meetings.add(meeting);
    }
    courses.add(Course(
      id: _courseId(entry.key), code: '', name: entry.key,
      teacher: teachers.isEmpty ? '' : teachers.first, teachers: teachers, rooms: rooms,
      credits: null, type: '', category: '', kind: '', meetings: courseMeetings,
      weeks: List<int>.generate(20, (i) => i + 1), weeksText: '1-20周',
      roomsText: rooms.join(' / '), colorIndex: _colorIndex(entry.key), adjusted: false,
    ));
  }
  meetings.sort((a, b) => a.day == b.day ? a.startPeriod - b.startPeriod : a.day - b.day);
  final start = _mondayOf(now), end = start.add(const Duration(days: 139));
  return Schedule(
    student: const Student(),
    semester: Semester(academicYear: now.year.toString(), term: 1, start: _dateKey(start),
        end: _dateKey(end), name: '导入课表', totalWeeks: 20),
    periods: _standardPeriods, courses: courses, meetings: meetings,
    conflicts: [], fetchedAt: now, source: '网页导入',
  );
}

Meeting _toMeeting(_TempMeeting item, String courseName) {
  final startTime = item.times.isNotEmpty ? item.times.first : (_periodMap[item.start]?.start ?? '');
  final endActual = item.times.length >= 2 ? item.times[1] : (_periodMap[item.end]?.end ?? '');
  final startMinutes = _minutes(startTime);
  final end45 = startMinutes == null ? '' : _formatMinutes(startMinutes + (item.end - item.start + 1) * 45);
  return Meeting(
    id: 'imp_${_hash(item.key)}', courseId: _courseId(courseName), courseName: courseName,
    sectionName: '', teacher: item.teacher, room: item.rooms.join(' / '), campus: '',
    day: item.day, startPeriod: item.start, endPeriod: item.end,
    weeks: List<int>.generate(20, (i) => i + 1), weeksText: '1-20周',
    startTime: startTime, endTime45: end45, endTimeActual: endActual,
    credits: null, courseCode: '', courseType: '', category: '', kind: '',
  );
}

// ---------------------------------------------------------------- HTML utils
String _cleanCell(String raw) {
  var text = raw.replaceAll(_commentRe, ' ').replaceAll(_scriptRe, ' ');
  text = text.replaceAll(RegExp(r'(?:<br\b[^>]*>\s*){2,}', caseSensitive: false), '\n---\n');
  text = text.replaceAll(_brRe, '\n').replaceAll(_hrRe, '\n---\n').replaceAll(_blockEndRe, '\n');
  text = text.replaceAll(_tagRe, ' ');
  text = _decodeEntities(text).replaceAll(RegExp(r'[\u00a0\u3000]'), ' ');
  final lines = text.split(RegExp(r'\r\n|\r|\n')).map((part) => part.replaceAll(RegExp(r'[ \t\f\v]+'), ' ').trim()).where((line) => line.isNotEmpty).toList();
  return lines.join('\n');
}

String _decodeEntities(String input) {
  if (!input.contains('&')) return input;
  var out = input.replaceAllMapped(RegExp(r'&#[xX]([0-9a-fA-F]{1,6});?'), (m) => _charOrEmpty(int.tryParse(m.group(1)!, radix: 16)));
  out = out.replaceAllMapped(RegExp(r'&#(\d{1,7});?'), (m) => _charOrEmpty(int.tryParse(m.group(1)!)));
  const named = <String, String>{
    'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' ', 'middot': '·', 'hellip': '…', 'mdash': '—', 'ndash': '–', 'times': '×', 'divide': '÷', 'deg': '°',
    'ldquo': '“', 'rdquo': '”', 'lsquo': '‘', 'rsquo': '’', 'bull': '•', 'copy': '©', 'reg': '®',
  };
  return out.replaceAllMapped(RegExp(r'&([a-zA-Z][a-zA-Z0-9]{1,31});?'), (m) => named[m.group(1)!.toLowerCase()] ?? m.group(0)!);
}

String _charOrEmpty(int? code) => code == null || code <= 0 || code > 0x10ffff || (code >= 0xd800 && code <= 0xdfff) ? '' : String.fromCharCode(code);

// --------------------------------------------------------------- table utils
int? _dayOf(String text) => _dayNumbers[_dayRe.firstMatch(text)?.group(1) ?? ''];

bool _isSectionRow(List<String> cells) {
  final filled = cells.map((cell) => cell.trim()).where((cell) => cell.isNotEmpty).toList();
  return filled.isNotEmpty && filled.every(_sectionWords.contains);
}

(int, int)? _periodFromRow(List<String> cells, int firstDayColumn) =>
    cells.take(firstDayColumn).map((cell) => _parsePeriod(cell, allowBare: true)).whereType<(int, int)>().firstOrNull;

/// Parses "第3-4节", "3-4" (row labels only), "第5节" and "5".
(int, int)? _parsePeriod(String text, {required bool allowBare}) {
  final s = text.replaceAll(RegExp(r'\s+'), '');
  var match = RegExp(r'第?(\d{1,2})[-–—~～至－](\d{1,2})节').firstMatch(s);
  if (match != null) return _range(int.parse(match.group(1)!), int.parse(match.group(2)!));
  match = RegExp(r'第(\d{1,2})节').firstMatch(s) ?? RegExp(r'(\d{1,2})节').firstMatch(s);
  if (match != null) return _range(int.parse(match.group(1)!), null);
  if (!allowBare) return null;
  match = RegExp(r'^第?(\d{1,2})(?:[-–—~～至－](\d{1,2})?)?节?$').firstMatch(s);
  if (match == null) return null;
  return _range(int.parse(match.group(1)!), match.group(2) == null ? null : int.parse(match.group(2)!));
}

(int, int)? _range(int? a, int? b) {
  if (a == null || a < 1) return null;
  final other = b ?? a;
  return other < 1 ? null : (math.min(a, other), math.max(a, other));
}

List<String> _times(String text) {
  final result = <String>[];
  for (final match in _clockRe.allMatches(text)) {
    final hour = int.tryParse(match.group(1)!), minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) continue;
    final clock = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    if (result.isEmpty || result.last != clock) result.add(clock);
  }
  return result;
}

bool _looksLikeRoom(String line, {bool first = false}) {
  if (line.startsWith('@') || line.startsWith('＠')) return true;
  return (!first && RegExp(r'(楼|室|馆|场|机房|实验室|报告厅|礼堂|操场|球场|校区|基地|中心)').hasMatch(line)) ||
      RegExp(r'^[A-Za-z]{1,4}-?\d{2,4}[A-Za-z]?$').hasMatch(line) ||
      RegExp(r'^[A-Za-z]?\d{1,2}[-－]\d{2,4}$').hasMatch(line);
}

bool _looksLikeTeacher(String line) => line.contains('老师') || line.contains('教师');
bool _looksLikePlainTeacher(String line) => RegExp(r'^[\u4e00-\u9fa5]{2,3}$').hasMatch(line) && !_shortCourseWords.contains(line) && _surnames.contains(line[0]);
String _cleanRoom(String value) => value.trim().replaceAll(RegExp(r'^[@＠]\s*'), '').replaceAll(RegExp(r'[，,;；、]+$'), '').trim();
String _cleanPerson(String value) => value.replaceAll(RegExp(r'[\s,，;；、]+'), '').trim();

// ------------------------------------------------------------------- helpers
int? _minutes(String clock) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(clock);
  return match == null ? null : int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
}

String _formatMinutes(int minutes) => '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

DateTime _mondayOf(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String _courseId(String name) => 'imp_${_hash(name)}';

int _colorIndex(String name) {
  var sum = 0;
  for (final unit in name.codeUnits) {
    sum = (sum + unit) & 0x7fffffff;
  }
  return sum % 8;
}

String _hash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(36);
}

// ---------------------------------------------------------- private data types
typedef _TableScan = ({List<_TempMeeting> meetings, String? error});
typedef _Header = ({int index, Map<int, int> dayByColumn});

class _CellCourse {
  final String name, teacher;
  final List<String> rooms, times;
  final int? startPeriod, endPeriod;
  const _CellCourse(this.name, this.rooms, this.teacher, this.startPeriod, this.endPeriod, this.times);
}

class _TempMeeting {
  final String name, teacher;
  final List<String> rooms, times;
  final int day, start, end;
  const _TempMeeting(this.name, this.teacher, this.rooms, this.day, this.start, this.end, this.times);
  String get key => '$name|$day|$start|$end|${rooms.join(',')}|$teacher';
}
