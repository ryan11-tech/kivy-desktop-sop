import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/models/content_item.dart';
import 'package:zinme_app/core/models/parameter.dart';
import 'package:zinme_app/core/recipes/recipe_catalog_controller.dart';
import 'package:zinme_app/core/recipes/recipe_repository.dart';
import 'package:zinme_app/core/sops/sop_catalog_controller.dart'
    show SopCatalogStatus;
import 'package:zinme_app/core/staff/shop.dart';

class _FakeRepo implements RecipeRepository {
  final Map<String, List<ContentItem>> byShop = <String, List<ContentItem>>{};
  final Map<String, Object> errorByShop = <String, Object>{};
  int calls = 0;

  @override
  Future<List<ContentItem>> listShopRecipes(String shopId) async {
    calls++;
    final error = errorByShop[shopId];
    if (error != null) {
      throw error;
    }
    return byShop[shopId] ?? const <ContentItem>[];
  }
}

ContentItem _recipe(String id, {String recipeType = 'drink', int order = 0}) {
  return ContentItem(
    id: id,
    contentType: ContentType.recipe,
    status: ContentStatus.published,
    categoryId: '',
    name: id,
    notes: '',
    imageUrl: '',
    imagePath: '',
    recipe: RecipeContent(
      recipeType: recipeType,
      parameters: const <Parameter>[],
      steps: const <String>[],
      variants: const [],
    ),
    sop: SopContent.empty(),
    order: order,
  );
}

void main() {
  test('null shop yields noShopSelected', () async {
    final controller = RecipeCatalogController(_FakeRepo());

    await controller.loadForShop(null);

    expect(controller.status, SopCatalogStatus.noShopSelected);
    expect(controller.groups, isEmpty);
  });

  test('selected shop loads and groups recipes', () async {
    final repo =
        _FakeRepo()
          ..byShop['s1'] = [
            _recipe('a', recipeType: 'prep'),
            _recipe('b', recipeType: 'drink'),
          ];
    final controller = RecipeCatalogController(repo);

    await controller.loadForShop(const Shop(id: 's1', name: 'S1'));

    expect(controller.status, SopCatalogStatus.loaded);
    expect(controller.groups.map((group) => group.key), <String>[
      'drink',
      'prep',
    ]);
  });

  test('empty result yields empty state', () async {
    final repo = _FakeRepo()..byShop['s1'] = <ContentItem>[];
    final controller = RecipeCatalogController(repo);

    await controller.loadForShop(const Shop(id: 's1', name: 'S1'));

    expect(controller.status, SopCatalogStatus.empty);
  });

  test('403 maps to permissionDenied', () async {
    final repo =
        _FakeRepo()
          ..errorByShop['s1'] = const ClientApiException(
            'forbidden',
            statusCode: 403,
          );
    final controller = RecipeCatalogController(repo);

    await controller.loadForShop(const Shop(id: 's1', name: 'S1'));

    expect(controller.status, SopCatalogStatus.permissionDenied);
  });

  test('network failure maps to error', () async {
    final repo =
        _FakeRepo()..errorByShop['s1'] = const NetworkException('offline');
    final controller = RecipeCatalogController(repo);

    await controller.loadForShop(const Shop(id: 's1', name: 'S1'));

    expect(controller.status, SopCatalogStatus.error);
  });

  test('changing shop reloads and clears the previous shop groups', () async {
    final repo =
        _FakeRepo()
          ..byShop['s1'] = [_recipe('a')]
          ..errorByShop['s2'] = const NetworkException('offline');
    final controller = RecipeCatalogController(repo);

    await controller.loadForShop(const Shop(id: 's1', name: 'S1'));
    expect(controller.status, SopCatalogStatus.loaded);
    expect(controller.groups, isNotEmpty);

    await controller.loadForShop(const Shop(id: 's2', name: 'S2'));
    expect(controller.status, SopCatalogStatus.error);
    expect(controller.groups, isEmpty);
  });

  test('reselecting the same shop does not reload', () async {
    final repo = _FakeRepo()..byShop['s1'] = [_recipe('a')];
    final controller = RecipeCatalogController(repo);

    await controller.loadForShop(const Shop(id: 's1', name: 'S1'));
    await controller.loadForShop(const Shop(id: 's1', name: 'S1'));

    expect(repo.calls, 1);
  });

  test(
    'force reloads the same shop so published updates can be fetched',
    () async {
      final repo = _FakeRepo()..byShop['s1'] = [_recipe('a')];
      final controller = RecipeCatalogController(repo);
      const shop = Shop(id: 's1', name: 'S1');

      await controller.loadForShop(shop);
      repo.byShop['s1'] = [_recipe('b')];
      await controller.loadForShop(shop, force: true);

      expect(repo.calls, 2);
      expect(controller.groups.single.items.single.id, 'b');
    },
  );
}
