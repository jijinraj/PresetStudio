import 'dart:typed_data';

abstract interface class PresetPreviewCache {
  Future<Uint8List?> load({
    required String sourceId,
    required String presetId,
    required int revision,
  });

  Future<void> save({
    required String sourceId,
    required String presetId,
    required int revision,
    required Uint8List bytes,
  });

  Future<void> removeSource(String sourceId);
}
