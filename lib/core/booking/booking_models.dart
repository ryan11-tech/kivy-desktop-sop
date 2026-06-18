// Models for the staff self-service booking endpoints
// (`/api/staff/scheduling/*`). Each type owns its `fromJson`, mirroring the rest
// of the app's models. The backend is the source of truth for capacity, the
// 7-day lead (`tooSoon`), the 48h cancel window (`canCancel`), and overlap.

/// An open shift slot a confirmed staff member can browse and book.
///
/// Returned by `GET /scheduling/shift-slots` (list) and
/// `GET /scheduling/shift-slots/:id` (detail, which also sets [overlap]).
class OpenSlot {
  const OpenSlot({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.positionId,
    required this.positionName,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.remaining,
    required this.tooSoon,
    this.overlap = false,
  });

  factory OpenSlot.fromJson(Map<String, Object?> json) {
    return OpenSlot(
      id: json['id'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      positionId: json['positionId'] as String? ?? '',
      positionName: json['positionName'] as String? ?? '',
      slotDate: json['slotDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      capacity: _int(json['capacity']) ?? 0,
      remaining: _int(json['remaining']) ?? 0,
      tooSoon: json['tooSoon'] as bool? ?? false,
      // Only present on the detail response; absent in the list.
      overlap: json['overlap'] as bool? ?? false,
    );
  }

  final String id;
  final String shopId;
  final String shopName;
  final String positionId;
  final String positionName;

  /// `YYYY-MM-DD` in the shop's local (Bangkok) day.
  final String slotDate;

  /// `HH:MM:SS` wall-clock; use [startHm] / [endHm] for display.
  final String startTime;
  final String endTime;

  final int capacity;

  /// Seats still open (`capacity - booked`).
  final int remaining;

  /// True when the slot starts less than 7 days out, so it cannot be booked yet.
  final bool tooSoon;

  /// True when the caller already holds a booked slot whose time-range
  /// intersects this one on the same date (detail response only).
  final bool overlap;

  bool get isFull => remaining <= 0;

  /// Bookable only when there is room and it clears the 7-day lead window.
  bool get isBookable => !isFull && !tooSoon;

  String get startHm => _hm(startTime);
  String get endHm => _hm(endTime);
}

/// One of the caller's upcoming bookings (`GET /scheduling/bookings/my`).
class MyBooking {
  const MyBooking({
    required this.bookingId,
    required this.shiftSlotId,
    required this.shopName,
    required this.positionName,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.canCancel,
  });

  factory MyBooking.fromJson(Map<String, Object?> json) {
    return MyBooking(
      bookingId: json['bookingId'] as String? ?? '',
      shiftSlotId: json['shiftSlotId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      positionName: json['positionName'] as String? ?? '',
      slotDate: json['slotDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as String? ?? 'booked',
      canCancel: json['canCancel'] as bool? ?? false,
    );
  }

  final String bookingId;
  final String shiftSlotId;
  final String shopName;
  final String positionName;
  final String slotDate;
  final String startTime;
  final String endTime;
  final String status;

  /// True while the self-cancel window is still open (>48h before start).
  final bool canCancel;

  String get startHm => _hm(startTime);
  String get endHm => _hm(endTime);

  /// The slot start as a local wall-clock DateTime. The backend already resolved
  /// these to the shop's local day/time, so they are parsed without timezone
  /// conversion (the device is expected to run on shop-local time).
  DateTime get startDateTime => _slotDateTime(slotDate, startTime);
  DateTime get endDateTime => _slotDateTime(slotDate, endTime);
}

DateTime _slotDateTime(String slotDate, String time) {
  // time is 'HH:MM:SS' (or 'HH:MM'); pad to a full ISO local timestamp.
  final hms = time.length >= 8 ? time : '${_hm(time)}:00';
  return DateTime.tryParse('${slotDate}T$hms') ?? DateTime.now();
}

/// A schedule-change alert (`GET /scheduling/alerts`): a booked slot was
/// cancelled or had its time changed by a manager.
class ScheduleAlert {
  const ScheduleAlert({
    required this.id,
    required this.type,
    required this.createdAt,
    this.payload,
    this.readAt,
  });

  factory ScheduleAlert.fromJson(Map<String, Object?> json) {
    final payload = json['payload'];
    return ScheduleAlert(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      createdAt: _date(json['createdAt']) ?? DateTime.now().toUtc(),
      payload: payload is Map<String, Object?> ? payload : null,
      readAt: _date(json['readAt']),
    );
  }

  final String id;

  /// `slot_cancelled` | `slot_time_changed`.
  final String type;
  final DateTime createdAt;
  final Map<String, Object?>? payload;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}

/// `HH:MM:SS` (or `HH:MM`) → `HH:MM` for display.
String _hm(String time) => time.length >= 5 ? time.substring(0, 5) : time;

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
