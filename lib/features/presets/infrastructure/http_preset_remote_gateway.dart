import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../application/preset_remote_gateway.dart';
import '../domain/preset.dart';
import '../domain/preset_catalog.dart';
import '../domain/preset_catalog_json_codec.dart';
import '../domain/preset_json_codec.dart';
import '../domain/preset_source.dart';

typedef PresetRemoteTextLoader = Future<String> Function(Uri uri);
typedef PresetRemoteBytesLoader = Future<Uint8List> Function(Uri uri);

class HttpPresetRemoteGateway
    implements PresetRemoteGateway, PresetRemotePreviewGateway {
  HttpPresetRemoteGateway({
    PresetRemoteTextLoader? textLoader,
    PresetRemoteBytesLoader? bytesLoader,
    this.catalogCodec = const PresetCatalogJsonCodec(),
    this.presetCodec = const PresetJsonCodec(),
  }) : _textLoader = textLoader ?? _loadText,
       _bytesLoader = bytesLoader ?? _loadBytes;

  final PresetRemoteTextLoader _textLoader;
  final PresetRemoteBytesLoader _bytesLoader;
  final PresetCatalogJsonCodec catalogCodec;
  final PresetJsonCodec presetCodec;

  @override
  Future<PresetCatalog> fetchCatalog(PresetRemoteSource source) async {
    final uri = catalogUriFor(source);
    final text = await _textLoader(uri);

    try {
      return catalogCodec.decode(text);
    } on PresetCatalogFormatException catch (error) {
      throw PresetRemoteException(
        'Catalog from ${source.name} is invalid: ${error.message}',
      );
    }
  }

  @override
  Future<Preset> fetchPreset(
    PresetRemoteSource source,
    PresetCatalogEntry entry,
  ) async {
    final uri = presetUriFor(source, entry);
    final text = await _textLoader(uri);

    try {
      return presetCodec.decode(text);
    } on PresetFormatException catch (error) {
      throw PresetRemoteException(
        'Preset ${entry.name} is invalid: ${error.message}',
      );
    }
  }

  @override
  Future<Uint8List> fetchPreview(
    PresetRemoteSource source,
    PresetCatalogEntry entry,
  ) async {
    final uri = previewUriFor(source, entry);
    return _bytesLoader(uri);
  }

  Uri catalogUriFor(PresetRemoteSource source) {
    switch (source.kind) {
      case PresetSourceKind.repository:
        final base = _repositoryRawBase(source.location);
        return base.resolve('catalog.json');
      case PresetSourceKind.catalog:
        return source.location;
    }
  }

  Uri presetUriFor(PresetRemoteSource source, PresetCatalogEntry entry) {
    switch (source.kind) {
      case PresetSourceKind.repository:
        return _repositoryRawBase(source.location).resolve(entry.presetPath);
      case PresetSourceKind.catalog:
        return source.location.resolve(entry.presetPath);
    }
  }

  Uri previewUriFor(PresetRemoteSource source, PresetCatalogEntry entry) {
    final previewPath = entry.previewPath;

    if (previewPath == null) {
      throw PresetRemoteException(
        'Preset ${entry.name} does not declare a preview.',
      );
    }

    switch (source.kind) {
      case PresetSourceKind.repository:
        return _repositoryRawBase(source.location).resolve(previewPath);
      case PresetSourceKind.catalog:
        return source.location.resolve(previewPath);
    }
  }

  Uri _repositoryRawBase(Uri repositoryUri) {
    if (repositoryUri.host.toLowerCase() != 'github.com') {
      throw PresetRemoteException(
        'Repository source ${repositoryUri.host} is not supported yet. '
        'Use a GitHub repository URL or a direct catalog URL.',
      );
    }

    final segments = repositoryUri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);

    if (segments.length < 2) {
      throw const PresetRemoteException(
        'GitHub repository URL must include owner and repository name.',
      );
    }

    final owner = segments[0];
    var repository = segments[1];

    if (repository.endsWith('.git')) {
      repository = repository.substring(0, repository.length - 4);
    }

    var branch = 'main';

    if (segments.length >= 4 && segments[2] == 'tree') {
      branch = segments[3];
    }

    return Uri.https(
      'raw.githubusercontent.com',
      '/$owner/$repository/$branch/',
    );
  }

  static Future<String> _loadText(Uri uri) async {
    final bytes = await _loadBytes(uri, maxBytes: 1024 * 1024);

    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const PresetRemoteException(
        'Remote preset response is not valid UTF-8 text.',
      );
    }
  }

  static Future<Uint8List> _loadBytes(
    Uri uri, {
    int maxBytes = 5 * 1024 * 1024,
  }) async {
    final client = HttpClient()
      ..userAgent = 'PresetStudio/1'
      ..connectionTimeout = const Duration(seconds: 12);

    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));
      request.followRedirects = true;
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != HttpStatus.ok) {
        await response.drain();
        throw PresetRemoteException(
          'Request failed (${response.statusCode}) for $uri.',
        );
      }

      final bytes = await response.fold<List<int>>(<int>[], (buffer, chunk) {
        buffer.addAll(chunk);

        if (buffer.length > maxBytes) {
          throw PresetRemoteException(
            'Remote response exceeded the ${maxBytes ~/ (1024 * 1024)} MB '
            'limit.',
          );
        }

        return buffer;
      });

      return Uint8List.fromList(bytes);
    } on PresetRemoteException {
      rethrow;
    } on SocketException catch (error) {
      throw PresetRemoteException('Could not reach $uri: ${error.message}');
    } on TimeoutException {
      throw PresetRemoteException('Request timed out for $uri.');
    } on HttpException catch (error) {
      throw PresetRemoteException(
        'HTTP request failed for $uri: ${error.message}',
      );
    } finally {
      client.close(force: true);
    }
  }
}
