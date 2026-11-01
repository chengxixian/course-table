import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/app_controller.dart';
import '../lib/manual_course.dart';
import '../lib/models.dart';
import '../lib/schedule_overlays.dart';
import '../lib/ui/week_screen.dart';
import 'schedule_overlays_test.dart' as fixtures;

class DragTestController extends AppController {
  late final Schedule base = fixtures.sample();
  final List<MeetingMove> moves = [];
  int commits = 0;
  DragTestController() { schedule = base; }

  @override
  Future<void> moveMeeting(Meeting meeting, int day, int start) async {
    commits++;
    moves.add(MeetingMove(meetingId: meeting.id, day: day,
      startPeriod: start, endPeriod: start + meeting.periodCount - 1));
    schedule = ScheduleOverlays.compose(base, const [], moves);
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}

void main() {
  testWidgets('finger cell highlights; release commits once before ghost snaps and disappears', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = DragTestController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AnimatedBuilder(
      animation: controller,
      builder: (_, __) => WeekScreen(controller: controller, week: 1, onWeekChange: (_) {}),
    ))));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('course-drag-native'));
    expect(card, findsOneWidget);
    final source = tester.getRect(card);
    final pointer = await tester.startGesture(source.center);
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.byKey(const ValueKey('course-drag-feedback')), findsOneWidget);
    final target = source.topLeft + const Offset(2 * 88 + 30, 2 * 60 + 20);
    await pointer.moveTo(target);
    await tester.pump();
    expect(find.byKey(const ValueKey('course-drop-highlight')), findsOneWidget);
    await pointer.up();
    await tester.pump();
    expect(controller.commits, 1);
    expect(controller.schedule!.meetings, hasLength(1));
    expect(controller.schedule!.meetings.single.day, 3);
    expect(controller.schedule!.meetings.single.startPeriod, 3);
    expect(find.byKey(const ValueKey('course-drag-feedback')), findsOneWidget,
      reason: 'ghost remains until data save and snap finish');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('course-drag-feedback')), findsNothing);
    expect(find.byKey(const ValueKey('course-drag-native')), findsOneWidget);
    final moved = tester.getRect(find.byKey(const ValueKey('course-drag-native')));
    expect(moved.left, closeTo(source.left + 2 * 88, 1));
    expect(moved.top, closeTo(source.top + 2 * 60, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('release outside visible timetable does not write coordinates', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = DragTestController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WeekScreen(
      controller: controller, week: 1, onWeekChange: (_) {}))));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('course-drag-native'));
    final pointer = await tester.startGesture(tester.getRect(card).center);
    await tester.pump(const Duration(milliseconds: 650));
    await pointer.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(find.byKey(const ValueKey('course-drop-highlight')), findsNothing);
    await pointer.up();
    await tester.pumpAndSettle();
    expect(controller.commits, 0);
    expect(find.byKey(const ValueKey('course-drag-native')), findsOneWidget);
    expect(find.byKey(const ValueKey('course-drag-feedback')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
