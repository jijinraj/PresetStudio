class ImageTransform {
  const ImageTransform({
    this.rotationQuarterTurns = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  final int rotationQuarterTurns;
  final bool flipHorizontal;
  final bool flipVertical;

  static const ImageTransform initial = ImageTransform();

  bool get isDefault =>
      rotationQuarterTurns == 0 && !flipHorizontal && !flipVertical;

  ImageTransform copyWith({
    int? rotationQuarterTurns,
    bool? flipHorizontal,
    bool? flipVertical,
  }) {
    return ImageTransform(
      rotationQuarterTurns: _normalizeQuarterTurns(
        rotationQuarterTurns ?? this.rotationQuarterTurns,
      ),
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
    );
  }

  ImageTransform rotateClockwise() {
    return copyWith(rotationQuarterTurns: rotationQuarterTurns + 1);
  }

  ImageTransform rotateCounterClockwise() {
    return copyWith(rotationQuarterTurns: rotationQuarterTurns - 1);
  }

  ImageTransform toggleFlipHorizontal() {
    return copyWith(flipHorizontal: !flipHorizontal);
  }

  ImageTransform toggleFlipVertical() {
    return copyWith(flipVertical: !flipVertical);
  }

  static int _normalizeQuarterTurns(int quarterTurns) {
    return ((quarterTurns % 4) + 4) % 4;
  }
}
