import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/editor/application/editor_controller.dart';
import 'package:presetstudio/features/editor/presentation/widgets/desktop_editor_shell.dart';
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
import 'package:presetstudio/features/presets/presentation/widgets/preset_bottom_tray.dart';
import 'package:presetstudio/theme/preset_studio_theme.dart';

void main() {
  testWidgets('remote tray preset applies on click and saves separately', (
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
      revision: 1,
      presetPath: 'presets/warm-film.presetstudio',
    );
    final preset = Preset(
      id: entry.id,
      name: entry.name,
      author: entry.author,
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
      gateway: _MemoryRemoteGateway(
        catalog: PresetCatalog(name: source.name, presets: [entry]),
        preset: preset,
      ),
    );
    final editor = EditorController()..setSourceImage('missing-test-image.jpg');

    addTearDown(library.dispose);
    addTearDown(remote.dispose);
    addTearDown(editor.dispose);

    await library.initialize();
    await remote.initialize();
    await remote.refresh();

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            height: 220,
            child: PresetBottomTray(
              libraryController: library,
              remoteController: remote,
              editorController: editor,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('preset-bottom-tray-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('preset-tray-remote-default-warm-film')),
      findsOneWidget,
    );
    expect(library.records, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('preset-tray-remote-default-warm-film')),
    );
    await tester.pump();
    await tester.pump();

    expect(editor.session.adjustments.temperature, 10);
    expect(editor.history.last.label, 'Preset: Warm Film');
    expect(library.records, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('preset-tray-save-default-warm-film')),
    );
    await tester.pump();
    await tester.pump();

    expect(library.records, hasLength(1));
    expect(
      library.records.single.origin.type,
      PresetOriginType.remoteInstalled,
    );
  });

  testWidgets('desktop mouse wheel scrolls the horizontal preset strip', (
    tester,
  ) async {
    final source = PresetRemoteSource(
      id: 'default',
      name: 'PresetStudio Presets',
      kind: PresetSourceKind.repository,
      location: 'https://github.com/jijinraj/presetstudio-presets',
    );
    final entries = List<PresetCatalogEntry>.generate(
      12,
      (index) => PresetCatalogEntry(
        id: 'preset-$index',
        name: 'Preset $index',
        author: 'Jijin',
        revision: 1,
        presetPath: 'presets/preset-$index.presetstudio',
      ),
    );
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
        preset: Preset(
          id: entries.first.id,
          name: entries.first.name,
          author: 'Jijin',
          createdAt: DateTime.utc(2026, 9, 25),
          adjustments: PresetAdjustmentValues.initial,
        ),
      ),
    );
    final editor = EditorController()..setSourceImage('missing-test-image.jpg');

    addTearDown(library.dispose);
    addTearDown(remote.dispose);
    addTearDown(editor.dispose);

    await library.initialize();
    await remote.initialize();
    await remote.refresh();

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 220,
            child: PresetBottomTray(
              libraryController: library,
              remoteController: remote,
              editorController: editor,
            ),
          ),
        ),
      ),
    );

    final list = find.byKey(const ValueKey('preset-bottom-tray-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );

    expect(scrollable, findsOneWidget);
    final state = tester.state<ScrollableState>(scrollable);
    expect(state.position.maxScrollExtent, greaterThan(0));

    final before = state.position.pixels;

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(list),
        scrollDelta: const Offset(0, 160),
      ),
    );
    await tester.pump();

    expect(state.position.pixels, greaterThan(before));
  });

  testWidgets('desktop presets live in a collapsible bottom tray', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final library = PresetLibraryController(
      libraryLoader: () async =>
          PresetLibrary(store: _MemoryPresetLibraryStore()),
    );
    final editor = EditorController();

    addTearDown(library.dispose);
    addTearDown(editor.dispose);

    await library.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: PresetStudioTheme.dark,
        home: DesktopEditorShell(
          controller: editor,
          presetLibraryController: library,
          onImportImage: () async {},
          isImporting: false,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('desktop-presets-tray')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('desktop-presets-tray-body')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('desktop-presets-body')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('desktop-presets-tray-toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('desktop-presets-tray-body')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('desktop-presets-tray-toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('desktop-presets-tray-body')),
      findsOneWidget,
    );
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
