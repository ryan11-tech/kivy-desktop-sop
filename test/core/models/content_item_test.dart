import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/firestore/mock_catalog_repository.dart';
import 'package:zinme_app/core/models/content_item.dart';
import 'package:zinme_app/core/models/member.dart';
import 'package:zinme_app/core/models/parameter.dart';
import 'package:zinme_app/core/models/recipe_variant.dart';

void main() {
  test('serializes and validates a drink recipe', () {
    final item = mockItems.first;
    final json = item.toJson();
    final parsed = ContentItem.fromJson(item.id, json);

    expect(parsed.contentType, ContentType.recipe);
    expect(parsed.recipe.recipeType, 'drink');
    expect(parsed.validate(), isEmpty);
  });

  test('scales parameters with a serving multiplier', () {
    const parameter = Parameter(name: 'Tea base', amount: 150, unit: 'ml');

    expect(parameter.scaledBy(3).amount, 450);
    expect(parameter.scaledBy(3).formattedAmount, '450');
  });

  test('enforces draft visibility for staff', () {
    final draft = mockItems.firstWhere(
      (item) => item.status == ContentStatus.draft,
    );

    expect(draft.canBeSeenBy(DemoAccounts.admin), isTrue);
    expect(draft.canBeSeenBy(DemoAccounts.staff), isFalse);
  });

  test('requires hot and cold variants for drink recipes', () {
    const item = ContentItem(
      id: 'bad_drink',
      contentType: ContentType.recipe,
      status: ContentStatus.draft,
      categoryId: 'milk_tea',
      name: 'Bad Drink',
      notes: '',
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
              Parameter(name: 'Tea', amount: 1, unit: 'cup'),
            ],
            steps: <String>[],
          ),
        ],
      ),
      sop: SopContent(
        sopType: 'other',
        parameters: <Parameter>[],
        steps: <String>[],
      ),
      order: 0,
    );

    expect(
      item.validate().map((issue) => issue.field),
      contains('recipe.variants'),
    );
  });

  test('normalizes email and creates deterministic grant keys', () {
    expect(Member.normalizeEmail(' Staff@Gmail.COM '), 'staff@gmail.com');
    expect(Member.emailKey('Staff+Shop@gmail.com'), 'staff_shop_gmail_com');
  });
}
