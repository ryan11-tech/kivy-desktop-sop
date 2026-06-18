import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/booking/booking_controller.dart';
import 'package:zinme_app/core/booking/booking_models.dart';
import 'package:zinme_app/core/booking/booking_repository.dart';
import 'package:zinme_app/core/staff/shop.dart';

OpenSlot _slot({
  required String id,
  required String positionId,
  required String positionName,
  int remaining = 2,
  bool tooSoon = false,
}) {
  return OpenSlot(
    id: id,
    shopId: 'shop',
    shopName: 'Shop',
    positionId: positionId,
    positionName: positionName,
    slotDate: '2026-06-30',
    startTime: '09:00:00',
    endTime: '12:00:00',
    capacity: 2,
    remaining: remaining,
    tooSoon: tooSoon,
  );
}

MyBooking _booking({required String id, required String shopId}) {
  return MyBooking(
    bookingId: id,
    shiftSlotId: 'slot-$id',
    shopId: shopId,
    shopName: shopId,
    positionName: 'Bar',
    slotDate: '2026-06-30',
    startTime: '09:00:00',
    endTime: '12:00:00',
    status: 'booked',
    canCancel: true,
  );
}

class _FakeBookingRepo implements BookingRepository {
  Completer<List<OpenSlot>>? pendingSlots;
  List<OpenSlot> slotsResult = const <OpenSlot>[];
  Object? slotsError;

  List<MyBooking> bookingsResult = const <MyBooking>[];
  List<ScheduleAlert> alertsResult = const <ScheduleAlert>[];

  Object? bookError;
  Object? cancelError;
  int bookCalls = 0;
  int cancelCalls = 0;

  @override
  Future<List<OpenSlot>> openSlots({
    required String shopId,
    String? positionId,
    DateTime? date,
  }) {
    final pending = pendingSlots;
    if (pending != null) return pending.future;
    final error = slotsError;
    if (error != null) return Future<List<OpenSlot>>.error(error);
    return Future<List<OpenSlot>>.value(slotsResult);
  }

  @override
  Future<OpenSlot> slot(String slotId) async => slotsResult.first;

  @override
  Future<String> book(String shiftSlotId) async {
    bookCalls++;
    final error = bookError;
    if (error != null) throw error;
    return 'booking-1';
  }

  @override
  Future<List<MyBooking>> myBookings() async => bookingsResult;

  @override
  Future<void> cancel(String bookingId) async {
    cancelCalls++;
    final error = cancelError;
    if (error != null) throw error;
  }

  @override
  Future<List<ScheduleAlert>> alerts() async => alertsResult;

  @override
  Future<void> markAlertRead(String alertId) async {}
}

