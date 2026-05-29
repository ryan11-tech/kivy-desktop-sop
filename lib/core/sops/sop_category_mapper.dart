import '../models/content_item.dart';

/// A set of SOPs sharing a `sopType`, used to section the home screen.
class SopGroup {
  const SopGroup({required this.key, required this.label, required this.items});

  final String key;
  final String label;
  final List<ContentItem> items;
}

// Friendly labels for the backend's built-in sopType keys. The staff payload
// has no category names, so sopType is the only human-readable grouping axis.
// This mapper is deliberately isolated so a future staff category endpoint can
// replace it without touching the controller or UI.
const _knownSopTypeLabels = <String, String>{
  'opening': 'Opening',
  'closing': 'Closing',
  'cleaning': 'Cleaning',
  'prep': 'Prep',
  'maintenance': 'Maintenance',
  'inventory': 'Inventory',
  'safety': 'Safety',
  'training': 'Training',
  'other': 'Other',
};

// Display order for known types; unknown custom types sort alphabetically after.
const _knownSopTypeOrder = <String>[
  'opening',
  'closing',
  'cleaning',
  'prep',
  'maintenance',
  'inventory',
  'safety',
  'training',
  'other',
];

const _fallbackSopTypeKey = 'other';

/// Maps a `sopType` key to a display label, title-casing unknown custom keys.
String sopTypeLabel(String sopType) {
  final key = sopType.trim();
  if (key.isEmpty) {
    return _knownSopTypeLabels[_fallbackSopTypeKey]!;
  }

  final known = _knownSopTypeLabels[key];
  if (known != null) {
    return known;
  }

  return key
      .split(RegExp(r'[_-]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

/// Groups [items] by `sopType`, ordered by [_knownSopTypeOrder] then
/// alphabetically, with items inside each group sorted by `order`.
List<SopGroup> groupBySopType(List<ContentItem> items) {
  final byKey = <String, List<ContentItem>>{};
  for (final item in items) {
    final trimmed = item.sop.sopType.trim();
    final key = trimmed.isEmpty ? _fallbackSopTypeKey : trimmed;
    (byKey[key] ??= <ContentItem>[]).add(item);
  }

  int rank(String key) {
    final index = _knownSopTypeOrder.indexOf(key);
    return index == -1 ? _knownSopTypeOrder.length : index;
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
        label: sopTypeLabel(key),
        items: [...byKey[key]!]
          ..sort((left, right) => left.order.compareTo(right.order)),
      ),
  ];
}
