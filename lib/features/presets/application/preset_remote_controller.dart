import 'package:flutter/foundation.dart';

import '../domain/preset.dart';
import '../domain/preset_catalog.dart';
import '../domain/preset_record.dart';
import '../domain/preset_source.dart';
import 'preset_catalog_cache.dart';
import 'preset_default_sources.dart';
import 'preset_library_controller.dart';
import 'preset_preview_cache.dart';
import 'preset_remote_gateway.dart';
import 'preset_source_store.dart';

typedef PresetSourceStoreLoader = Future<PresetSourceStore> Function();
typedef PresetCatalogCacheLoader = Future<PresetCatalogCache> Function();
typedef PresetPreviewCacheLoader = Future<PresetPreviewCache> Function();

class RemotePresetCatalogItem {
  const RemotePresetCatalogItem({
    required this.source,
    required this.catalog,
    required this.entry,
  });

  final PresetRemoteSource source;
  final PresetCatalog catalog;
  final PresetCatalogEntry entry;

  String get key => '${source.id}:${entry.id}';
}

class PresetRemoteController extends ChangeNotifier {
  PresetRemoteController({
    required PresetSourceStoreLoader sourceStoreLoader,
    required PresetCatalogCacheLoader catalogCacheLoader,
    PresetPreviewCacheLoader? previewCacheLoader,
    required PresetRemoteGateway gateway,
    Iterable<PresetRemoteSource>? defaultSources,
  }) : this._(
         sourceStoreLoader,
         catalogCacheLoader,
         previewCacheLoader,
         gateway,
         List<PresetRemoteSource>.unmodifiable(
           defaultSources ?? PresetDefaultSources.all,
         ),
       );

  PresetRemoteController._(
    this._sourceStoreLoader,
    this._catalogCacheLoader,
    this._previewCacheLoader,
    this._gateway,
    this._defaultSources,
  );

  final PresetSourceStoreLoader _sourceStoreLoader;
  final PresetCatalogCacheLoader _catalogCacheLoader;
  final PresetPreviewCacheLoader? _previewCacheLoader;
  final PresetRemoteGateway _gateway;
  final List<PresetRemoteSource> _defaultSources;

  PresetSourceStore? _sourceStore;
  PresetCatalogCache? _catalogCache;
  PresetPreviewCache? _previewCache;
  PresetSourceRegistry _registry = PresetSourceRegistry();
  final Map<String, PresetCatalog> _catalogs = <String, PresetCatalog>{};
  final Map<String, String> _sourceErrors = <String, String>{};
  final Set<String> _installingKeys = <String>{};
  final Map<String, Future<Uint8List?>> _previewFutures =
      <String, Future<Uint8List?>>{};
  final Map<String, Future<Preset?>> _presetPreviewFutures =
      <String, Future<Preset?>>{};

  bool _isInitializing = false;
  bool _isInitialized = false;
  bool _isRefreshing = false;
  bool _isDisposed = false;
  String? _errorMessage;

  PresetSourceRegistry get registry => _registry;
  bool get isInitializing => _isInitializing;
  bool get isInitialized => _isInitialized;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  Map<String, String> get sourceErrors =>
      Map<String, String>.unmodifiable(_sourceErrors);

  List<RemotePresetCatalogItem> get items {
    final items = <RemotePresetCatalogItem>[];

    for (final source in _registry.sources.where((source) => source.enabled)) {
      final catalog = _catalogs[source.id];

      if (catalog == null) {
        continue;
      }

      for (final entry in catalog.presets) {
        items.add(
          RemotePresetCatalogItem(
            source: source,
            catalog: catalog,
            entry: entry,
          ),
        );
      }
    }

    items.sort((a, b) {
      final sourceCompare = a.source.name.toLowerCase().compareTo(
        b.source.name.toLowerCase(),
      );
      if (sourceCompare != 0) {
        return sourceCompare;
      }

      return a.entry.name.toLowerCase().compareTo(b.entry.name.toLowerCase());
    });

    return List<RemotePresetCatalogItem>.unmodifiable(items);
  }

