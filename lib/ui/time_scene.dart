import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Coarse time-of-day band used by [TimeScene] to pick a landscape palette.
enum TimePhase {
  morning,
  noon,
  sunset,
  night;

  /// 05:00-10:00 morning, 10:00-15:00 noon, 15:00-19:00 sunset, else night.
  static TimePhase of(DateTime time) => switch (time.hour) {
        >= 5 && < 10 => TimePhase.morning,
        >= 10 && < 15 => TimePhase.noon,
        >= 15 && < 19 => TimePhase.sunset,
        _ => TimePhase.night,
      };
}

/// A blurred, out-of-focus landscape backdrop that follows the time of day.
///
/// Fills the parent's tight constraints, blurs the whole painted landscape,
/// then lays a translucent scrim above it so light foreground text keeps its
/// contrast. Phase changes crossfade over 600 ms, reduced-motion settings swap
/// instantly, and no semantics are exposed.
class TimeScene extends StatelessWidget {
  /// Backdrop for the phase that [time] falls into.
  const TimeScene({
    super.key,
    required this.time,
    this.blur = 10,
    this.scrimOpacity = 0.28,
  })  : _explicitPhase = null,
        assert(blur >= 0),
        assert(scrimOpacity >= 0 && scrimOpacity <= 1);

  /// Backdrop for an explicit phase, independent of the wall clock.
  const TimeScene.phase({
    super.key,
    required TimePhase phase,
    this.blur = 10,
    this.scrimOpacity = 0.28,
  })  : time = null,
        _explicitPhase = phase,
        assert(blur >= 0),
        assert(scrimOpacity >= 0 && scrimOpacity <= 1);

  /// Clock that selects the palette; null when the phase is explicit.
  final DateTime? time;

  final TimePhase? _explicitPhase;

  /// Gaussian blur sigma for the landscape; 0 disables the blur layer.
  final double blur;

  /// Base opacity of the black scrim, ramped from 62% at the top to full at
  /// the bottom; kept in the 0..1 range.
  final double scrimOpacity;

  /// The phase that is rendered, derived from [time] when not explicit.
  TimePhase get resolvedPhase => _explicitPhase ?? TimePhase.of(time ?? DateTime.now());

