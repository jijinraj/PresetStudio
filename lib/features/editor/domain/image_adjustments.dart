import 'adjustment_definition.dart';
import 'adjustment_type.dart';

class ImageAdjustments {
  const ImageAdjustments({
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
    this.vignetteAmount = 0,
    this.vignetteFeather = 50,
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
  final double vignetteAmount;
  final double vignetteFeather;

  static const ImageAdjustments initial = ImageAdjustments();

  bool get isDefault {
    return AdjustmentType.values.every((type) {
      final definition = AdjustmentDefinitions.of(type);

      return valueFor(type) == definition.defaultValue;
    });
  }

  double valueFor(AdjustmentType type) {
    return switch (type) {
      AdjustmentType.exposure => exposure,
      AdjustmentType.contrast => contrast,
      AdjustmentType.highlights => highlights,
      AdjustmentType.shadows => shadows,
      AdjustmentType.whites => whites,
      AdjustmentType.blacks => blacks,
      AdjustmentType.temperature => temperature,
      AdjustmentType.tint => tint,
      AdjustmentType.vibrance => vibrance,
      AdjustmentType.saturation => saturation,
      AdjustmentType.vignetteAmount => vignetteAmount,
      AdjustmentType.vignetteFeather => vignetteFeather,
    };
  }

  double normalizedValueFor(AdjustmentType type) {
    final definition = AdjustmentDefinitions.of(type);

    return definition.normalize(valueFor(type));
  }

  ImageAdjustments withValue(AdjustmentType type, double value) {
    final sanitizedValue = AdjustmentDefinitions.of(type).sanitize(value);

    return switch (type) {
      AdjustmentType.exposure => copyWith(exposure: sanitizedValue),
      AdjustmentType.contrast => copyWith(contrast: sanitizedValue),
      AdjustmentType.highlights => copyWith(highlights: sanitizedValue),
      AdjustmentType.shadows => copyWith(shadows: sanitizedValue),
      AdjustmentType.whites => copyWith(whites: sanitizedValue),
      AdjustmentType.blacks => copyWith(blacks: sanitizedValue),
      AdjustmentType.temperature => copyWith(temperature: sanitizedValue),
      AdjustmentType.tint => copyWith(tint: sanitizedValue),
      AdjustmentType.vibrance => copyWith(vibrance: sanitizedValue),
      AdjustmentType.saturation => copyWith(saturation: sanitizedValue),
      AdjustmentType.vignetteAmount => copyWith(vignetteAmount: sanitizedValue),
      AdjustmentType.vignetteFeather => copyWith(
        vignetteFeather: sanitizedValue,
      ),
    };
  }

  ImageAdjustments sanitized() {
    var result = this;

    for (final type in AdjustmentType.values) {
      result = result.withValue(type, result.valueFor(type));
    }

    return result;
  }

  ImageAdjustments copyWith({
    double? exposure,
    double? contrast,
    double? highlights,
    double? shadows,
    double? whites,
    double? blacks,
    double? temperature,
    double? tint,
    double? vibrance,
    double? saturation,
    double? vignetteAmount,
    double? vignetteFeather,
  }) {
    return ImageAdjustments(
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      whites: whites ?? this.whites,
      blacks: blacks ?? this.blacks,
      temperature: temperature ?? this.temperature,
      tint: tint ?? this.tint,
      vibrance: vibrance ?? this.vibrance,
      saturation: saturation ?? this.saturation,
      vignetteAmount: vignetteAmount ?? this.vignetteAmount,
      vignetteFeather: vignetteFeather ?? this.vignetteFeather,
    );
  }
}