  PresetCatalog? catalogForSource(String sourceId) => _catalogs[sourceId];

  bool isInstalling(RemotePresetCatalogItem item) {
    return _installingKeys.contains(item.key);
  }

  Future<Uint8List?> previewFor(RemotePresetCatalogItem item) {
    if (item.entry.previewPath == null) {
      return Future<Uint8List?>.value(null);
    }

    final key = _previewKey(item);
    return _previewFutures.putIfAbsent(key, () => _loadPreview(item));
  }

  Future<Preset?> presetForPreview(RemotePresetCatalogItem item) {
    final key = _presetPayloadKey(item);
    return _presetPreviewFutures.putIfAbsent(
      key,
      () => _loadPresetForPreview(item),
    );
  }

  Future<void> initialize() async {
    if (_isInitializing || _isInitialized) {
      return;
    }

    _isInitializing = true;
    _notifyListeners();

    try {
      final sourceStore = await _sourceStoreLoader();
      final catalogCache = await _catalogCacheLoader();
      PresetPreviewCache? previewCache;

      if (_previewCacheLoader != null) {
        try {
          previewCache = await _previewCacheLoader();
        } on Object {
          previewCache = null;
        }
      }

      var registry = await sourceStore.loadRegistry();

      if (registry == null) {
        registry = PresetSourceRegistry(sources: _defaultSources);
        await sourceStore.saveRegistry(registry);
      }

      _sourceStore = sourceStore;
      _catalogCache = catalogCache;
      _previewCache = previewCache;
      _registry = registry;
      _errorMessage = null;

      for (final source in registry.sources.where((source) => source.enabled)) {
        try {
          final cached = await catalogCache.load(source.id);

          if (cached != null) {
            _catalogs[source.id] = cached;
          }
        } on Object catch (error) {
          _sourceErrors[source.id] = '$error';
        }
      }

      _isInitialized = true;
    } on Object catch (error) {
      _errorMessage = 'Preset sources could not be loaded: $error';
    } finally {
      _isInitializing = false;
      _notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!_isInitialized || _isRefreshing) {
      return;
    }

    _isRefreshing = true;
    _previewFutures.clear();
    _presetPreviewFutures.clear();
    _notifyListeners();

    try {
      for (final source in _registry.sources.where(
        (source) => source.enabled,
      )) {
        try {
          final catalog = await _gateway.fetchCatalog(source);
          _catalogs[source.id] = catalog;
          _sourceErrors.remove(source.id);
          await _requireCache().save(source.id, catalog);
        } on Object catch (error) {
          _sourceErrors[source.id] = '$error';
        }

        _notifyListeners();
      }
    } finally {
      _isRefreshing = false;
      _notifyListeners();
    }
  }

  Future<PresetRecord> install(
    RemotePresetCatalogItem item, {
    required PresetLibraryController libraryController,
  }) async {
    if (_installingKeys.contains(item.key)) {
      throw const PresetRemoteException(
        'This preset is already being installed.',
      );
    }

    _installingKeys.add(item.key);
    _notifyListeners();

    try {
      final previewFuture = _presetPreviewFutures[_presetPayloadKey(item)];
      final previewPreset = previewFuture == null ? null : await previewFuture;
      final preset =
          previewPreset ?? await _gateway.fetchPreset(item.source, item.entry);

      if (previewPreset == null) {
        _validateDownloadedPreset(item.entry, preset);
      }

      return await libraryController.installRemote(
        preset: preset,
        sourceId: item.source.id,
        remotePresetId: item.entry.id,
        remoteRevision: item.entry.revision,
      );
    } finally {
      _installingKeys.remove(item.key);
      _notifyListeners();
    }
  }

  Future<void> addSource(PresetRemoteSource source) async {
    _registry = _registry.add(source);
    await _requireSourceStore().saveRegistry(_registry);
    _notifyListeners();
  }

