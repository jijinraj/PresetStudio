import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_json_codec.dart';

void main() {
  const codec = PresetJsonCodec();

  test('round-trips a versioned portable preset', () {
    final preset = Preset(
      id: '7f0e64f0-7c1a-4f3e-b796-56aa0f24d0af',
      name: 'Dark Forest',
      description: 'Muted greens with warmer highlights.',
      author: 'Jijin',
      createdAt: DateTime.utc(2026, 9, 25, 14, 0),
      revision: 3,
      adjustments: const PresetAdjustmentValues(
        exposure: -0.25,
        contrast: 18,
        highlights: -30,
        shadows: 14,
        whites: -8,
        blacks: -16,
        temperature: 6,
        tint: -4,
        vibrance: 22,
        saturation: -7,
      ),
    );

    final encoded = codec.encode(preset);
    final decoded = codec.decode(encoded);

    expect(decoded, preset);
    expect(encoded, contains('"format": "presetstudio.preset"'));
    expect(encoded, contains('"schemaVersion": 1'));
    expect(encoded, contains('"revision": 3'));
    expect(encoded, isNot(contains('repositoryUrl')));
    expect(encoded, isNot(contains('sourceId')));
    expect(encoded, isNot(contains('crop')));
    expect(encoded, isNot(contains('transform')));
  });

  test('optional metadata can be omitted', () {
    final preset = Preset(
      id: 'minimal-preset',
      name: 'Minimal',
      createdAt: DateTime.utc(2026, 9, 25),
      adjustments: PresetAdjustmentValues.initial,
    );

    final decoded = codec.decode(codec.encode(preset));

    expect(decoded.description, isNull);
    expect(decoded.author, isNull);
    expect(decoded.revision, 1);
  });

  test('rejects unsupported schema versions', () {
    const source = '''
{
  "format": "presetstudio.preset",
  "schemaVersion": 2,
  "id": "future",
  "name": "Future",
  "createdAt": "2026-09-25T00:00:00.000Z",
  "revision": 1,
  "adjustments": {
    "exposure": 0,
    "contrast": 0,
    "highlights": 0,
    "shadows": 0,
    "whites": 0,
    "blacks": 0,
    "temperature": 0,
    "tint": 0,
    "vibrance": 0,
    "saturation": 0
  }
}
''';

    expect(() => codec.decode(source), throwsA(isA<PresetFormatException>()));
  });

  test('rejects incomplete adjustment payloads', () {
    const source = '''
{
  "format": "presetstudio.preset",
  "schemaVersion": 1,
  "id": "broken",
  "name": "Broken",
  "createdAt": "2026-09-25T00:00:00.000Z",
  "revision": 1,
  "adjustments": {
    "exposure": 0,
    "contrast": 0
  }
}
''';

    expect(() => codec.decode(source), throwsA(isA<PresetFormatException>()));
  });

  test('rejects non numeric adjustment values', () {
    const source = '''
{
  "format": "presetstudio.preset",
  "schemaVersion": 1,
  "id": "broken",
  "name": "Broken",
  "createdAt": "2026-09-25T00:00:00.000Z",
  "revision": 1,
  "adjustments": {
    "exposure": "warm",
    "contrast": 0,
    "highlights": 0,
    "shadows": 0,
    "whites": 0,
    "blacks": 0,
    "temperature": 0,
    "tint": 0,
    "vibrance": 0,
    "saturation": 0
  }
}
''';

    expect(() => codec.decode(source), throwsA(isA<PresetFormatException>()));
  });
}
