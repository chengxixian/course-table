import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Draws [child] at [geometry] by translating a retained layer.
///
/// A drag ghost is the one widget that moves every frame, so it must not cost a
/// build or a layout per pointer event. The child keeps its own composited
/// layer and the movement becomes a transform, which also stops the elevation
/// shadow from being re-rasterised on every frame — that shadow is the most
/// expensive thing the ghost paints.
///
/// The technique is adapted from FlClash (`lib/ui/goo.dart`,
/// `lib/ui/navigation_dock.dart`, GPL-3.0); see `NOTICE`.
class DragGhostLayer extends SingleChildRenderObjectWidget {
  const DragGhostLayer({super.key, required this.geometry, super.child});

  /// Ghost rectangle in this layer's coordinate space.
  final ValueListenable<Rect> geometry;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderDragGhost(geometry);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderDragGhost).geometry = geometry;
  }
}

class _RenderDragGhost extends RenderProxyBox {
  _RenderDragGhost(this._geometry) : _laidOutSize = _geometry.value.size;

  ValueListenable<Rect> _geometry;
  Size _laidOutSize;

  set geometry(ValueListenable<Rect> value) {
    if (identical(value, _geometry)) return;
    if (attached) _geometry.removeListener(_handleGeometry);
    _geometry = value;
    if (attached) _geometry.addListener(_handleGeometry);
    _handleGeometry();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _geometry.addListener(_handleGeometry);
  }

  @override
  void detach() {
    _geometry.removeListener(_handleGeometry);
    super.detach();
  }

  /// A size change needs a layout; a pure move needs only a repaint.
  void _handleGeometry() {
    if (_geometry.value.size != _laidOutSize) {
      markNeedsLayout();
    } else {
      markNeedsPaint();
    }
  }

  /// The child is composited so the transform reuses its raster.
  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performLayout() {
    size = constraints.biggest;
    final childSize = _geometry.value.size;
    _laidOutSize = childSize;
    child?.layout(BoxConstraints.tight(childSize));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final rect = _geometry.value;
    context.pushTransform(
      true,
      Offset.zero,
      Matrix4.translationValues(rect.left, rect.top, 0),
      (PaintingContext context, Offset _) => context.paintChild(child, Offset.zero),
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
}

/// Paints the drop target as a rounded highlight, at render-object level.
///
/// The highlight used to be a `DecoratedBox` rebuilt inside a `Stack` on every
/// pointer move; it only changes when the target cell changes, so it paints
/// itself and repaints on its own signal.
class DropHighlightLayer extends LeafRenderObjectWidget {
  const DropHighlightLayer({
    super.key,
    required this.rect,
    this.radius = 12,
    required this.fill,
    required this.stroke,
    this.strokeWidth = 2,
  });

  /// Highlight rectangle in this layer's coordinate space.
  final Rect rect;
  final double radius;
  final Color fill;
  final Color stroke;
  final double strokeWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDropHighlight(rect, radius, fill, stroke, strokeWidth);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderDropHighlight)
      ..rect = rect
      ..radius = radius
      ..fill = fill
      ..stroke = stroke
      ..strokeWidth = strokeWidth;
  }
}

class _RenderDropHighlight extends RenderBox {
  _RenderDropHighlight(this._rect, this._radius, this._fill, this._stroke, this._strokeWidth);

  Rect _rect;
  set rect(Rect value) {
    if (value == _rect) return;
    _rect = value;
    markNeedsPaint();
  }

  double _radius;
  set radius(double value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  Color _fill;
  set fill(Color value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsPaint();
  }

  Color _stroke;
  set stroke(Color value) {
    if (value == _stroke) return;
    _stroke = value;
    markNeedsPaint();
  }

  double _strokeWidth;
  set strokeWidth(double value) {
    if (value == _strokeWidth) return;
    _strokeWidth = value;
    markNeedsPaint();
  }

  @override
  void performLayout() => size = constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final shape = RRect.fromRectAndRadius(_rect.shift(offset), Radius.circular(_radius));
    context.canvas
      ..drawRRect(shape, Paint()..color = _fill)
      ..drawRRect(
        shape.deflate(_strokeWidth / 2),
        Paint()
          ..color = _stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
      );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;
}
