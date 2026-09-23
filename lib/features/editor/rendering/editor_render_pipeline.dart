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
      colorMatrix: identityColorMatrix,
    );
  }
}
