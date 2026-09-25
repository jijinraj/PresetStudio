import '../domain/preset_catalog.dart';

abstract interface class PresetCatalogCache {
  Future<PresetCatalog?> load(String sourceId);

  Future<void> save(String sourceId, PresetCatalog catalog);

  Future<void> remove(String sourceId);
}
