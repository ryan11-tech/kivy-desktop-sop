import '../api/api_exceptions.dart';
import '../firestore/mock_catalog_repository.dart';
import '../models/content_item.dart';
import 'recipe_repository.dart';

/// Wraps a remote [RecipeRepository] and, only when [useMock] is set, serves
/// bundled mock recipes if the network call fails.
///
/// Fallback is intentionally narrow: it triggers only on [NetworkException].
/// Auth (401), client (403/4xx), and server (5xx) failures propagate so the UI
/// can show the right access/error state instead of masking it with mocks.
class FallbackRecipeRepository implements RecipeRepository {
  const FallbackRecipeRepository(this._remote, {required this.useMock});

  final RecipeRepository _remote;
  final bool useMock;

  @override
  Future<List<ContentItem>> listShopRecipes(String shopId) async {
    try {
      return await _remote.listShopRecipes(shopId);
    } on NetworkException {
      if (!useMock) {
        rethrow;
      }
      return mockItems
          .where((item) => item.isRecipe && item.isPublished)
          .toList()
        ..sort((left, right) => left.order.compareTo(right.order));
    }
  }
}
