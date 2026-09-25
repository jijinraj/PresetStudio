import '../domain/preset_source.dart';

abstract interface class PresetSourceStore {
  Future<PresetSourceRegistry?> loadRegistry();

  Future<void> saveRegistry(PresetSourceRegistry registry);
}
