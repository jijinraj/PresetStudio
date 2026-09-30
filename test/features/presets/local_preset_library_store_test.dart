import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_record.dart';
import 'package:presetstudio/features/presets/infrastructure/local_preset_library_store.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'presetstudio-preset-library-test-',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('persists and reloads a local preset across store instances', () async {
    final preset = _preset('local-one', name: 'Local One');
    final record = PresetRecord(
      libraryId: PresetRecord.localLibraryId(preset.id),
      preset: preset,
      origin: PresetOrigin.local(),
      installedAt: DateTime.utc(2026, 9, 25, 12),
      updatedAt: DateTime.utc(2026, 9, 25, 12),
    );

    await LocalPresetLibraryStore(rootDirectory: tempDirectory)
        .upsertRecord(record);

    final reloaded = await LocalPresetLibraryStore(rootDirectory: tempDirectory)
        .loadRecords();

    expect(reloaded, [record]);
  });

  test('keeps provenance out of portable preset JSON files', () async {
    final preset = _preset('remote-one', name: 'Remote One');
    final record = PresetRecord(
      libraryId: PresetRecord.remoteLibraryId(
        sourceId: 'community',
        remotePresetId: preset.id,
      ),
      preset: preset,
      origin: PresetOrigin.remoteInstalled(
        sourceId: 'community',
        remotePresetId: preset.id,
        remoteRevision: 4,
      ),
      installedAt: DateTime.utc(2026, 9, 25, 12),
      updatedAt: DateTime.utc(2026, 9, 25, 12),
    );
    final store = LocalPresetLibraryStore(rootDirectory: tempDirectory);

    await store.upsertRecord(record);

    final presetDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}presets',
    );
    final files = await presetDirectory.list().where((entity) {
      return entity is File && entity.path.endsWith('.presetstudio');
    }).toList();

    expect(files, hasLength(1));
    final source = await File(files.single.path).readAsString();
    expect(source, contains('"format": "presetstudio.preset"'));
    expect(source, isNot(contains('sourceId')));
    expect(source, isNot(contains('remotePresetId')));
    expect(source, isNot(contains('remoteRevision')));
  });

  test(
    'supports identical portable preset ids from different sources',
    () async {
      final preset = _preset('shared-id', name: 'Shared');
      final first = _remoteRecord(
        preset: preset,
        sourceId: 'source-one',
        updatedAt: DateTime.utc(2026, 9, 25, 12),
      );
      final second = _remoteRecord(
        preset: preset,
        sourceId: 'source-two',
        updatedAt: DateTime.utc(2026, 9, 25, 13),
      );
      final store = LocalPresetLibraryStore(rootDirectory: tempDirectory);

      await store.upsertRecord(first);
      await store.upsertRecord(second);

      final records = await store.loadRecords();
      expect(records, hasLength(2));
      expect(records.map((record) => record.libraryId).toSet(), {
        first.libraryId,
        second.libraryId,
      });
    },
  );

  test('deleting a record persists across a new store instance', () async {
    final preset = _preset('delete-me', name: 'Delete Me');
    final record = PresetRecord(
      libraryId: PresetRecord.localLibraryId(preset.id),
      preset: preset,
      origin: PresetOrigin.local(),
      installedAt: DateTime.utc(2026, 9, 25, 12),
      updatedAt: DateTime.utc(2026, 9, 25, 12),
    );
    final store = LocalPresetLibraryStore(rootDirectory: tempDirectory);

    await store.upsertRecord(record);
    await store.deleteRecord(record.libraryId);

    final reloaded = await LocalPresetLibraryStore(rootDirectory: tempDirectory)
        .loadRecords();
    expect(reloaded, isEmpty);
  });
}

Preset _preset(String id, {required String name}) {
  return Preset(
    id: id,
    name: name,
    createdAt: DateTime.utc(2026, 9, 25),
    adjustments: const PresetAdjustmentValues(contrast: 12, vibrance: 8),
  );
}

PresetRecord _remoteRecord({
  required Preset preset,
  required String sourceId,
  required DateTime updatedAt,
}) {
  return PresetRecord(
    libraryId: PresetRecord.remoteLibraryId(
      sourceId: sourceId,
      remotePresetId: preset.id,
    ),
    preset: preset,
    origin: PresetOrigin.remoteInstalled(
      sourceId: sourceId,
      remotePresetId: preset.id,
      remoteRevision: 1,
    ),
    installedAt: DateTime.utc(2026, 9, 25, 12),
    updatedAt: updatedAt,
  );
}
