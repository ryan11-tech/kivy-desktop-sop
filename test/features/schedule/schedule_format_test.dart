import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/features/schedule/schedule_format.dart';

void main() {
  test('formatSlotDateString formats a valid YYYY-MM-DD', () {
    expect(formatSlotDateString('2026-06-30'), 'Tue, 30 Jun 2026');
  });

  test('formatSlotDateString falls back to the raw string, never throws', () {
    // Unparseable values render as-is instead of throwing FormatException and
    // taking down the screen during build (the K3 guard).
    expect(formatSlotDateString(''), '');
    expect(formatSlotDateString('not-a-date'), 'not-a-date');
    // Any string is safe to pass — the call must never throw.
    expect(() => formatSlotDateString('2026-13-99'), returnsNormally);
    expect(() => formatSlotDateString('garbage'), returnsNormally);
  });
}
