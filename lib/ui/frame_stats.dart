import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Frame-timing capture for debug and profile builds.
///
/// FlClash keeps a measured per-effect frame-cost table and decides what to cut
/// from it. This is the same idea at app scale: bracket an interaction, then
/// read back p50/p95 and the jank count instead of arguing about whether it
/// feels smooth.
///
/// Only release builds compile the body away: profile matters more than debug
/// here, because JIT timings in debug say nothing about a real frame.
class FrameStats {
  FrameStats._();

  static final FrameStats instance = FrameStats._();

  static const double defaultBudgetMs = 1000 / 60;

  /// Debug and profile, not release.
  static bool get enabled => !kReleaseMode;

  final List<FrameTiming> _samples = <FrameTiming>[];
  late final TimingsCallback _callback = _onTimings;
  String? _label;
  bool _capturing = false;
  int? _autoFinishAfter;
  Timer? _deadline;

  bool get isCapturing => _capturing;

  /// Starts a capture window, replacing any samples from a previous one.
  ///
  /// Call [end] when the interaction finishes.
  void begin(String label) {
    if (!enabled) return;
    _samples.clear();
    _label = label;
    _autoFinishAfter = null;
    if (_capturing) return;
    _capturing = true;
    SchedulerBinding.instance.addTimingsCallback(_callback);
  }

  /// Captures [frames] frames starting now, then reports and stops by itself.
  ///
  /// For one-shot work with no natural end — a week switch or a popup opening —
  /// where the cost is the rebuild itself rather than a gesture.
  void beginFrames(String label, {int frames = 5}) {
    if (!enabled) return;
    begin(label);
    _autoFinishAfter = math.max(1, frames);
    _armSafetyValve();
  }

  /// The frame count is a hint, not a guarantee: if timings never arrive (no
  /// frames are being produced) the window would stay open and swallow every
  /// later frame, so a wall-clock deadline closes it as well.
  void _armSafetyValve() {
    _deadline?.cancel();
    _deadline = Timer(const Duration(milliseconds: 1500), () {
      if (_capturing) end();
    });
  }

  /// Stops the window and prints one summary line outside release builds.
  FrameReport? end() {
    if (!enabled || !_capturing) return null;
    SchedulerBinding.instance.removeTimingsCallback(_callback);
    _capturing = false;
    _autoFinishAfter = null;
    final report = FrameReport.from(
      _label ?? 'frames',
      List<FrameTiming>.unmodifiable(_samples),
    );
    _samples.clear();
    _label = null;
    if (report.frames > 0) debugPrint(report.describe());
    return report;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!_capturing) return;
    _samples.addAll(timings);
    final target = _autoFinishAfter;
    if (target != null && _samples.length >= target) {
      end();
    }
  }
}

/// Aggregated build/raster timings for one capture window.
@immutable
class FrameReport {
  const FrameReport({
    required this.label,
    required this.frames,
    required this.budgetMs,
    required this.p50BuildMs,
    required this.p95BuildMs,
    required this.maxBuildMs,
    required this.p50RasterMs,
    required this.p95RasterMs,
    required this.maxRasterMs,
    required this.jankyFrames,
  });

  factory FrameReport.from(String label, List<FrameTiming> timings, {double budgetMs = FrameStats.defaultBudgetMs}) {
    if (timings.isEmpty) {
      return FrameReport(label: label, frames: 0, budgetMs: budgetMs, p50BuildMs: 0, p95BuildMs: 0,
        maxBuildMs: 0, p50RasterMs: 0, p95RasterMs: 0, maxRasterMs: 0, jankyFrames: 0);
    }
    final build = timings.map((t) => t.buildDuration.inMicroseconds / 1000).toList()..sort();
    final raster = timings.map((t) => t.rasterDuration.inMicroseconds / 1000).toList()..sort();
    final janky = timings.where((t) =>
        (t.buildDuration + t.rasterDuration).inMicroseconds / 1000 > budgetMs).length;
    return FrameReport(
      label: label,
      frames: timings.length,
      budgetMs: budgetMs,
      p50BuildMs: percentile(build, 50),
      p95BuildMs: percentile(build, 95),
      maxBuildMs: build.last,
      p50RasterMs: percentile(raster, 50),
      p95RasterMs: percentile(raster, 95),
      maxRasterMs: raster.last,
      jankyFrames: janky,
    );
  }

  final String label;
  final int frames;
  final double budgetMs;
  final double p50BuildMs;
  final double p95BuildMs;
  final double maxBuildMs;
  final double p50RasterMs;
  final double p95RasterMs;
  final double maxRasterMs;
  final int jankyFrames;

  double get jankRate => frames == 0 ? 0 : jankyFrames / frames;

  /// Nearest-rank percentile over an already sorted list.
  static double percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    if (sorted.length == 1) return sorted.first;
    final rank = (p / 100 * (sorted.length - 1)).round().clamp(0, sorted.length - 1);
    return sorted[rank];
  }

  String describe() => '$label: $frames frames  build p50 ${p50BuildMs.toStringAsFixed(1)} '
      'p95 ${p95BuildMs.toStringAsFixed(1)} max ${maxBuildMs.toStringAsFixed(1)}ms  '
      'raster p50 ${p50RasterMs.toStringAsFixed(1)} p95 ${p95RasterMs.toStringAsFixed(1)} '
      'max ${maxRasterMs.toStringAsFixed(1)}ms  jank $jankyFrames/$frames '
      '(${(jankRate * 100).toStringAsFixed(0)}%, budget ${budgetMs.toStringAsFixed(1)}ms)';
}

extension FrameBudget on FrameReport {
  /// Headroom left at p95, negative when the interaction already misses frames.
  double get p95HeadroomMs => budgetMs - math.max(p95BuildMs, p95RasterMs);
}
