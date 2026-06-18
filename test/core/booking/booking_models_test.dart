import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/booking/booking_models.dart';

void main() {
  MyBooking booking({
    String shopId = 'shop-1',
    String slotDate = '2026-06-30',
    String startTime = '09:00:00',
    String endTime = '12:00:00',
  }) {
    return MyBooking(
      bookingId: 'b1',
      shiftSlotId: 's1',
      shopId: shopId,
      shopName: 'Shop',
      positionName: 'Bar',
      slotDate: slotDate,
      startTime: startTime,
      endTime: endTime,
      status: 'booked',
      canCancel: true,
    );
  }

  test('startInstant anchors shop-local wall-clock to +07:00 (UTC instant)', () {
    // 2026-06-30 09:00 Bangkok == 2026-06-30T02:00:00Z, regardless of device tz.
    final start = booking().startInstant;
    expect(start, isNotNull);
    expect(start!.isUtc, isTrue);
    expect(start, DateTime.parse('2026-06-30T02:00:00Z'));
  });

  test('endInstant anchors to +07:00 as well', () {
    expect(booking().endInstant, DateTime.parse('2026-06-30T05:00:00Z'));
  });

  test('instants are null (not now()) on malformed input', () {
    expect(booking(slotDate: '', startTime: '09:00:00').startInstant, isNull);
    expect(booking(startTime: 'not-a-time').startInstant, isNull);
    expect(booking(slotDate: 'garbage').startInstant, isNull);
  });

  test('bangkokWallClockToUtc handles HH:MM and HH:MM:SS', () {
    expect(
      bangkokWallClockToUtc('2026-06-30', '09:00'),
      DateTime.parse('2026-06-30T02:00:00Z'),
    );
    expect(
      bangkokWallClockToUtc('2026-06-30', '09:00:00'),
      DateTime.parse('2026-06-30T02:00:00Z'),
    );
    expect(bangkokWallClockToUtc('', '09:00'), isNull);
  });
}
