import 'package:flutter_test/flutter_test.dart';

import 'package:zinme_app/core/staff/staff_profile.dart';

void main() {
  group('StaffProfile.fromJson', () {
    test('parses profile and assigned shops', () {
      final profile = StaffProfile.fromJson(<String, Object?>{
        'profile': <String, Object?>{
          'id': 'p1',
          'email': 'su@example.com',
          'displayName': 'Su Su',
          'preferredName': 'Su',
          'phone': '0801234567',
          'lineId': 'su_line',
          'accountRole': 'staff',
          'status': 'active',
          'staffCode': 'CS1234',
        },
        'shops': <Object?>[
          <String, Object?>{'id': 's1', 'name': 'Wat Ket', 'role': 'cashier'},
          <String, Object?>{'id': 's2', 'name': 'HQ', 'role': null},
        ],
      });

      expect(profile.id, 'p1');
      expect(profile.email, 'su@example.com');
      expect(profile.displayName, 'Su Su');
      expect(profile.preferredName, 'Su');
      expect(profile.phone, '0801234567');
      expect(profile.lineId, 'su_line');
      expect(profile.accountRole, 'staff');
      expect(profile.status, 'active');
      expect(profile.staffCode, 'CS1234');
      expect(profile.shops.length, 2);
      expect(profile.shops.first.name, 'Wat Ket');
      expect(profile.shops.first.role, 'cashier');
      expect(profile.shops.last.role, isNull);
    });

    test('treats blank optionals as null and ignores forbidden fields', () {
      final profile = StaffProfile.fromJson(<String, Object?>{
        'profile': <String, Object?>{
          'id': 'p1',
          'email': 'su@example.com',
          'displayName': 'Su Su',
          'preferredName': '',
          'phone': null,
          'lineId': '',
          'accountRole': 'staff',
          'status': 'active',
          'staffCode': null,
          // Manager-controlled data that must never surface on the model.
          'membershipStatus': 'active',
          'permissionsByShop': <String, Object?>{
            's1': <Object?>['*'],
          },
          'mustChangePassword': false,
          'emergencyContactName': 'Mom',
          'preferredLanguage': 'my',
        },
        'shops': const <Object?>[],
      });

      expect(profile.preferredName, isNull);
      expect(profile.phone, isNull);
      expect(profile.lineId, isNull);
      expect(profile.staffCode, isNull);
      expect(profile.shops, isEmpty);
    });
  });

  group('StaffProfileUpdate.toJson', () {
    test('serializes only the four editable fields', () {
      const update = StaffProfileUpdate(
        displayName: 'Su Su',
        preferredName: 'Su',
        phone: '0801234567',
        lineId: 'su_line',
      );

      expect(update.toJson(), <String, Object?>{
        'displayName': 'Su Su',
        'preferredName': 'Su',
        'phone': '0801234567',
        'lineId': 'su_line',
      });
    });

    test('trims and collapses blank optionals to null', () {
      const update = StaffProfileUpdate(
        displayName: '  Su Su  ',
        preferredName: '   ',
        phone: '',
        lineId: '  line42  ',
      );

      final json = update.toJson();
      expect(json['displayName'], 'Su Su');
      expect(json['preferredName'], isNull);
      expect(json['phone'], isNull);
      expect(json['lineId'], 'line42');
      expect(json.keys.toSet(), <String>{
        'displayName',
        'preferredName',
        'phone',
        'lineId',
      });
    });
  });
}
