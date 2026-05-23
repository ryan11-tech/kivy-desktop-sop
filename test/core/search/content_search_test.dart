import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/firestore/mock_catalog_repository.dart';
import 'package:zinme_app/core/models/category.dart';
import 'package:zinme_app/core/search/content_search.dart';

void main() {
  test('searches names, categories, parameters, and steps', () {
    final categoriesById = <String, Category>{
      for (final category in mockCategories) category.id: category,
    };

    expect(
      searchContentItems(
        items: mockItems,
        categoriesById: categoriesById,
        query: 'milk',
      ).map((item) => item.id),
      contains('classic_milk_tea'),
    );

    expect(
      searchContentItems(
        items: mockItems,
        categoriesById: categoriesById,
        query: 'fridge',
      ).map((item) => item.id),
      contains('closing_checklist'),
    );

    expect(
      searchContentItems(
        items: mockItems,
        categoriesById: categoriesById,
        query: 'black leaves',
      ).map((item) => item.id),
      contains('black_tea_base_draft'),
    );
  });
}
