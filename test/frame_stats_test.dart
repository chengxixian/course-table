import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsu_schedule/ui/frame_stats.dart';

void main() {
  test('percentile uses nearest rank and tolerates empty input', () {
    expect(FrameReport.percentile(const [], 50), 0);
    expect(FrameReport.percentile(const [7], 95), 7);
    final sorted = List<double>.generate(101, (i) => i.toDouble());
    expect(FrameReport.percentile(sorted, 50), 50);
    expect(FrameReport.percentile(sorted, 95), 95);
    expect(FrameReport.percentile(sorted, 0), 0);
    expect(FrameReport.percentile(sorted, 100), 100);
  });

  test('report separates build and raster and counts frames over budget', () {
    final timings = [
      _timing(buildMs: 4, rasterMs: 3),
      _timing(buildMs: 6, rasterMs: 5),
      _timing(buildMs: 12, rasterMs: 9),
    ];
    final report = FrameReport.from('drag', timings, budgetMs: 16.7);

    expect(report.frames, 3);
    expect(report.p50BuildMs, 6);
    expect(report.maxBuildMs, 12);
    expect(report.maxRasterMs, 9);
    expect(report.jankyFrames, 1, reason: '12 + 9 ms misses a 16.7 ms frame');
    expect(report.jankRate, closeTo(1 / 3, 1e-9));
    expect(report.describe(), contains('jank 1/3'));
  });

  test('empty window reports zeroes instead of dividing by zero', () {
    final report = FrameReport.from('idle', const []);
    expect(report.frames, 0);
    expect(report.jankRate, 0);
    expect(report.p95BuildMs, 0);
  });

  test('capture is a no-op when nothing was started', () {
    expect(FrameStats.instance.end(), isNull);
    expect(FrameStats.instance.isCapturing, isFalse);
  });

  testWidgets('a frame window closes by itself even when timings never arrive', (tester) async {
    addTearDown(FrameStats.instance.end);
    await tester.pumpWidget(const SizedBox());
    FrameStats.instance.beginFrames('probe', frames: 1);
    expect(FrameStats.instance.isCapturing, isTrue);

    // A widget test produces no FrameTiming, so only the wall-clock valve can
    // close the window; without it every later frame would be swallowed.
    await tester.pump(const Duration(seconds: 2));
    expect(FrameStats.instance.isCapturing, isFalse);
  });
}

FrameTiming _timing({required double buildMs, required double rasterMs}) => FrameTiming(
      vsyncStart: 0,
      buildStart: 0,
      buildFinish: (buildMs * 1000).round(),
      rasterStart: 0,
      rasterFinish: (rasterMs * 1000).round(),
      rasterFinishWallTime: (rasterMs * 1000).round(),
    );
