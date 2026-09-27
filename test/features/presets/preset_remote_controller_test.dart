import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/application/preset_catalog_cache.dart';
import 'package:presetstudio/features/presets/application/preset_library.dart';
import 'package:presetstudio/features/presets/application/preset_library_controller.dart';
import 'package:presetstudio/features/presets/application/preset_library_store.dart';
import 'package:presetstudio/features/presets/application/preset_preview_cache.dart';
import 'package:presetstudio/features/presets/application/preset_remote_controller.dart';
import 'package:presetstudio/features/presets/application/preset_remote_gateway.dart';
import 'package:presetstudio/features/presets/application/preset_source_store.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_catalog.dart';
import 'package:presetstudio/features/presets/domain/preset_record.dart';
import 'package:presetstudio/features/presets/domain/preset_source.dart';

void main() {
  test(
    'seeds default sources once and loads cached catalogs offline',
    () async {
      final source = PresetRemoteSource(
        id: 'default',
        name: 'Default',
        kind: PresetSourceKind.repository,
        location: 'https://github.com/example/presets',
      );
      final cached = PresetCatalog(
        name: 'Cached',
        presets: [
          PresetCatalogEntry(
            id: 'cached-one',
            name: 'Cached One',
            revision: 1,
            presetPath: 'presets/cached-one.presetstudio',
          ),
        ],
      );
      final sourceStore = _MemorySourceStore();
      final cache = _MemoryCatalogCache()..catalogs[source.id] = cached;
      final controller = PresetRemoteController(
        sourceStoreLoader: () async => sourceStore,
        catalogCacheLoader: () async => cache,
        gateway: _FakeRemoteGateway(),
        defaultSources: [source],
      );

      await controller.initialize();

      expect(controller.isInitialized, isTrue);
      expect(sourceStore.registry?.sources, hasLength(1));
      expect(sourceStore.saveCount, 1);
      expect(controller.items, hasLength(1));
      expect(controller.items.single.entry.name, 'Cached One');

      final restarted = PresetRemoteController(
        sourceStoreLoader: () async => sourceStore,
        catalogCacheLoader: () async => cache,
        gateway: _FakeRemoteGateway(),
        defaultSources: const [],
      );

      await restarted.initialize();

      expect(sourceStore.saveCount, 1);
      expect(restarted.items.single.entry.id, 'cached-one');
    },
  );

  test(
    'refresh updates cache and keeps cached catalog after network failure',
    () async {
      final source = PresetRemoteSource(
        id: 'source',
        name: 'Source',
        kind: PresetSourceKind.catalog,
        location: 'https://example.com/catalog.json',
      );
      final sourceStore = _MemorySourceStore(
        registry: PresetSourceRegistry(sources: [source]),
      );
      final oldCatalog = PresetCatalog(
        name: 'Old',
        presets: [
          PresetCatalogEntry(
            id: 'old',
            name: 'Old',
            revision: 1,
            presetPath: 'presets/old.presetstudio',
          ),
        ],
      );
      final newCatalog = PresetCatalog(
        name: 'New',
        presets: [
          PresetCatalogEntry(
            id: 'new',
            name: 'New',
            revision: 1,
            presetPath: 'presets/new.presetstudio',
          ),
        ],
      );
      final cache = _MemoryCatalogCache()..catalogs[source.id] = oldCatalog;
      final gateway = _FakeRemoteGateway()..catalogs[source.id] = newCatalog;
      final controller = PresetRemoteController(
        sourceStoreLoader: () async => sourceStore,
        catalogCacheLoader: () async => cache,
        gateway: gateway,
      );

      await controller.initialize();
      expect(controller.items.single.entry.id, 'old');

      await controller.refresh();

      expect(controller.items.single.entry.id, 'new');
      expect(cache.catalogs[source.id], same(newCatalog));

      gateway.failCatalogs = true;
      await controller.refresh();

      expect(controller.items.single.entry.id, 'new');
      expect(controller.sourceErrors[source.id], isNotNull);
    },
  );

  test(
    'install validates catalog identity and records remote provenance',
    () async {
      final source = PresetRemoteSource(
        id: 'repo-a',
        name: 'Repo A',
        kind: PresetSourceKind.repository,
        location: 'https://github.com/example/repo-a',
      );
      final entry = PresetCatalogEntry(
        id: 'warm-film',
        name: 'Warm Film',
        revision: 3,
        presetPath: 'presets/warm-film.presetstudio',
      );
      final catalog = PresetCatalog(name: 'Repo A', presets: [entry]);
      final preset = Preset(
        id: 'warm-film',
        name: 'Warm Film',
        createdAt: DateTime.utc(2026, 9, 25),
        revision: 3,
        adjustments: const PresetAdjustmentValues(contrast: 12),
      );
      final sourceStore = _MemorySourceStore(
        registry: PresetSourceRegistry(sources: [source]),
      );
      final gateway = _FakeRemoteGateway()
        ..catalogs[source.id] = catalog
        ..presets['${source.id}:${entry.id}'] = preset;
      final remote = PresetRemoteController(
        sourceStoreLoader: () async => sourceStore,
        catalogCacheLoader: () async => _MemoryCatalogCache(),
        gateway: gateway,
      );
      final libraryStore = _MemoryPresetLibraryStore();
      final library = PresetLibraryController(
        libraryLoader: () async => PresetLibrary(store: libraryStore),
      );

      await remote.initialize();
      await remote.refresh();
      await library.initialize();

      final record = await remote.install(
        remote.items.single,
        libraryController: library,
      );

      expect(record.origin.type, PresetOriginType.remoteInstalled);
      expect(record.origin.sourceId, source.id);
      expect(record.origin.remotePresetId, entry.id);
      expect(record.origin.remoteRevision, 3);
      expect(
        library
            .remoteRecordFor(sourceId: source.id, remotePresetId: entry.id)
            ?.libraryId,
        record.libraryId,
      );
    },
  );

  test(
    'rejects a downloaded preset that disagrees with catalog metadata',
    () async {
      final source = PresetRemoteSource(
        id: 'repo',
        name: 'Repo',
        kind: PresetSourceKind.repository,
        location: 'https://github.com/example/repo',
      );
      final entry = PresetCatalogEntry(
        id: 'catalog-id',
        name: 'Catalog preset',
        revision: 1,
        presetPath: 'presets/preset.presetstudio',
      );
      final gateway = _FakeRemoteGateway()
        ..catalogs[source.id] = PresetCatalog(name: 'Repo', presets: [entry])
        ..presets['${source.id}:${entry.id}'] = Preset(
          id: 'different-id',
          name: 'Wrong',
          createdAt: DateTime.utc(2026, 9, 25),
          revision: 1,
          adjustments: const PresetAdjustmentValues(),
        );
      final remote = PresetRemoteController(
        sourceStoreLoader: () async => _MemorySourceStore(
          registry: PresetSourceRegistry(sources: [source]),
        ),
        catalogCacheLoader: () async => _MemoryCatalogCache(),
        gateway: gateway,
      );
      final library = PresetLibraryController(
        libraryLoader: () async =>
            PresetLibrary(store: _MemoryPresetLibraryStore()),
      );

      await remote.initialize();
      await remote.refresh();
      await library.initialize();

      expect(
        () => remote.install(remote.items.single, libraryController: library),
        throwsA(isA<PresetRemoteException>()),
      );
    },
  );

  test(
    'remote previews load lazily, cache locally, and work offline',
    () async {
      final source = PresetRemoteSource(
        id: 'preview-source',
        name: 'Preview source',
        kind: PresetSourceKind.repository,
        location: 'https://github.com/example/previews',
      );
      final entry = PresetCatalogEntry(
        id: 'warm-film',
        name: 'Warm Film',
        revision: 2,
        presetPath: 'presets/warm-film.presetstudio',
        previewPath: 'previews/warm-film.webp',
      );
      final catalog = PresetCatalog(name: 'Preview source', presets: [entry]);
      final sourceStore = _MemorySourceStore(
        registry: PresetSourceRegistry(sources: [source]),
      );
      final cache = _MemoryPreviewCache();
      final gateway = _FakeRemoteGateway()
        ..catalogs[source.id] = catalog
        ..previews['${source.id}:${entry.id}'] = Uint8List.fromList(const [
          1,
          2,
          3,
          4,
        ]);
      final controller = PresetRemoteController(
        sourceStoreLoader: () async => sourceStore,
        catalogCacheLoader: () async => _MemoryCatalogCache(),
        previewCacheLoader: () async => cache,
        gateway: gateway,
      );

      await controller.initialize();
      await controller.refresh();

      final item = controller.items.single;
      final first = await controller.previewFor(item);

      expect(first, [1, 2, 3, 4]);
      expect(gateway.previewFetchCount, 1);

      final cached = await cache.load(
        sourceId: source.id,
        presetId: entry.id,
        revision: entry.revision,
      );
      expect(cached, [1, 2, 3, 4]);

      gateway.failPreviews = true;
      await controller.refresh();
      final offline = await controller.previewFor(controller.items.single);

      expect(offline, [1, 2, 3, 4]);
      expect(gateway.previewFetchCount, 1);
    },
  );

  test('live preview fetches preset data and install reuses it', () async {
    final source = PresetRemoteSource(
      id: 'live-source',
      name: 'Live source',
      kind: PresetSourceKind.repository,
      location: 'https://github.com/example/live-presets',
    );
    final entry = PresetCatalogEntry(
      id: 'warm-film',
      name: 'Warm Film',
      revision: 1,
      presetPath: 'presets/warm-film.presetstudio',
    );
    final preset = Preset(
      id: entry.id,
      name: entry.name,
      createdAt: DateTime.utc(2026, 9, 25),
      revision: entry.revision,
      adjustments: const PresetAdjustmentValues(temperature: 12),
    );
    final gateway = _FakeRemoteGateway()
      ..catalogs[source.id] = PresetCatalog(name: source.name, presets: [entry])
      ..presets['${source.id}:${entry.id}'] = preset;
    final remote = PresetRemoteController(
      sourceStoreLoader: () async =>
          _MemorySourceStore(registry: PresetSourceRegistry(sources: [source])),
      catalogCacheLoader: () async => _MemoryCatalogCache(),
      gateway: gateway,
    );
    final library = PresetLibraryController(
      libraryLoader: () async =>
          PresetLibrary(store: _MemoryPresetLibraryStore()),
    );

    await remote.initialize();
    await remote.refresh();
    await library.initialize();

    final item = remote.items.single;
    final previewPreset = await remote.presetForPreview(item);

    expect(previewPreset, same(preset));
    expect(gateway.presetFetchCount, 1);

    await remote.install(item, libraryController: library);

    expect(gateway.presetFetchCount, 1);
    expect(library.records, hasLength(1));
  });
}

