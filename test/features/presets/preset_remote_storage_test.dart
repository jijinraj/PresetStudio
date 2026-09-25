import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/domain/preset_catalog.dart';
import 'package:presetstudio/features/presets/domain/preset_source.dart';
import 'package:presetstudio/features/presets/infrastructure/local_preset_catalog_cache.dart';
import 'package:presetstudio/features/presets/infrastructure/local_preset_source_store.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'presetstudio-remote-preset-storage-test-',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('source registry persists multiple sources and enable state', () async {
    final store = LocalPresetSourceStore(
      file: File('${tempDirectory.path}${Platform.pathSeparator}sources.json'),
    );
    final registry = PresetSourceRegistry(
      sources: [
        PresetRemoteSource(
          id: 'repo',
          name: 'Repo',
          kind: PresetSourceKind.repository,
          location: 'https://github.com/example/repo',
        ),
        PresetRemoteSource(
          id: 'catalog',
          name: 'Catalog',
          kind: PresetSourceKind.catalog,
          location: 'https://example.com/catalog.json',
          enabled: false,
        ),
      ],
    );

    expect(await store.loadRegistry(), isNull);

    await store.saveRegistry(registry);
    final loaded = await store.loadRegistry();

    expect(loaded, isNotNull);
    expect(loaded!.sources, hasLength(2));
    expect(loaded.sourceById('repo')?.enabled, isTrue);
    expect(loaded.sourceById('catalog')?.enabled, isFalse);
    expect(loaded.sourceById('catalog')?.kind, PresetSourceKind.catalog);
  });

  test('catalog cache survives reload and can be removed', () async {
    final cache = LocalPresetCatalogCache(
      directory: Directory(
        '${tempDirectory.path}${Platform.pathSeparator}cache',
      ),
    );
    final catalog = PresetCatalog(
      name: 'Cached',
      presets: [
        PresetCatalogEntry(
          id: 'one',
          name: 'One',
          revision: 1,
          presetPath: 'presets/one.presetstudio',
        ),
      ],
    );

    expect(await cache.load('source-a'), isNull);

    await cache.save('source-a', catalog);

    final loaded = await cache.load('source-a');
    expect(loaded?.name, 'Cached');
    expect(loaded?.presets.single.id, 'one');

    await cache.remove('source-a');

    expect(await cache.load('source-a'), isNull);
  });
}
