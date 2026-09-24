class NormalizedCropRect {
  const NormalizedCropRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  static const double minimumExtent = 0.01;

  static const NormalizedCropRect fullFrame = NormalizedCropRect(
    left: 0,
    top: 0,
    right: 1,
    bottom: 1,
  );

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  bool get isFullFrame => this == fullFrame;

  NormalizedCropRect copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return NormalizedCropRect(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  NormalizedCropRect sanitized() {
    var sanitizedLeft = _finiteOr(left, 0).clamp(0.0, 1.0).toDouble();
    var sanitizedTop = _finiteOr(top, 0).clamp(0.0, 1.0).toDouble();
    var sanitizedRight = _finiteOr(right, 1).clamp(0.0, 1.0).toDouble();
    var sanitizedBottom = _finiteOr(bottom, 1).clamp(0.0, 1.0).toDouble();

    if (sanitizedRight < sanitizedLeft) {
      final swap = sanitizedLeft;
      sanitizedLeft = sanitizedRight;
      sanitizedRight = swap;
    }

    if (sanitizedBottom < sanitizedTop) {
      final swap = sanitizedTop;
      sanitizedTop = sanitizedBottom;
      sanitizedBottom = swap;
    }

    if (sanitizedRight - sanitizedLeft < minimumExtent) {
      final center = (sanitizedLeft + sanitizedRight) / 2;
      sanitizedLeft = (center - minimumExtent / 2)
          .clamp(0.0, 1.0 - minimumExtent)
          .toDouble();
      sanitizedRight = sanitizedLeft + minimumExtent;
    }

    if (sanitizedBottom - sanitizedTop < minimumExtent) {
      final center = (sanitizedTop + sanitizedBottom) / 2;
      sanitizedTop = (center - minimumExtent / 2)
          .clamp(0.0, 1.0 - minimumExtent)
          .toDouble();
      sanitizedBottom = sanitizedTop + minimumExtent;
    }

    return NormalizedCropRect(
      left: sanitizedLeft,
      top: sanitizedTop,
      right: sanitizedRight,
      bottom: sanitizedBottom,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NormalizedCropRect &&
        left == other.left &&
        top == other.top &&
        right == other.right &&
        bottom == other.bottom;
  }

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  static double _finiteOr(double value, double fallback) {
    return value.isFinite ? value : fallback;
  }
}

class NormalizedCropOffset {
  const NormalizedCropOffset({required this.dx, required this.dy});

  static const NormalizedCropOffset zero = NormalizedCropOffset(dx: 0, dy: 0);

  final double dx;
  final double dy;

  bool get isZero => this == zero;

  NormalizedCropOffset copyWith({double? dx, double? dy}) {
    return NormalizedCropOffset(dx: dx ?? this.dx, dy: dy ?? this.dy);
  }

  NormalizedCropOffset sanitized() {
    return NormalizedCropOffset(
      dx: dx.isFinite ? dx : 0,
      dy: dy.isFinite ? dy : 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NormalizedCropOffset && dx == other.dx && dy == other.dy;
  }

  @override
  int get hashCode => Object.hash(dx, dy);
}

class CropState {
  const CropState({
    this.normalizedRect = NormalizedCropRect.fullFrame,
    this.aspectRatio,
    this.straightenDegrees = 0,
    this.scale = 1,
    this.offset = NormalizedCropOffset.zero,
  });

  static const double minimumStraightenDegrees = -45;
  static const double maximumStraightenDegrees = 45;
  static const double minimumScale = 1;
  static const double maximumScale = 20;

  final NormalizedCropRect normalizedRect;

  /// Width divided by height. `null` means Free.
  final double? aspectRatio;

  /// Fine crop-workspace straightening, separate from ordinary 90° rotation.
  final double straightenDegrees;

  /// Relative image scale used while positioning the photo behind the crop.
  final double scale;

  /// Normalized image-position offset used by the crop workspace.
  final NormalizedCropOffset offset;

  static const CropState initial = CropState();

  bool get isDefault =>
      normalizedRect.isFullFrame &&
      aspectRatio == null &&
      straightenDegrees == 0 &&
      scale == 1 &&
      offset.isZero;

  CropState copyWith({
    NormalizedCropRect? normalizedRect,
    double? aspectRatio,
    bool clearAspectRatio = false,
    double? straightenDegrees,
    double? scale,
    NormalizedCropOffset? offset,
  }) {
    return CropState(
      normalizedRect: normalizedRect ?? this.normalizedRect,
      aspectRatio: clearAspectRatio ? null : aspectRatio ?? this.aspectRatio,
      straightenDegrees: straightenDegrees ?? this.straightenDegrees,
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
    );
  }

  CropState sanitized() {
    final ratio = aspectRatio;

    return CropState(
      normalizedRect: normalizedRect.sanitized(),
      aspectRatio: ratio != null && ratio.isFinite && ratio > 0 ? ratio : null,
      straightenDegrees: (straightenDegrees.isFinite ? straightenDegrees : 0)
          .clamp(minimumStraightenDegrees, maximumStraightenDegrees)
          .toDouble(),
      scale: (scale.isFinite ? scale : minimumScale)
          .clamp(minimumScale, maximumScale)
          .toDouble(),
      offset: offset.sanitized(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CropState &&
        normalizedRect == other.normalizedRect &&
        aspectRatio == other.aspectRatio &&
        straightenDegrees == other.straightenDegrees &&
        scale == other.scale &&
        offset == other.offset;
  }

  @override
  int get hashCode {
    return Object.hash(
      normalizedRect,
      aspectRatio,
      straightenDegrees,
      scale,
      offset,
    );
  }
}
