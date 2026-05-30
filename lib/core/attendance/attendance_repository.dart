import '../api/staff_api_client.dart';
import 'attendance_models.dart';
import 'location_service.dart';

/// Source of attendance state and actions for the signed-in staff member.
abstract class AttendanceRepository {
  Future<AttendanceStatus> status(String shopId);

  Future<ClockInResult> clockIn({
    required String shopId,
    CapturedLocation? location,
  });

  Future<ClockOutResult> clockOut({
    required String shopId,
    CapturedLocation? location,
  });

  Future<List<AttendanceSession>> history({DateTime? from, DateTime? to});
}

/// [AttendanceRepository] backed by the staff attendance endpoints.
class RemoteAttendanceRepository implements AttendanceRepository {
  const RemoteAttendanceRepository(this._api);

  final StaffApiClient _api;

  @override
  Future<AttendanceStatus> status(String shopId) =>
      _api.getAttendanceStatus(shopId);

  @override
  Future<ClockInResult> clockIn({
    required String shopId,
    CapturedLocation? location,
  }) {
    return _api.clockInAttendance(
      shopId: shopId,
      latitude: location?.latitude,
      longitude: location?.longitude,
      accuracyMeters: location?.accuracyMeters,
      capturedAt: location?.capturedAt,
    );
  }

  @override
  Future<ClockOutResult> clockOut({
    required String shopId,
    CapturedLocation? location,
  }) {
    return _api.clockOutAttendance(
      shopId: shopId,
      latitude: location?.latitude,
      longitude: location?.longitude,
      accuracyMeters: location?.accuracyMeters,
      capturedAt: location?.capturedAt,
    );
  }

  @override
  Future<List<AttendanceSession>> history({DateTime? from, DateTime? to}) =>
      _api.listMyAttendance(from: from, to: to);
}
