import 'package:shared_preferences/shared_preferences.dart';

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

class SharedPreferencesFavoritesRepository implements FavoritesRepository {
  SharedPreferencesFavoritesRepository({
    required String Function() shopIdProvider,
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _shopIdProvider = shopIdProvider,
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  final String Function() _shopIdProvider;
  final Future<SharedPreferences> Function() _preferencesProvider;

  static const _prefix = 'zinme.favorites';

  @override
  Future<Set<String>> loadFavoriteIds(String uid) async {
    final prefs = await _preferencesProvider();
    return Set<String>.unmodifiable(
      prefs.getStringList(_key(uid)) ?? const <String>[],
    );
  }

  @override
  Future<void> saveFavoriteIds(String uid, Set<String> itemIds) async {
    final prefs = await _preferencesProvider();
    final values = itemIds.toList()..sort();
    await prefs.setStringList(_key(uid), values);
  }

  String _key(String uid) {
    final shopId = _shopIdProvider();
    return '$_prefix.$uid.$shopId';
  }
}