void main() {
  const shopA = Shop(id: 'a', name: 'A');
  const shopB = Shop(id: 'b', name: 'B');

  test(
    'clearing the shop invalidates an in-flight fetch (no stale restore)',
    () async {
      final repo = _FakeBookingRepo();
      final controller = BookingController(repo);

      // Gate the fetch for shop A so it is still in flight when we clear.
      final gate = Completer<List<OpenSlot>>();
      repo.pendingSlots = gate;
      final pending = controller.loadForShop(shopA);
      expect(controller.slotsStatus, BookingLoadStatus.loading);

      // Clear the active shop while the fetch is outstanding.
      await controller.loadForShop(null);
      expect(controller.slotsStatus, BookingLoadStatus.idle);

      // The previous shop's fetch now resolves — it must NOT restore slots.
      gate.complete([_slot(id: 's1', positionId: 'p1', positionName: 'Bar')]);
      await pending;

      expect(controller.slots, isEmpty);
      expect(controller.slotsStatus, BookingLoadStatus.idle);
    },
  );

  test(
    'switching shop drops the previous shop slots before the new load',
    () async {
      final repo = _FakeBookingRepo();
      final controller = BookingController(repo);

      repo.slotsResult = [
        _slot(id: 's1', positionId: 'p1', positionName: 'Bar'),
      ];
      await controller.loadForShop(shopA);
      expect(controller.availablePositions.map((p) => p.id), ['p1']);

      // Gate shop B's fetch; the chips must not leak shop A's roles meanwhile.
      final gate = Completer<List<OpenSlot>>();
      repo.pendingSlots = gate;
      final pending = controller.loadForShop(shopB);

      expect(controller.slots, isEmpty);
      expect(controller.availablePositions, isEmpty);
      expect(controller.slotsStatus, BookingLoadStatus.loading);

      repo.pendingSlots = null;
      gate.complete([
        _slot(id: 's2', positionId: 'p2', positionName: 'Cashier'),
      ]);
      await pending;

      expect(controller.availablePositions.map((p) => p.id), ['p2']);
    },
  );

  test('book maps a SLOT_FULL rejection to a friendly message', () async {
    final repo = _FakeBookingRepo();
    final controller = BookingController(repo);
    await controller.loadForShop(shopA);
    repo.bookError = const ClientApiException(
      'full',
      statusCode: 409,
      code: 'SLOT_FULL',
    );

    final message = await controller.book('s1', shopId: 'a');
    expect(message, 'This shift is already full.');
  });

  test('cancel maps CANCEL_WINDOW_CLOSED to a friendly message', () async {
    final repo = _FakeBookingRepo();
    final controller = BookingController(repo);
    await controller.loadForShop(shopA);
    repo.cancelError = const ClientApiException(
      'closed',
      statusCode: 409,
      code: 'CANCEL_WINDOW_CLOSED',
    );

    final message = await controller.cancel('b1', shopId: 'a');
    expect(
      message,
      'Cancellation closes 48 hours before the shift. Contact your manager.',
    );
  });

  test('book/cancel reject a stale shop id without hitting the API', () async {
    final repo = _FakeBookingRepo();
    final controller = BookingController(repo);
    await controller.loadForShop(shopA);

    // The active shop switched to B; a detail route / cancel sheet still holds a
    // shop-A slot/booking. The action must be rejected, no API call made.
    await controller.loadForShop(shopB);

    final bookMsg = await controller.book('s1', shopId: 'a');
    expect(bookMsg, contains('active shop changed'));
    expect(repo.bookCalls, 0);

    final cancelMsg = await controller.cancel('b1', shopId: 'a');
    expect(cancelMsg, contains('active shop changed'));
    expect(repo.cancelCalls, 0);
  });

  test(
    'bookingsForActiveShop only returns the loaded shop\'s bookings',
    () async {
      final repo = _FakeBookingRepo();
      final controller = BookingController(repo);
      repo.bookingsResult = [
        _booking(id: 'b-a', shopId: 'a'),
        _booking(id: 'b-b', shopId: 'b'),
      ];

      // No shop loaded yet → empty (never leak another shop's bookings).
      expect(controller.bookingsForActiveShop, isEmpty);

      await controller.loadForShop(shopA);
      expect(controller.bookings.length, 2); // raw caller-scoped list
      expect(controller.bookingsForActiveShop.map((b) => b.bookingId), ['b-a']);

      await controller.loadForShop(shopB);
      expect(controller.bookingsForActiveShop.map((b) => b.bookingId), ['b-b']);
    },
  );

  test('role filter narrows slots client-side without refetching', () async {
    final repo = _FakeBookingRepo();
    final controller = BookingController(repo);
    repo.slotsResult = [
      _slot(id: 's1', positionId: 'p1', positionName: 'Bar'),
      _slot(id: 's2', positionId: 'p2', positionName: 'Cashier'),
    ];
    await controller.loadForShop(shopA);
    expect(controller.slots.length, 2);

    await controller.setPositionFilter('p2');
    expect(controller.slots.map((s) => s.id), ['s2']);

    await controller.setPositionFilter(null);
    expect(controller.slots.length, 2);
  });
}
