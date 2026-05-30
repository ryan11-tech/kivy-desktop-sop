// Models for the staff attendance endpoints (`/api/staff/attendance/*`).
//
// Each type owns its own `fromJson`, mirroring the rest of the app's models.
// The backend is the source of truth for timestamps, distances, and status.

/// Snapshot from `GET /api/staff/attendance/status` for the selected shop.
class AttendanceStatus {
  const AttendanceStatus({
    required this.shopId,
    required this.shopName,
    required this.isClockedIn,
    required this.shopLocationConfigured,
    required this.attendanceRadiusMeters,
    required this.attendanceLocationRequired,
    this.openSession,
  });

  factory AttendanceStatus.fromJson(Map<String, Object?> json) {
    final session = json['openSession'];
    return AttendanceStatus(
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      isClockedIn: json['isClockedIn'] as bool? ?? false,
      shopLocationConfigured: json['shopLocationConfigured'] as bool? ?? false,
      attendanceRadiusMeters: _int(json['attendanceRadiusMeters']) ?? 0,
      attendanceLocationRequired:
          json['attendanceLocationRequired'] as bool? ?? false,
      openSession:
          session is Map<String, Object?>
              ? AttendanceOpenSession.fromJson(session)
              : null,
    );
  }

  final String shopId;
  final String shopName;
  final bool isClockedIn;
  final bool shopLocationConfigured;
  final int attendanceRadiusMeters;
  final bool attendanceLocationRequired;
  final AttendanceOpenSession? openSession;

  /// True when the shop demands a validated location but none is saved yet, so
  /// clocking in is impossible until an admin sets the shop coordinates.
  bool get blockedByMissingShopLocation =>
      attendanceLocationRequired && !shopLocationConfigured;
}

/// The currently open session embedded in [AttendanceStatus].
class AttendanceOpenSession {
  const AttendanceOpenSession({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.clockInAt,
    required this.durationMinutes,
    this.clockInDistanceMeters,
  });

  factory AttendanceOpenSession.fromJson(Map<String, Object?> json) {
    return AttendanceOpenSession(
      id: json['id'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      clockInAt: _date(json['clockInAt']) ?? DateTime.now().toUtc(),
      durationMinutes: _int(json['durationMinutes']) ?? 0,
      clockInDistanceMeters: _int(json['clockInDistanceMeters']),
    );
  }

  final String id;
  final String shopId;
  final String shopName;
  final DateTime clockInAt;
  final int durationMinutes;
  final int? clockInDistanceMeters;
}

/// Result of `POST /api/staff/attendance/clock-in`.
class ClockInResult {
  const ClockInResult({
    required this.sessionId,
    required this.clockInAt,
    required this.allowedRadiusMeters,
    this.distanceMeters,
  });

  factory ClockInResult.fromJson(Map<String, Object?> json) {
    return ClockInResult(
      sessionId: json['sessionId'] as String? ?? '',
      clockInAt: _date(json['clockInAt']) ?? DateTime.now().toUtc(),
      allowedRadiusMeters: _int(json['allowedRadiusMeters']) ?? 0,
      distanceMeters: _int(json['distanceMeters']),
    );
  }

  final String sessionId;
  final DateTime clockInAt;
  final int allowedRadiusMeters;
  final int? distanceMeters;
}

/// Result of `POST /api/staff/attendance/clock-out`.
class ClockOutResult {
  const ClockOutResult({
    required this.sessionId,
    required this.clockOutAt,
    required this.totalMinutes,
    required this.allowedRadiusMeters,
    this.distanceMeters,
  });

  factory ClockOutResult.fromJson(Map<String, Object?> json) {
    return ClockOutResult(
      sessionId: json['sessionId'] as String? ?? '',
      clockOutAt: _date(json['clockOutAt']) ?? DateTime.now().toUtc(),
      totalMinutes: _int(json['totalMinutes']) ?? 0,
      allowedRadiusMeters: _int(json['allowedRadiusMeters']) ?? 0,
      distanceMeters: _int(json['distanceMeters']),
    );
  }

  final String sessionId;
  final DateTime clockOutAt;
  final int totalMinutes;
  final int allowedRadiusMeters;
  final int? distanceMeters;
}

/// One row of `GET /api/staff/attendance/my`.
class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.clockInAt,
    required this.status,
    this.clockOutAt,
    this.totalMinutes,
  });

  factory AttendanceSession.fromJson(Map<String, Object?> json) {
    return AttendanceSession(
      id: json['id'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      clockInAt: _date(json['clockInAt']) ?? DateTime.now().toUtc(),
      clockOutAt: _date(json['clockOutAt']),
      totalMinutes: _int(json['totalMinutes']),
      status: json['status'] as String? ?? 'open',
    );
  }

  final String id;
  final String shopId;
  final String shopName;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final int? totalMinutes;
  final String status;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _date(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
