import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/rendering/editor_render_pipeline.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';

void main() {
  group('EditorRenderPipeline', () {
    const pipeline = EditorRenderPipeline();

    test('builds identity render plan for default adjustments', () {
      final plan = pipeline.buildPlan(ImageAdjustments.initial);

      expect(plan.adjustments.isDefault, isTrue);

      expect(plan.colorMatrix, EditorRenderPipeline.identityColorMatrix);
    });

    test('produces a valid 4x5 color matrix', () {
      final plan = pipeline.buildPlan(ImageAdjustments.initial);

      expect(plan.colorMatrix, hasLength(20));
    });

    test(
      'applies a two-times RGB multiplier at positive one exposure stop',
      () {
        const adjustments = ImageAdjustments(exposure: 1.0);

        final plan = pipeline.buildPlan(adjustments);

        expect(plan.colorMatrix[0], closeTo(2.0, 0.000001));
        expect(plan.colorMatrix[6], closeTo(2.0, 0.000001));
        expect(plan.colorMatrix[12], closeTo(2.0, 0.000001));
      },
    );

    test('applies a half RGB multiplier at negative one exposure stop', () {
      const adjustments = ImageAdjustments(exposure: -1.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.colorMatrix[0], closeTo(0.5, 0.000001));
      expect(plan.colorMatrix[6], closeTo(0.5, 0.000001));
      expect(plan.colorMatrix[12], closeTo(0.5, 0.000001));
    });

    test('preserves alpha while changing exposure', () {
      const adjustments = ImageAdjustments(exposure: 2.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.colorMatrix[18], 1.0);
      expect(plan.colorMatrix[19], 0.0);
    });

    test('uses sanitized exposure values before rendering', () {
      const adjustments = ImageAdjustments(exposure: 500.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.adjustments.exposure, 5.0);

      expect(plan.colorMatrix[0], closeTo(32.0, 0.000001));
      expect(plan.colorMatrix[6], closeTo(32.0, 0.000001));
      expect(plan.colorMatrix[12], closeTo(32.0, 0.000001));
    });

    test('sanitizes other adjustment state before rendering', () {
      const adjustments = ImageAdjustments(
        exposure: 0.0,
        contrast: -800.0,
        saturation: 400.0,
      );

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.adjustments.exposure, 0.0);
      expect(plan.adjustments.contrast, -100.0);
      expect(plan.adjustments.saturation, 100.0);
    });

    test('does not mutate supplied adjustment state', () {
      const adjustments = ImageAdjustments(exposure: 500.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(adjustments.exposure, 500.0);
      expect(plan.adjustments.exposure, 5.0);
    });

    test('includes image transform in render plan', () {
      const transform = ImageTransform(rotationQuarterTurns: 1);

      final plan = pipeline.buildPlan(
        ImageAdjustments.initial,
        transform: transform,
      );

      expect(plan.transform.rotationQuarterTurns, 1);
      expect(plan.transform.flipHorizontal, isFalse);
      expect(plan.transform.flipVertical, isFalse);
    });
  });
}
