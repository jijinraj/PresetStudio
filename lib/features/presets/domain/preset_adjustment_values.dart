class PresetAdjustmentValues {
  const PresetAdjustmentValues({
    this.exposure = 0,
    this.contrast = 0,
    this.highlights = 0,
    this.shadows = 0,
    this.whites = 0,
    this.blacks = 0,
    this.temperature = 0,
    this.tint = 0,
    this.vibrance = 0,
    this.saturation = 0,
  });

  final double exposure;
  final double contrast;
  final double highlights;
  final double shadows;
  final double whites;
  final double blacks;
  final double temperature;
  final double tint;
  final double vibrance;
  final double saturation;

  static const PresetAdjustmentValues initial = PresetAdjustmentValues();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PresetAdjustmentValues &&
            exposure == other.exposure &&
            contrast == other.contrast &&
            highlights == other.highlights &&
            shadows == other.shadows &&
            whites == other.whites &&
            blacks == other.blacks &&
            temperature == other.temperature &&
            tint == other.tint &&
            vibrance == other.vibrance &&
            saturation == other.saturation;
  }

  @override
  int get hashCode => Object.hash(
    exposure,
    contrast,
    highlights,
    shadows,
    whites,
    blacks,
    temperature,
    tint,
    vibrance,
    saturation,
  );
}
