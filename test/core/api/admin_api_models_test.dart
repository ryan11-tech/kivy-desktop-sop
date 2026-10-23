import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/api/admin_api_models.dart';

PortalStaffMutation _mutation({String? status, String? statusReason}) {
  return PortalStaffMutation(
    accountRole: 'staff',
    email: 'mya@example.com',
    name: 'Mya',
    status: status,
    statusReason: statusReason,
    shopMemberships: const [
      PortalStaffMembershipInput(shopId: 'shop-1', role: 'cashier'),
    ],
  );
}

void main() {
  group('PortalStaffMutation', () {
    test('create JSON carries no password or status fields', () {
      final json = _mutation(status: 'active').toCreateJson();

      expect(json, <String, Object?>{
        'accountRole': 'staff',
        'email': 'mya@example.com',
        'name': 'Mya',
        'shopMemberships': [
          {'shopId': 'shop-1', 'role': 'cashier'},
        ],
      });
      expect(json.containsKey('temporaryPassword'), isFalse);
      expect(json.containsKey('mustChangePassword'), isFalse);
    });

    test('update JSON leaves status out when unchanged', () {
      final json = _mutation().toUpdateJson();

      expect(json.keys, <String>[
        'accountRole',
        'email',
        'name',
        'shopMemberships',
      ]);
    });

    test('update JSON sends status and trimmed reason when suspending', () {
      final json =
          _mutation(
            status: 'suspended',
            statusReason: '  Left the shop  ',
          ).toUpdateJson();

      expect(json['status'], 'suspended');
      expect(json['statusReason'], 'Left the shop');
      expect(json.containsKey('temporaryPassword'), isFalse);
      expect(json.containsKey('mustChangePassword'), isFalse);
    });

    test('update JSON sends unsuspend without a reason', () {
      final json = _mutation(status: 'active').toUpdateJson();

      expect(json['status'], 'active');
      expect(json.containsKey('statusReason'), isFalse);
    });

    test('update JSON drops a reason when status is not sent', () {
      final json = _mutation(statusReason: 'Left the shop').toUpdateJson();

      expect(json.containsKey('status'), isFalse);
      expect(json.containsKey('statusReason'), isFalse);
    });
  });

  group('validateSuspendReason', () {
    test('needs 5 to 500 characters after trimming', () {
      expect(validateSuspendReason('   '), isNotNull);
      expect(validateSuspendReason(' abcd '), isNotNull);
      expect(validateSuspendReason('abcde'), isNull);
      expect(validateSuspendReason('a' * 500), isNull);
      expect(validateSuspendReason('a' * 501), isNotNull);
    });
  });

  group('PortalOneTimePassword', () {
    test('parses the password as returned and the expiry in UTC', () {
      final otp = PortalOneTimePassword.fromJson(const {
        'oneTimePassword': 'K7QM-4XPA',
        'expiresAt': '2026-10-31T07:05:00.000Z',
      });

      expect(otp.password, 'K7QM-4XPA');
      expect(otp.expiresAt, DateTime.utc(2026, 10, 31, 7, 5));
      expect(otp.expiresAtText, '2026-10-31T07:05:00.000Z');
    });

    test('keeps the raw expiry when it cannot be parsed', () {
      final otp = PortalOneTimePassword.fromJson(const {
        'oneTimePassword': 'K7QM-4XPA',
        'expiresAt': 'soon',
      });

      expect(otp.expiresAt, isNull);
      expect(otp.expiresAtText, 'soon');
    });

    test('toString never includes the password', () {
      final otp = PortalOneTimePassword.fromJson(const {
        'oneTimePassword': 'K7QM-4XPA',
        'expiresAt': '2026-10-31T07:05:00.000Z',
      });

      expect(otp.toString(), isNot(contains('K7QM-4XPA')));
    });
  });

  test('PortalStaffCreateResult parses staff and one-time password', () {
    final result = PortalStaffCreateResult.fromJson(const {
      'staff': {
        'id': 'profile-1',
        'userId': 'user-1',
        'name': 'Mya',
        'email': 'mya@example.com',
        'accountRole': 'staff',
        'status': 'invited',
        'staffCode': null,
        'mustChangePassword': true,
        'shops': [
          {'id': 'shop-1', 'name': 'Silom', 'role': 'cashier'},
        ],
      },
      'oneTimePassword': 'K7QM-4XPA',
      'expiresAt': '2026-10-31T07:05:00.000Z',
    });

    expect(result.staff.id, 'profile-1');
    expect(result.staff.status, 'invited');
    expect(result.staff.shops.single.shopName, 'Silom');
    expect(result.oneTimePassword.password, 'K7QM-4XPA');
    expect(result.oneTimePassword.expiresAt, DateTime.utc(2026, 10, 31, 7, 5));
  });
}
