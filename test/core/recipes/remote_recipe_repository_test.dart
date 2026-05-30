import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/core/models/content_item.dart';
import 'package:zinme_app/core/models/parameter.dart';
import 'package:zinme_app/core/recipes/remote_recipe_repository.dart';

class _MockApi extends Mock implements StaffApiClient {}

ContentItem _recipe(String id, int order) {
  return ContentItem(
    id: id,
    contentType: ContentType.recipe,
    status: ContentStatus.published,
    categoryId: '',
    name: id,
    notes: '',
    imageUrl: '',
    imagePath: '',
    recipe: const RecipeContent(
      recipeType: 'drink',
      parameters: <Parameter>[],
      steps: <String>[],
      variants: [],
    ),
    sop: SopContent.empty(),
    order: order,
  );
}

void main() {
  test('calls listShopRecipes and sorts by order', () async {
    final api = _MockApi();
    when(() => api.listShopRecipes('shop-1')).thenAnswer(
      (_) async => [_recipe('b', 30), _recipe('a', 10), _recipe('c', 20)],
    );

    final repo = RemoteRecipeRepository(api);
    final items = await repo.listShopRecipes('shop-1');

    expect(items.map((item) => item.id), <String>['a', 'c', 'b']);
    verify(() => api.listShopRecipes('shop-1')).called(1);
  });

  test('handles an empty list', () async {
    final api = _MockApi();
    when(
      () => api.listShopRecipes(any()),
    ).thenAnswer((_) async => const <ContentItem>[]);

    final repo = RemoteRecipeRepository(api);

    expect(await repo.listShopRecipes('shop-1'), isEmpty);
  });
}
