import '../api/staff_api_client.dart';
import '../models/content_item.dart';
import 'sop_repository.dart';

/// [SopRepository] backed by the staff SOP endpoint.
class RemoteSopRepository implements SopRepository {
  const RemoteSopRepository(this._api);

  final StaffApiClient _api;

  @override
  Future<List<ContentItem>> listShopSops(String shopId) async {
    final items = await _api.listShopSops(shopId);
    return [...items]..sort((left, right) => left.order.compareTo(right.order));
  }
}
