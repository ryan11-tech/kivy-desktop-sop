import '../models/category.dart';
import '../models/content_item.dart';
import '../models/member.dart';
import '../models/parameter.dart';
import '../models/recipe_variant.dart';
import 'category_repository.dart';
import 'item_repository.dart';

class MockCategoryRepository implements CategoryRepository {
  const MockCategoryRepository();

  @override
  Future<List<Category>> listCategories() async {
    final categories = List<Category>.from(mockCategories);
    categories.sort((left, right) => left.order.compareTo(right.order));
    return categories;
  }
}

class MockItemRepository implements ItemRepository {
  const MockItemRepository();

  @override
  Future<List<ContentItem>> listVisibleItems(Member member) async {
    final items = mockItems.where((item) => item.canBeSeenBy(member)).toList()
      ..sort((left, right) => left.order.compareTo(right.order));

    return items;
  }
}

const mockCategories = <Category>[
  Category(id: 'milk_tea', name: 'Milk Tea', icon: 'T', order: 10),
  Category(id: 'opening', name: 'Opening SOP', icon: 'O', order: 20),
  Category(id: 'prep', name: 'Prep Bases', icon: 'B', order: 30),
];

const mockItems = <ContentItem>[
  ContentItem(
    id: 'classic_milk_tea',
    contentType: ContentType.recipe,
    status: ContentStatus.published,
    categoryId: 'milk_tea',
    name: 'Classic Milk Tea',
    notes: 'Balanced house milk tea with hot and cold workflows.',
    imageUrl: '',
    imagePath: '',
    recipe: RecipeContent(
      recipeType: 'drink',
      parameters: <Parameter>[],
      steps: <String>[],
      variants: <RecipeVariant>[
        RecipeVariant(
          key: 'hot',
          name: 'Hot',
          parameters: <Parameter>[
            Parameter(name: 'Tea base', amount: 150, unit: 'ml'),
            Parameter(name: 'Milk', amount: 40, unit: 'ml'),
            Parameter(name: 'Sugar syrup', amount: 18, unit: 'ml'),
          ],
          steps: <String>[
            'Warm the serving cup.',
            'Add tea base, milk, and syrup.',
            'Stir until the color is even.',
          ],
        ),
        RecipeVariant(
          key: 'cold',
          name: 'Cold',
          parameters: <Parameter>[
            Parameter(name: 'Tea base', amount: 180, unit: 'ml'),
            Parameter(name: 'Milk', amount: 35, unit: 'ml'),
            Parameter(name: 'Ice', amount: 1, unit: 'cup'),
          ],
          steps: <String>[
            'Fill the shaker with ice.',
            'Add tea base and milk.',
            'Shake and pour into the cup.',
          ],
        ),
      ],
    ),
    sop: SopContent(
      sopType: 'other',
      parameters: <Parameter>[],
      steps: <String>[],
    ),
    order: 10,
  ),
  ContentItem(
    id: 'closing_checklist',
    contentType: ContentType.sop,
    status: ContentStatus.published,
    categoryId: 'opening',
    name: 'Opening Counter Checklist',
    notes: 'Daily setup before first customer service.',
    imageUrl: '',
    imagePath: '',
    recipe: RecipeContent(
      recipeType: 'other',
      parameters: <Parameter>[],
      steps: <String>[],
      variants: <RecipeVariant>[],
    ),
    sop: SopContent(
      sopType: 'opening',
      parameters: <Parameter>[
        Parameter(name: 'Sanitizer check', amount: 1, unit: 'round'),
        Parameter(name: 'Fridge temperature', amount: 4, unit: 'C'),
      ],
      steps: <String>[
        'Turn on lights and counter equipment.',
        'Check fridge temperature and sanitizer level.',
        'Prepare cups, lids, straws, and receipt paper.',
      ],
    ),
    order: 20,
  ),
  ContentItem(
    id: 'black_tea_base_draft',
    contentType: ContentType.recipe,
    status: ContentStatus.draft,
    categoryId: 'prep',
    name: 'Black Tea Base Draft',
    notes: 'Visible to admins only until the brew timing is approved.',
    imageUrl: '',
    imagePath: '',
    recipe: RecipeContent(
      recipeType: 'base',
      parameters: <Parameter>[
        Parameter(name: 'Black tea leaves', amount: 45, unit: 'g'),
        Parameter(name: 'Hot water', amount: 1500, unit: 'ml'),
      ],
      steps: <String>[
        'Steep tea leaves in hot water.',
        'Strain into a labeled container.',
      ],
      variants: <RecipeVariant>[],
    ),
    sop: SopContent(
      sopType: 'other',
      parameters: <Parameter>[],
      steps: <String>[],
    ),
    order: 30,
  ),
];
