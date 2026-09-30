import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_hsl_color_mixer_values.dart';
import 'package:presetstudio/features/presets/domain/preset_json_codec.dart';

void main() {
  const codec = PresetJsonCodec();

  Preset presetWithHsl() => Preset(
    id: 'hsl-portable',
    name: 'HSL Portable',
    createdAt: DateTime.utc(2026, 9, 30),
    adjustments: PresetAdjustmentValues.initial,
    hslColorMixer: const PresetHslColorMixerValues(
      red: PresetHslColorAdjustmentValues(
        hue: 12,
        saturation: 34,
        luminance: -20,
      ),
      blue: PresetHslColorAdjustmentValues(
        hue: -18,
        saturation: 25,
        luminance: 11,
      ),
    ),
  );

  test('round-trips portable HSL color mixer values', () {
    final preset = presetWithHsl();
    final encoded = codec.encode(preset);
    expect(codec.decode(encoded), preset);
    expect(encoded, contains('"hslColorMixer"'));
    expect(encoded, contains('"magenta"'));
  });

  test('schema v1 preset without HSL remains compatible', () {
    final map =
        jsonDecode(codec.encode(presetWithHsl())) as Map<String, dynamic>;
    map.remove('hslColorMixer');
    final decoded = codec.decode(jsonEncode(map));
    expect(decoded.hslColorMixer, PresetHslColorMixerValues.initial);
    expect(decoded.schemaVersion, 1);
  });

  test('rejects malformed HSL payloads', () {
    final map =
        jsonDecode(codec.encode(presetWithHsl())) as Map<String, dynamic>;
    map['hslColorMixer'] = <String, Object?>{'red': 'broken'};
    expect(
      () => codec.decode(jsonEncode(map)),
      throwsA(isA<PresetFormatException>()),
    );
  });
}
