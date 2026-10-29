import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsu_schedule/ui/time_scene.dart';

void main() {
  test('phase boundaries', () {
    TimePhase at(int h, [int m = 0]) => TimePhase.of(DateTime(2026, 1, 1, h, m));
    expect(at(4, 59), TimePhase.night);
    expect(at(5), TimePhase.morning);
    expect(at(9, 59), TimePhase.morning);
    expect(at(10), TimePhase.noon);
    expect(at(14, 59), TimePhase.noon);
    expect(at(15), TimePhase.sunset);
    expect(at(18, 59), TimePhase.sunset);
    expect(at(19), TimePhase.night);
    expect(at(0), TimePhase.night);
    expect(at(23, 59), TimePhase.night);
  });

  final cases = <(String, DateTime, Size)>[
    ('morning', DateTime(2026, 10, 29, 7, 30), const Size(900, 360)),
    ('noon', DateTime(2026, 10, 29, 12, 15), const Size(900, 360)),
    ('sunset', DateTime(2026, 10, 29, 17, 40), const Size(900, 360)),
    ('night', DateTime(2026, 10, 29, 21, 5), const Size(900, 360)),
    ('small_night', DateTime(2026, 10, 29, 22, 0), const Size(320, 320)),
  ];

  for (final (name, time, size) in cases) {
    testWidgets('render $name', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: RepaintBoundary(
          key: key,
          child: TimeScene(time: time),
        ),
      ));
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File(
          '${Directory.current.path}/.dart_tool/preview_$name.png');
      await out.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    });
  }
}
