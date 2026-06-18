import 'package:flutter/material.dart';

import '../../core/booking/booking_controller.dart';
import '../../core/booking/booking_models.dart';
import '../../theme/app_colors.dart';
import 'schedule_format.dart';

/// Schedule-change alerts: a booked slot was cancelled or had its time changed
/// by a manager. Tapping an unread alert marks it read (updating the bell badge).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({required this.controller, super.key});

  final BookingController controller;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  BookingController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Refresh on open so the list and badge are current.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        title: const Text('Schedule alerts'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_controller.alertsStatus) {
      case BookingLoadStatus.idle:
      case BookingLoadStatus.loading:
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case BookingLoadStatus.error:
        return _AlertsMessage(
          icon: Icons.error_outline,
          title: 'Could not load alerts',
          message: _controller.alertsError ?? 'Something went wrong.',
          onRetry: _controller.loadAlerts,
        );
      case BookingLoadStatus.ready:
        break;
    }

    final alerts = _controller.alerts;
    if (alerts.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _controller.loadAlerts,
        child: const _AlertsMessage(
          icon: Icons.notifications_none,
          title: 'No alerts',
          message: 'Changes to your booked shifts will show up here.',
          scrollable: true,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _controller.loadAlerts,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
        itemCount: alerts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return _AlertCard(
            alert: alert,
            onTap:
                alert.isUnread
                    ? () => _controller.markAlertRead(alert.id)
                    : null,
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, this.onTap});

  final ScheduleAlert alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cancelled = alert.type == 'slot_cancelled';
    final color = cancelled ? AppColors.primary : AppColors.amber;
    final icon = cancelled ? Icons.event_busy : Icons.update;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              alert.isUnread
                  ? color.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cancelled ? 'Shift cancelled' : 'Shift time changed',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _describe(alert),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (alert.isUnread)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _describe(ScheduleAlert alert) {
    final payload = alert.payload ?? const <String, Object?>{};
    final slotDate = payload['slotDate'];
    final dateText =
        slotDate is String && slotDate.isNotEmpty
            ? formatSlotDateString(slotDate)
            : 'one of your shifts';

    if (alert.type == 'slot_time_changed') {
      final newStart = _hm(payload['newStart']);
      final newEnd = _hm(payload['newEnd']);
      if (newStart != null && newEnd != null) {
        return '$dateText is now $newStart – $newEnd.';
      }
      return 'The time for $dateText changed.';
    }
    final startTime = _hm(payload['startTime']);
    return startTime != null
        ? '$dateText at $startTime was cancelled.'
        : '$dateText was cancelled.';
  }

  String? _hm(Object? value) {
    if (value is String && value.length >= 5) return value.substring(0, 5);
    if (value is String && value.isNotEmpty) return value;
    return null;
  }
}

class _AlertsMessage extends StatelessWidget {
  const _AlertsMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
    this.scrollable = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? onRetry;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics:
              scrollable
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 48, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
