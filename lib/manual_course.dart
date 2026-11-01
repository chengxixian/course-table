import 'dart:convert';

class ManualCourseEntry {
  final String id;
  final String name;
  final String teacher;
  final String room;
  final int day;
  final int startPeriod;
  final int endPeriod;
  final String weeksText;
  final List<int> weeks;
  final int colorIndex;

  const ManualCourseEntry({
    required this.id,
    required this.name,
    this.teacher = '',
    this.room = '',
    required this.day,
    required this.startPeriod,
    required this.endPeriod,
    this.weeksText = '',
    this.weeks = const [],
    this.colorIndex = 0,
  });

  factory ManualCourseEntry.fromJson(Map<String, dynamic> json) => ManualCourseEntry(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        teacher: json['teacher']?.toString() ?? '',
        room: json['room']?.toString() ?? '',
        day: (json['day'] as num?)?.toInt() ?? 1,
        startPeriod: (json['startPeriod'] as num?)?.toInt() ?? 1,
        endPeriod: (json['endPeriod'] as num?)?.toInt() ?? 1,
        weeksText: json['weeksText']?.toString() ?? '',
        weeks: (json['weeks'] as List?)?.whereType<num>().map((e) => e.toInt()).toList() ?? const [],
        colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'teacher': teacher,
        'room': room,
        'day': day,
        'startPeriod': startPeriod,
        'endPeriod': endPeriod,
        'weeksText': weeksText,
        'weeks': weeks,
        'colorIndex': colorIndex,
      };

  String encode() => jsonEncode(toJson());
}

List<int> parseManualWeeks(String text, int totalWeeks) {
  final out = <int>{};
  for (final part in text.split(RegExp(r'[,，]'))) {
    final s = part.trim();
    if (s.isEmpty) continue;
    final m = RegExp(r'^(\d+)\s*[-~—]\s*(\d+)$').firstMatch(s);
    if (m != null) {
      final a = int.tryParse(m.group(1)!) ?? 0;
      final b = int.tryParse(m.group(2)!) ?? 0;
      for (var i = a; i <= b; i++) {
        if (i >= 1 && i <= totalWeeks) out.add(i);
      }
    } else {
      final n = int.tryParse(s);
      if (n != null && n >= 1 && n <= totalWeeks) out.add(n);
    }
  }
  if (out.isEmpty) out.addAll(List.generate(totalWeeks, (i) => i + 1));
  return out.toList()..sort();
}


class MeetingMove {
  final String meetingId;
  final int day;
  final int startPeriod;
  final int endPeriod;
  const MeetingMove({required this.meetingId, required this.day, required this.startPeriod, required this.endPeriod});
  factory MeetingMove.fromJson(Map<String, dynamic> json) => MeetingMove(
        meetingId: json['meetingId']?.toString() ?? '',
        day: (json['day'] as num?)?.toInt() ?? 1,
        startPeriod: (json['startPeriod'] as num?)?.toInt() ?? 1,
        endPeriod: (json['endPeriod'] as num?)?.toInt() ?? 1,
      );
  Map<String, dynamic> toJson() => {'meetingId': meetingId, 'day': day, 'startPeriod': startPeriod, 'endPeriod': endPeriod};
}
