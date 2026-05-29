import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/core/models/content_item.dart';
import 'package:zinme_app/core/models/parameter.dart';
import 'package:zinme_app/core/sops/remote_sop_repository.dart';

class _MockApi extends Mock implements StaffApiClient {}

ContentItem _sop(String id, int order) {
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
    sop: const SopContent(
      sopType: 'opening',
      parameters: <Parameter>[],
      steps: <String>[],
    ),
    order: order,
  );
}

void main() {
  test('calls listShopSops and sorts by order', () async {
    final api = _MockApi();
    when(
      () => api.listShopSops('shop-1'),
    ).thenAnswer((_) async => [_sop('b', 30), _sop('a', 10), _sop('c', 20)]);

    final repo = RemoteSopRepository(api);
    final items = await repo.listShopSops('shop-1');

    expect(items.map((item) => item.id), <String>['a', 'c', 'b']);
    verify(() => api.listShopSops('shop-1')).called(1);
  });

  test('handles an empty list', () async {
    final api = _MockApi();
    when(
      () => api.listShopSops(any()),
    ).thenAnswer((_) async => const <ContentItem>[]);

    final repo = RemoteSopRepository(api);

    expect(await repo.listShopSops('shop-1'), isEmpty);
  });
}
