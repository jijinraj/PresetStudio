import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/application/preset_browse_model.dart';
import 'package:presetstudio/features/presets/application/preset_favorite_store.dart';
import 'package:presetstudio/features/presets/application/preset_favorites_controller.dart';
import 'package:presetstudio/features/presets/application/preset_remote_controller.dart';
import 'package:presetstudio/features/presets/domain/preset_catalog.dart';
import 'package:presetstudio/features/presets/domain/preset_source.dart';

void main() {
  test('loads persisted favorite identities', () async {
    final store = _MemoryFavoriteStore({'remote:default:warm-film'});
    final controller = PresetFavoritesController(
      storeLoader: () async => store,
    );

    await controller.initialize();

    expect(controller.isInitialized, isTrue);
    expect(controller.isFavorite(_remoteItem()), isTrue);
  });

  test(
    'favoriting remote preset persists identity without installing it',
    () async {
      final store = _MemoryFavoriteStore();
      final controller = PresetFavoritesController(
        storeLoader: () async => store,
      );
      await controller.initialize();
      final item = _remoteItem();

      await controller.setFavorite(item, favorite: true);

      expect(controller.isFavorite(item), isTrue);
      expect(store.ids, {'remote:default:warm-film'});
      expect(item.isSaved, isFalse);
    },
  );

  test('toggle removes an existing favorite', () async {
    final store = _MemoryFavoriteStore({'remote:default:warm-film'});
    final controller = PresetFavoritesController(
      storeLoader: () async => store,
    );
    await controller.initialize();
    final item = _remoteItem();

    final result = await controller.toggle(item);

    expect(result, isFalse);
    expect(controller.isFavorite(item), isFalse);
    expect(store.ids, isEmpty);
  });

  test('failed persistence does not mutate favorite state', () async {
    final store = _MemoryFavoriteStore()..failSaves = true;
    final controller = PresetFavoritesController(
      storeLoader: () async => store,
    );
    await controller.initialize();
    final item = _remoteItem();

    await expectLater(
      controller.setFavorite(item, favorite: true),
      throwsA(isA<StateError>()),
    );

    expect(controller.isFavorite(item), isFalse);
    expect(controller.errorMessage, isNotNull);
  });

  test('mutation before initialization is rejected', () async {
    final controller = PresetFavoritesController(
      storeLoader: () async => _MemoryFavoriteStore(),
    );

    await expectLater(
      controller.setFavorite(_remoteItem(), favorite: true),
      throwsA(isA<PresetFavoritesException>()),
    );
  });
}

PresetBrowseItem _remoteItem() {
  final source = PresetRemoteSource(
    id: 'default',
    name: 'PresetStudio',
    kind: PresetSourceKind.repository,
    location: 'https://github.com/example/presets',
  );
  final entry = PresetCatalogEntry(
    id: 'warm-film',
    name: 'Warm Film',
    revision: 1,
    presetPath: 'presets/warm-film.presetstudio',
  );

  return PresetBrowseItem.remote(
    item: RemotePresetCatalogItem(
      source: source,
      catalog: PresetCatalog(name: source.name, presets: [entry]),
      entry: entry,
    ),
  );
}

class _MemoryFavoriteStore implements PresetFavoriteStore {
  _MemoryFavoriteStore([Set<String>? ids])
    : ids = Set<String>.from(ids ?? const <String>{});

  Set<String> ids;
  bool failSaves = false;

  @override
  Future<Set<String>> loadFavoriteIds() async => Set<String>.from(ids);

  @override
  Future<void> saveFavoriteIds(Set<String> favoriteIds) async {
    if (failSaves) {
      throw StateError('save failed');
    }
    ids = Set<String>.from(favoriteIds);
  }
}
