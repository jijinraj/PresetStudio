import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../application/preset_source_store.dart';
import '../domain/preset_source.dart';

class PresetSourceStorageException implements Exception {
  const PresetSourceStorageException(this.message);

  final String message;

  @override
  String toString() => 'PresetSourceStorageException: $message';
}

class LocalPresetSourceStore implements PresetSourceStore {
  LocalPresetSourceStore({required this.file});

  static const String _format = 'presetstudio.preset-sources';
  static const int _schemaVersion = 1;

  final File file;

  static Future<LocalPresetSourceStore> openDefault() async {
    final applicationSupportDirectory = await getApplicationSupportDirectory();
    final separator = Platform.pathSeparator;

    return LocalPresetSourceStore(
      file: File(
        '${applicationSupportDirectory.path}${separator}presetstudio'
        '${separator}presets${separator}sources.json',
      ),
    );
  }

  @override
  Future<PresetSourceRegistry?> loadRegistry() async {
    if (!await file.exists()) {
      return null;
    }

    final String source;

    try {
      source = await file.readAsString();
    } on FileSystemException catch (error) {
      throw PresetSourceStorageException(
        'Preset sources could not be read: ${error.message}',
      );
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw PresetSourceStorageException(
        'Preset sources contain invalid JSON: ${error.message}',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const PresetSourceStorageException(
        'Preset sources must contain an object at the top level.',
      );
    }

    if (decoded['format'] != _format) {
      throw const PresetSourceStorageException(
        'Unsupported preset source registry format.',
      );
    }

    if (decoded['schemaVersion'] != _schemaVersion) {
      throw const PresetSourceStorageException(
        'Unsupported preset source registry schema version.',
      );
    }

    final rawSources = decoded['sources'];

    if (rawSources is! List) {
      throw const PresetSourceStorageException(
        'Preset source registry sources must be an array.',
      );
    }

    final sources = <PresetRemoteSource>[];

    for (var index = 0; index < rawSources.length; index++) {
      final raw = rawSources[index];

      if (raw is! Map<String, dynamic>) {
        throw PresetSourceStorageException(
          'Preset source at index $index must be an object.',
        );
      }

      final kindName = raw['kind'];
      final kind = PresetSourceKind.values.where(
        (value) => value.name == kindName,
      );

      if (kind.length != 1) {
        throw PresetSourceStorageException(
          'Preset source at index $index has an unsupported kind.',
        );
      }

      try {
        sources.add(
          PresetRemoteSource(
            id: _requiredString(raw, 'id'),
            name: _requiredString(raw, 'name'),
            kind: kind.single,
            location: _requiredString(raw, 'location'),
            enabled: _requiredBool(raw, 'enabled'),
          ),
        );
      } on PresetSourceException catch (error) {
        throw PresetSourceStorageException(error.message);
      }
    }

    try {
      return PresetSourceRegistry(sources: sources);
    } on PresetSourceException catch (error) {
      throw PresetSourceStorageException(error.message);
    }
  }

  @override
  Future<void> saveRegistry(PresetSourceRegistry registry) async {
    final data = <String, Object?>{
      'format': _format,
      'schemaVersion': _schemaVersion,
      'sources': registry.sources
          .map(
            (source) => <String, Object?>{
              'id': source.id,
              'name': source.name,
              'kind': source.kind.name,
              'location': source.location.toString(),
              'enabled': source.enabled,
            },
          )
          .toList(growable: false),
    };

    try {
      await file.parent.create(recursive: true);
      final temporaryFile = File('${file.path}.tmp');
      await temporaryFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );

      if (await file.exists()) {
        await file.delete();
      }

      await temporaryFile.rename(file.path);
    } on FileSystemException catch (error) {
      throw PresetSourceStorageException(
        'Preset sources could not be saved: ${error.message}',
      );
    }
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw PresetSourceStorageException('$key must be a non-empty string.');
    }

    return value;
  }

  bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! bool) {
      throw PresetSourceStorageException('$key must be a boolean.');
    }

    return value;
  }
}
