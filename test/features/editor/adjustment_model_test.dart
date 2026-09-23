import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/adjustment_definition.dart';
import 'package:presetstudio/features/editor/domain/adjustment_type.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';

void main() {
  group('AdjustmentDefinitions', () {
    test('defines metadata for every adjustment type', () {
      for (final type in AdjustmentType.values) {
        expect(
          AdjustmentDefinitions.values.containsKey(type),
          isTrue,
          reason: 'Missing definition for $type',
        );
      }

      expect(AdjustmentDefinitions.values.length, AdjustmentType.values.length);
    });

    test('defines exposure range', () {
      final definition = AdjustmentDefinitions.of(AdjustmentType.exposure);

      expect(definition.label, 'Exposure');
      expect(definition.minValue, -5);
      expect(definition.maxValue, 5);
      expect(definition.defaultValue, 0);
      expect(definition.step, 0.1);
    });

    test('defines standard adjustment range', () {
      final definition = AdjustmentDefinitions.of(AdjustmentType.contrast);

      expect(definition.minValue, -100);
      expect(definition.maxValue, 100);
      expect(definition.defaultValue, 0);
      expect(definition.step, 1);
    });

    test('clamps values to valid range', () {
      final definition = AdjustmentDefinitions.of(AdjustmentType.exposure);

      expect(definition.clamp(10), 5);
      expect(definition.clamp(-10), -5);
      expect(definition.clamp(2.5), 2.5);
    });

    test('sanitizes values using configured step', () {
      final exposure = AdjustmentDefinitions.of(AdjustmentType.exposure);

      final contrast = AdjustmentDefinitions.of(AdjustmentType.contrast);

      expect(exposure.sanitize(1.24), closeTo(1.2, 0.0001));

      expect(exposure.sanitize(1.27), closeTo(1.3, 0.0001));

      expect(contrast.sanitize(12.3), 12);

      expect(contrast.sanitize(12.8), 13);
    });

    test('sanitization also clamps values', () {
      final exposure = AdjustmentDefinitions.of(AdjustmentType.exposure);

      expect(exposure.sanitize(500), 5);

      expect(exposure.sanitize(-500), -5);
    });

    test('normalizes positive and negative values', () {
      final definition = AdjustmentDefinitions.of(AdjustmentType.contrast);

      expect(definition.normalize(100), 1);

      expect(definition.normalize(50), 0.5);

      expect(definition.normalize(0), 0);

      expect(definition.normalize(-50), -0.5);

      expect(definition.normalize(-100), -1);
    });

    test('normalization clamps invalid values', () {
      final definition = AdjustmentDefinitions.of(AdjustmentType.exposure);

      expect(definition.normalize(500), 1);

      expect(definition.normalize(-500), -1);
    });
  });

  group('ImageAdjustments', () {
    test('initial adjustments are default', () {
      const adjustments = ImageAdjustments.initial;

      expect(adjustments.isDefault, isTrue);
    });

    test('detects modified adjustment state', () {
      const adjustments = ImageAdjustments(saturation: 10);

      expect(adjustments.isDefault, isFalse);
    });

    test('reads adjustment values by type', () {
      const adjustments = ImageAdjustments(exposure: 1.5, contrast: 20);

      expect(adjustments.valueFor(AdjustmentType.exposure), 1.5);

      expect(adjustments.valueFor(AdjustmentType.contrast), 20);
    });

    test('updates a single adjustment by type', () {
      const adjustments = ImageAdjustments.initial;

      final updated = adjustments.withValue(AdjustmentType.exposure, 1.5);

      expect(updated.exposure, 1.5);

      expect(updated.contrast, 0);

      expect(updated.saturation, 0);
    });

    test('single adjustment update clamps value', () {
      const adjustments = ImageAdjustments.initial;

      final updated = adjustments.withValue(AdjustmentType.exposure, 50);

      expect(updated.exposure, 5);
    });

    test('single adjustment update respects step', () {
      const adjustments = ImageAdjustments.initial;

      final exposure = adjustments.withValue(AdjustmentType.exposure, 1.27);

      final contrast = adjustments.withValue(AdjustmentType.contrast, 12.8);

      expect(exposure.exposure, closeTo(1.3, 0.0001));

      expect(contrast.contrast, 13);
    });

    test('normalizes stored adjustment value', () {
      const adjustments = ImageAdjustments(contrast: 50);

      expect(adjustments.normalizedValueFor(AdjustmentType.contrast), 0.5);
    });

    test('sanitizes complete adjustment state', () {
      const adjustments = ImageAdjustments(
        exposure: 20,
        contrast: -400,
        saturation: 500,
        temperature: 12.8,
      );

      final sanitized = adjustments.sanitized();

      expect(sanitized.exposure, 5);

      expect(sanitized.contrast, -100);

      expect(sanitized.saturation, 100);

      expect(sanitized.temperature, 13);
    });

    test('sanitizing preserves valid untouched values', () {
      const adjustments = ImageAdjustments(
        exposure: 1.5,
        contrast: 25,
        tint: -30,
      );

      final sanitized = adjustments.sanitized();

      expect(sanitized.exposure, 1.5);

      expect(sanitized.contrast, 25);

      expect(sanitized.tint, -30);
    });
  });
}
