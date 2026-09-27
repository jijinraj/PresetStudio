import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../application/preset_preview_cache.dart';

class PresetPreviewCacheException implements Exception {
  const PresetPreviewCacheException(this.message);

  final String message;

  @override
  String toString() => 'PresetPreviewCacheException: $message';
}

class LocalPresetPreviewCache implements PresetPreviewCache {
  LocalPresetPreviewCache({required this.directory});

  final Directory directory;

  static Future<LocalPresetPreviewCache> openDefault() async {
    final applicationSupportDirectory = await getApplicationSupportDirectory();
    final separator = Platform.pathSeparator;

    return LocalPresetPreviewCache(
      directory: Directory(
        '${applicationSupportDirectory.path}${separator}presetstudio'
        '${separator}presets${separator}preview-cache',
      ),
    );
  }

  @override
  Future<Uint8List?> load({
    required String sourceId,
    required String presetId,
    required int revision,
  }) async {
    final file = _fileFor(
      sourceId: sourceId,
      presetId: presetId,
      revision: revision,
    );

    if (!await file.exists()) {
      return null;
    }

    try {
      return await file.readAsBytes();
    } on FileSystemException catch (error) {
      throw PresetPreviewCacheException(
        'Cached preset preview could not be read: ${error.message}',
      );
    }
  }

  @override
  Future<void> save({
    required String sourceId,
    required String presetId,
    required int revision,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const PresetPreviewCacheException(
        'Preset preview cannot be empty.',
      );
    }

    final file = _fileFor(
      sourceId: sourceId,
      presetId: presetId,
      revision: revision,
    );

    try {
      await file.parent.create(recursive: true);
      await _removeOldRevisions(
        directory: file.parent,
        presetId: presetId,
        keepRevision: revision,
      );

      final temporaryFile = File('${file.path}.tmp');
      await temporaryFile.writeAsBytes(bytes, flush: true);

      if (await file.exists()) {
        await file.delete();
      }

      await temporaryFile.rename(file.path);
    } on FileSystemException catch (error) {
      throw PresetPreviewCacheException(
        'Preset preview could not be cached: ${error.message}',
      );
    }
  }

  @override
  Future<void> removeSource(String sourceId) async {
    final sourceDirectory = _sourceDirectory(sourceId);

    try {
      if (await sourceDirectory.exists()) {
        await sourceDirectory.delete(recursive: true);
      }
    } on FileSystemException catch (error) {
      throw PresetPreviewCacheException(
        'Cached preset previews could not be removed: ${error.message}',
      );
    }
  }

  Future<void> _removeOldRevisions({
    required Directory directory,
    required String presetId,
    required int keepRevision,
  }) async {
    if (!await directory.exists()) {
      return;
    }

    final prefix = '${_encode(presetId)}-r';
    final keepName = '$prefix$keepRevision.preview';

    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }

      final name = entity.uri.pathSegments.last;
      if (name.startsWith(prefix) && name != keepName) {
        await entity.delete();
      }
    }
  }

  File _fileFor({
    required String sourceId,
    required String presetId,
    required int revision,
  }) {
    final sourceDirectory = _sourceDirectory(sourceId);

    return File(
      '${sourceDirectory.path}${Platform.pathSeparator}'
      '${_encode(presetId)}-r$revision.preview',
    );
  }

  Directory _sourceDirectory(String sourceId) {
    return Directory(
      '${directory.path}${Platform.pathSeparator}${_encode(sourceId)}',
    );
  }

  String _encode(String value) {
    return base64Url.encode(utf8.encode(value.trim())).replaceAll('=', '');
  }
}
