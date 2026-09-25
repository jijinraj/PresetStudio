import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../application/preset_library_store.dart';
import '../domain/preset_json_codec.dart';
import '../domain/preset_record.dart';

class PresetLibraryStorageException implements Exception {
  const PresetLibraryStorageException(this.message);

  final String message;

  @override
  String toString() => 'PresetLibraryStorageException: $message';
}

class LocalPresetLibraryStore implements PresetLibraryStore {
  LocalPresetLibraryStore({
    required this.rootDirectory,
    this.codec = const PresetJsonCodec(),
  });

  static const String _indexFormat = 'presetstudio.preset-library';
  static const int _indexSchemaVersion = 1;
  static const String _indexFileName = 'library.json';
  static const String _presetDirectoryName = 'presets';

  final Directory rootDirectory;
  final PresetJsonCodec codec;

  static Future<LocalPresetLibraryStore> openDefault() async {
    final applicationSupportDirectory = await getApplicationSupportDirectory();
    final separator = Platform.pathSeparator;

    return LocalPresetLibraryStore(
      rootDirectory: Directory(
        '${applicationSupportDirectory.path}${separator}presetstudio'
        '${separator}presets',
      ),
    );
  }

  @override
  Future<List<PresetRecord>> loadRecords() async {
    final metadata = await _readIndex();
    final records = <PresetRecord>[];

    for (final item in metadata) {
      final file = File(
        '${_presetDirectory.path}${Platform.pathSeparator}${item.fileName}',
      );

      if (!await file.exists()) {
        throw PresetLibraryStorageException(
          'Preset file is missing for library record ${item.libraryId}.',
        );
      }

      try {
        final preset = codec.decode(await file.readAsString());

        if (preset.id != item.presetId) {
          throw PresetLibraryStorageException(
            'Preset id ${preset.id} does not match index id ${item.presetId}.',
          );
        }

        records.add(
          PresetRecord(
            libraryId: item.libraryId,
            preset: preset,
            origin: item.origin,
            installedAt: item.installedAt,
            updatedAt: item.updatedAt,
          ),
        );
      } on PresetLibraryStorageException {
        rethrow;
      } on Object catch (error) {
        throw PresetLibraryStorageException(
          'Failed to read preset ${item.libraryId}: $error',
        );
      }
    }

    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<PresetRecord>.unmodifiable(records);
  }

  @override
  Future<void> upsertRecord(PresetRecord record) async {
    await _ensureDirectories();

    final metadata = await _readIndex();
    _StoredPresetMetadata? existingMetadata;

    for (final item in metadata) {
      if (item.libraryId == record.libraryId) {
        existingMetadata = item;
        break;
      }
    }

    final fileName =
        existingMetadata?.fileName ?? await _nextAvailableFileName(metadata);
    final presetFile = File(
      '${_presetDirectory.path}${Platform.pathSeparator}$fileName',
    );

    await _writeText(presetFile, codec.encode(record.preset));

    final replacement = _StoredPresetMetadata.fromRecord(
      record,
      fileName: fileName,
    );
    final updatedMetadata = <_StoredPresetMetadata>[
      ...metadata.where((item) => item.libraryId != record.libraryId),
      replacement,
    ]..sort((a, b) => a.libraryId.compareTo(b.libraryId));

    await _writeIndex(updatedMetadata);
  }

  @override
  Future<void> deleteRecord(String libraryId) async {
    final metadata = await _readIndex();
    _StoredPresetMetadata? target;

    for (final item in metadata) {
      if (item.libraryId == libraryId) {
        target = item;
        break;
      }
    }

    if (target == null) {
      return;
    }

    final updatedMetadata = metadata
        .where((item) => item.libraryId != libraryId)
        .toList(growable: false);
    await _writeIndex(updatedMetadata);

    final presetFile = File(
      '${_presetDirectory.path}${Platform.pathSeparator}${target.fileName}',
    );

    if (await presetFile.exists()) {
      await presetFile.delete();
    }
  }

  Directory get _presetDirectory {
    return Directory(
      '${rootDirectory.path}${Platform.pathSeparator}$_presetDirectoryName',
    );
  }

  File get _indexFile {
    return File(
      '${rootDirectory.path}${Platform.pathSeparator}$_indexFileName',
    );
  }

  Future<void> _ensureDirectories() async {
    await rootDirectory.create(recursive: true);
    await _presetDirectory.create(recursive: true);
  }

