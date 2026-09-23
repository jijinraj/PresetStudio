class CropState {
  const CropState({this.aspectRatio});

  final double? aspectRatio;

  static const CropState initial = CropState();

  CropState copyWith({double? aspectRatio, bool clearAspectRatio = false}) {
    return CropState(
      aspectRatio: clearAspectRatio ? null : aspectRatio ?? this.aspectRatio,
    );
  }
}