class _MemorySourceStore implements PresetSourceStore {
  _MemorySourceStore({this.registry});

  PresetSourceRegistry? registry;
  int saveCount = 0;

  @override
  Future<PresetSourceRegistry?> loadRegistry() async => registry;

  @override
  Future<void> saveRegistry(PresetSourceRegistry registry) async {
    this.registry = registry;
    saveCount++;
  }
}

class _MemoryCatalogCache implements PresetCatalogCache {
  final Map<String, PresetCatalog> catalogs = <String, PresetCatalog>{};

  @override
  Future<PresetCatalog?> load(String sourceId) async => catalogs[sourceId];

  @override
  Future<void> save(String sourceId, PresetCatalog catalog) async {
    catalogs[sourceId] = catalog;
  }

  @override
  Future<void> remove(String sourceId) async {
    catalogs.remove(sourceId);
  }
}

class _FakeRemoteGateway
    implements PresetRemoteGateway, PresetRemotePreviewGateway {
  final Map<String, PresetCatalog> catalogs = <String, PresetCatalog>{};
  final Map<String, Preset> presets = <String, Preset>{};
  final Map<String, Uint8List> previews = <String, Uint8List>{};
  bool failCatalogs = false;
  bool failPreviews = false;
  int previewFetchCount = 0;
  int presetFetchCount = 0;

  @override
  Future<PresetCatalog> fetchCatalog(PresetRemoteSource source) async {
    if (failCatalogs) {
      throw const PresetRemoteException('offline');
    }

    final catalog = catalogs[source.id];

    if (catalog == null) {
      throw PresetRemoteException('No catalog for ${source.id}.');
    }

    return catalog;
  }

  @override
  Future<Preset> fetchPreset(
    PresetRemoteSource source,
    PresetCatalogEntry entry,
  ) async {
    presetFetchCount++;
    final preset = presets['${source.id}:${entry.id}'];

    if (preset == null) {
      throw PresetRemoteException('No preset for ${entry.id}.');
    }

    return preset;
  }

  @override
  Future<Uint8List> fetchPreview(
    PresetRemoteSource source,
    PresetCatalogEntry entry,
  ) async {
    if (failPreviews) {
      throw const PresetRemoteException('offline');
    }

    final preview = previews['${source.id}:${entry.id}'];

    if (preview == null) {
      throw PresetRemoteException('No preview for ${entry.id}.');
    }

    previewFetchCount++;
    return preview;
  }
}

