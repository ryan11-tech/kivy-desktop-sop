import '../models/content_item.dart';
import '../sops/sop_category_mapper.dart' show SopGroup;

// Friendly labels for the backend's built-in recipeType keys. The staff payload
// has no category names, so recipeType is the only human-readable grouping axis
// — mirrors the SOP side. Isolated so a future staff category endpoint can
// replace it without touching the controller or UI.
const _knownRecipeTypeLabels = <String, String>{
  'drink': 'Drinks',
  'base': 'Bases',
  'food': 'Food',
  'prep': 'Prep',
  'other': 'Other',
};

// Display order for known types; unknown custom types sort alphabetically after.
const _knownRecipeTypeOrder = <String>[
  'drink',
  'base',
  'food',
  'prep',
  'other',
];

const _fallbackRecipeTypeKey = 'other';

/// Maps a `recipeType` key to a display label, title-casing unknown custom keys.
String recipeTypeLabel(String recipeType) {
  final key = recipeType.trim();
  if (key.isEmpty) {
    return _knownRecipeTypeLabels[_fallbackRecipeTypeKey]!;
  }

  final known = _knownRecipeTypeLabels[key];
  if (known != null) {
    return known;
  }

  return key
      .split(RegExp(r'[_-]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

/// Groups [items] by `recipeType`, ordered by [_knownRecipeTypeOrder] then
/// alphabetically, with items inside each group sorted by `order`.
List<SopGroup> groupByRecipeType(List<ContentItem> items) {
  final byKey = <String, List<ContentItem>>{};
  for (final item in items) {
    final trimmed = item.recipe.recipeType.trim();
    final key = trimmed.isEmpty ? _fallbackRecipeTypeKey : trimmed;
    (byKey[key] ??= <ContentItem>[]).add(item);
  }

  int rank(String key) {
    final index = _knownRecipeTypeOrder.indexOf(key);
    return index == -1 ? _knownRecipeTypeOrder.length : index;
  }

  final keys =
      byKey.keys.toList()..sort((left, right) {
        final byRank = rank(left).compareTo(rank(right));
        return byRank != 0 ? byRank : left.compareTo(right);
      });

  return <SopGroup>[
    for (final key in keys)
      SopGroup(
        key: key,
        label: recipeTypeLabel(key),
        items: [...byKey[key]!]
          ..sort((left, right) => left.order.compareTo(right.order)),
      ),
  ];
}
