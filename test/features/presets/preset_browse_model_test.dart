import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/application/preset_browse_model.dart';
import 'package:presetstudio/features/presets/application/preset_remote_controller.dart';
import 'package:presetstudio/features/presets/domain/preset.dart';
import 'package:presetstudio/features/presets/domain/preset_adjustment_values.dart';
import 'package:presetstudio/features/presets/domain/preset_catalog.dart';
import 'package:presetstudio/features/presets/domain/preset_record.dart';
import 'package:presetstudio/features/presets/domain/preset_source.dart';

void main() {
  final source = PresetRemoteSource(
    id: 'default',
    name: 'PresetStudio',
    kind: PresetSourceKind.repository,
    location: 'https://github.com/example/presets',
  );

  test(
    'composes local and remote presets without duplicating saved remotes',
    () {
      final local = _localRecord('local-one', 'Local One');
      final savedRemote = _remoteRecord(
        sourceId: source.id,
        presetId: 'warm-film',
        name: 'Warm Film',
        revision: 2,
      );
      final remoteItems = [
        _remoteItem(
          source: source,
          id: 'warm-film',
          name: 'Warm Film',
          revision: 2,
          tags: const ['film', 'warm'],
        ),
        _remoteItem(
          source: source,
          id: 'clean',
          name: 'Clean',
          revision: 1,
          tags: const ['clean'],
        ),
      ];

      final snapshot = PresetBrowseSnapshot(
        records: [local, savedRemote],
        remoteItems: remoteItems,
      );

      expect(snapshot.all, hasLength(3));
      expect(snapshot.saved, hasLength(2));
      expect(snapshot.discover, hasLength(2));

      final warm = snapshot.remoteItemFor(
        sourceId: source.id,
        remotePresetId: 'warm-film',
      );
      expect(warm, isNotNull);
      expect(warm!.state, PresetBrowseItemState.remoteSaved);
      expect(warm.isSaved, isTrue);
      expect(
        snapshot.all.where((item) => item.name == 'Warm Film'),
        hasLength(1),
      );
    },
  );

  test('distinguishes remote updates from current saved presets', () {
    final savedRemote = _remoteRecord(
      sourceId: source.id,
      presetId: 'warm-film',
      name: 'Warm Film',
      revision: 1,
    );
    final snapshot = PresetBrowseSnapshot(
      records: [savedRemote],
      remoteItems: [
        _remoteItem(
          source: source,
          id: 'warm-film',
          name: 'Warm Film',
          revision: 3,
        ),
      ],
    );

    final item = snapshot.discover.single;
    expect(item.state, PresetBrowseItemState.remoteUpdateAvailable);
    expect(item.isSaved, isTrue);
    expect(item.hasUpdate, isTrue);
  });

  test('keeps saved remote presets available when catalog item is absent', () {
    final savedRemote = _remoteRecord(
      sourceId: source.id,
      presetId: 'offline',
      name: 'Offline',
      revision: 1,
    );

    final snapshot = PresetBrowseSnapshot(
      records: [savedRemote],
      remoteItems: const [],
    );

    expect(snapshot.all, hasLength(1));
    expect(snapshot.saved, hasLength(1));
    expect(snapshot.discover, isEmpty);
    expect(snapshot.all.single.name, 'Offline');
    expect(snapshot.all.single.isSaved, isTrue);
  });

  test('builds normalized categories from catalog tags', () {
    final snapshot = PresetBrowseSnapshot(
      records: [_localRecord('local-one', 'Local One')],
      remoteItems: [
        _remoteItem(
          source: source,
          id: 'one',
          name: 'One',
          revision: 1,
          tags: const ['film look', 'Warm'],
        ),
        _remoteItem(
          source: source,
          id: 'two',
          name: 'Two',
          revision: 1,
          tags: const ['FILM LOOK', 'clean-tone'],
        ),
      ],
    );

    expect(snapshot.categories.take(3), [
      const PresetBrowseCategory(key: 'all', label: 'All', count: 3),
      const PresetBrowseCategory(key: 'saved', label: 'Saved', count: 1),
      const PresetBrowseCategory(
        key: 'film-look',
        label: 'Film Look',
        count: 2,
      ),
    ]);
    expect(
      snapshot.categories.map((category) => category.key),
      containsAll(<String>['warm', 'clean-tone']),
    );
  });

  test('marks unsaved catalog entries as remotely available', () {
    final snapshot = PresetBrowseSnapshot(
      records: const [],
      remoteItems: [
        _remoteItem(
          source: source,
          id: 'available',
          name: 'Available',
          revision: 1,
        ),
      ],
    );

    expect(
      snapshot.discover.single.state,
      PresetBrowseItemState.remoteAvailable,
    );
    expect(snapshot.discover.single.isSaved, isFalse);
  });
}

PresetRecord _localRecord(String id, String name) {
  final createdAt = DateTime.utc(2026, 9, 30);
  return PresetRecord(
    libraryId: PresetRecord.localLibraryId(id),
    preset: Preset(
      id: id,
      name: name,
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
  List<String> tags = const [],
}) {
  final entry = PresetCatalogEntry(
    id: id,
    name: name,
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
