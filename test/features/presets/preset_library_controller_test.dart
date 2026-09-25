import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/presets/application/preset_library.dart';
import 'package:presetstudio/features/presets/application/preset_library_controller.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_record.dart';
import 'package:presetstudio/features/presets/infrastructure/local_preset_library_store.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'presetstudio-preset-library-controller-test-',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('initializes, saves current adjustments, and reloads them', () async {
    final createdAt = DateTime.utc(2026, 9, 25, 16);
    final controller = _controller(
      tempDirectory,
      idGenerator: () => 'local-test',
      clock: () => createdAt,
    );

    await controller.initialize();

    expect(controller.isReady, isTrue);
    expect(controller.records, isEmpty);

    final record = await controller.saveCurrent(
      name: 'Dark Forest',
      description: 'Muted greens',
      adjustments: const ImageAdjustments(
        exposure: -0.4,
        contrast: 22,
        temperature: 8,
        vibrance: 17,
      ),
    );

    expect(record.origin.type, PresetOriginType.local);
    expect(record.preset.id, 'local-test');
    expect(record.preset.createdAt, createdAt);
    expect(record.preset.adjustments.exposure, -0.4);
    expect(record.preset.adjustments.contrast, 22);
    expect(controller.records, [record]);

    final reloaded = _controller(tempDirectory);
    await reloaded.initialize();

    expect(reloaded.records, hasLength(1));
    expect(reloaded.records.single.preset.name, 'Dark Forest');
    expect(reloaded.records.single.preset.description, 'Muted greens');
  });

  test(
    'imports portable presets, sanitizes values, and supports copies',
    () async {
      final controller = _controller(
        tempDirectory,
        idGenerator: () => 'imported-copy',
      );
      await controller.initialize();

      final portable = Preset(
        id: 'portable-id',
        name: 'Portable Look',
        description: 'Shared preset',
        author: 'Preset Author',
        createdAt: DateTime.utc(2026, 9, 20),
        revision: 4,
        adjustments: const PresetAdjustmentValues(
          exposure: 12,
          contrast: 240,
          temperature: -180,
          vibrance: 35,
        ),
      );

      final imported = await controller.importPortablePreset(portable);

      expect(imported.preset.id, 'portable-id');
      expect(imported.preset.revision, 4);
      expect(imported.preset.adjustments.exposure, 5);
      expect(imported.preset.adjustments.contrast, 100);
      expect(imported.preset.adjustments.temperature, -100);
      expect(
        controller.localRecordForPresetId('portable-id')?.libraryId,
        imported.libraryId,
      );

      final copy = await controller.importPortablePreset(
        portable,
        asCopy: true,
      );

      expect(copy.preset.id, 'imported-copy');
      expect(copy.preset.name, portable.name);
      expect(copy.preset.description, portable.description);
      expect(copy.preset.author, portable.author);
      expect(copy.preset.createdAt, portable.createdAt);
      expect(copy.preset.revision, portable.revision);
      expect(controller.records, hasLength(2));
    },
  );

  test('import without copy replaces the matching local portable ID', () async {
    final controller = _controller(tempDirectory);
    await controller.initialize();

    final original = Preset(
      id: 'same-id',
      name: 'Original',
      createdAt: DateTime.utc(2026, 9, 20),
      adjustments: const PresetAdjustmentValues(contrast: 10),
    );
    final replacement = Preset(
      id: 'same-id',
      name: 'Replacement',
      createdAt: DateTime.utc(2026, 9, 21),
      revision: 2,
      adjustments: const PresetAdjustmentValues(contrast: 30),
    );

    final first = await controller.importPortablePreset(original);
    final second = await controller.importPortablePreset(replacement);

    expect(first.libraryId, second.libraryId);
    expect(controller.records, hasLength(1));
    expect(controller.records.single.preset.name, 'Replacement');
    expect(controller.records.single.preset.revision, 2);
    expect(controller.records.single.preset.adjustments.contrast, 30);
  });

  test('rename and delete update the in-memory library state', () async {
    var now = DateTime.utc(2026, 9, 25, 16);
    final controller = _controller(
      tempDirectory,
      idGenerator: () => 'rename-delete',
      clock: () => now,
      libraryClock: () => now,
    );

    await controller.initialize();
    final saved = await controller.saveCurrent(
      name: 'Before',
      adjustments: const ImageAdjustments(contrast: 15),
    );

    now = DateTime.utc(2026, 9, 25, 17);
    final renamed = await controller.renameLocal(saved.libraryId, 'After');

    expect(renamed.preset.name, 'After');
    expect(renamed.preset.revision, 2);
    expect(controller.records.single, renamed);

    await controller.delete(saved.libraryId);

    expect(controller.records, isEmpty);
  });
}

PresetLibraryController _controller(
  Directory root, {
  String Function()? idGenerator,
  DateTime Function()? clock,
  DateTime Function()? libraryClock,
}) {
  return PresetLibraryController(
    idGenerator: idGenerator,
    clock: clock,
    libraryLoader: () async {
      return PresetLibrary(
        store: LocalPresetLibraryStore(rootDirectory: root),
        clock: libraryClock,
      );
    },
  );
}
