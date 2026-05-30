import '../api/staff_api_client.dart';
import '../models/content_item.dart';
import 'recipe_repository.dart';

/// [RecipeRepository] backed by the staff recipe endpoint.
class RemoteRecipeRepository implements RecipeRepository {
  const RemoteRecipeRepository(this._api);

  final StaffApiClient _api;

  @override
  Future<List<ContentItem>> listShopRecipes(String shopId) async {
    final items = await _api.listShopRecipes(shopId);
    return [...items]..sort((left, right) => left.order.compareTo(right.order));
  }
}
