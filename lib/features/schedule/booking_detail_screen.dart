import 'package:flutter/material.dart';

import '../../core/booking/booking_controller.dart';
import '../../core/booking/booking_models.dart';
import '../../theme/app_colors.dart';
import 'schedule_format.dart';

/// Detail for a single open shift, with the overlap warning (G5) and the book
/// action. Re-fetches the slot on open so the `overlap` flag and live capacity
/// reflect the caller's current bookings.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    required this.controller,
    required this.slot,
    super.key,
  });

  final BookingController controller;

  /// The slot as shown in the list (no `overlap` flag); refreshed on open.
  final OpenSlot slot;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late OpenSlot _slot = widget.slot;
  bool _loadingDetail = true;
  bool _submitting = false;

  // The list response carries no `overlap` flag, so booking must stay blocked
  // until a successful detail load supplies it. A failed load is a blocking
  // error, not a fall-through to the list slot (which would default overlap to
  // false and wrongly enable booking on an overlapping shift).
  String? _detailError;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });
    try {
      final detail = await widget.controller.slotDetail(widget.slot.id);
      if (!mounted) return;
      setState(() {
        _slot = detail;
        _loadingDetail = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _detailError =
            'Could not load the latest shift details. Check your connection '
            'and retry before booking.';
      });
    }
  }

  Future<void> _book() async {
    if (_submitting) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);

    final error = await widget.controller.book(_slot.id);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Shift booked.'),
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.primary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = _slot;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        title: const Text('Shift details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailCard(slot: slot),
          const SizedBox(height: 16),
          ..._buildActionSection(slot),
        ],
      ),
    );
  }

  List<Widget> _buildActionSection(OpenSlot slot) {
    // A failed detail load is blocking: the overlap flag is unknown, so booking
    // stays disabled until a retry succeeds.
    if (_detailError != null) {
      return [
        _Banner(
          icon: Icons.cloud_off,
          color: AppColors.amber,
          title: 'Couldn’t check this shift',
          message: _detailError!,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _loadingDetail ? null : _loadDetail,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.surfaceHigh),
            ),
          ),
        ),
      ];
    }

    // Booking is only offered once a successful detail load supplies the live
    // overlap / capacity / lead-time facts.
    final canBook = !_loadingDetail && slot.isBookable && !slot.overlap;

    return [
      if (slot.overlap) ...[
        const _Banner(
          icon: Icons.warning_amber_rounded,
          color: AppColors.amber,
          title: 'Overlaps another shift',
          message:
              'You already have a booked shift that overlaps this time. '
              'Cancel that one first if you want this slot.',
        ),
        const SizedBox(height: 12),
      ] else if (slot.isFull) ...[
        const _Banner(
          icon: Icons.event_busy_outlined,
          color: AppColors.silver,
          title: 'Shift full',
          message:
              'Every seat on this shift is taken. Check back later in '
              'case someone cancels.',
        ),
        const SizedBox(height: 12),
      ] else if (slot.tooSoon) ...[
        const _Banner(
          icon: Icons.lock_clock,
          color: AppColors.amber,
          title: 'Not open yet',
          message:
              'Shifts open for booking one week ahead. This one is still '
              'inside the one-week window — try again closer to the date.',
        ),
        const SizedBox(height: 12),
      ],
      SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: canBook && !_submitting ? _book : null,
          icon:
              _submitting || _loadingDetail
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.check_circle_outline),
          label: Text(
            _loadingDetail
                ? 'Checking…'
                : (_submitting ? 'Booking…' : 'Book this shift'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surfaceHigh,
            disabledForegroundColor: Colors.white38,
          ),
        ),
      ),
      if (!canBook && !_loadingDetail) ...[
        const SizedBox(height: 10),
        Text(
          _disabledReason(slot),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    ];
  }

  String _disabledReason(OpenSlot slot) {
    if (slot.overlap) return 'Cancel the overlapping shift to book this one.';
    if (slot.isFull) return 'This shift is full.';
    if (slot.tooSoon) return 'Booking opens one week before the shift.';
    return '';
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.slot});

  final OpenSlot slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot.positionName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            slot.shopName,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const Divider(height: 24, color: AppColors.surfaceHigh),
          _DetailRow(
            icon: Icons.calendar_today,
            label: formatSlotDate(DateTime.parse(slot.slotDate)),
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.schedule,
            label: '${slot.startHm} – ${slot.endHm}',
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.people_outline,
            label:
                slot.isFull
                    ? 'No seats left (${slot.capacity} booked)'
                    : '${slot.remaining} of ${slot.capacity} seats open',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.silver),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
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
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
