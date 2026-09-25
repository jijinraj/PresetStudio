import 'crop_state.dart';

enum CropResizeHandle { topLeft, topRight, bottomLeft, bottomRight }

/// Pure geometry for aspect-ratio-locked crop resizing.
///
/// The rectangle lives in normalized source coordinates. Because those
/// coordinates are already mapped through the source image's aspect ratio by
/// the workspace, preserving the starting normalized width/height ratio keeps
/// the selected crop ratio locked while a corner moves.
class CropResizeGeometry {
  const CropResizeGeometry._();

  static NormalizedCropRect resize({
    required NormalizedCropRect startRect,
    required CropResizeHandle handle,
    required double deltaX,
    required double deltaY,
    required double minimumWidth,
    required double minimumHeight,
  }) {
    final rect = startRect.sanitized();

    if (rect.width <= 0 || rect.height <= 0) {
      return rect;
    }

    final normalizedAspectRatio = rect.width / rect.height;

    if (!normalizedAspectRatio.isFinite || normalizedAspectRatio <= 0) {
      return rect;
    }

    final isLeft =
        handle == CropResizeHandle.topLeft ||
        handle == CropResizeHandle.bottomLeft;

    final isTop =
        handle == CropResizeHandle.topLeft ||
        handle == CropResizeHandle.topRight;

    final anchorX = isLeft ? rect.right : rect.left;
    final anchorY = isTop ? rect.bottom : rect.top;
    final startCornerX = isLeft ? rect.left : rect.right;
    final startCornerY = isTop ? rect.top : rect.bottom;

    final directionX = isLeft ? -1.0 : 1.0;
    final directionY = isTop ? -1.0 : 1.0;

    final targetX = startCornerX + deltaX;
    final targetY = startCornerY + deltaY;

    // Convert the pointer target into positive width/height distances measured
    // away from the fixed opposite corner.
    final desiredWidth = directionX * (targetX - anchorX);
    final desiredHeight = directionY * (targetY - anchorY);

    // Project the pointer onto the aspect-ratio ray instead of privileging only
    // horizontal or vertical movement. This keeps diagonal corner drags smooth
    // while preserving the exact starting ratio.
    final ratioSquared = normalizedAspectRatio * normalizedAspectRatio;
    var height =
        ((desiredWidth * normalizedAspectRatio) + desiredHeight) /
        (ratioSquared + 1);

    final maxWidth = isLeft ? anchorX : 1 - anchorX;
    final maxHeight = isTop ? anchorY : 1 - anchorY;
    final maximumHeight = _minimum(maxHeight, maxWidth / normalizedAspectRatio);

    if (!maximumHeight.isFinite || maximumHeight <= 0) {
      return rect;
    }

    final requestedMinimumHeight = _maximum(
      minimumHeight,
      minimumWidth / normalizedAspectRatio,
    );

    final effectiveMinimumHeight = _minimum(
      requestedMinimumHeight,
      maximumHeight,
    );

    height = height.clamp(effectiveMinimumHeight, maximumHeight).toDouble();

    final width = height * normalizedAspectRatio;

    final left = isLeft ? anchorX - width : anchorX;
    final right = isLeft ? anchorX : anchorX + width;
    final top = isTop ? anchorY - height : anchorY;
    final bottom = isTop ? anchorY : anchorY + height;

    return NormalizedCropRect(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    ).sanitized();
  }

  static double _minimum(double a, double b) => a < b ? a : b;

  static double _maximum(double a, double b) => a > b ? a : b;
}
