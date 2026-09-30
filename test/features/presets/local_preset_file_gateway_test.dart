import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/infrastructure/local_preset_file_gateway.dart';

void main() {
  group('LocalPresetFileGateway.suggestedFileName', () {
    test(
      'uses the portable preset suffix and removes invalid filename chars',
      () {
        final preset = Preset(
          id: 'preset-id',
          name: r'Warm: Film / Portrait*',
          createdAt: DateTime.utc(2026, 9, 25),
          adjustments: const PresetAdjustmentValues(),
        );

        expect(
          LocalPresetFileGateway.suggestedFileName(preset),
          'Warm- Film - Portrait-.presetstudio',
        );
      },
    );

    test('falls back to a safe name', () {
      final preset = Preset(
        id: 'preset-id',
        name: '   .   ',
        createdAt: DateTime.utc(2026, 9, 25),
        adjustments: const PresetAdjustmentValues(),
      );

      expect(
        LocalPresetFileGateway.suggestedFileName(preset),
        'preset.presetstudio',
      );
    });
  });
}
