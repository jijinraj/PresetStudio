import '../../editor/domain/image_adjustments.dart';
import '../domain/preset_adjustment_values.dart';

class PresetAdjustmentMapper {
  const PresetAdjustmentMapper._();

  static PresetAdjustmentValues fromImageAdjustments(
    ImageAdjustments adjustments,
  ) {
    final sanitized = adjustments.sanitized();

    return PresetAdjustmentValues(
      exposure: sanitized.exposure,
      contrast: sanitized.contrast,
      highlights: sanitized.highlights,
      shadows: sanitized.shadows,
      whites: sanitized.whites,
      blacks: sanitized.blacks,
      temperature: sanitized.temperature,
      tint: sanitized.tint,
      vibrance: sanitized.vibrance,
      saturation: sanitized.saturation,
      vignetteAmount: sanitized.vignetteAmount,
      vignetteFeather: sanitized.vignetteFeather,
    );
  }

  static ImageAdjustments toImageAdjustments(PresetAdjustmentValues values) {
    return ImageAdjustments(
      exposure: values.exposure,
      contrast: values.contrast,
      highlights: values.highlights,
      shadows: values.shadows,
      whites: values.whites,
      blacks: values.blacks,
      temperature: values.temperature,
      tint: values.tint,
      vibrance: values.vibrance,
      saturation: values.saturation,
      vignetteAmount: values.vignetteAmount,
      vignetteFeather: values.vignetteFeather,
    ).sanitized();
  }
}
