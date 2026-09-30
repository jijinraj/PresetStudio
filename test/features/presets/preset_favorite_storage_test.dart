import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/infrastructure/local_preset_favorite_store.dart';

void main() {
  late Directory tempDirectory;
  late File file;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'presetstudio-favorites-',
    );
    file = File('${tempDirectory.path}${Platform.pathSeparator}favorites.json');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('missing file loads an empty favorite set', () async {
    final store = LocalPresetFavoriteStore(file: file);

    expect(await store.loadFavoriteIds(), isEmpty);
  });

  test('favorite identities persist across store instances', () async {
    final store = LocalPresetFavoriteStore(file: file);

    await store.saveFavoriteIds({
      'remote:default:warm-film',
      'local.bXktcG9ydHJhaXQ',
    });

    final restarted = LocalPresetFavoriteStore(file: file);
    expect(await restarted.loadFavoriteIds(), {
      'remote:default:warm-film',
      'local.bXktcG9ydHJhaXQ',
    });
  });

  test('saved favorite identities are deterministic', () async {
    final store = LocalPresetFavoriteStore(file: file);

    await store.saveFavoriteIds({'z-last', 'a-first'});

    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(decoded['format'], 'presetstudio.preset-favorites');
    expect(decoded['schemaVersion'], 1);
    expect(decoded['favoriteIds'], ['a-first', 'z-last']);
  });

  test('invalid stored data is rejected', () async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'format': 'presetstudio.preset-favorites',
        'schemaVersion': 1,
        'favoriteIds': ['valid', ''],
      }),
    );
    final store = LocalPresetFavoriteStore(file: file);

    await expectLater(
      store.loadFavoriteIds(),
      throwsA(isA<PresetFavoriteStorageException>()),
    );
  });
}
