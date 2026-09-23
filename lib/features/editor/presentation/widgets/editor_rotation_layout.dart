import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class EditorRotationLayout extends SingleChildRenderObjectWidget {
  const EditorRotationLayout({
    required this.rotationDegrees,
    super.child,
    super.key,
  });

  final double rotationDegrees;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderEditorRotationLayout(rotationDegrees);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _RenderEditorRotationLayout).rotationDegrees =
        rotationDegrees;
  }
}

class _RenderEditorRotationLayout extends RenderProxyBox {
  _RenderEditorRotationLayout(this._rotationDegrees);

  double _rotationDegrees;
  double _scale = 1.0;

  double get rotationDegrees => _rotationDegrees;

  set rotationDegrees(double value) {
    if (_rotationDegrees == value) {
      return;
    }

    _rotationDegrees = value;
    markNeedsLayout();
  }

  double get _rotationRadians {
    return _rotationDegrees * math.pi / 180.0;
  }

  @override
  void performLayout() {
    final child = this.child;

    if (child == null) {
      size = constraints.smallest;
      _scale = 1.0;
      return;
    }

    child.layout(constraints.loosen(), parentUsesSize: true);

    final rotatedSize = _calculateRotatedSize(child.size, _rotationRadians);

    var scale = 1.0;

    if (constraints.hasBoundedWidth && rotatedSize.width > 0.0) {
      scale = math.min(scale, constraints.maxWidth / rotatedSize.width);
    }

    if (constraints.hasBoundedHeight && rotatedSize.height > 0.0) {
      scale = math.min(scale, constraints.maxHeight / rotatedSize.height);
    }

    _scale = scale.clamp(0.0, 1.0);

    size = constraints.constrain(
      Size(rotatedSize.width * _scale, rotatedSize.height * _scale),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;

    if (child == null) {
      return;
    }

    context.pushTransform(
      needsCompositing,
      offset,
      _effectiveTransform(child.size),
      (context, transformedOffset) {
        context.paintChild(child, transformedOffset);
      },
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_effectiveTransform(child.size));
  }

  Matrix4 _effectiveTransform(Size childSize) {
    final transform = Matrix4.translationValues(
      size.width / 2.0,
      size.height / 2.0,
      0.0,
    );

    transform.multiply(Matrix4.rotationZ(_rotationRadians));

    transform.multiply(Matrix4.diagonal3Values(_scale, _scale, 1.0));

    transform.multiply(
      Matrix4.translationValues(
        -childSize.width / 2.0,
        -childSize.height / 2.0,
        0.0,
      ),
    );

    return transform;
  }

  Size _calculateRotatedSize(Size childSize, double radians) {
    final cosine = math.cos(radians).abs();
    final sine = math.sin(radians).abs();

    return Size(
      childSize.width * cosine + childSize.height * sine,
      childSize.width * sine + childSize.height * cosine,
    );
  }
}
