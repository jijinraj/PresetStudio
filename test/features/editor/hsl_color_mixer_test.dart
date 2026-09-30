import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';

void main() {
  group('HslColorAdjustment', () {
    test('neutral state contains zero hue saturation and luminance', () {
      const adjustment = HslColorAdjustment.neutral;

      expect(adjustment.hue, 0);
      expect(adjustment.saturation, 0);
      expect(adjustment.luminance, 0);
      expect(adjustment.isNeutral, isTrue);
    });

    test('clamps values to the supported range', () {
      final adjustment = HslColorAdjustment(
        hue: -150,
        saturation: 125,
        luminance: 250,
      );

      expect(adjustment.hue, -100);
      expect(adjustment.saturation, 100);
      expect(adjustment.luminance, 100);
    });

    test('sanitizes non-finite values to neutral', () {
      final adjustment = HslColorAdjustment(
        hue: double.nan,
        saturation: double.infinity,
        luminance: double.negativeInfinity,
      );

      expect(adjustment, HslColorAdjustment.neutral);
    });

    test('copyWith preserves untouched components and sanitizes changes', () {
      final adjustment = HslColorAdjustment(
        hue: 10,
        saturation: 20,
        luminance: 30,
      );
      final changed = adjustment.copyWith(saturation: 150);

      expect(changed.hue, 10);
      expect(changed.saturation, 100);
      expect(changed.luminance, 30);
    });

    test('supports value equality', () {
      expect(
        HslColorAdjustment(hue: 10, saturation: -20, luminance: 30),
        HslColorAdjustment(hue: 10, saturation: -20, luminance: 30),
      );
    });
  });

  group('HslColorMixer', () {
    test('initial state is neutral for all eight color ranges', () {
      const mixer = HslColorMixer.initial;

      expect(HslColorRange.values, hasLength(8));
      for (final range in HslColorRange.values) {
        expect(mixer.adjustmentFor(range), HslColorAdjustment.neutral);
      }
      expect(mixer.isDefault, isTrue);
    });

    test('detects a modified color range', () {
      final mixer = HslColorMixer.initial.withAdjustment(
        HslColorRange.blue,
        HslColorAdjustment(saturation: 25),
      );

      expect(mixer.isDefault, isFalse);
      expect(mixer.blue.saturation, 25);
      expect(mixer.red.isNeutral, isTrue);
    });

    test('withAdjustment routes every range to its matching value', () {
      var mixer = HslColorMixer.initial;

      for (var index = 0; index < HslColorRange.values.length; index += 1) {
        final range = HslColorRange.values[index];
        mixer = mixer.withAdjustment(range, HslColorAdjustment(hue: index + 1));
      }

      for (var index = 0; index < HslColorRange.values.length; index += 1) {
        final range = HslColorRange.values[index];
        expect(mixer.adjustmentFor(range).hue, index + 1);
      }
    });

    test('copyWith preserves untouched color ranges', () {
      final blue = HslColorAdjustment(hue: -15, saturation: 30, luminance: -10);
      final mixer = HslColorMixer.initial.copyWith(blue: blue);

      expect(mixer.blue, blue);
      expect(mixer.red, HslColorAdjustment.neutral);
      expect(mixer.orange, HslColorAdjustment.neutral);
      expect(mixer.yellow, HslColorAdjustment.neutral);
      expect(mixer.green, HslColorAdjustment.neutral);
      expect(mixer.aqua, HslColorAdjustment.neutral);
      expect(mixer.purple, HslColorAdjustment.neutral);
      expect(mixer.magenta, HslColorAdjustment.neutral);
    });

    test('supports value equality', () {
      final first = HslColorMixer.initial.copyWith(
        orange: HslColorAdjustment(hue: 12, saturation: 34, luminance: -8),
      );
      final second = HslColorMixer.initial.copyWith(
        orange: HslColorAdjustment(hue: 12, saturation: 34, luminance: -8),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
