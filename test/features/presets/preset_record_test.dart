import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_record.dart';

void main() {
  test('remote library identity includes source identity', () {
    final one = PresetRecord.remoteLibraryId(
      sourceId: 'source-one',
      remotePresetId: 'shared-preset',
    );
    final two = PresetRecord.remoteLibraryId(
      sourceId: 'source-two',
      remotePresetId: 'shared-preset',
    );

    expect(one, isNot(two));
  });

  test('remote origin requires source and preset identity', () {
    expect(
      () =>
          PresetOrigin.remoteInstalled(sourceId: ' ', remotePresetId: 'preset'),
      throwsA(isA<PresetRecordValidationException>()),
    );
    expect(
      () =>
          PresetOrigin.remoteInstalled(sourceId: 'source', remotePresetId: ' '),
      throwsA(isA<PresetRecordValidationException>()),
    );
  });

  test('record rejects timestamps that move backwards', () {
    final preset = _preset('local-one');

    expect(
      () => PresetRecord(
        libraryId: PresetRecord.localLibraryId(preset.id),
        preset: preset,
        origin: PresetOrigin.local(),
        installedAt: DateTime.utc(2026, 9, 25, 12),
        updatedAt: DateTime.utc(2026, 9, 25, 11),
      ),
      throwsA(isA<PresetRecordValidationException>()),
    );
  });
}

Preset _preset(String id) {
  return Preset(
    id: id,
    name: 'Preset $id',
    createdAt: DateTime.utc(2026, 9, 25),
    adjustments: PresetAdjustmentValues.initial,
  );
}
