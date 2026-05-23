import '../models/category.dart';
import '../models/content_item.dart';

List<ContentItem> searchContentItems({
  required List<ContentItem> items,
  required Map<String, Category> categoriesById,
  required String query,
}) {
  final tokens = query
      .trim()
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();

  if (tokens.isEmpty) {
    return items;
  }

  return items.where((item) {
    final category = categoriesById[item.categoryId];
    final haystack = _searchText(item, category).toLowerCase();
    return tokens.every(haystack.contains);
  }).toList();
}

String _searchText(ContentItem item, Category? category) {
  final parts = <String>[
    item.name,
    item.kindLabel,
    item.subtypeLabel,
    item.notes,
    category?.name ?? '',
  ];

  if (item.isRecipe) {
    parts.addAll(item.recipe.parameters.map((parameter) => parameter.name));
    parts.addAll(item.recipe.steps);
    for (final variant in item.recipe.variants) {
      parts
        ..add(variant.key)
        ..add(variant.name)
        ..addAll(variant.parameters.map((parameter) => parameter.name))
        ..addAll(variant.steps);
    }
  } else {
    parts
      ..addAll(item.sop.parameters.map((parameter) => parameter.name))
      ..addAll(item.sop.steps);
  }

  return parts.join(' ');
}
