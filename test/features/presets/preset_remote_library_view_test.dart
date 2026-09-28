import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/presets/application/preset_catalog_cache.dart';
import 'package:presetstudio/features/presets/application/preset_library.dart';
import 'package:presetstudio/features/presets/application/preset_library_controller.dart';
import 'package:presetstudio/features/presets/application/preset_library_store.dart';
import 'package:presetstudio/features/presets/application/preset_remote_controller.dart';
import 'package:presetstudio/features/presets/application/preset_remote_gateway.dart';
import 'package:presetstudio/features/presets/application/preset_source_store.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_catalog.dart';
import 'package:presetstudio/features/presets/domain/preset_record.dart';
import 'package:presetstudio/features/presets/domain/preset_source.dart';
import 'package:presetstudio/features/presets/presentation/widgets/preset_library_view.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('discover preset applies on click and saves only on request', (
    tester,
  ) async {
    final source = PresetRemoteSource(
      id: 'default',
      name: 'PresetStudio Presets',
      kind: PresetSourceKind.repository,
      location: 'https://github.com/jijinraj/presetstudio-presets',
    );
    final entry = PresetCatalogEntry(
      id: 'warm-film',
      name: 'Warm Film',
      author: 'Jijin',
      description: 'Warm film-inspired tones with softened highlights.',
      tags: const ['film', 'warm', 'portrait'],
      revision: 1,
      presetPath: 'presets/warm-film.presetstudio',
      previewPath: 'previews/warm-film.webp',
    );
    final catalog = PresetCatalog(
      name: 'PresetStudio Presets',
      presets: [entry],
    );
    final preset = Preset(
      id: entry.id,
      name: entry.name,
      author: 'Jijin',
      createdAt: DateTime.utc(2026, 9, 25),
      adjustments: const PresetAdjustmentValues(temperature: 10),
    );
    final library = PresetLibraryController(
      libraryLoader: () async =>
          PresetLibrary(store: _MemoryPresetLibraryStore()),
    );
    final remote = PresetRemoteController(
      sourceStoreLoader: () async =>
          _MemorySourceStore(PresetSourceRegistry(sources: [source])),
      catalogCacheLoader: () async => _MemoryCatalogCache(),
      gateway: _MemoryRemoteGateway(catalog: catalog, preset: preset),
    );
    final editor = EditorController()..setSourceImage('missing-test-image.jpg');

    await library.initialize();
    await remote.initialize();
    await remote.refresh();

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 620,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PresetLibraryView(
                libraryController: library,
                remoteController: remote,
                editorController: editor,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Warm Film'), findsOneWidget);
    expect(
      find.text('Warm film-inspired tones with softened highlights.'),
      findsOneWidget,
    );
    expect(find.text('film · warm · portrait'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('preset-remote-default-warm-film')),
    );
    await tester.pump();
    await tester.pump();

    expect(editor.session.adjustments.temperature, 10);
    expect(editor.history.last.label, 'Preset: Warm Film');
    expect(library.records, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('preset-remote-save-default-warm-film')),
    );
    await tester.pump();
    await tester.pump();

    expect(library.records, hasLength(1));
    expect(
      library.records.single.origin.type,
      PresetOriginType.remoteInstalled,
    );
    expect(find.text('Saved'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    library.dispose();
    remote.dispose();
    editor.dispose();
  });
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

class _MemorySourceStore implements PresetSourceStore {
  _MemorySourceStore(this.registry);

  PresetSourceRegistry registry;

  @override
  Future<PresetSourceRegistry?> loadRegistry() async => registry;

  @override
  Future<void> saveRegistry(PresetSourceRegistry registry) async {
    this.registry = registry;
  }
}

class _MemoryCatalogCache implements PresetCatalogCache {
  @override
  Future<PresetCatalog?> load(String sourceId) async => null;

  @override
  Future<void> save(String sourceId, PresetCatalog catalog) async {}

  @override
  Future<void> remove(String sourceId) async {}
}

class _MemoryRemoteGateway implements PresetRemoteGateway {
  _MemoryRemoteGateway({required this.catalog, required this.preset});

  final PresetCatalog catalog;
  final Preset preset;

  @override
  Future<PresetCatalog> fetchCatalog(PresetRemoteSource source) async {
    return catalog;
  }

  @override
  Future<Preset> fetchPreset(
    PresetRemoteSource source,
    PresetCatalogEntry entry,
  ) async {
    return preset;
  }
}
