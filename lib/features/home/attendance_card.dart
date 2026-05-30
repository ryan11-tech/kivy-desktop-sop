import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/attendance/attendance_controller.dart';
import '../../core/attendance/attendance_models.dart';
import '../../theme/app_colors.dart';

/// Clock in / clock out card shown near the top of the home screen for the
/// active shop. Renders every attendance state and captures location only when
/// the staff member confirms an action.
class AttendanceCard extends StatefulWidget {
  const AttendanceCard({
    required this.controller,
    required this.onViewHistory,
    super.key,
  });

  final AttendanceController controller;
  final VoidCallback onViewHistory;

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

  List<Widget> _notClockedIn(
    BuildContext context,
    AttendanceController controller,
  ) {
    return [
      const Text(
        'Not clocked in',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
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
