import 'package:flutter_test/flutter_test.dart';

import 'package:zinme_app/core/staff/shop.dart';

void main() {
  group('Shop', () {
    test('round-trips through JSON with role', () {
      const shop = Shop(id: 's1', name: 'Sukhumvit', role: 'barista');
      final parsed = Shop.fromJson(shop.toJson());

      expect(parsed.id, 's1');
      expect(parsed.name, 'Sukhumvit');
      expect(parsed.role, 'barista');
    });

    test('omits role when null', () {
      const shop = Shop(id: 's1', name: 'Sukhumvit');
      final json = shop.toJson();

      expect(json.containsKey('role'), isFalse);
    });
  });
}
