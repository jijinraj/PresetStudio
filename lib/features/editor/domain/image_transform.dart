class ImageTransform {
  const ImageTransform({
    this.rotationDegrees = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  static const double quarterTurnDegrees = 90.0;
  static const double fullRotationDegrees = 360.0;

  final double rotationDegrees;
  final bool flipHorizontal;
  final bool flipVertical;

  static const ImageTransform initial = ImageTransform();

  double get normalizedRotationDegrees => _normalizeDegrees(rotationDegrees);

  bool get isDefault =>
      normalizedRotationDegrees == 0.0 && !flipHorizontal && !flipVertical;

  /// Temporary compatibility with the current quarter-turn renderer.
  ///
  /// Arbitrary-angle rendering will replace this in the next rendering
  /// commit. Until then, the existing 90-degree rotation behavior remains
  /// unchanged.
  int get rotationQuarterTurns {
    final turns = (normalizedRotationDegrees / quarterTurnDegrees).round();

    return ((turns % 4) + 4) % 4;
  }

  ImageTransform copyWith({
    double? rotationDegrees,
    bool? flipHorizontal,
    bool? flipVertical,
  }) {
    return ImageTransform(
      rotationDegrees: _normalizeDegrees(
        rotationDegrees ?? this.rotationDegrees,
      ),
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
    );
  }

  ImageTransform rotateClockwise() {
    return rotateBy(quarterTurnDegrees);
  }

  ImageTransform rotateCounterClockwise() {
    return rotateBy(-quarterTurnDegrees);
  }

  ImageTransform rotateBy(double degrees) {
    return copyWith(rotationDegrees: normalizedRotationDegrees + degrees);
  }

  ImageTransform toggleFlipHorizontal() {
    return copyWith(flipHorizontal: !flipHorizontal);
  }

  ImageTransform toggleFlipVertical() {
    return copyWith(flipVertical: !flipVertical);
  }

  static double _normalizeDegrees(double degrees) {
    if (!degrees.isFinite) {
      return 0.0;
    }

    var normalized = degrees.remainder(fullRotationDegrees);

    if (normalized > 180.0) {
      normalized -= fullRotationDegrees;
    } else if (normalized < -180.0) {
      normalized += fullRotationDegrees;
    }

    if (normalized == 0.0) {
      return 0.0;
    }

    return normalized;
  }
}
