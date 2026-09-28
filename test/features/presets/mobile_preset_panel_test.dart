import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_crop_preview.dart';
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
import 'package:presetstudio/features/presets/presentation/widgets/mobile_preset_panel.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('mobile preset panel uses real tags and applies remote presets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    fixture.editor.setSourceImage('missing-mobile-preset-panel-image.jpg');

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: MobilePresetPanel(
              libraryController: fixture.library,
              remoteController: fixture.remote,
              editorController: fixture.editor,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(
      find.byKey(const ValueKey('mobile-preset-category-all')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-preset-category-saved')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-preset-category-film')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-preset-original')),
      findsOneWidget,
    );
    expect(find.byType(EditorCropPreview), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('mobile-preset-remote-default-warm-film')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(fixture.editor.session.activePresetId, 'remote:default:warm-film');
    expect(fixture.editor.history.last.label, 'Preset: Warm Film');
  });

  testWidgets('mobile remote preset save remains explicit and appears saved', (
    tester,
  ) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    fixture.editor.setSourceImage('missing-mobile-preset-panel-image.jpg');

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: MobilePresetPanel(
              libraryController: fixture.library,
              remoteController: fixture.remote,
              editorController: fixture.editor,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(fixture.library.records, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('mobile-preset-save-default-warm-film')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final saved = fixture.library.remoteRecordFor(
      sourceId: 'default',
      remotePresetId: 'warm-film',
    );
    expect(saved, isNotNull);

    await tester.tap(
      find.byKey(const ValueKey('mobile-preset-category-saved')),
    );
    await tester.pump();

    expect(
      find.byKey(ValueKey('mobile-preset-local-${saved!.libraryId}')),
      findsOneWidget,
    );
  });
}

class _Fixture {
  _Fixture({required this.editor, required this.library, required this.remote});

  final EditorController editor;
  final PresetLibraryController library;
  final PresetRemoteController remote;

  static Future<_Fixture> create() async {
    final source = PresetRemoteSource(
      id: 'default',
      name: 'PresetStudio Presets',
      kind: PresetSourceKind.repository,
      location: 'https://github.com/jijinraj/presetstudio-presets',
    );
    final entries = <PresetCatalogEntry>[
      PresetCatalogEntry(
        id: 'warm-film',
        name: 'Warm Film',
        author: 'Jijin',
        tags: const ['film', 'warm'],
        revision: 1,
        presetPath: 'presets/warm-film.presetstudio',
      ),
      PresetCatalogEntry(
        id: 'mono-soft',
        name: 'Mono Soft',
        author: 'Jijin',
        tags: const ['b&w', 'soft'],
        revision: 1,
        presetPath: 'presets/mono-soft.presetstudio',
      ),
    ];
    final presets = <String, Preset>{
      'warm-film': Preset(
        id: 'warm-film',
        name: 'Warm Film',
        author: 'Jijin',
        createdAt: DateTime.utc(2026, 9, 25),
        adjustments: const PresetAdjustmentValues(temperature: 12),
      ),
      'mono-soft': Preset(
        id: 'mono-soft',
        name: 'Mono Soft',
        author: 'Jijin',
        createdAt: DateTime.utc(2026, 9, 25),
        adjustments: const PresetAdjustmentValues(saturation: -100),
      ),
    };
    final library = PresetLibraryController(
      libraryLoader: () async =>
          PresetLibrary(store: _MemoryPresetLibraryStore()),
    );
    final remote = PresetRemoteController(
      sourceStoreLoader: () async =>
          _MemorySourceStore(PresetSourceRegistry(sources: [source])),
      catalogCacheLoader: () async => _MemoryCatalogCache(),
      gateway: _MemoryRemoteGateway(
        catalog: PresetCatalog(name: source.name, presets: entries),
        presets: presets,
      ),
    );
    final editor = EditorController();

    await library.initialize();
    await remote.initialize();
    await remote.refresh();

    return _Fixture(editor: editor, library: library, remote: remote);
  }

  void dispose() {
    editor.dispose();
    library.dispose();
    remote.dispose();
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
  _MemoryRemoteGateway({required this.catalog, required this.presets});

  final PresetCatalog catalog;
  final Map<String, Preset> presets;

  @override
  Future<PresetCatalog> fetchCatalog(PresetRemoteSource source) async {
    return catalog;
  }

  @override
  Future<Preset> fetchPreset(
    PresetRemoteSource source,
    PresetCatalogEntry entry,
  ) async {
    return presets[entry.id]!;
  }
}
