import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/attendance/attendance_controller.dart';
import '../../core/attendance/attendance_models.dart';
import '../../core/booking/booking_models.dart';
import '../../theme/app_colors.dart';

/// Clock in / clock out card shown near the top of the home screen for the
/// active shop. Renders every attendance state and captures location only when
/// the staff member confirms an action.
class AttendanceCard extends StatefulWidget {
  const AttendanceCard({
    required this.controller,
    required this.onViewHistory,
    this.nextShift,
    this.todayShiftStart,
    super.key,
  });

  final AttendanceController controller;
  final VoidCallback onViewHistory;

  /// The staff member's nearest upcoming booked shift (a tie-in to scheduling),
  /// shown when they are not clocked in. Null when there is no booking.
  final MyBooking? nextShift;

  /// Start of today's booked shift, used to note lateness while clocked in.
  final DateTime? todayShiftStart;

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        // Tick the live duration only while a session is open, so the widget
        // never leaves a stray timer pending when nothing is counting.
        _syncTicker();
        return _buildContent(context);
      },
    );
  }

  void _syncTicker() {
    final controller = widget.controller;
    final clockedIn =
        controller.status == AttendanceCardStatus.ready &&
        (controller.data?.isClockedIn ?? false) &&
        controller.openSession != null;
    if (clockedIn && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    } else if (!clockedIn && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Widget _buildContent(BuildContext context) {
    final controller = widget.controller;
    switch (controller.status) {
      case AttendanceCardStatus.noShop:
        return const SizedBox.shrink();
      case AttendanceCardStatus.loading:
        return _shell(
          child: const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Checking attendance…',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      case AttendanceCardStatus.error:
        return _shell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage ?? 'Could not load attendance.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: controller.retry,
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        );
      case AttendanceCardStatus.ready:
        return _shell(child: _readyContent(context, controller));
    }
  }

  Widget _readyContent(BuildContext context, AttendanceController controller) {
    final data = controller.data!;
    final session = controller.openSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 4),
        Text(
          data.shopName,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 14),
        if (data.isClockedIn && session != null)
          ..._clockedIn(context, controller, session)
        else if (data.blockedByMissingShopLocation)
          ..._missingLocation()
        else
          ..._notClockedIn(context, controller),
        if (controller.actionMessage != null) ...[
          const SizedBox(height: 12),
          _banner(controller.actionMessage!),
        ],
      ],
    );
  }

  List<Widget> _clockedIn(
    BuildContext context,
    AttendanceController controller,
    AttendanceOpenSession session,
  ) {
    final elapsed = DateTime.now().toUtc().difference(session.clockInAt);
    return [
      Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Text(
            'Clocked in · ${_formatDuration(elapsed)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        'Since ${_formatLocalTime(session.clockInAt)}',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      ..._latenessNote(session),
      const SizedBox(height: 14),
      _actionButton(
        context,
        controller,
        clockIn: false,
        label: 'Clock out',
        icon: Icons.logout,
        color: AppColors.primary,
      ),
    ];
  }

  // Lateness vs the booked shift start, when this clock-in is for a shift the
  // staff member is working at the active shop and clocked in after it began.
  // Both times are UTC instants, so the comparison is timezone-independent.
  List<Widget> _latenessNote(AttendanceOpenSession session) {
    final shiftStart = widget.todayShiftStart;
    if (shiftStart == null) return const [];
    final minutesLate = session.clockInAt.difference(shiftStart).inMinutes;
    if (minutesLate <= 0) return const [];
    return [
      const SizedBox(height: 6),
      Row(
        children: [
          const Icon(
            Icons.watch_later_outlined,
            size: 14,
            color: AppColors.amber,
          ),
          const SizedBox(width: 6),
          Text(
            '$minutesLate min after your ${_formatBangkok(shiftStart)} shift start',
            style: const TextStyle(color: AppColors.amber, fontSize: 12),
          ),
        ],
      ),
    ];
  }

  List<Widget> _notClockedIn(
    BuildContext context,
    AttendanceController controller,
  ) {
    return [
      const Text(
        'Not clocked in',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      ..._nextShiftRow(),
      const SizedBox(height: 14),
      _actionButton(
        context,
        controller,
        clockIn: true,
        label: 'Clock in',
        icon: Icons.login,
        color: AppColors.success,
      ),
    ];
  }

  // "Next shift" tie-in: the staff member's nearest upcoming booked shift.
  List<Widget> _nextShiftRow() {
    final shift = widget.nextShift;
    if (shift == null) return const [];
    return [
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.event_available, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next shift',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatShiftDate(shift.slotDate)} · ${shift.startHm}–${shift.endHm}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    '${shift.positionName} · ${shift.shopName}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _missingLocation() {
    return [
      const Text(
        'Not clocked in',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      const SizedBox(height: 10),
      _banner(
        'This shop has no saved location yet. Ask an admin to set it before you can clock in.',
      ),
    ];
  }

  Widget _actionButton(
    BuildContext context,
    AttendanceController controller, {
    required bool clockIn,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final submitting = controller.isSubmitting;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed:
            submitting ? null : () => _handleAction(context, clockIn: clockIn),
        icon:
            submitting
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Icon(icon),
        label: Text(submitting ? 'Working…' : label),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context, {
    required bool clockIn,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surfaceHigh,
            title: Text(clockIn ? 'Clock in?' : 'Clock out?'),
            content: Text(
              clockIn
                  ? 'We will check your location to confirm you are at the shop.'
                  : 'We will record your clock-out time and location.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(clockIn ? 'Clock in' : 'Clock out'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Permission is only requested here, inside the controller, after consent.
    if (clockIn) {
      await widget.controller.clockIn();
    } else {
      await widget.controller.clockOut();
    }
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.access_time, color: AppColors.gold, size: 20),
        const SizedBox(width: 8),
        const Text(
          'Attendance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Attendance history',
          icon: const Icon(Icons.history, color: Colors.white70),
          onPressed: widget.onViewHistory,
        ),
      ],
    );
  }

  Widget _banner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber, color: AppColors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shell({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: child,
    );
  }
}

String _formatDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes % 60;
  return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
}

String _formatLocalTime(DateTime utc) {
  final local = utc.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

// Formats a UTC instant as Asia/Bangkok (+07:00) HH:MM.
String _formatBangkok(DateTime utc) {
  final bangkok = utc.add(const Duration(hours: 7));
  final hour = bangkok.hour.toString().padLeft(2, '0');
  final minute = bangkok.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
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

// `slotDate` is a shop-local `YYYY-MM-DD`. Labels "Today" when it matches the
// current Bangkok date, else "Wkd, D Mon".
String _formatShiftDate(String slotDate) {
  final bangkokNow = DateTime.now().toUtc().add(const Duration(hours: 7));
  final todayStr =
      '${bangkokNow.year.toString().padLeft(4, '0')}-'
      '${bangkokNow.month.toString().padLeft(2, '0')}-'
      '${bangkokNow.day.toString().padLeft(2, '0')}';
  if (slotDate == todayStr) return 'Today';
  final date = DateTime.tryParse('${slotDate}T00:00:00');
  if (date == null) return slotDate;
  return '${_weekdayNames[date.weekday - 1]}, ${date.day} ${_monthNames[date.month - 1]}';
}
