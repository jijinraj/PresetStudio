import 'dart:typed_data';

import '../domain/preset.dart';
import '../domain/preset_catalog.dart';
import '../domain/preset_source.dart';

class PresetRemoteException implements Exception {
  const PresetRemoteException(this.message);

  final String message;

  @override
  String toString() => 'PresetRemoteException: $message';
}

abstract interface class PresetRemoteGateway {
  Future<PresetCatalog> fetchCatalog(PresetRemoteSource source);

  Future<Preset> fetchPreset(
    PresetRemoteSource source,
    PresetCatalogEntry entry,
  );
}

abstract interface class PresetRemotePreviewGateway {
  Future<Uint8List> fetchPreview(
    PresetRemoteSource source,
    PresetCatalogEntry entry,
  );
}
