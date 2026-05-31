import 'package:flutter_test/flutter_test.dart';

import 'package:zinme_app/core/staff/staff_user.dart';

void main() {
  group('StaffUser', () {
    test('round-trips through JSON', () {
      const user = StaffUser(
        id: 'u1',
        email: 'a@b.c',
        displayName: 'Alice',
        requiresPasswordChange: true,
      );

      final parsed = StaffUser.fromJson(user.toJson());

      expect(parsed.id, user.id);
      expect(parsed.email, user.email);
      expect(parsed.displayName, user.displayName);
      expect(parsed.requiresPasswordChange, isTrue);
    });

    test('falls back to name when displayName absent', () {
      final parsed = StaffUser.fromJson(<String, Object?>{
        'id': 'u1',
        'email': 'a@b.c',
        'name': 'Old Name',
      });

      expect(parsed.displayName, 'Old Name');
      expect(parsed.requiresPasswordChange, isFalse);
    });

    test('reads profile fields from the staff session payload', () {
      final parsed = StaffUser.fromStaffSessionJson(<String, Object?>{
        'accountRole': 'staff',
        'user': <String, Object?>{
          'id': 'u1',
          'email': 'a@b.c',
          'name': 'Alice',
        },
        'staffProfile': <String, Object?>{
          'id': 'sp1',
          'status': 'active',
          'staffCode': 'CS1234',
          'preferredName': 'Al',
          'phone': '0801',
          'lineId': 'al_line',
        },
      });

      expect(parsed.staffProfileId, 'sp1');
      expect(parsed.staffCode, 'CS1234');
      expect(parsed.status, 'active');
      expect(parsed.preferredName, 'Al');
      expect(parsed.phone, '0801');
      expect(parsed.lineId, 'al_line');
    });

    test('withProfile updates editable fields and can clear optionals', () {
      const user = StaffUser(
        id: 'u1',
        email: 'a@b.c',
        displayName: 'Old',
        requiresPasswordChange: false,
        staffCode: 'CS1234',
        status: 'active',
        preferredName: 'P',
        phone: '1',
        lineId: 'L',
      );

      final updated = user.withProfile(
        displayName: 'New',
        preferredName: null,
        phone: null,
        lineId: null,
      );

      expect(updated.displayName, 'New');
      expect(updated.preferredName, isNull);
      expect(updated.phone, isNull);
      expect(updated.lineId, isNull);
      // Identity and work fields are preserved.
      expect(updated.email, 'a@b.c');
      expect(updated.staffCode, 'CS1234');
      expect(updated.status, 'active');
    });
  });
}
