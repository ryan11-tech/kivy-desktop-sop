import '../api/api_exceptions.dart';
import '../firestore/mock_catalog_repository.dart';
import '../models/content_item.dart';
import 'sop_repository.dart';

/// Wraps a remote [SopRepository] and, only when [useMock] is set, serves
/// bundled mock SOPs if the network call fails.
///
/// Fallback is intentionally narrow: it triggers only on [NetworkException].
/// Auth (401), client (403/4xx), and server (5xx) failures propagate so the UI
/// can show the right access/error state instead of masking it with mocks.
class FallbackSopRepository implements SopRepository {
  const FallbackSopRepository(this._remote, {required this.useMock});

  final SopRepository _remote;
  final bool useMock;

  @override
  Future<List<ContentItem>> listShopSops(String shopId) async {
    try {
      return await _remote.listShopSops(shopId);
    } on NetworkException {
      if (!useMock) {
        rethrow;
      }
      return mockItems.where((item) => item.isSop && item.isPublished).toList()
        ..sort((left, right) => left.order.compareTo(right.order));
    }
  }
}
