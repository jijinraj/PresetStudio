import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';
import 'package:presetstudio/features/presets/application/preset_adjustment_mapper.dart';
import 'package:presetstudio/features/presets/domain/preset_hsl_color_mixer_values.dart';

void main() {
  test('round-trips shareable HSL color mixer state', () {
    final mixer = HslColorMixer.initial.copyWith(
      red: HslColorAdjustment(hue: 18, saturation: 35, luminance: -12),
      aqua: HslColorAdjustment(hue: -20, saturation: 16, luminance: 24),
    );
    final restored = PresetAdjustmentMapper.toHslColorMixer(
      PresetAdjustmentMapper.fromHslColorMixer(mixer),
    );
    expect(restored, mixer);
  });

  test('sanitizes portable HSL values entering the editor', () {
    const values = PresetHslColorMixerValues(
      red: PresetHslColorAdjustmentValues(
        hue: 500,
        saturation: -250,
        luminance: 140,
      ),
    );
    final restored = PresetAdjustmentMapper.toHslColorMixer(values);
    expect(restored.red.hue, 100);
    expect(restored.red.saturation, -100);
    expect(restored.red.luminance, 100);
  });
}
