import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/application/preset_library.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_record.dart';
import 'package:presetstudio/features/presets/infrastructure/local_preset_library_store.dart';

void main() {
  late Directory tempDirectory;
  late LocalPresetLibraryStore store;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'presetstudio-preset-library-service-test-',
    );
    store = LocalPresetLibraryStore(rootDirectory: tempDirectory);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('saveLocal creates an offline local library record', () async {
    final now = DateTime.utc(2026, 9, 25, 15);
    final library = PresetLibrary(store: store, clock: () => now);
    final preset = _preset('local-one', name: 'Local One');

    final record = await library.saveLocal(preset);
    final reloaded = await PresetLibrary(
      store: LocalPresetLibraryStore(rootDirectory: tempDirectory),
    ).load();

    expect(record.origin.type, PresetOriginType.local);
    expect(record.libraryId, PresetRecord.localLibraryId(preset.id));
    expect(reloaded, [record]);
  });

  test('renaming a local preset increments revision and persists', () async {
    var now = DateTime.utc(2026, 9, 25, 15);
    final library = PresetLibrary(store: store, clock: () => now);
    final saved = await library.saveLocal(_preset('rename-me', name: 'Before'));

    now = DateTime.utc(2026, 9, 25, 16);
    final renamed = await library.renameLocal(saved.libraryId, 'After');
    final reloaded = await library.load();

    expect(renamed.preset.name, 'After');
    expect(renamed.preset.revision, 2);
    expect(renamed.installedAt, saved.installedAt);
    expect(renamed.updatedAt, now);
    expect(reloaded.single, renamed);
  });

  test(
    'installed remote preset remains usable without its source registry',
    () async {
      final now = DateTime.utc(2026, 9, 25, 15);
      final library = PresetLibrary(store: store, clock: () => now);
      final preset = _preset('film-one', name: 'Film One');

      final installed = await library.installRemote(
        preset: preset,
        sourceId: 'film-repository',
        remoteRevision: 7,
      );

      final offlineLibrary = PresetLibrary(
        store: LocalPresetLibraryStore(rootDirectory: tempDirectory),
      );
      final records = await offlineLibrary.load();

      expect(records, [installed]);
      expect(records.single.preset, preset);
      expect(records.single.origin.sourceId, 'film-repository');
      expect(records.single.origin.remoteRevision, 7);
    },
  );

  test(
    'same remote preset id from two sources installs independently',
    () async {
      final library = PresetLibrary(
        store: store,
        clock: () => DateTime.utc(2026, 9, 25, 15),
      );
      final preset = _preset('shared', name: 'Shared');

      final first = await library.installRemote(
        preset: preset,
        sourceId: 'source-one',
      );
      final second = await library.installRemote(
        preset: preset,
        sourceId: 'source-two',
      );

      expect(first.libraryId, isNot(second.libraryId));
      expect(await library.load(), hasLength(2));
    },
  );

  test('remote-installed presets cannot be renamed in place', () async {
    final library = PresetLibrary(
      store: store,
      clock: () => DateTime.utc(2026, 9, 25, 15),
    );
    final installed = await library.installRemote(
      preset: _preset('remote', name: 'Remote'),
      sourceId: 'source-one',
    );

    await expectLater(
      library.renameLocal(installed.libraryId, 'Changed'),
      throwsA(isA<PresetLibraryException>()),
    );
  });

  test('delete removes local and remote-installed records', () async {
    final library = PresetLibrary(
      store: store,
      clock: () => DateTime.utc(2026, 9, 25, 15),
    );
    final local = await library.saveLocal(
      _preset('local-delete', name: 'Local Delete'),
    );
    final remote = await library.installRemote(
      preset: _preset('remote-delete', name: 'Remote Delete'),
      sourceId: 'source-one',
    );

    await library.delete(local.libraryId);
    await library.delete(remote.libraryId);

    expect(await library.load(), isEmpty);
  });
}

Preset _preset(String id, {required String name}) {
  return Preset(
    id: id,
    name: name,
    createdAt: DateTime.utc(2026, 9, 25),
    adjustments: const PresetAdjustmentValues(
      exposure: 0.2,
      contrast: 10,
      temperature: 4,
      vibrance: 12,
    ),
  );
}
