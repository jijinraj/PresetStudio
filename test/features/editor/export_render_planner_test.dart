import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/crop_state.dart';
import 'package:presetstudio/features/editor/domain/export_settings.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
import 'package:presetstudio/features/editor/rendering/export_render_planner.dart';

void main() {
  const planner = ExportRenderPlanner();

  test('keeps original source dimensions for an untouched image', () {
    final plan = planner.buildPlan(
      sourceWidth: 6000,
      sourceHeight: 4000,
      crop: CropState.initial,
      transform: ImageTransform.initial,
      settings: ExportSettings.initial,
    );

    expect(plan.fullResolutionWidth, 6000);
    expect(plan.fullResolutionHeight, 4000);
    expect(plan.outputWidth, 6000);
    expect(plan.outputHeight, 4000);
    expect(plan.isDownscaled, isFalse);
  });

  test('uses rotated source bounds when crop composition is untouched', () {
    final plan = planner.buildPlan(
      sourceWidth: 6000,
      sourceHeight: 4000,
      crop: CropState.initial,
      transform: const ImageTransform(rotationDegrees: 90),
      settings: ExportSettings.initial,
    );

    expect(plan.fullResolutionWidth, 4000);
    expect(plan.fullResolutionHeight, 6000);
  });

  test('uses committed crop frame dimensions at full resolution', () {
    const crop = CropState(
      normalizedRect: NormalizedCropRect(
        left: 0.125,
        top: 0,
        right: 0.875,
        bottom: 1,
      ),
      aspectRatio: 1,
    );

    final plan = planner.buildPlan(
      sourceWidth: 4000,
      sourceHeight: 3000,
      crop: crop,
      transform: ImageTransform.initial,
      settings: ExportSettings.initial,
    );

    expect(plan.fullResolutionWidth, 3000);
    expect(plan.fullResolutionHeight, 3000);
    expect(plan.outputWidth, 3000);
    expect(plan.outputHeight, 3000);
  });

  test('max dimension only downsizes and preserves aspect ratio', () {
    const settings = ExportSettings(
      resolutionMode: ExportResolutionMode.maxDimension,
      maxDimension: 2048,
    );

    final plan = planner.buildPlan(
      sourceWidth: 6000,
      sourceHeight: 4000,
      crop: CropState.initial,
      transform: ImageTransform.initial,
      settings: settings,
    );

    expect(plan.fullResolutionWidth, 6000);
    expect(plan.fullResolutionHeight, 4000);
    expect(plan.outputWidth, 2048);
    expect(plan.outputHeight, 1365);
    expect(plan.isDownscaled, isTrue);
  });

  test('max dimension never upscales a smaller source', () {
    const settings = ExportSettings(
      resolutionMode: ExportResolutionMode.maxDimension,
      maxDimension: 4096,
    );

    final plan = planner.buildPlan(
      sourceWidth: 1600,
      sourceHeight: 1200,
      crop: CropState.initial,
      transform: ImageTransform.initial,
      settings: settings,
    );

    expect(plan.outputWidth, 1600);
    expect(plan.outputHeight, 1200);
    expect(plan.isDownscaled, isFalse);
  });

  test('carries WebP format and quality into the render plan', () {
    const settings = ExportSettings(format: ExportFormat.webp, quality: 81);

    final plan = planner.buildPlan(
      sourceWidth: 1200,
      sourceHeight: 800,
      crop: CropState.initial,
      transform: ImageTransform.initial,
      settings: settings,
    );

    expect(plan.format, ExportFormat.webp);
    expect(plan.quality, 81);
    expect(plan.fileExtension, 'webp');
  });

  test('rejects invalid source dimensions', () {
    expect(
      () => planner.buildPlan(
        sourceWidth: 0,
        sourceHeight: 100,
        crop: CropState.initial,
        transform: ImageTransform.initial,
        settings: ExportSettings.initial,
      ),
      throwsArgumentError,
    );
  });
}
