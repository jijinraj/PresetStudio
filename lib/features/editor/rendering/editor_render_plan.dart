import '../domain/image_adjustments.dart';
import '../domain/image_transform.dart';
import 'tone_curve_lut.dart';

class EditorRenderPlan {
  const EditorRenderPlan({
    required this.adjustments,
    required this.transform,
    required this.colorMatrix,
    required this.toneCurveLut,
  });

  final ImageAdjustments adjustments;
  final ImageTransform transform;
  final ToneCurveLut toneCurveLut;

  /// Flutter-compatible fallback matrix for the linear adjustment stage.
  ///
  /// Exposure, contrast, temperature, tint, saturation, and a restrained
  /// vibrance approximation can be represented here. Luminance-dependent tonal
  /// controls such as highlights, shadows, whites, and blacks, plus the fully
  /// selective vibrance curve, are evaluated by the GPU tonal shader when
  /// shader filters are available.
  final List<double> colorMatrix;
}
