class CropState {
  const CropState({
    this.aspectRatio,
    this.rotationQuarterTurns = 0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  final double? aspectRatio;
  final int rotationQuarterTurns;
  final bool flipHorizontal;
  final bool flipVertical;

  static const CropState initial = CropState();

  CropState copyWith({
    double? aspectRatio,
    bool clearAspectRatio = false,
    int? rotationQuarterTurns,
    bool? flipHorizontal,
    bool? flipVertical,
  }) {
    return CropState(
      aspectRatio: clearAspectRatio ? null : aspectRatio ?? this.aspectRatio,
      rotationQuarterTurns: rotationQuarterTurns ?? this.rotationQuarterTurns,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
    );
  }
}
