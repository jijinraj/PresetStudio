import 'dart:math' as math;

import '../domain/image_adjustments.dart';
import '../domain/image_transform.dart';
import 'editor_render_plan.dart';

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
  }) {
    final sanitizedAdjustments = adjustments.sanitized();

    final exposureMatrix = _buildExposureMatrix(sanitizedAdjustments.exposure);

    final contrastMatrix = _buildContrastMatrix(sanitizedAdjustments.contrast);

    final saturationMatrix = _buildSaturationMatrix(
      sanitizedAdjustments.saturation,
    );

    final exposureAndContrast = _multiplyColorMatrices(
      contrastMatrix,
      exposureMatrix,
    );

    final colorMatrix = _multiplyColorMatrices(
      saturationMatrix,
      exposureAndContrast,
    );

    return EditorRenderPlan(
      adjustments: sanitizedAdjustments,
      transform: transform,
      colorMatrix: colorMatrix,
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
