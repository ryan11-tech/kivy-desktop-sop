import '../models/content_item.dart';
import '../models/member.dart';

abstract class ItemRepository {
  Future<List<ContentItem>> listVisibleItems(Member member);
}
