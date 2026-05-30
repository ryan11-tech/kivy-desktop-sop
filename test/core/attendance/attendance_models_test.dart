import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/attendance/attendance_models.dart';

void main() {
  test('AttendanceStatus parses an embedded open session', () {
    final status = AttendanceStatus.fromJson(<String, Object?>{
      'shopId': 's1',
      'shopName': 'Shop One',
      'isClockedIn': true,
      'shopLocationConfigured': true,
      'attendanceRadiusMeters': 500,
      'attendanceLocationRequired': true,
      'openSession': <String, Object?>{
        'id': 'sess',
        'shopId': 's1',
        'shopName': 'Shop One',
        'clockInAt': '2026-05-30T01:00:00.000Z',
        'durationMinutes': 65,
        'clockInDistanceMeters': 42,
      },
    });

    expect(status.isClockedIn, isTrue);
    expect(status.openSession?.durationMinutes, 65);
    expect(status.openSession?.clockInDistanceMeters, 42);
    expect(status.blockedByMissingShopLocation, isFalse);
  });

  test('AttendanceStatus with no coordinates is blocked when required', () {
    final status = AttendanceStatus.fromJson(<String, Object?>{
      'shopId': 's1',
      'shopName': 'Shop',
      'isClockedIn': false,
      'shopLocationConfigured': false,
      'attendanceRadiusMeters': 500,
      'attendanceLocationRequired': true,
    });

    expect(status.openSession, isNull);
    expect(status.blockedByMissingShopLocation, isTrue);
  });

  test('clock-in and clock-out results parse distances and totals', () {
    final inResult = ClockInResult.fromJson(<String, Object?>{
      'sessionId': 'x',
      'clockInAt': '2026-05-30T01:00:00.000Z',
      'distanceMeters': 120,
      'allowedRadiusMeters': 500,
    });
    expect(inResult.distanceMeters, 120);
    expect(inResult.allowedRadiusMeters, 500);

    final outResult = ClockOutResult.fromJson(<String, Object?>{
      'sessionId': 'x',
      'clockOutAt': '2026-05-30T09:00:00.000Z',
      'totalMinutes': 480,
      'distanceMeters': null,
      'allowedRadiusMeters': 500,
    });
    expect(outResult.totalMinutes, 480);
    expect(outResult.distanceMeters, isNull);
  });

  test('AttendanceSession tolerates a null clock-out and total', () {
    final session = AttendanceSession.fromJson(<String, Object?>{
      'id': '1',
      'shopId': 's1',
      'shopName': 'Shop One',
      'clockInAt': '2026-05-30T01:00:00.000Z',
      'clockOutAt': null,
      'totalMinutes': null,
      'status': 'open',
    });

    expect(session.clockOutAt, isNull);
    expect(session.totalMinutes, isNull);
    expect(session.status, 'open');
  });
}
