import 'dart:math' as math;

import '../domain/crop_state.dart';
import '../domain/export_render_plan.dart';
import '../domain/export_settings.dart';
import '../domain/image_transform.dart';

class ExportRenderPlanner {
  const ExportRenderPlanner();

  ExportRenderPlan buildPlan({
    required int sourceWidth,
    required int sourceHeight,
    required CropState crop,
    required ImageTransform transform,
    required ExportSettings settings,
  }) {
    if (sourceWidth <= 0 || sourceHeight <= 0) {
      throw ArgumentError('Source dimensions must be greater than zero.');
    }

    final sanitizedCrop = crop.sanitized();
    final sanitizedSettings = settings.sanitized();

    final fullResolutionSize = sanitizedCrop.isDefault
        ? _rotatedSourceBounds(
            sourceWidth: sourceWidth,
            sourceHeight: sourceHeight,
            rotationDegrees: transform.normalizedRotationDegrees,
          )
        : _cropFrameSize(
            sourceWidth: sourceWidth,
            sourceHeight: sourceHeight,
            crop: sanitizedCrop,
          );

    final outputSize = _applyResolutionLimit(
      width: fullResolutionSize.$1,
      height: fullResolutionSize.$2,
      settings: sanitizedSettings,
    );

    return ExportRenderPlan(
      format: sanitizedSettings.format,
      quality: sanitizedSettings.quality,
      fullResolutionWidth: fullResolutionSize.$1,
      fullResolutionHeight: fullResolutionSize.$2,
      outputWidth: outputSize.$1,
      outputHeight: outputSize.$2,
    );
  }

  (int, int) _cropFrameSize({
    required int sourceWidth,
    required int sourceHeight,
    required CropState crop,
  }) {
    final rect = crop.normalizedRect.sanitized();

    final width = math.max(1, (sourceWidth * rect.width).round());
    final height = math.max(1, (sourceHeight * rect.height).round());

    return (width, height);
  }

  (int, int) _rotatedSourceBounds({
    required int sourceWidth,
    required int sourceHeight,
    required double rotationDegrees,
  }) {
    final radians = rotationDegrees * math.pi / 180.0;
    final cosine = math.cos(radians).abs();
    final sine = math.sin(radians).abs();

    final width = math.max(
      1,
      ((sourceWidth * cosine) + (sourceHeight * sine)).round(),
    );

    final height = math.max(
      1,
      ((sourceWidth * sine) + (sourceHeight * cosine)).round(),
    );

    return (width, height);
  }

  (int, int) _applyResolutionLimit({
    required int width,
    required int height,
    required ExportSettings settings,
  }) {
    if (settings.resolutionMode == ExportResolutionMode.original) {
      return (width, height);
    }

    final longestEdge = math.max(width, height);

    if (longestEdge <= settings.maxDimension) {
      return (width, height);
    }

    final scale = settings.maxDimension / longestEdge;

    return (
      math.max(1, (width * scale).round()),
      math.max(1, (height * scale).round()),
    );
  }
}
