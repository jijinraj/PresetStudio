import 'dart:convert';

import 'preset_catalog.dart';

class PresetCatalogFormatException implements Exception {
  const PresetCatalogFormatException(this.message);

  final String message;

  @override
  String toString() => 'PresetCatalogFormatException: $message';
}

class PresetCatalogJsonCodec {
  const PresetCatalogJsonCodec();

  static const String format = 'presetstudio.catalog';

  String encode(PresetCatalog catalog) {
    final json = <String, Object?>{
      'format': format,
      'schemaVersion': catalog.schemaVersion,
      'name': catalog.name,
      if (catalog.description != null) 'description': catalog.description,
      'presets': catalog.presets
          .map(
            (entry) => <String, Object?>{
              'id': entry.id,
              'name': entry.name,
              if (entry.author != null) 'author': entry.author,
              if (entry.description != null) 'description': entry.description,
              if (entry.tags.isNotEmpty) 'tags': entry.tags,
              'revision': entry.revision,
              'preset': entry.presetPath,
              if (entry.previewPath != null) 'preview': entry.previewPath,
            },
          )
          .toList(growable: false),
    };

    return const JsonEncoder.withIndent('  ').convert(json);
  }

  PresetCatalog decode(String source) {
    final Object? decoded;

    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw PresetCatalogFormatException(
        'Invalid catalog JSON: ${error.message}',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const PresetCatalogFormatException(
        'Catalog JSON must contain an object at the top level.',
      );
    }

    final catalogFormat = _requiredString(decoded, 'format');

    if (catalogFormat != format) {
      throw PresetCatalogFormatException(
        'Unsupported catalog format $catalogFormat.',
      );
    }

    final schemaVersion = _requiredInt(decoded, 'schemaVersion');

    if (schemaVersion != PresetCatalog.currentSchemaVersion) {
      throw PresetCatalogFormatException(
        'Unsupported catalog schemaVersion $schemaVersion.',
      );
    }

    final rawPresets = decoded['presets'];

    if (rawPresets is! List) {
      throw const PresetCatalogFormatException('presets must be an array.');
    }

    final entries = <PresetCatalogEntry>[];

    for (var index = 0; index < rawPresets.length; index++) {
      final rawEntry = rawPresets[index];

      if (rawEntry is! Map<String, dynamic>) {
        throw PresetCatalogFormatException(
          'presets[$index] must be an object.',
        );
      }

      try {
        entries.add(
          PresetCatalogEntry(
            id: _requiredString(rawEntry, 'id'),
            name: _requiredString(rawEntry, 'name'),
            author: _optionalString(rawEntry, 'author'),
            description: _optionalString(rawEntry, 'description'),
            tags: _optionalStringList(rawEntry, 'tags'),
            revision: _requiredInt(rawEntry, 'revision'),
            presetPath: _requiredString(rawEntry, 'preset'),
            previewPath: _optionalString(rawEntry, 'preview'),
          ),
        );
      } on PresetCatalogException catch (error) {
        throw PresetCatalogFormatException(error.message);
      }
    }

    try {
      return PresetCatalog(
        schemaVersion: schemaVersion,
        name: _requiredString(decoded, 'name'),
        description: _optionalString(decoded, 'description'),
        presets: entries,
      );
    } on PresetCatalogException catch (error) {
      throw PresetCatalogFormatException(error.message);
    }
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw PresetCatalogFormatException('$key must be a non-empty string.');
    }

    return value;
  }

  String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw PresetCatalogFormatException('$key must be a string.');
    }

    return value;
  }

  List<String> _optionalStringList(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return const <String>[];
    }

    if (value is! List) {
      throw PresetCatalogFormatException('$key must be an array.');
    }

    final result = <String>[];

    for (var index = 0; index < value.length; index++) {
      final item = value[index];

      if (item is! String) {
        throw PresetCatalogFormatException('$key[$index] must be a string.');
      }

      result.add(item);
    }

    return result;
  }

  int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! int) {
      throw PresetCatalogFormatException('$key must be an integer.');
    }

    return value;
  }
}
