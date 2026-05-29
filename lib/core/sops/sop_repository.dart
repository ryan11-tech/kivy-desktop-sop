import '../models/content_item.dart';

/// Source of SOP content for a single shop.
abstract class SopRepository {
  /// Returns the published SOPs visible to the staff user for [shopId].
  Future<List<ContentItem>> listShopSops(String shopId);
}
