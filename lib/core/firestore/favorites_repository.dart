abstract class FavoritesRepository {
  Future<Set<String>> loadFavoriteIds(String uid);
  Future<void> saveFavoriteIds(String uid, Set<String> itemIds);
}

class InMemoryFavoritesRepository implements FavoritesRepository {
  InMemoryFavoritesRepository({Set<String>? initialFavorites})
    : _favoriteIds = Set<String>.from(initialFavorites ?? const <String>{});

  Set<String> _favoriteIds;

  @override
  Future<Set<String>> loadFavoriteIds(String uid) async {
    return Set<String>.unmodifiable(_favoriteIds);
  }

  @override
  Future<void> saveFavoriteIds(String uid, Set<String> itemIds) async {
    _favoriteIds = Set<String>.from(itemIds);
  }
}
