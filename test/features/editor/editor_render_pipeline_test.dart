import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/rendering/editor_render_pipeline.dart';

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

    test('sanitizes adjustment state before rendering', () {
      const adjustments = ImageAdjustments(
        exposure: 500,
        contrast: -800,
        saturation: 400,
      );

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.adjustments.exposure, 5);

      expect(plan.adjustments.contrast, -100);

      expect(plan.adjustments.saturation, 100);
    });

    test('does not mutate the supplied adjustment state', () {
      const adjustments = ImageAdjustments(exposure: 500);

      final plan = pipeline.buildPlan(adjustments);

      expect(adjustments.exposure, 500);

      expect(plan.adjustments.exposure, 5);
    });
  });
}
