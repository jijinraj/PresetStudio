import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/presets/application/preset_library.dart';
import 'package:presetstudio/features/presets/application/preset_library_controller.dart';
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
