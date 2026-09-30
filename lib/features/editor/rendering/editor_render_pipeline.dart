import 'dart:math' as math;

import '../domain/hsl_color_mixer.dart';
import '../domain/image_adjustments.dart';
import '../domain/image_transform.dart';
import '../domain/tone_curves.dart';
import 'editor_render_plan.dart';
import 'tone_curve_lut.dart';

class EditorRenderPipeline {
  const EditorRenderPipeline();

  static const double _contrastPivot = 127.5;

  static const double _redLuminance = 0.2126;
  static const double _greenLuminance = 0.7152;
  static const double _blueLuminance = 0.0722;

  static const List<double> identityColorMatrix = <double>[
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
  ];

  EditorRenderPlan buildPlan(
    ImageAdjustments adjustments, {
    ImageTransform transform = ImageTransform.initial,
    ToneCurves? toneCurves,
    HslColorMixer hslColorMixer = HslColorMixer.initial,
  }) {
    final sanitizedAdjustments = adjustments.sanitized();
    final curveLut = ToneCurveLut.fromToneCurves(
      toneCurves ?? ToneCurves.initial,
    );

    final exposureMatrix = _buildExposureMatrix(sanitizedAdjustments.exposure);

    final contrastMatrix = _buildContrastMatrix(sanitizedAdjustments.contrast);

    final colorBalanceMatrix = _buildColorBalanceMatrix(
      sanitizedAdjustments.temperature,
      sanitizedAdjustments.tint,
    );

    final vibranceMatrix = _buildVibranceFallbackMatrix(
      sanitizedAdjustments.vibrance,
    );

    final saturationMatrix = _buildSaturationMatrix(
      sanitizedAdjustments.saturation,
    );

    final exposureAndContrast = _multiplyColorMatrices(
      contrastMatrix,
      exposureMatrix,
    );

    final withColorBalance = _multiplyColorMatrices(
      colorBalanceMatrix,
      exposureAndContrast,
    );

    final withVibrance = _multiplyColorMatrices(
      vibranceMatrix,
      withColorBalance,
    );

    final colorMatrix = _multiplyColorMatrices(saturationMatrix, withVibrance);

    return EditorRenderPlan(
      adjustments: sanitizedAdjustments,
      transform: transform,
      colorMatrix: colorMatrix,
      toneCurveLut: curveLut,
      hslColorMixer: hslColorMixer,
    );
  }

  List<double> _buildExposureMatrix(double exposure) {
    if (exposure == 0.0) {
      return identityColorMatrix;
    }

    final exposureMultiplier = math.pow(2.0, exposure).toDouble();

    return <double>[
      exposureMultiplier,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      exposureMultiplier,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      exposureMultiplier,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];
  }

  List<double> _buildContrastMatrix(double contrast) {
    if (contrast == 0.0) {
      return identityColorMatrix;
    }

    final normalizedContrast = contrast / 100.0;
    final contrastFactor = 1.0 + normalizedContrast;

    final offset = _contrastPivot * (1.0 - contrastFactor);

    return <double>[
      contrastFactor,
      0.0,
      0.0,
      0.0,
      offset,
      0.0,
      contrastFactor,
      0.0,
      0.0,
      offset,
      0.0,
      0.0,
      contrastFactor,
      0.0,
      offset,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];
  }

  List<double> _buildColorBalanceMatrix(double temperature, double tint) {
    if (temperature == 0.0 && tint == 0.0) {
      return identityColorMatrix;
    }

    final normalizedTemperature = temperature / 100.0;
    final normalizedTint = tint / 100.0;

    final redFactor =
        1.0 + (normalizedTemperature * 0.12) + (normalizedTint * 0.05);
    final greenFactor =
        1.0 + (normalizedTemperature * 0.02) - (normalizedTint * 0.08);
    final blueFactor =
        1.0 - (normalizedTemperature * 0.12) + (normalizedTint * 0.05);

    return <double>[
      redFactor,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      greenFactor,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      blueFactor,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];
  }

  List<double> _buildVibranceFallbackMatrix(double vibrance) {
    if (vibrance == 0.0) {
      return identityColorMatrix;
    }

    // A color matrix cannot reproduce PresetStudio's selective GPU vibrance
    // curve because that curve depends on each pixel's existing chroma. Keep
    // the fallback deliberately restrained so unsupported shader platforms
    // still receive a useful approximation without turning Vibrance into a
    // second full-strength Saturation control.
    final fallbackSaturation = vibrance * 0.6;

    return _buildSaturationMatrix(fallbackSaturation);
  }

  List<double> _buildSaturationMatrix(double saturation) {
    if (saturation == 0.0) {
      return identityColorMatrix;
    }

    final normalizedSaturation = saturation / 100.0;
    final saturationFactor = 1.0 + normalizedSaturation;
    final inverseSaturation = 1.0 - saturationFactor;

    final redContribution = inverseSaturation * _redLuminance;
    final greenContribution = inverseSaturation * _greenLuminance;
    final blueContribution = inverseSaturation * _blueLuminance;

    return <double>[
      redContribution + saturationFactor,
      greenContribution,
      blueContribution,
      0.0,
      0.0,
      redContribution,
      greenContribution + saturationFactor,
      blueContribution,
      0.0,
      0.0,
      redContribution,
      greenContribution,
      blueContribution + saturationFactor,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];
  }

  List<double> _multiplyColorMatrices(List<double> left, List<double> right) {
    assert(left.length == 20);
    assert(right.length == 20);

    final result = List<double>.filled(20, 0.0, growable: false);

    for (var row = 0; row < 4; row++) {
      final rowOffset = row * 5;

      for (var column = 0; column < 4; column++) {
        var value = 0.0;

        for (var index = 0; index < 4; index++) {
          value += left[rowOffset + index] * right[(index * 5) + column];
        }

        result[rowOffset + column] = value;
      }

      var offset = left[rowOffset + 4];

      for (var index = 0; index < 4; index++) {
        offset += left[rowOffset + index] * right[(index * 5) + 4];
      }

      result[rowOffset + 4] = offset;
    }

    return result;
  }
}
