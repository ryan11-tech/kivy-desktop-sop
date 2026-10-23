import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/features/admin_users/admin_users_screen.dart';

void main() {
  test('formats an instant as Bangkok wall time (UTC+7)', () {
    expect(
      formatBangkokDateTime(DateTime.utc(2026, 10, 31, 7, 5)),
      'Oct 31, 2026, 14:05',
    );
  });

  test('rolls over to the next Bangkok day', () {
    expect(
      formatBangkokDateTime(DateTime.utc(2026, 12, 31, 20, 30)),
      'Jan 1, 2027, 03:30',
    );
  });
}
