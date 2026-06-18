const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a slot date as e.g. `Tue, 9 Jun 2026`. [date] is treated as a plain
/// calendar day (the backend already resolved the shop's local date), so no
/// timezone conversion is applied.
String formatSlotDate(DateTime date) {
  final weekday = _weekdays[date.weekday - 1];
  final month = _months[date.month - 1];
  return '$weekday, ${date.day} $month ${date.year}';
}

/// Formats a `YYYY-MM-DD` slot-date string defensively. A malformed or missing
/// value (schema/API skew) renders as the raw string instead of throwing a
/// FormatException that would take down the whole screen during build.
String formatSlotDateString(String slotDate) {
  final parsed = DateTime.tryParse(slotDate);
  return parsed == null ? slotDate : formatSlotDate(parsed);
}