  Future<void> removeSource(String sourceId) async {
    _registry = _registry.remove(sourceId);
    _catalogs.remove(sourceId);
    _sourceErrors.remove(sourceId);
    await _requireSourceStore().saveRegistry(_registry);
    await _requireCache().remove(sourceId);

    final previewCache = _previewCache;
    if (previewCache != null) {
      try {
        await previewCache.removeSource(sourceId);
      } on Object {
        // Preview cleanup is best-effort and must not block source removal.
      }
    }

    _previewFutures.removeWhere((key, _) => key.startsWith('$sourceId:'));
    _presetPreviewFutures.removeWhere((key, _) => key.startsWith('$sourceId:'));
    _notifyListeners();
  }

  Future<void> setSourceEnabled(String sourceId, bool enabled) async {
    _registry = _registry.setEnabled(sourceId, enabled);
    await _requireSourceStore().saveRegistry(_registry);

    if (enabled) {
      final cached = await _requireCache().load(sourceId);
      if (cached != null) {
        _catalogs[sourceId] = cached;
      }
    } else {
      _catalogs.remove(sourceId);
      _sourceErrors.remove(sourceId);
      _previewFutures.removeWhere((key, _) => key.startsWith('$sourceId:'));
      _presetPreviewFutures.removeWhere(
        (key, _) => key.startsWith('$sourceId:'),
      );
    }

    _notifyListeners();
  }

  Future<Uint8List?> _loadPreview(RemotePresetCatalogItem item) async {
    final cache = _previewCache;

    if (cache != null) {
      try {
        final cached = await cache.load(
          sourceId: item.source.id,
          presetId: item.entry.id,
          revision: item.entry.revision,
        );

        if (cached != null && cached.isNotEmpty) {
          return cached;
        }
      } on Object {
        // A corrupt/unreadable preview cache should fall back to the network.
      }
    }

    final previewGateway = _gateway is PresetRemotePreviewGateway
        ? _gateway as PresetRemotePreviewGateway
        : null;

    if (previewGateway == null) {
      return null;
    }

    try {
      final bytes = await previewGateway.fetchPreview(item.source, item.entry);

      if (bytes.isEmpty) {
        return null;
      }

      if (cache != null) {
        try {
          await cache.save(
            sourceId: item.source.id,
            presetId: item.entry.id,
            revision: item.entry.revision,
            bytes: bytes,
          );
        } on Object {
          // Preview caching is best-effort; display the downloaded bytes.
        }
      }

      return bytes;
    } on Object {
      // A missing/broken preview must never block catalog discovery/install.
      return null;
    }
  }

  Future<Preset?> _loadPresetForPreview(RemotePresetCatalogItem item) async {
    try {
      final preset = await _gateway.fetchPreset(item.source, item.entry);
      _validateDownloadedPreset(item.entry, preset);
      return preset;
    } on Object {
      // Live previews are best-effort. Installation retries independently,
      // and a preview failure must not make the remote preset unavailable.
      return null;
    }
  }

  String _previewKey(RemotePresetCatalogItem item) {
    return '${item.source.id}:${item.entry.id}:${item.entry.revision}:'
        '${item.entry.previewPath}';
  }

  String _presetPayloadKey(RemotePresetCatalogItem item) {
    return '${item.source.id}:${item.entry.id}:${item.entry.revision}:'
        '${item.entry.presetPath}';
  }

  void _validateDownloadedPreset(PresetCatalogEntry entry, Preset preset) {
    if (preset.id != entry.id) {
      throw PresetRemoteException(
        'Downloaded preset id ${preset.id} does not match catalog id '
        '${entry.id}.',
      );
    }

    if (preset.revision != entry.revision) {
      throw PresetRemoteException(
        'Downloaded preset revision ${preset.revision} does not match '
        'catalog revision ${entry.revision}.',
      );
    }
  }

  PresetSourceStore _requireSourceStore() {
    final store = _sourceStore;

    if (store == null) {
      throw const PresetRemoteException(
        'Preset source registry is not initialized.',
      );
    }

    return store;
  }

  PresetCatalogCache _requireCache() {
    final cache = _catalogCache;

    if (cache == null) {
      throw const PresetRemoteException(
        'Preset catalog cache is not initialized.',
      );
    }

    return cache;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
