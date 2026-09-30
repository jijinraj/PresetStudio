import 'package:flutter/foundation.dart';

import 'preset_browse_model.dart';
import 'preset_favorite_store.dart';

class PresetFavoritesException implements Exception {
  const PresetFavoritesException(this.message);

  final String message;

  @override
  String toString() => 'PresetFavoritesException: $message';
}

class PresetFavoritesController extends ChangeNotifier {
  PresetFavoritesController({required this._storeLoader});

  final Future<PresetFavoriteStore> Function() _storeLoader;

  PresetFavoriteStore? _store;
  Set<String> _favoriteIds = const <String>{};
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<String> get favoriteIds => Set<String>.unmodifiable(_favoriteIds);

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      final store = await _storeLoader();
      final loaded = await store.loadFavoriteIds();
      _store = store;
      _favoriteIds = Set<String>.unmodifiable(loaded.map(_normalizeFavoriteId));
      _isInitialized = true;
    } on Object catch (error) {
      _errorMessage = 'Preset favorites could not be loaded: $error';
      rethrow;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  bool isFavoriteId(String favoriteId) {
    return _favoriteIds.contains(_normalizeFavoriteId(favoriteId));
  }

  bool isFavorite(PresetBrowseItem item) => isFavoriteId(item.key);

  Future<bool> toggle(PresetBrowseItem item) async {
    return setFavorite(item, favorite: !isFavorite(item));
  }

  Future<bool> setFavorite(
    PresetBrowseItem item, {
    required bool favorite,
  }) async {
    final store = _requireStore();
    final favoriteId = _normalizeFavoriteId(item.key);
    final next = Set<String>.from(_favoriteIds);
    final changed = favorite ? next.add(favoriteId) : next.remove(favoriteId);

    if (!changed) {
      return favorite;
    }

    try {
      await store.saveFavoriteIds(next);
      _favoriteIds = Set<String>.unmodifiable(next);
      _errorMessage = null;
      _notifyListeners();
      return favorite;
    } on Object catch (error) {
      _errorMessage = 'Preset favorite could not be saved: $error';
      _notifyListeners();
      rethrow;
    }
  }

  PresetFavoriteStore _requireStore() {
    final store = _store;
    if (!_isInitialized || store == null) {
      throw const PresetFavoritesException(
        'Preset favorites are not ready yet.',
      );
    }
    return store;
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

String _normalizeFavoriteId(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw const PresetFavoritesException('Favorite id must not be empty.');
  }
  return normalized;
}
