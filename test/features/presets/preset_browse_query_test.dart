import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/application/preset_browse_model.dart';
import 'package:presetstudio/features/presets/application/preset_browse_query.dart';
import 'package:presetstudio/features/presets/application/preset_remote_controller.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_catalog.dart';
import 'package:presetstudio/features/presets/domain/preset_record.dart';
import 'package:presetstudio/features/presets/domain/preset_source.dart';

void main() {
  final source = PresetRemoteSource(
    id: 'default',
    name: 'PresetStudio Community',
    kind: PresetSourceKind.repository,
    location: 'https://github.com/example/presets',
  );

  test('empty query returns the complete All collection', () {
    final snapshot = _snapshot(source);

    final result = const PresetBrowseQuery().apply(snapshot);

    expect(result.map((item) => item.name), [
      'My Portrait',
      'Warm Film',
      'Cool Clean',
    ]);
  });

  test('search matches name author description source and tags', () {
    final snapshot = _snapshot(source);

    expect(
      const PresetBrowseQuery(searchText: 'warm film').apply(snapshot),
      hasLength(1),
    );
    expect(
      const PresetBrowseQuery(searchText: 'maya').apply(snapshot).single.name,
      'Warm Film',
    );
    expect(
      const PresetBrowseQuery(searchText: 'soft skin')
          .apply(snapshot)
          .single
          .name,
      'Warm Film',
    );
    expect(
      const PresetBrowseQuery(searchText: 'community clean')
          .apply(snapshot)
          .single
          .name,
      'Cool Clean',
    );
  });

  test('search matches local preset metadata', () {
    final snapshot = _snapshot(source);

    final result = const PresetBrowseQuery(searchText: 'portrait jijin')
        .apply(snapshot);

    expect(result.single.name, 'My Portrait');
  });

  test('category filtering uses normalized remote tags', () {
    final snapshot = _snapshot(source);

    final result = const PresetBrowseQuery(categoryKey: 'FILM LOOK')
        .apply(snapshot);

    expect(result.map((item) => item.name), ['Warm Film']);
  });

  test('Saved category returns local and installed remote presets only', () {
    final snapshot = _snapshot(source);

    final result = const PresetBrowseQuery(
      categoryKey: PresetBrowseCategory.savedKey,
    ).apply(snapshot);

    expect(result.map((item) => item.name), ['My Portrait', 'Warm Film']);
  });

  test('search and category filters compose', () {
    final snapshot = _snapshot(source);

    final result = const PresetBrowseQuery(
      searchText: 'warm',
      categoryKey: 'film-look',
    ).apply(snapshot);

    expect(result.single.name, 'Warm Film');
    expect(
      const PresetBrowseQuery(
        searchText: 'clean',
        categoryKey: 'film-look',
      ).apply(snapshot),
      isEmpty,
    );
  });

  test('copyWith preserves unspecified query fields', () {
    const query = PresetBrowseQuery(
      searchText: 'warm',
      categoryKey: 'film-look',
    );

    expect(query.copyWith(searchText: 'clean').searchText, 'clean');
    expect(query.copyWith(searchText: 'clean').categoryKey, 'film-look');
    expect(query.copyWith(categoryKey: 'saved').searchText, 'warm');
    expect(query.copyWith(categoryKey: 'saved').categoryKey, 'saved');
  });
}

PresetBrowseSnapshot _snapshot(PresetRemoteSource source) {
  final savedRemote = _remoteRecord(
    sourceId: source.id,
    presetId: 'warm-film',
    name: 'Warm Film',
    revision: 2,
  );

  return PresetBrowseSnapshot(
    records: [
      _localRecord(
        'my-portrait',
        'My Portrait',
        author: 'Jijin',
        description: 'Natural portrait preset',
      ),
      savedRemote,
    ],
    remoteItems: [
      _remoteItem(
        source: source,
        id: 'warm-film',
        name: 'Warm Film',
        author: 'Maya',
        description: 'Soft skin and warm highlights',
        revision: 2,
        tags: const ['Film Look', 'Warm'],
      ),
      _remoteItem(
        source: source,
        id: 'cool-clean',
        name: 'Cool Clean',
        author: 'Alex',
        description: 'Crisp modern finish',
        revision: 1,
        tags: const ['Clean', 'Cool'],
      ),
    ],
  );
}

PresetRecord _localRecord(
  String id,
  String name, {
  String? author,
  String? description,
}) {
  final createdAt = DateTime.utc(2026, 9, 30);
  return PresetRecord(
    libraryId: PresetRecord.localLibraryId(id),
    preset: Preset(
      id: id,
      name: name,
      author: author,
      description: description,
      createdAt: createdAt,
      adjustments: const PresetAdjustmentValues(),
    ),
    origin: PresetOrigin.local(),
    installedAt: createdAt,
    updatedAt: createdAt,
  );
}

PresetRecord _remoteRecord({
  required String sourceId,
  required String presetId,
  required String name,
  required int revision,
}) {
  final createdAt = DateTime.utc(2026, 9, 30);
  return PresetRecord(
    libraryId: PresetRecord.remoteLibraryId(
      sourceId: sourceId,
      remotePresetId: presetId,
    ),
    preset: Preset(
      id: presetId,
      name: name,
      createdAt: createdAt,
      revision: revision,
      adjustments: const PresetAdjustmentValues(),
    ),
    origin: PresetOrigin.remoteInstalled(
      sourceId: sourceId,
      remotePresetId: presetId,
      remoteRevision: revision,
    ),
    installedAt: createdAt,
    updatedAt: createdAt,
  );
}

RemotePresetCatalogItem _remoteItem({
  required PresetRemoteSource source,
  required String id,
  required String name,
  required int revision,
  String? author,
  String? description,
  List<String> tags = const [],
}) {
  final entry = PresetCatalogEntry(
    id: id,
    name: name,
    author: author,
    description: description,
    tags: tags,
    revision: revision,
    presetPath: 'presets/$id.presetstudio',
  );

  return RemotePresetCatalogItem(
    source: source,
    catalog: PresetCatalog(name: source.name, presets: [entry]),
    entry: entry,
  );
}
