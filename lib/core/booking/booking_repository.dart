import '../api/staff_api_client.dart';
import 'booking_models.dart';

/// Source of self-service booking state and actions for the signed-in staff
/// member. Screens and controllers depend on this, not on [StaffApiClient].
abstract class BookingRepository {
  Future<List<OpenSlot>> openSlots({
    required String shopId,
    String? positionId,
    DateTime? date,
  });

  Future<OpenSlot> slot(String slotId);

  Future<String> book(String shiftSlotId);

  Future<List<MyBooking>> myBookings();

  Future<void> cancel(String bookingId);

  Future<List<ScheduleAlert>> alerts();

  Future<void> markAlertRead(String alertId);
}

/// [BookingRepository] backed by the staff scheduling endpoints.
class RemoteBookingRepository implements BookingRepository {
  const RemoteBookingRepository(this._api);

  final StaffApiClient _api;

  @override
  Future<List<OpenSlot>> openSlots({
    required String shopId,
    String? positionId,
    DateTime? date,
  }) {
    return _api.listOpenSlots(
      shopId: shopId,
      positionId: positionId,
      date: date,
    );
  }

  @override
  Future<OpenSlot> slot(String slotId) => _api.getSlot(slotId);

  @override
  Future<String> book(String shiftSlotId) => _api.createBooking(shiftSlotId);

  @override
  Future<List<MyBooking>> myBookings() => _api.listMyBookings();

  @override
  Future<void> cancel(String bookingId) => _api.cancelBooking(bookingId);

  @override
  Future<List<ScheduleAlert>> alerts() => _api.listScheduleAlerts();

  @override
  Future<void> markAlertRead(String alertId) => _api.markAlertRead(alertId);
}
