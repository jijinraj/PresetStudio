import '../domain/image_adjustments.dart';
import '../domain/image_transform.dart';

class EditorRenderPlan {
  const EditorRenderPlan({
    required this.adjustments,
    required this.transform,
    required this.colorMatrix,
  });

  final ImageAdjustments adjustments;
  final ImageTransform transform;

  /// A Flutter-compatible 4x5 color matrix derived from the
  /// supported non-destructive color adjustments.
  final List<double> colorMatrix;
}
