import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/domain/preset_catalog.dart';
import 'package:presetstudio/features/presets/domain/preset_source.dart';
import 'package:presetstudio/features/presets/infrastructure/http_preset_remote_gateway.dart';

void main() {
  test(
    'resolves GitHub repository source to raw catalog and preset URLs',
    () async {
      final requested = <Uri>[];
      final gateway = HttpPresetRemoteGateway(
        textLoader: (uri) async {
          requested.add(uri);

          if (uri.path.endsWith('/catalog.json')) {
            return '''
{
  "format": "presetstudio.catalog",
  "schemaVersion": 1,
  "name": "PresetStudio Presets",
  "presets": [
    {
      "id": "warm-film",
      "name": "Warm Film",
      "revision": 1,
      "preset": "presets/warm-film.presetstudio"
    }
  ]
}
''';
          }

          return '''
{
  "format": "presetstudio.preset",
  "schemaVersion": 1,
  "id": "warm-film",
  "name": "Warm Film",
  "createdAt": "2026-09-25T00:00:00.000Z",
  "revision": 1,
  "adjustments": {
    "exposure": 0,
    "contrast": 0,
    "highlights": 0,
    "shadows": 0,
    "whites": 0,
    "blacks": 0,
    "temperature": 0,
    "tint": 0,
    "vibrance": 0,
    "saturation": 0
  }
}
''';
        },
      );
      final source = PresetRemoteSource(
        id: 'default',
        name: 'PresetStudio Presets',
        kind: PresetSourceKind.repository,
        location: 'https://github.com/jijinraj/presetstudio-presets',
      );

      final catalog = await gateway.fetchCatalog(source);
      await gateway.fetchPreset(source, catalog.presets.single);

      expect(
        requested[0].toString(),
        'https://raw.githubusercontent.com/jijinraj/'
        'presetstudio-presets/main/catalog.json',
      );
      expect(
        requested[1].toString(),
        'https://raw.githubusercontent.com/jijinraj/'
        'presetstudio-presets/main/presets/warm-film.presetstudio',
      );
    },
  );

  test('supports repository tree URLs and direct catalog URLs', () {
    final gateway = HttpPresetRemoteGateway(textLoader: (_) async => '');
    final entry = PresetCatalogEntry(
      id: 'one',
      name: 'One',
      revision: 1,
      presetPath: 'presets/one.presetstudio',
    );

    final repository = PresetRemoteSource(
      id: 'repo',
      name: 'Repo',
      kind: PresetSourceKind.repository,
      location: 'https://github.com/example/repo/tree/develop',
    );
    final catalog = PresetRemoteSource(
      id: 'catalog',
      name: 'Catalog',
      kind: PresetSourceKind.catalog,
      location: 'https://example.com/presets/catalog.json',
    );

    expect(
      gateway.catalogUriFor(repository).toString(),
      'https://raw.githubusercontent.com/example/repo/develop/catalog.json',
    );
    expect(
      gateway.presetUriFor(repository, entry).toString(),
      'https://raw.githubusercontent.com/example/repo/develop/'
      'presets/one.presetstudio',
    );
    expect(
      gateway.presetUriFor(catalog, entry).toString(),
      'https://example.com/presets/presets/one.presetstudio',
    );
  });
}
