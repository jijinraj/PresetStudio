import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/editor_session.dart';
import '../domain/export_render_plan.dart';
import '../domain/export_render_result.dart';
import '../domain/export_settings.dart';
import 'export_pixel_mapping.dart';
import 'export_render_planner.dart';
import 'export_tonal_processor.dart';

class ExportImageRenderException implements Exception {
  const ExportImageRenderException(this.message);

  final String message;

  @override
  String toString() => 'ExportImageRenderException: $message';
}

/// CPU full-resolution export renderer.
///
/// Export always starts again from the original encoded source bytes instead
/// of capturing/upscaling the editor preview. EXIF orientation is baked first,
/// then the current non-destructive edit state is replayed at the planner's
/// target dimensions before JPEG, PNG, or WebP encoding.
///
/// Export v1 is intentionally an 8-bit RGB(A) pipeline. Higher-bit-depth and
/// color-managed output can be added later without changing the session model.
class ExportImageRenderer {
  const ExportImageRenderer({this.planner = const ExportRenderPlanner()});

  final ExportRenderPlanner planner;

  ExportRenderResult render({
    required Uint8List sourceBytes,
    required EditorSession session,
  }) {
    img.Image? decoded;

    try {
      decoded = img.decodeImage(sourceBytes);
    } on Object {
      throw const ExportImageRenderException(
        'The source image could not be decoded.',
      );
    }

    if (decoded == null) {
      throw const ExportImageRenderException(
        'The source image could not be decoded.',
      );
    }

    final source = img.bakeOrientation(decoded);
    final crop = session.crop.sanitized();
    final adjustments = session.adjustments.sanitized();
    final settings = session.exportSettings.sanitized();

    final plan = planner.buildPlan(
      sourceWidth: source.width,
      sourceHeight: source.height,
      crop: crop,
      transform: session.transform,
      settings: settings,
    );

    final mapping = ExportPixelMapping.build(
      sourceWidth: source.width,
      sourceHeight: source.height,
      plan: plan,
      crop: crop,
      transform: session.transform,
    );

    final processor = ExportTonalProcessor(
      adjustments,
      toneCurves: session.effectiveToneCurves,
      hslColorMixer: session.hslColorMixer,
    );
    final raster = img.Image(
      width: plan.outputWidth,
      height: plan.outputHeight,
      numChannels: 4,
    );

    for (var y = 0; y < raster.height; y += 1) {
      for (var x = 0; x < raster.width; x += 1) {
        final sourcePoint = mapping.sourcePointForOutputPixel(x, y);

        if (!_isInsideSource(
          sourcePoint,
          sourceWidth: source.width,
          sourceHeight: source.height,
        )) {
          raster.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }

        final sampleX = sourcePoint.$1
            .clamp(0.0, math.max(0, source.width - 1).toDouble())
            .toDouble();
        final sampleY = sourcePoint.$2
            .clamp(0.0, math.max(0, source.height - 1).toDouble())
            .toDouble();

        final sampled = source.getPixelLinear(sampleX, sampleY);
        final alpha = sampled.aNormalized.toDouble();

        if (alpha <= 0.0) {
          raster.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }

        final adjusted = processor.apply(
          sampled.rNormalized.toDouble(),
          sampled.gNormalized.toDouble(),
          sampled.bNormalized.toDouble(),
          normalizedX: raster.width <= 1 ? 0.5 : x / (raster.width - 1),
          normalizedY: raster.height <= 1 ? 0.5 : y / (raster.height - 1),
          aspectRatio: raster.width / raster.height,
        );

        raster.setPixelRgba(
          x,
          y,
          _toByte(adjusted.$1),
          _toByte(adjusted.$2),
          _toByte(adjusted.$3),
          _toByte(alpha),
        );
      }
    }

    return ExportRenderResult(bytes: _encode(raster, plan), plan: plan);
  }

  static bool _isInsideSource(
    (double, double) point, {
    required int sourceWidth,
    required int sourceHeight,
  }) {
    // Pixel centers occupy -0.5 .. dimension-0.5 in the continuous plane.
    return point.$1 >= -0.5 &&
        point.$1 <= sourceWidth - 0.5 &&
        point.$2 >= -0.5 &&
        point.$2 <= sourceHeight - 0.5;
  }

  static Uint8List _encode(img.Image raster, ExportRenderPlan plan) {
    return switch (plan.format) {
      ExportFormat.jpeg => img.encodeJpg(raster, quality: plan.quality),
      ExportFormat.png => img.encodePng(raster),
      ExportFormat.webp => img.encodeWebP(
        raster,
        lossless: false,
        quality: plan.quality,
      ),
    };
  }

  static int _toByte(double value) {
    return (value.clamp(0.0, 1.0) * 255.0).round();
  }
}
