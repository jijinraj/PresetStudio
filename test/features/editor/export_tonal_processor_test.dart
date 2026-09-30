import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/curve_point.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/domain/tone_curves.dart';
import 'package:presetstudio/features/editor/rendering/export_tonal_processor.dart';
import 'package:presetstudio/features/editor/rendering/tone_curve_lut.dart';

void main() {
  test('default processor preserves RGB', () {
    final processor = ExportTonalProcessor(ImageAdjustments.initial);

    final result = processor.apply(0.25, 0.5, 0.75);

    expect(result.$1, closeTo(0.25, 0.000001));
    expect(result.$2, closeTo(0.5, 0.000001));
    expect(result.$3, closeTo(0.75, 0.000001));
  });

  test('positive one-stop exposure doubles unclipped RGB', () {
    final processor = ExportTonalProcessor(ImageAdjustments(exposure: 1));

    final result = processor.apply(0.2, 0.1, 0.05);

    expect(result.$1, closeTo(0.4, 0.000001));
    expect(result.$2, closeTo(0.2, 0.000001));
    expect(result.$3, closeTo(0.1, 0.000001));
  });

  test('positive temperature warms the RGB balance', () {
    final processor = ExportTonalProcessor(ImageAdjustments(temperature: 100));

    final result = processor.apply(0.5, 0.5, 0.5);

    expect(result.$1, closeTo(0.56, 0.000001));
    expect(result.$2, closeTo(0.51, 0.000001));
    expect(result.$3, closeTo(0.44, 0.000001));
  });

  test('positive vibrance boosts low-chroma color selectively', () {
    final processor = ExportTonalProcessor(ImageAdjustments(vibrance: 100));

    final muted = processor.apply(0.55, 0.50, 0.45);
    final vivid = processor.apply(0.9, 0.5, 0.1);

    final mutedSpread = muted.$1 - muted.$3;
    final vividSpread = vivid.$1 - vivid.$3;

    expect(mutedSpread, greaterThan(0.10));
    expect(vividSpread, greaterThan(0.80));
    expect(mutedSpread / 0.10, greaterThan(vividSpread / 0.80));
  });

  test('positive vignette darkens edges while preserving center', () {
    final processor = ExportTonalProcessor(
      ImageAdjustments(vignetteAmount: 80, vignetteFeather: 50),
    );
    final center = processor.apply(0.6, 0.6, 0.6);
    final corner = processor.apply(
      0.6,
      0.6,
      0.6,
      normalizedX: 0,
      normalizedY: 0,
      aspectRatio: 1.5,
    );
    expect(center.$1, closeTo(0.6, 0.000001));
    expect(corner.$1, lessThan(center.$1));
    expect(corner.$2, lessThan(center.$2));
    expect(corner.$3, lessThan(center.$3));
  });

  test('negative vignette lifts edges', () {
    final processor = ExportTonalProcessor(
      ImageAdjustments(vignetteAmount: -80, vignetteFeather: 50),
    );
    final corner = processor.apply(
      0.4,
      0.4,
      0.4,
      normalizedX: 1,
      normalizedY: 1,
    );
    expect(corner.$1, greaterThan(0.4));
  });
  test('tone curves are applied after saturation', () {
    final processor = ExportTonalProcessor(
      const ImageAdjustments(saturation: -100),
      toneCurves: ToneCurves.initial.copyWith(
        red: ToneCurve(points: [CurvePoint(input: 0.5, output: 0.75)]),
      ),
    );

    final result = processor.apply(0.8, 0.2, 0.2);

    expect(result.$1, greaterThan(result.$2));
    expect(result.$2, closeTo(result.$3, 0.000001));
  });

  test('tone curves are applied before vignette', () {
    final processor = ExportTonalProcessor(
      const ImageAdjustments(vignetteAmount: 100, vignetteFeather: 50),
      toneCurves: ToneCurves.initial.copyWith(
        master: ToneCurve(points: [CurvePoint(input: 0.5, output: 0.8)]),
      ),
    );

    final center = processor.apply(0.5, 0.5, 0.5);
    final corner = processor.apply(
      0.5,
      0.5,
      0.5,
      normalizedX: 0,
      normalizedY: 0,
    );

    final expectedCenter = ToneCurveLut.sample(processor.toneCurveLut.red, 0.5);

    expect(center.$1, closeTo(expectedCenter, 0.000001));
    expect(corner.$1, lessThan(center.$1));
  });
}
