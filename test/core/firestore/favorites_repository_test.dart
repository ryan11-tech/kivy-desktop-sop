import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zinme_app/core/firestore/favorites_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists favorites by user and active shop', () async {
    var shopId = 'shop-a';
    final repository = SharedPreferencesFavoritesRepository(
      shopIdProvider: () => shopId,
    );

    await repository.saveFavoriteIds('u1', {'sop-1', 'recipe-1'});
    expect(await repository.loadFavoriteIds('u1'), {'sop-1', 'recipe-1'});

    shopId = 'shop-b';
    expect(await repository.loadFavoriteIds('u1'), isEmpty);
    await repository.saveFavoriteIds('u1', {'sop-2'});

    shopId = 'shop-a';
    expect(await repository.loadFavoriteIds('u1'), {'sop-1', 'recipe-1'});
    expect(await repository.loadFavoriteIds('u2'), isEmpty);
  });
}
