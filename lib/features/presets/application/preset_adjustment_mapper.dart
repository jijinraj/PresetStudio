import '../../editor/domain/curve_point.dart';
import '../../editor/domain/hsl_color_mixer.dart';
import '../../editor/domain/image_adjustments.dart';
import '../../editor/domain/tone_curves.dart';
import '../domain/preset_adjustment_values.dart';
import '../domain/preset_hsl_color_mixer_values.dart';
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

  static PresetHslColorMixerValues fromHslColorMixer(HslColorMixer mixer) {
    return PresetHslColorMixerValues(
      red: _fromHslAdjustment(mixer.red),
      orange: _fromHslAdjustment(mixer.orange),
      yellow: _fromHslAdjustment(mixer.yellow),
      green: _fromHslAdjustment(mixer.green),
      aqua: _fromHslAdjustment(mixer.aqua),
      blue: _fromHslAdjustment(mixer.blue),
      purple: _fromHslAdjustment(mixer.purple),
      magenta: _fromHslAdjustment(mixer.magenta),
    );
  }

  static HslColorMixer toHslColorMixer(PresetHslColorMixerValues values) {
    return HslColorMixer(
      red: _toHslAdjustment(values.red),
      orange: _toHslAdjustment(values.orange),
      yellow: _toHslAdjustment(values.yellow),
      green: _toHslAdjustment(values.green),
      aqua: _toHslAdjustment(values.aqua),
      blue: _toHslAdjustment(values.blue),
      purple: _toHslAdjustment(values.purple),
      magenta: _toHslAdjustment(values.magenta),
    );
  }

  static PresetHslColorAdjustmentValues _fromHslAdjustment(
    HslColorAdjustment adjustment,
  ) {
    return PresetHslColorAdjustmentValues(
      hue: adjustment.hue,
      saturation: adjustment.saturation,
      luminance: adjustment.luminance,
    );
  }

  static HslColorAdjustment _toHslAdjustment(
    PresetHslColorAdjustmentValues values,
  ) {
    return HslColorAdjustment(
      hue: values.hue,
      saturation: values.saturation,
      luminance: values.luminance,
    );
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