class _MemoryPreviewCache implements PresetPreviewCache {
  final Map<String, Uint8List> previews = <String, Uint8List>{};

  String _key(String sourceId, String presetId, int revision) {
    return '$sourceId:$presetId:$revision';
  }

  @override
  Future<Uint8List?> load({
    required String sourceId,
    required String presetId,
    required int revision,
  }) async {
    return previews[_key(sourceId, presetId, revision)];
  }

  @override
  Future<void> save({
    required String sourceId,
    required String presetId,
    required int revision,
    required Uint8List bytes,
  }) async {
    previews[_key(sourceId, presetId, revision)] = bytes;
  }

  @override
  Future<void> removeSource(String sourceId) async {
    previews.removeWhere((key, _) => key.startsWith('$sourceId:'));
  }
}

class _MemoryPresetLibraryStore implements PresetLibraryStore {
  final Map<String, PresetRecord> records = <String, PresetRecord>{};

  @override
  Future<List<PresetRecord>> loadRecords() async {
    return List<PresetRecord>.unmodifiable(records.values);
  }

  @override
  Future<void> upsertRecord(PresetRecord record) async {
    records[record.libraryId] = record;
  }

  @override
  Future<void> deleteRecord(String libraryId) async {
    records.remove(libraryId);
  }
}
