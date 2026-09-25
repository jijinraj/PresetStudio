import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/domain/preset_source.dart';

void main() {
  test('registry supports multiple independent repository URLs', () {
    final registry = PresetSourceRegistry()
        .add(
          PresetRemoteSource(
            id: 'personal',
            name: 'Personal Presets',
            kind: PresetSourceKind.repository,
            location: 'https://github.com/example/presetstudio-presets',
          ),
        )
        .add(
          PresetRemoteSource(
            id: 'film-community',
            name: 'Film Community',
            kind: PresetSourceKind.repository,
            location: 'https://codeberg.org/example/film-presets',
          ),
        )
        .add(
          PresetRemoteSource(
            id: 'direct-catalog',
            name: 'Direct Catalog',
            kind: PresetSourceKind.catalog,
            location: 'https://presets.example.com/catalog.json',
          ),
        );

    expect(registry.sources, hasLength(3));
    expect(registry.sourceById('personal')?.enabled, isTrue);
    expect(
      registry.sourceById('film-community')?.location.host,
      'codeberg.org',
    );
  });

  test('sources can be independently enabled and disabled', () {
    final source = PresetRemoteSource(
      id: 'personal',
      name: 'Personal Presets',
      kind: PresetSourceKind.repository,
      location: 'https://github.com/example/presetstudio-presets',
    );

    final registry = PresetSourceRegistry(sources: [source]);
    final disabled = registry.setEnabled('personal', false);

    expect(registry.sourceById('personal')?.enabled, isTrue);
    expect(disabled.sourceById('personal')?.enabled, isFalse);
  });

  test('registry rejects duplicate ids', () {
    expect(
      () => PresetSourceRegistry(
        sources: [
          PresetRemoteSource(
            id: 'same',
            name: 'One',
            kind: PresetSourceKind.repository,
            location: 'https://github.com/example/one',
          ),
          PresetRemoteSource(
            id: 'same',
            name: 'Two',
            kind: PresetSourceKind.repository,
            location: 'https://github.com/example/two',
          ),
        ],
      ),
      throwsA(isA<PresetSourceException>()),
    );
  });

  test('registry rejects duplicate canonical locations', () {
    expect(
      () => PresetSourceRegistry(
        sources: [
          PresetRemoteSource(
            id: 'one',
            name: 'One',
            kind: PresetSourceKind.repository,
            location: 'https://github.com/example/presets',
          ),
          PresetRemoteSource(
            id: 'two',
            name: 'Two',
            kind: PresetSourceKind.repository,
            location: 'https://github.com/example/presets/',
          ),
        ],
      ),
      throwsA(isA<PresetSourceException>()),
    );
  });

  test('source URLs must be absolute HTTP or HTTPS URLs', () {
    expect(
      () => PresetRemoteSource(
        id: 'local-file',
        name: 'Local File',
        kind: PresetSourceKind.catalog,
        location: 'file:///tmp/catalog.json',
      ),
      throwsA(isA<PresetSourceException>()),
    );
  });
}
