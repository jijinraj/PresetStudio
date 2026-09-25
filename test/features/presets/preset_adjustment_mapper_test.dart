import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/presets/application/preset_adjustment_mapper.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';

void main() {
  test('captures the shareable editor adjustments', () {
    const adjustments = ImageAdjustments(
      exposure: 1.25,
      contrast: 12,
      highlights: -20,
      shadows: 14,
      whites: 8,
      blacks: -11,
      temperature: 18,
      tint: -6,
      vibrance: 25,
      saturation: -4,
    );

    final values = PresetAdjustmentMapper.fromImageAdjustments(adjustments);

    expect(values.exposure, 1.25);
    expect(values.contrast, 12);
    expect(values.highlights, -20);
    expect(values.shadows, 14);
    expect(values.whites, 8);
    expect(values.blacks, -11);
    expect(values.temperature, 18);
    expect(values.tint, -6);
    expect(values.vibrance, 25);
    expect(values.saturation, -4);
  });

  test('sanitizes preset values when they enter the editor', () {
    const values = PresetAdjustmentValues(
      exposure: 99,
      contrast: -500,
      temperature: 12.8,
      tint: -12.7,
      vibrance: 155,
    );

    final adjustments = PresetAdjustmentMapper.toImageAdjustments(values);

    expect(adjustments.exposure, 5);
    expect(adjustments.contrast, -100);
    expect(adjustments.temperature, 13);
    expect(adjustments.tint, -13);
    expect(adjustments.vibrance, 100);
  });
}
