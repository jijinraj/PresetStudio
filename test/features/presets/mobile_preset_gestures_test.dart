import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/editor_image_viewport.dart';
import 'package:presetstudio/features/editor/presentation/widgets/mobile_editor_shell.dart';
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
import 'package:presetstudio/theme/preset_studio_theme.dart';
import 'package:presetstudio/theme/tokens/app_radii.dart';

void main() {
  testWidgets('new mobile image gets a random preset and swipes keep a trail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: MobileEditorShell(
          controller: fixture.editor,
          presetLibraryController: fixture.library,
          presetRemoteController: fixture.remote,
          onImportImage: () async {},
          isImporting: false,
          onExportImage: () async {},
        ),
      ),
    );

    fixture.editor.setSourceImage('missing-mobile-image.jpg');
    await tester.pump();
    await tester.pump();

    final initialPresetId = fixture.editor.session.activePresetId;

    expect(initialPresetId, isNotNull);
    expect(fixture.editor.history, hasLength(2));
    expect(fixture.editor.history.last.label, startsWith('Preset: '));

    final viewport = tester.widget<EditorImageViewport>(
      find.byType(EditorImageViewport),
    );
    expect(viewport.contentPadding, EdgeInsets.zero);
    expect(viewport.imageFit, BoxFit.contain);
    expect(
      viewport.imageBorderRadius,
      BorderRadius.circular(AppRadii.editorImage),
    );

    final surface = find.byKey(
      const ValueKey('editor-viewport-pointer-surface'),
    );

    await tester.drag(surface, const Offset(-140, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final secondPresetId = fixture.editor.session.activePresetId;
    expect(secondPresetId, isNot(initialPresetId));
    expect(fixture.editor.history.last.label, startsWith('Preset: '));

    await tester.drag(surface, const Offset(140, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fixture.editor.session.activePresetId, initialPresetId);
    expect(
      find.byKey(const ValueKey('mobile-active-filter-label')),
      findsOneWidget,
    );
  });

  testWidgets('tapping mobile image offers save image and save filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    var exportCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: MobileEditorShell(
          controller: fixture.editor,
          presetLibraryController: fixture.library,
          presetRemoteController: fixture.remote,
          onImportImage: () async {},
          isImporting: false,
          onExportImage: () async {
            exportCount += 1;
          },
        ),
      ),
    );

    fixture.editor.setSourceImage('missing-mobile-image.jpg');
    await tester.pump();
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('editor-viewport-gesture-surface')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mobile-image-action-save-image')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mobile-image-action-save-filter')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('mobile-image-action-save-filter')),
    );
    await tester.pump();
    await tester.pump();

    expect(fixture.library.records, hasLength(1));
    expect(
      fixture.library.records.single.origin.type,
      PresetOriginType.remoteInstalled,
    );

    await tester.tap(
      find.byKey(const ValueKey('editor-viewport-gesture-surface')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('mobile-image-action-save-image')),
    );
    await tester.pump();

    expect(exportCount, 1);
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
        revision: 1,
        presetPath: 'presets/warm-film.presetstudio',
      ),
      PresetCatalogEntry(
        id: 'cool-film',
        name: 'Cool Film',
        author: 'Jijin',
        revision: 1,
        presetPath: 'presets/cool-film.presetstudio',
      ),
      PresetCatalogEntry(
        id: 'mono-soft',
        name: 'Mono Soft',
        author: 'Jijin',
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
        adjustments: const PresetAdjustmentValues(temperature: 10),
      ),
      'cool-film': Preset(
        id: 'cool-film',
        name: 'Cool Film',
        author: 'Jijin',
        createdAt: DateTime.utc(2026, 9, 25),
        adjustments: const PresetAdjustmentValues(temperature: -10),
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
