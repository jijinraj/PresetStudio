import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/curve_point.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/domain/tone_curves.dart';
import 'package:presetstudio/features/editor/rendering/export_tonal_processor.dart';
import 'package:presetstudio/features/editor/rendering/tone_curve_lut.dart';

void main() {
  HslColorMixer mixerFor(
    HslColorRange range, {
    double hue = 0,
    double saturation = 0,
    double luminance = 0,
  }) {
    return HslColorMixer.initial.withAdjustment(
      range,
      HslColorAdjustment(
        hue: hue,
        saturation: saturation,
        luminance: luminance,
      ),
    );
  }

  test('neutral HSL mixer preserves RGB', () {
    final processor = ExportTonalProcessor(ImageAdjustments.initial);

    final result = processor.apply(0.8, 0.35, 0.2);

    expect(result.$1, closeTo(0.8, 0.000001));
    expect(result.$2, closeTo(0.35, 0.000001));
    expect(result.$3, closeTo(0.2, 0.000001));
  });

  test('red saturation adjustment selectively strengthens red', () {
    final processor = ExportTonalProcessor(
      ImageAdjustments.initial,
      hslColorMixer: mixerFor(HslColorRange.red, saturation: 100),
    );

    final result = processor.apply(0.8, 0.3, 0.3);

    expect(result.$1, greaterThan(0.8));
    expect(result.$2, lessThan(0.3));
    expect(result.$3, lessThan(0.3));
  });

  test('blue luminance adjustment selectively lifts blue', () {
    final processor = ExportTonalProcessor(
      ImageAdjustments.initial,
      hslColorMixer: mixerFor(HslColorRange.blue, luminance: 50),
    );

    final result = processor.apply(0.2, 0.3, 0.8);

    expect(result.$1, greaterThan(0.2));
    expect(result.$2, greaterThan(0.3));
    expect(result.$3, greaterThan(0.8));
  });

  test('selective HSL leaves grayscale pixels neutral', () {
    final processor = ExportTonalProcessor(
      ImageAdjustments.initial,
      hslColorMixer: mixerFor(
        HslColorRange.red,
        hue: 100,
        saturation: 100,
        luminance: 100,
      ),
    );

    final result = processor.apply(0.5, 0.5, 0.5);

    expect(result.$1, closeTo(0.5, 0.000001));
    expect(result.$2, closeTo(0.5, 0.000001));
    expect(result.$3, closeTo(0.5, 0.000001));
  });

  test('HSL ranges blend continuously around overlapping hue bands', () {
    final mixer = HslColorMixer.initial.copyWith(
      red: HslColorAdjustment(saturation: -60),
      orange: HslColorAdjustment(saturation: 60),
    );
    final processor = ExportTonalProcessor(
      ImageAdjustments.initial,
      hslColorMixer: mixer,
    );

    // Nearby red-orange colors should produce nearby outputs rather than a
    // hard discontinuity at a range boundary.
    final left = processor.apply(0.8, 0.38, 0.2);
    final right = processor.apply(0.8, 0.40, 0.2);

    expect((left.$1 - right.$1).abs(), lessThan(0.05));
    expect((left.$2 - right.$2).abs(), lessThan(0.05));
    expect((left.$3 - right.$3).abs(), lessThan(0.05));
  });

  test('HSL is applied after global saturation', () {
    final processor = ExportTonalProcessor(
      const ImageAdjustments(saturation: -100),
      hslColorMixer: mixerFor(HslColorRange.red, saturation: 100),
    );

    final result = processor.apply(0.8, 0.2, 0.2);

    // Global -100 saturation produces grayscale before HSL, so the HSL
    // grayscale guard prevents selective color from being reintroduced.
    expect(result.$1, closeTo(result.$2, 0.000001));
    expect(result.$2, closeTo(result.$3, 0.000001));
  });

  test('HSL is applied before tone curves', () {
    final curves = ToneCurves.initial.copyWith(
      red: ToneCurve(points: [CurvePoint(input: 0.5, output: 0.8)]),
    );
    final mixer = mixerFor(HslColorRange.red, luminance: 50);
    final hslOnly = ExportTonalProcessor(
      ImageAdjustments.initial,
      hslColorMixer: mixer,
    ).apply(0.8, 0.2, 0.2);

    final processor = ExportTonalProcessor(
      ImageAdjustments.initial,
      hslColorMixer: mixer,
      toneCurves: curves,
    );
    final result = processor.apply(0.8, 0.2, 0.2);

    final expectedRed = ToneCurveLut.sample(
      processor.toneCurveLut.red,
      hslOnly.$1,
    );

    expect(result.$1, closeTo(expectedRed, 0.000001));
  });
}
