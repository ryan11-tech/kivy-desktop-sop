import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/attendance/attendance_models.dart';
import '../../core/attendance/attendance_repository.dart';
import '../../theme/app_colors.dart';

/// Simple read-only list of the signed-in staff member's recent attendance.
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  AttendanceRepository? _repository;
  Future<List<AttendanceSession>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository ??= context.read<AttendanceRepository>();
    _future ??= _load();
  }

  Future<List<AttendanceSession>> _load() {
    final now = DateTime.now();
    // Roughly the last month of records; the backend defaults are open-ended.
    final from = now.subtract(const Duration(days: 30));
    return _repository!.history(from: from, to: now);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Attendance history'),
      ),
      body: FutureBuilder<List<AttendanceSession>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _Message(
              text: 'Could not load your attendance history.',
              onRetry: _reload,
            );
          }

          final sessions = snapshot.data ?? const <AttendanceSession>[];
          if (sessions.isEmpty) {
            return const _Message(text: 'No attendance records yet.');
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _SessionTile(sessions[index]),
            ),
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile(this.session);

  final AttendanceSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatDate(session.clockInAt),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _StatusPill(session.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatTime(session.clockInAt)} → ${session.clockOutAt == null ? '—' : _formatTime(session.clockOutAt!)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Text(
                _formatTotal(session.totalMinutes),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          Text(
            session.shopName,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.split('_').join(' '),
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: Colors.white70)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'closed':
      return AppColors.success;
    case 'open':
      return AppColors.info;
    case 'missing_clock_out':
      return AppColors.hot;
    case 'manually_adjusted':
      return AppColors.amber;
    default:
      return AppColors.silver;
  }
}

String _formatTotal(int? minutes) {
  if (minutes == null) return '—';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
}

String _formatDate(DateTime utc) {
  final local = utc.toLocal();
  const months = [
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
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

String _formatTime(DateTime utc) {
  final local = utc.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
