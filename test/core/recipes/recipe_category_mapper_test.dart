import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/models/content_item.dart';
import 'package:zinme_app/core/models/parameter.dart';
import 'package:zinme_app/core/recipes/recipe_category_mapper.dart';

ContentItem _recipe(String id, String recipeType, int order) {
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
  test('labels known and unknown recipe types', () {
    expect(recipeTypeLabel('drink'), 'Drinks');
    expect(recipeTypeLabel('cold_brew'), 'Cold Brew');
    expect(recipeTypeLabel('house-blend'), 'House Blend');
    expect(recipeTypeLabel(''), 'Other');
  });

  test('groups by recipe type: known order first, then alphabetical', () {
    final groups = groupByRecipeType([
      _recipe('z', 'zebra', 1),
      _recipe('p', 'prep', 1),
      _recipe('d', 'drink', 1),
      _recipe('a', 'apple', 1),
    ]);

    expect(groups.map((group) => group.key), <String>[
      'drink',
      'prep',
      'apple',
      'zebra',
    ]);
  });

  test('sorts items within a group by order', () {
    final groups = groupByRecipeType([
      _recipe('b', 'drink', 30),
      _recipe('a', 'drink', 10),
    ]);

    expect(groups.single.items.map((item) => item.id), <String>['a', 'b']);
  });

  test('empty recipe type buckets into other', () {
    final groups = groupByRecipeType([_recipe('x', '', 1)]);

    expect(groups.single.key, 'other');
    expect(groups.single.label, 'Other');
  });
}
