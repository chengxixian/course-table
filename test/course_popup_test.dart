import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/app_controller.dart';
import '../lib/models.dart';
import '../lib/ui/frame_stats.dart';
import '../lib/ui/week_screen.dart';
import 'schedule_overlays_test.dart' as fixtures;

class PopupTestController extends AppController {
  PopupTestController() { schedule = fixtures.sample(); }
}

void main() {
  testWidgets('course detail opens with the spring popup and dismisses on the barrier', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // The popup starts a frame capture; close it so no timer outlives the test.
    addTearDown(FrameStats.instance.end);

    final controller = PopupTestController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: WeekScreen(
      controller: controller, week: 1, onWeekChange: (_) {}))));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('course-drag-native'));
    expect(tester.widgetList(find.text('native')), hasLength(1));

    await tester.tap(card);
    // Mid-flight frame: the spring has started but has not settled.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
    expect(tester.widgetList(find.text('native')).length, greaterThan(1),
      reason: 'the detail sheet is on top of the grid card');

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The barrier is transparent and dismissible; the popup is clamped at least
    // 16 px from the edge, so the top-left corner is always outside it.
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(tester.widgetList(find.text('native')), hasLength(1));
    // Let the capture's wall-clock valve fire inside the test's fake clock.
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