  Future<List<_StoredPresetMetadata>> _readIndex() async {
    if (!await _indexFile.exists()) {
      return <_StoredPresetMetadata>[];
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(await _indexFile.readAsString());
    } on Object catch (error) {
      throw PresetLibraryStorageException(
        'Failed to decode preset library index: $error',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const PresetLibraryStorageException(
        'Preset library index must contain a JSON object.',
      );
    }

    if (decoded['format'] != _indexFormat) {
      throw const PresetLibraryStorageException(
        'Unsupported preset library index format.',
      );
    }

    if (decoded['schemaVersion'] != _indexSchemaVersion) {
      throw const PresetLibraryStorageException(
        'Unsupported preset library index schema version.',
      );
    }

    final recordsJson = decoded['records'];

    if (recordsJson is! List<dynamic>) {
      throw const PresetLibraryStorageException(
        'Preset library index records must be a JSON array.',
      );
    }

    try {
      return recordsJson
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const PresetLibraryStorageException(
                'Preset library record metadata must be a JSON object.',
              );
            }

            return _StoredPresetMetadata.fromJson(item);
          })
          .toList(growable: false);
    } on PresetLibraryStorageException {
      rethrow;
    } on Object catch (error) {
      throw PresetLibraryStorageException(
        'Failed to parse preset library index: $error',
      );
    }
  }

  Future<void> _writeIndex(List<_StoredPresetMetadata> metadata) async {
    await _ensureDirectories();

    final json = <String, Object?>{
      'format': _indexFormat,
      'schemaVersion': _indexSchemaVersion,
      'records': metadata.map((item) => item.toJson()).toList(growable: false),
    };

    await _writeText(
      _indexFile,
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }

  Future<void> _writeText(File file, String contents) async {
    await file.parent.create(recursive: true);
    final temporaryFile = File('${file.path}.tmp');

    try {
      await temporaryFile.writeAsString(contents, flush: true);

      if (await file.exists()) {
        await file.delete();
      }

      await temporaryFile.rename(file.path);
    } on Object catch (error) {
      if (await temporaryFile.exists()) {
        await temporaryFile.delete();
      }

      throw PresetLibraryStorageException(
        'Failed to write ${file.path}: $error',
      );
    }
  }

  Future<String> _nextAvailableFileName(
    List<_StoredPresetMetadata> metadata,
  ) async {
    final usedNames = metadata.map((item) => item.fileName).toSet();
    var counter = 1;

    while (true) {
      final number = counter.toString().padLeft(6, '0');
      final candidate = 'preset-$number${PresetJsonCodec.fileSuffix}';
      final candidateFile = File(
        '${_presetDirectory.path}${Platform.pathSeparator}$candidate',
      );

      if (!usedNames.contains(candidate) && !await candidateFile.exists()) {
        return candidate;
      }

      counter += 1;
    }
  }
}

class _StoredPresetMetadata {
  const _StoredPresetMetadata({
    required this.libraryId,
    required this.presetId,
    required this.fileName,
    required this.origin,
    required this.installedAt,
    required this.updatedAt,
  });

  factory _StoredPresetMetadata.fromRecord(
    PresetRecord record, {
    required String fileName,
  }) {
    return _StoredPresetMetadata(
      libraryId: record.libraryId,
      presetId: record.preset.id,
      fileName: fileName,
      origin: record.origin,
      installedAt: record.installedAt,
      updatedAt: record.updatedAt,
    );
  }

  factory _StoredPresetMetadata.fromJson(Map<String, dynamic> json) {
    final originJson = json['origin'];

    if (originJson is! Map<String, dynamic>) {
      throw const PresetLibraryStorageException(
        'Preset record origin must be a JSON object.',
      );
    }

    return _StoredPresetMetadata(
      libraryId: _requiredString(json, 'libraryId'),
      presetId: _requiredString(json, 'presetId'),
      fileName: _validatedFileName(_requiredString(json, 'file')),
      origin: _decodeOrigin(originJson),
      installedAt: _requiredDateTime(json, 'installedAt'),
      updatedAt: _requiredDateTime(json, 'updatedAt'),
    );
  }

  final String libraryId;
  final String presetId;
  final String fileName;
  final PresetOrigin origin;
  final DateTime installedAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'libraryId': libraryId,
      'presetId': presetId,
      'file': fileName,
      'origin': _encodeOrigin(origin),
      'installedAt': installedAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  static Map<String, Object?> _encodeOrigin(PresetOrigin origin) {
    return <String, Object?>{
      'type': origin.type.name,
      if (origin.sourceId != null) 'sourceId': origin.sourceId,
      if (origin.remotePresetId != null)
        'remotePresetId': origin.remotePresetId,
      if (origin.remoteRevision != null)
        'remoteRevision': origin.remoteRevision,
    };
  }

  static PresetOrigin _decodeOrigin(Map<String, dynamic> json) {
    final typeText = _requiredString(json, 'type');
    PresetOriginType? type;

    for (final candidate in PresetOriginType.values) {
      if (candidate.name == typeText) {
        type = candidate;
        break;
      }
    }

    if (type == null) {
      throw PresetLibraryStorageException(
        'Unknown preset origin type: $typeText.',
      );
    }

    return switch (type) {
      PresetOriginType.local => PresetOrigin.local(),
      PresetOriginType.builtIn => PresetOrigin.builtIn(),
      PresetOriginType.remoteInstalled => PresetOrigin.remoteInstalled(
        sourceId: _requiredString(json, 'sourceId'),
        remotePresetId: _requiredString(json, 'remotePresetId'),
        remoteRevision: _optionalPositiveInt(json, 'remoteRevision'),
      ),
    };
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw PresetLibraryStorageException('$key must be a non-empty string.');
    }

    return value.trim();
  }

  static String _validatedFileName(String value) {
    if (value.contains('/') || value.contains('\\')) {
      throw const PresetLibraryStorageException(
        'Preset file name cannot contain path separators.',
      );
    }

    return value;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = _requiredString(json, key);
    final result = DateTime.tryParse(value);

    if (result == null) {
      throw PresetLibraryStorageException(
        '$key must be a valid ISO-8601 timestamp.',
      );
    }

    return result.toUtc();
  }

  static int? _optionalPositiveInt(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! int || value <= 0) {
      throw PresetLibraryStorageException(
        '$key must be a positive integer when provided.',
      );
    }

    return value;
  }
}
