import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/editor/rendering/export_tonal_processor.dart';

void main() {
  test('default processor preserves RGB', () {
    const processor = ExportTonalProcessor(ImageAdjustments.initial);

    final result = processor.apply(0.25, 0.5, 0.75);

    expect(result.$1, closeTo(0.25, 0.000001));
    expect(result.$2, closeTo(0.5, 0.000001));
    expect(result.$3, closeTo(0.75, 0.000001));
  });

  test('positive one-stop exposure doubles unclipped RGB', () {
    const processor = ExportTonalProcessor(ImageAdjustments(exposure: 1));

    final result = processor.apply(0.2, 0.1, 0.05);

    expect(result.$1, closeTo(0.4, 0.000001));
    expect(result.$2, closeTo(0.2, 0.000001));
    expect(result.$3, closeTo(0.1, 0.000001));
  });

  test('positive temperature warms the RGB balance', () {
    const processor = ExportTonalProcessor(ImageAdjustments(temperature: 100));

    final result = processor.apply(0.5, 0.5, 0.5);

    expect(result.$1, closeTo(0.56, 0.000001));
    expect(result.$2, closeTo(0.51, 0.000001));
    expect(result.$3, closeTo(0.44, 0.000001));
  });

  test('positive vibrance boosts low-chroma color selectively', () {
    const processor = ExportTonalProcessor(ImageAdjustments(vibrance: 100));

    final muted = processor.apply(0.55, 0.50, 0.45);
    final vivid = processor.apply(0.9, 0.5, 0.1);

    final mutedSpread = muted.$1 - muted.$3;
    final vividSpread = vivid.$1 - vivid.$3;

    expect(mutedSpread, greaterThan(0.10));
    expect(vividSpread, greaterThan(0.80));
    expect(mutedSpread / 0.10, greaterThan(vividSpread / 0.80));
  });
}
