import '../models/content_item.dart';

/// Source of recipe content for a single shop.
abstract class RecipeRepository {
  /// Returns the published recipes visible to the staff user for [shopId].
  Future<List<ContentItem>> listShopRecipes(String shopId);
}
