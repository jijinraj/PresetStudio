import '../domain/image_adjustments.dart';

class EditorRenderPlan {
  const EditorRenderPlan({
    required this.adjustments,
    required this.colorMatrix,
  });

  final ImageAdjustments adjustments;

  /// A Flutter-compatible 4x5 color matrix.
  ///
  /// The matrix is currently identity-only. Future rendering stages
  /// will derive this matrix from supported non-destructive adjustments.
  final List<double> colorMatrix;
}
