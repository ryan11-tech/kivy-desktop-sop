import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/models/content_item.dart';
import 'package:zinme_app/core/models/parameter.dart';
import 'package:zinme_app/core/sops/sop_category_mapper.dart';

ContentItem _sop(String id, String sopType, int order) {
  return ContentItem(
    id: id,
    contentType: ContentType.sop,
    status: ContentStatus.published,
    categoryId: '',
    name: id,
    notes: '',
    imageUrl: '',
    imagePath: '',
    recipe: RecipeContent.empty(),
    sop: SopContent(
      sopType: sopType,
      parameters: const <Parameter>[],
      steps: const <String>[],
    ),
    order: order,
  );
}

void main() {
  test('labels known and unknown sop types', () {
    expect(sopTypeLabel('opening'), 'Opening');
    expect(sopTypeLabel('food_safety'), 'Food Safety');
    expect(sopTypeLabel('bar-prep'), 'Bar Prep');
    expect(sopTypeLabel(''), 'Other');
  });

  test('groups by sop type: known order first, then alphabetical', () {
    final groups = groupBySopType([
      _sop('z', 'zebra', 1),
      _sop('c', 'cleaning', 1),
      _sop('o', 'opening', 1),
      _sop('a', 'apple', 1),
    ]);

    expect(groups.map((group) => group.key), <String>[
      'opening',
      'cleaning',
      'apple',
      'zebra',
    ]);
  });

  test('sorts items within a group by order', () {
    final groups = groupBySopType([
      _sop('b', 'opening', 30),
      _sop('a', 'opening', 10),
    ]);

    expect(groups.single.items.map((item) => item.id), <String>['a', 'b']);
  });

  test('empty sop type buckets into other', () {
    final groups = groupBySopType([_sop('x', '', 1)]);

    expect(groups.single.key, 'other');
    expect(groups.single.label, 'Other');
  });
}
