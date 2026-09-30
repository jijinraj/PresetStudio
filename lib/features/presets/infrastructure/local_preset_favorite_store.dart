import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../application/preset_favorite_store.dart';

class PresetFavoriteStorageException implements Exception {
  const PresetFavoriteStorageException(this.message);

  final String message;

  @override
  String toString() => 'PresetFavoriteStorageException: $message';
}

class LocalPresetFavoriteStore implements PresetFavoriteStore {
  LocalPresetFavoriteStore({required this.file});

  static const String _format = 'presetstudio.preset-favorites';
  static const int _schemaVersion = 1;

  final File file;

  static Future<LocalPresetFavoriteStore> openDefault() async {
    final applicationSupportDirectory = await getApplicationSupportDirectory();
    final separator = Platform.pathSeparator;

    return LocalPresetFavoriteStore(
      file: File(
        '${applicationSupportDirectory.path}${separator}presetstudio'
        '${separator}presets${separator}favorites.json',
      ),
    );
  }

  @override
  Future<Set<String>> loadFavoriteIds() async {
    if (!await file.exists()) {
      return const <String>{};
    }

    final String source;
    try {
      source = await file.readAsString();
    } on FileSystemException catch (error) {
      throw PresetFavoriteStorageException(
        'Preset favorites could not be read: ${error.message}',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw PresetFavoriteStorageException(
        'Preset favorites contain invalid JSON: ${error.message}',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const PresetFavoriteStorageException(
        'Preset favorites must contain an object at the top level.',
      );
    }
    if (decoded['format'] != _format) {
      throw const PresetFavoriteStorageException(
        'Unsupported preset favorites format.',
      );
    }
    if (decoded['schemaVersion'] != _schemaVersion) {
      throw const PresetFavoriteStorageException(
        'Unsupported preset favorites schema version.',
      );
    }

    final rawIds = decoded['favoriteIds'];
    if (rawIds is! List) {
      throw const PresetFavoriteStorageException(
        'Preset favoriteIds must be an array.',
      );
    }

    final result = <String>{};
    for (var index = 0; index < rawIds.length; index++) {
      final value = rawIds[index];
      if (value is! String || value.trim().isEmpty) {
        throw PresetFavoriteStorageException(
          'Preset favorite id at index $index must be a non-empty string.',
        );
      }
      result.add(value.trim());
    }
    return Set<String>.unmodifiable(result);
  }

  @override
  Future<void> saveFavoriteIds(Set<String> favoriteIds) async {
    final normalized = favoriteIds.map((value) => value.trim()).toList();
    if (normalized.any((value) => value.isEmpty)) {
      throw const PresetFavoriteStorageException(
        'Preset favorite ids must not be empty.',
      );
    }
    normalized.sort();

    final data = <String, Object?>{
      'format': _format,
      'schemaVersion': _schemaVersion,
      'favoriteIds': normalized,
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
      throw PresetFavoriteStorageException(
        'Preset favorites could not be saved: ${error.message}',
      );
    }
  }
}
