import 'dart:math' as math;

import '../domain/image_adjustments.dart';
import 'editor_render_plan.dart';

class EditorRenderPipeline {
  const EditorRenderPipeline();

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

  EditorRenderPlan buildPlan(ImageAdjustments adjustments) {
    final sanitizedAdjustments = adjustments.sanitized();

    return EditorRenderPlan(
      adjustments: sanitizedAdjustments,
      colorMatrix: _buildExposureMatrix(sanitizedAdjustments.exposure),
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
}
