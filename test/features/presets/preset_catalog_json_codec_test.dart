import 'package:flutter_test/flutter_test.dart';
import 'package:presetstudio/features/presets/domain/preset_catalog.dart';
import 'package:presetstudio/features/presets/domain/preset_catalog_json_codec.dart';

void main() {
  const codec = PresetCatalogJsonCodec();

  test('decodes and round-trips the catalog v1 contract', () {
    const source = '''
{
  "format": "presetstudio.catalog",
  "schemaVersion": 1,
  "name": "PresetStudio Presets",
  "description": "Default collection",
  "presets": [
    {
      "id": "warm-film",
      "name": "Warm Film",
      "author": "Jijin",
      "description": "Warm film-inspired tones.",
      "tags": ["film", "warm", "portrait"],
      "revision": 2,
      "preset": "presets/warm-film.presetstudio",
      "preview": "previews/warm-film.webp"
    }
  ]
}
''';

    final catalog = codec.decode(source);

    expect(catalog.name, 'PresetStudio Presets');
    expect(catalog.description, 'Default collection');
    expect(catalog.presets, hasLength(1));

    final entry = catalog.presets.single;
    expect(entry.id, 'warm-film');
    expect(entry.description, 'Warm film-inspired tones.');
    expect(entry.tags, ['film', 'warm', 'portrait']);
    expect(entry.revision, 2);
    expect(entry.presetPath, 'presets/warm-film.presetstudio');
    expect(entry.previewPath, 'previews/warm-film.webp');

    final roundTripped = codec.decode(codec.encode(catalog));
    expect(roundTripped.presets.single.id, entry.id);
    expect(roundTripped.presets.single.description, entry.description);
    expect(roundTripped.presets.single.tags, entry.tags);
    expect(roundTripped.presets.single.revision, entry.revision);
  });

  test('rejects unsupported format and schema versions', () {
    expect(
      () => codec.decode(
        '{"format":"other","schemaVersion":1,"name":"x","presets":[]}',
      ),
      throwsA(isA<PresetCatalogFormatException>()),
    );

    expect(
      () => codec.decode(
        '{"format":"presetstudio.catalog","schemaVersion":2,'
        '"name":"x","presets":[]}',
      ),
      throwsA(isA<PresetCatalogFormatException>()),
    );
  });

  test('rejects unsafe preset paths and duplicate preset ids', () {
    expect(
      () => codec.decode('''
{
  "format": "presetstudio.catalog",
  "schemaVersion": 1,
  "name": "Unsafe",
  "presets": [
    {
      "id": "one",
      "name": "One",
      "revision": 1,
      "preset": "../outside.json"
    }
  ]
}
'''),
      throwsA(isA<PresetCatalogFormatException>()),
    );

    expect(
      () => PresetCatalog(
        name: 'Duplicate',
        presets: [
          PresetCatalogEntry(
            id: 'same',
            name: 'One',
            revision: 1,
            presetPath: 'presets/one.presetstudio',
          ),
          PresetCatalogEntry(
            id: 'same',
            name: 'Two',
            revision: 1,
            presetPath: 'presets/two.presetstudio',
          ),
        ],
      ),
      throwsA(isA<PresetCatalogException>()),
    );
  });

  test('normalizes duplicate tags and rejects invalid tag metadata', () {
    final entry = PresetCatalogEntry(
      id: 'tagged',
      name: 'Tagged',
      description: 'Description',
      tags: const [' Film ', 'film', 'Warm'],
      revision: 1,
      presetPath: 'presets/tagged.presetstudio',
    );

    expect(entry.tags, ['Film', 'Warm']);

    expect(
      () => PresetCatalogEntry(
        id: 'too-many',
        name: 'Too many',
        tags: List<String>.generate(13, (index) => 'tag-$index'),
        revision: 1,
        presetPath: 'presets/too-many.presetstudio',
      ),
      throwsA(isA<PresetCatalogException>()),
    );
  });
}
