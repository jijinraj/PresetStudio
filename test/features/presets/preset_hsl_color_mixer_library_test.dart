import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/domain/hsl_color_mixer.dart';
import 'package:presetstudio/features/editor/domain/image_adjustments.dart';
import 'package:presetstudio/features/presets/application/preset_adjustment_mapper.dart';
import 'package:presetstudio/features/presets/application/preset_library.dart';
import 'package:presetstudio/features/presets/application/preset_library_controller.dart';
import 'package:presetstudio/features/presets/infrastructure/local_preset_library_store.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('presetstudio-hsl-preset-');
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  test('saveCurrent persists HSL state across reload', () async {
    final mixer = HslColorMixer.initial.withAdjustment(
      HslColorRange.orange,
      HslColorAdjustment(hue: 14, saturation: 32, luminance: -9),
    );
    final controller = PresetLibraryController(
      idGenerator: () => 'hsl-local',
      libraryLoader: () async =>
          PresetLibrary(store: LocalPresetLibraryStore(rootDirectory: root)),
    );
    await controller.initialize();
    final saved = await controller.saveCurrent(
      name: 'HSL Look',
      adjustments: ImageAdjustments.initial,
      hslColorMixer: mixer,
    );
    expect(
      PresetAdjustmentMapper.toHslColorMixer(saved.preset.hslColorMixer),
      mixer,
    );

    final reloaded = PresetLibraryController(
      libraryLoader: () async =>
          PresetLibrary(store: LocalPresetLibraryStore(rootDirectory: root)),
    );
    await reloaded.initialize();
    expect(
      PresetAdjustmentMapper.toHslColorMixer(
        reloaded.records.single.preset.hslColorMixer,
      ),
      mixer,
    );
  });
}
