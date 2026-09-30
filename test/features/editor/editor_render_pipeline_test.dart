import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/domain/image_transform.dart';
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

    test('reduces contrast to midpoint at negative one hundred', () {
      const adjustments = ImageAdjustments(contrast: -100.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.colorMatrix[0], closeTo(0.0, 0.000001));

      expect(plan.colorMatrix[6], closeTo(0.0, 0.000001));

      expect(plan.colorMatrix[12], closeTo(0.0, 0.000001));

      expect(plan.colorMatrix[4], closeTo(127.5, 0.000001));

      expect(plan.colorMatrix[9], closeTo(127.5, 0.000001));

      expect(plan.colorMatrix[14], closeTo(127.5, 0.000001));
    });

    test('doubles contrast around midpoint at positive one hundred', () {
      const adjustments = ImageAdjustments(contrast: 100.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.colorMatrix[0], closeTo(2.0, 0.000001));

      expect(plan.colorMatrix[6], closeTo(2.0, 0.000001));

      expect(plan.colorMatrix[12], closeTo(2.0, 0.000001));

      expect(plan.colorMatrix[4], closeTo(-127.5, 0.000001));

      expect(plan.colorMatrix[9], closeTo(-127.5, 0.000001));

      expect(plan.colorMatrix[14], closeTo(-127.5, 0.000001));
    });

    test('desaturates fully to luminance grayscale', () {
      const adjustments = ImageAdjustments(saturation: -100.0);

      final plan = pipeline.buildPlan(adjustments);

      const red = 0.2126;
      const green = 0.7152;
      const blue = 0.0722;

      expect(plan.colorMatrix[0], closeTo(red, 0.000001));

      expect(plan.colorMatrix[1], closeTo(green, 0.000001));

      expect(plan.colorMatrix[2], closeTo(blue, 0.000001));

      expect(plan.colorMatrix[5], closeTo(red, 0.000001));

      expect(plan.colorMatrix[6], closeTo(green, 0.000001));

      expect(plan.colorMatrix[7], closeTo(blue, 0.000001));

      expect(plan.colorMatrix[10], closeTo(red, 0.000001));

      expect(plan.colorMatrix[11], closeTo(green, 0.000001));

      expect(plan.colorMatrix[12], closeTo(blue, 0.000001));
    });

    test('increases saturation at positive one hundred', () {
      const adjustments = ImageAdjustments(saturation: 100.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.colorMatrix[0], closeTo(1.7874, 0.000001));

      expect(plan.colorMatrix[1], closeTo(-0.7152, 0.000001));

      expect(plan.colorMatrix[2], closeTo(-0.0722, 0.000001));

      expect(plan.colorMatrix[6], closeTo(1.2848, 0.000001));

      expect(plan.colorMatrix[12], closeTo(1.9278, 0.000001));
    });

    test('applies exposure before contrast', () {
      const adjustments = ImageAdjustments(exposure: 1.0, contrast: 100.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.colorMatrix[0], closeTo(4.0, 0.000001));

      expect(plan.colorMatrix[6], closeTo(4.0, 0.000001));

      expect(plan.colorMatrix[12], closeTo(4.0, 0.000001));

      expect(plan.colorMatrix[4], closeTo(-127.5, 0.000001));

      expect(plan.colorMatrix[9], closeTo(-127.5, 0.000001));

      expect(plan.colorMatrix[14], closeTo(-127.5, 0.000001));
    });

    test('preserves alpha across combined color adjustments', () {
      const adjustments = ImageAdjustments(
        exposure: 1.0,
        contrast: 40.0,
        saturation: 35.0,
      );

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.colorMatrix[15], 0.0);
      expect(plan.colorMatrix[16], 0.0);
      expect(plan.colorMatrix[17], 0.0);
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

    test('sanitizes tonal range values before rendering', () {
      const adjustments = ImageAdjustments(
        highlights: 180.0,
        shadows: -240.0,
        whites: 37.0,
        blacks: -22.0,
      );

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.adjustments.highlights, 100.0);
      expect(plan.adjustments.shadows, -100.0);
      expect(plan.adjustments.whites, 37.0);
      expect(plan.adjustments.blacks, -22.0);
    });

    test('warms color balance with positive temperature', () {
      const adjustments = ImageAdjustments(temperature: 100.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.colorMatrix[0], closeTo(1.12, 0.000001));
      expect(plan.colorMatrix[6], closeTo(1.02, 0.000001));
      expect(plan.colorMatrix[12], closeTo(0.88, 0.000001));
    });

    test('moves positive tint toward magenta in the fallback matrix', () {
      const adjustments = ImageAdjustments(tint: 100.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.colorMatrix[0], closeTo(1.05, 0.000001));
      expect(plan.colorMatrix[6], closeTo(0.92, 0.000001));
      expect(plan.colorMatrix[12], closeTo(1.05, 0.000001));
    });

    test('uses restrained saturation as the linear vibrance fallback', () {
      const adjustments = ImageAdjustments(vibrance: 100.0);

      final plan = pipeline.buildPlan(adjustments);

      // Positive Vibrance uses the selective chroma-aware curve in the GPU
      // shader. The color-matrix fallback intentionally approximates it at
      // 60% of the equivalent Saturation strength.
      expect(plan.colorMatrix[0], closeTo(1.47244, 0.000001));
      expect(plan.colorMatrix[1], closeTo(-0.42912, 0.000001));
      expect(plan.colorMatrix[2], closeTo(-0.04332, 0.000001));
    });

    test('sanitizes color adjustment values before rendering', () {
      const adjustments = ImageAdjustments(
        temperature: 150.0,
        tint: -180.0,
        vibrance: 240.0,
      );

      final plan = pipeline.buildPlan(adjustments);

      expect(plan.adjustments.temperature, 100.0);
      expect(plan.adjustments.tint, -100.0);
      expect(plan.adjustments.vibrance, 100.0);
    });

    test('does not mutate supplied adjustment state', () {
      const adjustments = ImageAdjustments(exposure: 500.0);

      final plan = pipeline.buildPlan(adjustments);

      expect(adjustments.exposure, 500.0);

      expect(plan.adjustments.exposure, 5.0);
    });

    test('carries HSL color mixer state into the render plan', () {
      final mixer = HslColorMixer.initial.withAdjustment(
        HslColorRange.blue,
        HslColorAdjustment(hue: 20, saturation: 35, luminance: -15),
      );

      final plan = pipeline.buildPlan(
        ImageAdjustments.initial,
        hslColorMixer: mixer,
      );

      expect(plan.hslColorMixer, mixer);
      expect(plan.hslColorMixer.blue.hue, 20);
      expect(plan.hslColorMixer.blue.saturation, 35);
      expect(plan.hslColorMixer.blue.luminance, -15);
    });

    test('includes image transform in render plan', () {
      const transform = ImageTransform(rotationDegrees: 90.0);

      final plan = pipeline.buildPlan(
        ImageAdjustments.initial,
        transform: transform,
      );

      expect(plan.transform.rotationDegrees, 90.0);

      expect(plan.transform.flipHorizontal, isFalse);

      expect(plan.transform.flipVertical, isFalse);
    });
  });
}