  @override
  Widget build(BuildContext context) {
    final phase = resolvedPhase;
    final sigma = math.max(0.0, math.min(blur, 40.0));
    final scrim = math.max(0.0, math.min(scrimOpacity, 1.0));
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final black = Colors.black;
    return SizedBox.expand(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _scene(phase, sigma),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    black.withValues(alpha: scrim * 0.62),
                    black.withValues(alpha: scrim * 0.85),
                    black.withValues(alpha: scrim),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One phase layer, laid out `3 * sigma` larger so the blur keeps its edges.
  Widget _scene(TimePhase phase, double sigma) {
    final overscan = sigma * 3;
    final paint = CustomPaint(size: Size.infinite, painter: _ScenePainter(phase));
    final blurred = sigma <= 0
        ? paint
        : ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: paint,
          );
    return Stack(
      key: ValueKey(phase),
      fit: StackFit.expand,
      children: [
        Positioned(
          left: -overscan, top: -overscan, right: -overscan, bottom: -overscan,
          child: blurred,
        ),
      ],
    );
  }
}

/// Paints the sky, low sun/moon glow, horizon haze and hill silhouettes.
class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.phase);

  final TimePhase phase;

  /// Crest heights per hill layer, far to near, as height fractions.
  static const List<List<double>> _crests = [
    [0.62, 0.55, 0.60, 0.51, 0.58, 0.53, 0.62],
    [0.74, 0.68, 0.73, 0.64, 0.71, 0.66, 0.74],
    [0.88, 0.82, 0.86, 0.78, 0.84, 0.80, 0.88],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final palette = _paletteOf(phase);
    final sky = Offset.zero & size;
    canvas.drawRect(sky, Paint()
      ..shader = ui.Gradient.linear(
        sky.topCenter, sky.bottomCenter, palette.sky, const [0.0, 0.5, 0.84]));
    final center = palette.glowCenter.alongSize(size);
    final glow = palette.glow;
    final radius = size.shortestSide * 0.58;
    canvas.drawCircle(center, radius, Paint()
      ..shader = ui.Gradient.radial(center, radius, [
        glow.withValues(alpha: 0.65),
        glow.withValues(alpha: 0.22),
        glow.withValues(alpha: 0),
      ], const [0.0, 0.42, 1.0]));
    canvas.drawCircle(center, radius * 0.17, Paint()..color = glow.withValues(alpha: 0.7));
    final haze = Rect.fromLTRB(0, size.height * 0.38, size.width, size.height * 0.8);
    canvas.drawRect(haze, Paint()
      ..shader = ui.Gradient.linear(
        haze.topCenter, haze.bottomCenter, [
          glow.withValues(alpha: 0),
          glow.withValues(alpha: 0.2),
          glow.withValues(alpha: 0),
        ], const [0.0, 0.55, 1.0]));
    for (var layer = 0; layer < _crests.length; layer++) {
      final color = palette.hills[layer];
      final alpha = 0.16 + layer * 0.08;
      canvas.drawPath(_hillPath(_crests[layer], size), Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, _crests[layer].reduce(math.min) * size.height),
          Offset(0, size.height),
          [color.withValues(alpha: alpha), color.withValues(alpha: alpha + 0.14)],
        ));
    }
  }

  /// Closed, smoothly interpolated silhouette for one hill layer.
  Path _hillPath(List<double> crest, Size size) {
    final step = size.width / (crest.length - 1);
    final floor = size.height + 1;
    final path = Path()..moveTo(0, floor)..lineTo(0, crest.first * size.height);
    for (var i = 1; i < crest.length; i++) {
      final x = step * i;
      final y = crest[i] * size.height;
      final mid = (step * (i - 1) + x) / 2;
      path.cubicTo(mid, crest[i - 1] * size.height, mid, y, x, y);
    }
    return path..lineTo(size.width, floor)..close();
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) => oldDelegate.phase != phase;
}

/// Sky, glow and hill colours for one time of day.
typedef _Palette = ({List<Color> sky, Color glow, Alignment glowCenter, List<Color> hills});

_Palette _paletteOf(TimePhase phase) => switch (phase) {
      TimePhase.morning => _morning,
      TimePhase.noon => _noon,
      TimePhase.sunset => _sunset,
      TimePhase.night => _night,
    };

const _Palette _morning = (
  sky: [Color(0xFF2F6396), Color(0xFFD8A1A8), Color(0xFFF7B183)],
  glow: Color(0xFFFFD9A0), glowCenter: Alignment(-0.35, 0.42),
  hills: [Color(0xFF2B4A6B), Color(0xFF1D3653), Color(0xFF122642)],
);

const _Palette _noon = (
  sky: [Color(0xFF2769A6), Color(0xFF4F9EBD), Color(0xFF86C6BB)],
  glow: Color(0xFFFFF5CE), glowCenter: Alignment(-0.1, 0.06),
  hills: [Color(0xFF205964), Color(0xFF184A55), Color(0xFF103741)],
);

const _Palette _sunset = (
  sky: [Color(0xFF4B3A78), Color(0xFFA2658B), Color(0xFFF6A46F)],
  glow: Color(0xFFFFC887), glowCenter: Alignment(0.3, 0.4),
  hills: [Color(0xFF432F58), Color(0xFF312346), Color(0xFF221731)],
);

const _Palette _night = (
  sky: [Color(0xFF0C1A33), Color(0xFF15294A), Color(0xFF2A4066)],
  glow: Color(0xFFDCE9FF), glowCenter: Alignment(0.35, 0.12),
  hills: [Color(0xFF0C1830), Color(0xFF081124), Color(0xFF050B19)],
);
