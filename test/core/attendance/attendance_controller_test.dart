import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/attendance/attendance_controller.dart';
import 'package:zinme_app/core/attendance/attendance_models.dart';
import 'package:zinme_app/core/attendance/attendance_repository.dart';
import 'package:zinme_app/core/attendance/location_service.dart';
import 'package:zinme_app/core/staff/shop.dart';
import 'package:zinme_app/features/attendance/attendance_history_screen.dart';

class _FakeRepo implements AttendanceRepository {
  _FakeRepo(this._status);

  AttendanceStatus _status;
  AttendanceStatus? afterAction;
  Object? statusError;
  Object? actionError;
  List<AttendanceSession> historyResult = const <AttendanceSession>[];

  bool clockInCalled = false;
  bool clockOutCalled = false;
  CapturedLocation? lastLocation;

  @override
  Future<AttendanceStatus> status(String shopId) async {
    final error = statusError;
    if (error != null) throw error;
    return _status;
  }

  @override
  Future<ClockInResult> clockIn({
    required String shopId,
    CapturedLocation? location,
  }) async {
    clockInCalled = true;
    lastLocation = location;
    final error = actionError;
    if (error != null) throw error;
    if (afterAction != null) _status = afterAction!;
    return ClockInResult(
      sessionId: 'x',
      clockInAt: DateTime.now().toUtc(),
      allowedRadiusMeters: 500,
    );
  }

  @override
  Future<ClockOutResult> clockOut({
    required String shopId,
    CapturedLocation? location,
  }) async {
    clockOutCalled = true;
    lastLocation = location;
    final error = actionError;
    if (error != null) throw error;
    if (afterAction != null) _status = afterAction!;
    return ClockOutResult(
      sessionId: 'x',
      clockOutAt: DateTime.now().toUtc(),
      totalMinutes: 480,
      allowedRadiusMeters: 500,
    );
  }

  @override
  Future<List<AttendanceSession>> history({
    DateTime? from,
    DateTime? to,
  }) async => historyResult;
}

class _FakeLocation implements LocationProvider {
  _FakeLocation(this.outcome);
  LocationOutcome outcome;
  int calls = 0;

  @override
  Future<LocationOutcome> capture() async {
    calls++;
    return outcome;
  }
}

AttendanceStatus _status({
  bool clockedIn = false,
  bool required = true,
  bool configured = true,
  AttendanceOpenSession? session,
}) {
  return AttendanceStatus(
    shopId: 's1',
    shopName: 'Shop One',
    isClockedIn: clockedIn,
    shopLocationConfigured: configured,
    attendanceRadiusMeters: 500,
    attendanceLocationRequired: required,
    openSession: session,
  );
}

AttendanceOpenSession _session() => AttendanceOpenSession(
  id: 'open',
  shopId: 's1',
  shopName: 'Shop One',
  clockInAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
  durationMinutes: 60,
);

CapturedLocation _location() => CapturedLocation(
  latitude: 18.78,
  longitude: 98.95,
  accuracyMeters: 10,
  capturedAt: DateTime.now().toUtc(),
);

const _shop = Shop(id: 's1', name: 'Shop One');

void main() {
  test('null shop yields noShop', () async {
    final controller = AttendanceController(
      _FakeRepo(_status()),
      _FakeLocation(LocationCaptured(_location())),
    );

    await controller.loadForShop(null);

    expect(controller.status, AttendanceCardStatus.noShop);
    expect(controller.data, isNull);
  });

  test('loads status and becomes ready', () async {
    final controller = AttendanceController(
      _FakeRepo(_status()),
      _FakeLocation(LocationCaptured(_location())),
    );

    await controller.loadForShop(_shop);

    expect(controller.status, AttendanceCardStatus.ready);
    expect(controller.data?.isClockedIn, isFalse);
  });

  test('a failed status load surfaces an error', () async {
    final repo = _FakeRepo(_status())
      ..statusError = const NetworkException('offline');
    final controller = AttendanceController(
      repo,
      _FakeLocation(LocationCaptured(_location())),
    );

    await controller.loadForShop(_shop);

    expect(controller.status, AttendanceCardStatus.error);
  });

  test(
    'clock in captures location and reflects the clocked-in state',
    () async {
      final repo = _FakeRepo(_status())
        ..afterAction = _status(clockedIn: true, session: _session());
      final location = _FakeLocation(LocationCaptured(_location()));
      final controller = AttendanceController(repo, location);

      await controller.loadForShop(_shop);
      await controller.clockIn();

      expect(location.calls, 1);
      expect(repo.lastLocation, isNotNull);
      expect(controller.data?.isClockedIn, isTrue);
      expect(controller.actionMessage, isNull);
    },
  );

  test('out of range surfaces the distance and radius', () async {
    final repo = _FakeRepo(_status())
      ..actionError = const ClientApiException(
        'Too far',
        statusCode: 400,
        code: 'OUT_OF_RANGE',
        distanceMeters: 820,
        allowedRadiusMeters: 500,
      );
    final controller = AttendanceController(
      repo,
      _FakeLocation(LocationCaptured(_location())),
    );

    await controller.loadForShop(_shop);
    await controller.clockIn();

    expect(controller.actionMessage, contains('820m'));
    expect(controller.actionMessage, contains('500m'));
    expect(controller.data?.isClockedIn, isFalse);
  });

  test('a required clock-in is blocked when permission is denied', () async {
    final repo = _FakeRepo(_status(required: true));
    final controller = AttendanceController(
      repo,
      _FakeLocation(const LocationPermissionDenied()),
    );

    await controller.loadForShop(_shop);
    await controller.clockIn();

    expect(repo.clockInCalled, isFalse);
    expect(controller.actionMessage, contains('permission'));
  });

  test(
    'an optional location proceeds without a fix when capture fails',
    () async {
      final repo = _FakeRepo(_status(required: false, configured: true))
        ..afterAction = _status(
          required: false,
          configured: true,
          clockedIn: true,
          session: _session(),
        );
      final location = _FakeLocation(const LocationPermissionDenied());
      final controller = AttendanceController(repo, location);

      await controller.loadForShop(_shop);
      await controller.clockIn();

      expect(location.calls, 1);
      expect(repo.clockInCalled, isTrue);
      expect(repo.lastLocation, isNull);
      expect(controller.data?.isClockedIn, isTrue);
    },
  );

  test('clock out returns to the not-clocked-in state', () async {
    final repo = _FakeRepo(_status(clockedIn: true, session: _session()))
      ..afterAction = _status();
    final controller = AttendanceController(
      repo,
      _FakeLocation(LocationCaptured(_location())),
    );

    await controller.loadForShop(_shop);
    await controller.clockOut();

    expect(repo.clockOutCalled, isTrue);
    expect(controller.data?.isClockedIn, isFalse);
  });

  testWidgets('history screen lists recent sessions', (tester) async {
    final repo = _FakeRepo(_status())
      ..historyResult = [
        AttendanceSession(
          id: '1',
          shopId: 's1',
          shopName: 'Shop One',
          clockInAt: DateTime.utc(2026, 5, 30, 1, 0),
          clockOutAt: DateTime.utc(2026, 5, 30, 9, 0),
          totalMinutes: 480,
          status: 'closed',
        ),
      ];

    await tester.pumpWidget(
      Provider<AttendanceRepository>.value(
        value: repo,
        child: const MaterialApp(home: AttendanceHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('closed'), findsOneWidget);
    expect(find.text('Shop One'), findsOneWidget);
    expect(find.textContaining('8h'), findsOneWidget);
  });
}
