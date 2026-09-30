import '../../editor/domain/curve_point.dart';
import '../../editor/domain/image_adjustments.dart';
import '../../editor/domain/tone_curves.dart';
import '../domain/preset_adjustment_values.dart';
import '../domain/preset_tone_curve_values.dart';

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

  static PresetToneCurvesValues fromToneCurves(ToneCurves curves) {
    return PresetToneCurvesValues(
      master: _fromToneCurve(curves.master),
      red: _fromToneCurve(curves.red),
      green: _fromToneCurve(curves.green),
      blue: _fromToneCurve(curves.blue),
    );
  }

  static ToneCurves toToneCurves(PresetToneCurvesValues values) {
    return ToneCurves(
      master: _toToneCurve(values.master),
      red: _toToneCurve(values.red),
      green: _toToneCurve(values.green),
      blue: _toToneCurve(values.blue),
    );
  }

  static PresetToneCurveValues _fromToneCurve(ToneCurve curve) {
    return PresetToneCurveValues(
      points: curve.points.map(
        (point) =>
            PresetCurvePointValues(input: point.input, output: point.output),
      ),
    );
  }

  static ToneCurve _toToneCurve(PresetToneCurveValues curve) {
    return ToneCurve(
      points: curve.points.map(
        (point) => CurvePoint(input: point.input, output: point.output),
      ),
    );
  }
}
