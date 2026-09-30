abstract interface class PresetFavoriteStore {
  Future<Set<String>> loadFavoriteIds();

  Future<void> saveFavoriteIds(Set<String> favoriteIds);
}
