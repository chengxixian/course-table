import 'dart:async';

import 'package:flutter/material.dart';

/// Timing and curves shared by the app's motion primitives (180-320 ms).
///
/// All motion is skipped when the platform requests reduced motion or
/// accessible navigation.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  static bool reduceMotionOf(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      (MediaQuery.maybeAccessibleNavigationOf(context) ?? false);
}

/// Fades and slides [child] in once on mount, from [offset] after [delay].
///
/// With reduced motion the child appears immediately.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.medium,
    this.curve = Motion.emphasized,
    this.offset = const Offset(0, 12),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _started = false;
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _progress =
      CurvedAnimation(parent: _controller, curve: widget.curve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduceMotionOf(context)) {
      _timer?.cancel();
      _started = true;
      _controller.value = 1;
    } else if (!_started) {
      _started = true;
      if (widget.delay <= Duration.zero) {
        _controller.forward();
      } else {
        _timer = Timer(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: widget.offset * (1 - _progress.value),
          child: child,
        ),
      ),
    );
  }
}

/// Wraps one child in a [FadeSlideIn] whose delay is based on [index].
///
/// The stagger caps at index 12, and children should have stable keys if the
/// list can reorder.
class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.startDelay = Duration.zero,
    this.stagger = const Duration(milliseconds: 45),
    this.duration = Motion.medium,
    this.curve = Motion.emphasized,
  });

  final int index;
  final Widget child;
  final Duration startDelay;
  final Duration stagger;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final capped = index <= 0 ? 0 : (index > 12 ? 12 : index);
    return FadeSlideIn(
      delay: startDelay + stagger * capped,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}

/// Lays out [children] in a [Column], entering each with a staggered delay.
///
/// All children are built at once; use [AnimatedListItem] per row for long or
/// lazily built lists instead.
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.spacing = 0,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.startDelay = Duration.zero,
    this.stagger = const Duration(milliseconds: 45),
    this.duration = Motion.medium,
    this.curve = Motion.emphasized,
  });

  final List<Widget> children;
  final double spacing;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final Duration startDelay;
  final Duration stagger;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedListItem(
            index: i,
            startDelay: startDelay,
            stagger: stagger,
            duration: duration,
            curve: curve,
            child: children[i],
          ),
      ],
    );
  }
}

/// Cross-fades and slides between pages with an [AnimatedSwitcher].
///
/// Give the active [child] a unique [Key] (or a different runtime type) so the
/// switcher notices the change. Reduced-motion settings swap instantly.
class AnimatedPageSwitcher extends StatelessWidget {
  const AnimatedPageSwitcher({
    super.key,
    required this.child,
    this.duration = Motion.medium,
    this.switchInCurve = Motion.emphasized,
    this.switchOutCurve = Motion.exit,
    this.offset = const Offset(0, 0.04),
  });

  final Widget child;
  final Duration duration;
  final Curve switchInCurve;
  final Curve switchOutCurve;

  /// Fraction of the child's size the incoming page slides from.
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final reduce = Motion.reduceMotionOf(context);
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: offset, end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Subtly scales [child] down while a pointer is pressed on it.
///
/// Uses a raw [Listener], so taps, drags and scrolling owned by the child keep
/// working. Has no effect under reduced motion.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.duration = Motion.fast,
    this.curve = Motion.enter,
    this.enabled = true,
  });

  final Widget child;
  final double pressedScale;
  final Duration duration;
  final Curve curve;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  int? _pointer;
  bool _pressed = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = Motion.reduceMotionOf(context);
    if ((!widget.enabled || _reduceMotion) && _pressed) {
      _pointer = null;
      _pressed = false;
    }
  }

  @override
  void didUpdateWidget(PressScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) {
      _pointer = null;
      _pressed = false;
    }
  }

  void _handleDown(PointerDownEvent event) {
    if (!widget.enabled || _reduceMotion || _pointer != null) return;
    _pointer = event.pointer;
    setState(() => _pressed = true);
  }

  void _handleRelease(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = !widget.enabled || _reduceMotion
        ? 1.0
        : (_pressed ? widget.pressedScale : 1.0);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handleDown,
      onPointerUp: _handleRelease,
      onPointerCancel: _handleRelease,
      child: AnimatedScale(
        scale: scale,
        duration: _reduceMotion ? Duration.zero : widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}
