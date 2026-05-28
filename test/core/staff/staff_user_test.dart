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
        requiresOtp: false,
      );

      final parsed = StaffUser.fromJson(user.toJson());

      expect(parsed.id, user.id);
      expect(parsed.email, user.email);
      expect(parsed.displayName, user.displayName);
      expect(parsed.requiresPasswordChange, isTrue);
      expect(parsed.requiresOtp, isFalse);
    });

    test('falls back to name when displayName absent', () {
      final parsed = StaffUser.fromJson(<String, Object?>{
        'id': 'u1',
        'email': 'a@b.c',
        'name': 'Old Name',
      });

      expect(parsed.displayName, 'Old Name');
      expect(parsed.requiresPasswordChange, isFalse);
      expect(parsed.requiresOtp, isFalse);
    });
  });
}
