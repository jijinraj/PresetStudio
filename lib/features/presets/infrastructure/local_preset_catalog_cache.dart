import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../application/preset_catalog_cache.dart';
import '../domain/preset_catalog.dart';
import '../domain/preset_catalog_json_codec.dart';

class PresetCatalogCacheException implements Exception {
  const PresetCatalogCacheException(this.message);

  final String message;

  @override
  String toString() => 'PresetCatalogCacheException: $message';
}

class LocalPresetCatalogCache implements PresetCatalogCache {
  LocalPresetCatalogCache({
    required this.directory,
    this.codec = const PresetCatalogJsonCodec(),
  });

  final Directory directory;
  final PresetCatalogJsonCodec codec;

  static Future<LocalPresetCatalogCache> openDefault() async {
    final applicationSupportDirectory = await getApplicationSupportDirectory();
    final separator = Platform.pathSeparator;

    return LocalPresetCatalogCache(
      directory: Directory(
        '${applicationSupportDirectory.path}${separator}presetstudio'
        '${separator}presets${separator}catalog-cache',
      ),
    );
  }

  @override
  Future<PresetCatalog?> load(String sourceId) async {
    final file = _fileFor(sourceId);

    if (!await file.exists()) {
      return null;
    }

    try {
      return codec.decode(await file.readAsString());
    } on FileSystemException catch (error) {
      throw PresetCatalogCacheException(
        'Cached preset catalog could not be read: ${error.message}',
      );
    } on PresetCatalogFormatException catch (error) {
      throw PresetCatalogCacheException(
        'Cached preset catalog is invalid: ${error.message}',
      );
    }
  }

  @override
  Future<void> save(String sourceId, PresetCatalog catalog) async {
    final file = _fileFor(sourceId);

    try {
      await directory.create(recursive: true);
      final temporaryFile = File('${file.path}.tmp');
      await temporaryFile.writeAsString(codec.encode(catalog), flush: true);

      if (await file.exists()) {
        await file.delete();
      }

      await temporaryFile.rename(file.path);
    } on FileSystemException catch (error) {
      throw PresetCatalogCacheException(
        'Preset catalog could not be cached: ${error.message}',
      );
    }
  }

  @override
  Future<void> remove(String sourceId) async {
    final file = _fileFor(sourceId);

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException catch (error) {
      throw PresetCatalogCacheException(
        'Cached preset catalog could not be removed: ${error.message}',
      );
    }
  }

  File _fileFor(String sourceId) {
    final encoded = base64Url
        .encode(utf8.encode(sourceId.trim()))
        .replaceAll('=', '');

    return File(
      '${directory.path}${Platform.pathSeparator}$encoded.catalog.json',
    );
  }
}
