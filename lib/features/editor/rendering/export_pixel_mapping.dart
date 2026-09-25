import 'dart:math' as math;

import '../domain/crop_state.dart';
import '../domain/export_render_plan.dart';
import '../domain/image_transform.dart';

/// Maps output pixel centers back into original-source pixel coordinates.
///
/// This mirrors the committed crop composition order used by the editor:
/// source -> flip -> cover/zoom scale -> rotation/straighten -> translation.
class ExportPixelMapping {
  const ExportPixelMapping._({
    required this.sourceWidth,
    required this.sourceHeight,
    required this.fullWidth,
    required this.fullHeight,
    required this.outputWidth,
    required this.outputHeight,
    required this.radians,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.translationX,
    required this.translationY,
    required this.visualScale,
    required this.containedWidth,
    required this.containedHeight,
  });

  factory ExportPixelMapping.build({
    required int sourceWidth,
    required int sourceHeight,
    required ExportRenderPlan plan,
    required CropState crop,
    required ImageTransform transform,
  }) {
    if (crop.isDefault) {
      return ExportPixelMapping._(
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        fullWidth: plan.fullResolutionWidth.toDouble(),
        fullHeight: plan.fullResolutionHeight.toDouble(),
        outputWidth: plan.outputWidth,
        outputHeight: plan.outputHeight,
        radians: transform.normalizedRotationDegrees * math.pi / 180.0,
        flipHorizontal: transform.flipHorizontal,
        flipVertical: transform.flipVertical,
        translationX: 0.0,
        translationY: 0.0,
        visualScale: 1.0,
        containedWidth: sourceWidth.toDouble(),
        containedHeight: sourceHeight.toDouble(),
      );
    }

    final fullWidth = plan.fullResolutionWidth.toDouble();
    final fullHeight = plan.fullResolutionHeight.toDouble();
    final sourceAspectRatio = sourceWidth / sourceHeight;
    final frameAspectRatio = fullWidth / fullHeight;

    final containedWidth = sourceAspectRatio >= frameAspectRatio
        ? fullWidth
        : fullHeight * sourceAspectRatio;
    final containedHeight = sourceAspectRatio >= frameAspectRatio
        ? fullWidth / sourceAspectRatio
        : fullHeight;

    final radians =
        (transform.normalizedRotationDegrees + crop.straightenDegrees) *
        math.pi /
        180.0;

    final cosine = math.cos(radians);
    final sine = math.sin(radians);

    final requiredLocalHalfWidth =
        ((cosine.abs() * fullWidth) + (sine.abs() * fullHeight)) / 2.0;
    final requiredLocalHalfHeight =
        ((sine.abs() * fullWidth) + (cosine.abs() * fullHeight)) / 2.0;

    final widthScale = (requiredLocalHalfWidth * 2.0) / containedWidth;
    final heightScale = (requiredLocalHalfHeight * 2.0) / containedHeight;
    final minimumCoverScale = math.max(1.0, math.max(widthScale, heightScale));
    final visualScale = crop.scale * minimumCoverScale;

    final requestedTranslationX = crop.offset.dx * fullWidth;
    final requestedTranslationY = crop.offset.dy * fullHeight;

    final imageHalfWidth = containedWidth * visualScale / 2.0;
    final imageHalfHeight = containedHeight * visualScale / 2.0;

    final horizontalSlack = math.max(
      0.0,
      imageHalfWidth - requiredLocalHalfWidth,
    );
    final verticalSlack = math.max(
      0.0,
      imageHalfHeight - requiredLocalHalfHeight,
    );

    final requestedLocalX =
        (requestedTranslationX * cosine) + (requestedTranslationY * sine);
    final requestedLocalY =
        (-requestedTranslationX * sine) + (requestedTranslationY * cosine);

    final clampedLocalX = requestedLocalX
        .clamp(-horizontalSlack, horizontalSlack)
        .toDouble();
    final clampedLocalY = requestedLocalY
        .clamp(-verticalSlack, verticalSlack)
        .toDouble();

    return ExportPixelMapping._(
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      fullWidth: fullWidth,
      fullHeight: fullHeight,
      outputWidth: plan.outputWidth,
      outputHeight: plan.outputHeight,
      radians: radians,
      flipHorizontal: transform.flipHorizontal,
      flipVertical: transform.flipVertical,
      translationX: (cosine * clampedLocalX) - (sine * clampedLocalY),
      translationY: (sine * clampedLocalX) + (cosine * clampedLocalY),
      visualScale: visualScale,
      containedWidth: containedWidth,
      containedHeight: containedHeight,
    );
  }

  final int sourceWidth;
  final int sourceHeight;
  final double fullWidth;
  final double fullHeight;
  final int outputWidth;
  final int outputHeight;
  final double radians;
  final bool flipHorizontal;
  final bool flipVertical;
  final double translationX;
  final double translationY;
  final double visualScale;
  final double containedWidth;
  final double containedHeight;

  (double, double) sourcePointForOutputPixel(int x, int y) {
    final frameX = ((x + 0.5) * fullWidth / outputWidth) - (fullWidth / 2.0);
    final frameY = ((y + 0.5) * fullHeight / outputHeight) - (fullHeight / 2.0);

    final translatedX = frameX - translationX;
    final translatedY = frameY - translationY;

    final cosine = math.cos(radians);
    final sine = math.sin(radians);

    // Invert rotation, then scale, then the inner image flips.
    var localX = (translatedX * cosine) + (translatedY * sine);
    var localY = (-translatedX * sine) + (translatedY * cosine);

    localX /= visualScale;
    localY /= visualScale;

    if (flipHorizontal) {
      localX = -localX;
    }

    if (flipVertical) {
      localY = -localY;
    }

    final sourceX =
        ((localX + (containedWidth / 2.0)) / containedWidth) * sourceWidth -
        0.5;
    final sourceY =
        ((localY + (containedHeight / 2.0)) / containedHeight) * sourceHeight -
        0.5;

    return (sourceX, sourceY);
  }
}
