import 'package:flutter/material.dart';

import '../../core/booking/booking_controller.dart';
import '../../core/booking/booking_models.dart';
import '../../theme/app_colors.dart';
import 'booking_detail_screen.dart';
import 'schedule_format.dart';

/// Staff self-service schedule: browse open shifts and book them, or review and
/// cancel the caller's upcoming bookings. Replaces the old local-only mock; the
/// manager-facing roster lives in the web portal.
///
/// Rendered inside [HomeScreen]'s Scaffold (no Scaffold of its own). State lives
/// in the [BookingController], which [HomeScreen] drives from the active shop.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({required this.controller, super.key});

  final BookingController controller;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

enum _ScheduleTab { browse, mine }

class _ScheduleScreenState extends State<ScheduleScreen> {
  _ScheduleTab _tab = _ScheduleTab.browse;

  BookingController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    // HomeScreen already rebuilds on controller changes, but listen here too so
    // the screen stays correct if shown without that parent wiring.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            _buildTabBar(),
            Expanded(
              child:
                  _tab == _ScheduleTab.browse
                      ? _BrowseView(controller: _controller)
                      : _MyBookingsView(controller: _controller),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    final mineCount = _controller.bookingsForActiveShop.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: SegmentedButton<_ScheduleTab>(
        segments: [
          const ButtonSegment(
            value: _ScheduleTab.browse,
            label: Text('Open shifts'),
            icon: Icon(Icons.event_available_outlined),
          ),
          ButtonSegment(
            value: _ScheduleTab.mine,
            label: Text(mineCount > 0 ? 'My shifts ($mineCount)' : 'My shifts'),
            icon: const Icon(Icons.assignment_ind_outlined),
          ),
        ],
        selected: {_tab},
        onSelectionChanged: (selection) {
          setState(() => _tab = selection.first);
        },
      ),
    );
  }
}

// ── Browse open shifts ────────────────────────────────────────────────────────

class _BrowseView extends StatelessWidget {
  const _BrowseView({required this.controller});

  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterBar(controller: controller),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (controller.slotsStatus) {
      case BookingLoadStatus.idle:
        return const _ScheduleMessage(
          icon: Icons.store_mall_directory_outlined,
          title: 'No shop selected',
          message: 'Select a shop to see its open shifts.',
        );
      case BookingLoadStatus.loading:
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case BookingLoadStatus.error:
        return _ScheduleMessage(
          icon: Icons.error_outline,
          title: 'Could not load shifts',
          message: controller.slotsError ?? 'Something went wrong.',
          onRetry: controller.refreshSlots,
        );
      case BookingLoadStatus.ready:
        break;
    }

    final slots = controller.slots;
    if (slots.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: controller.refreshSlots,
        child: const _ScheduleMessage(
          icon: Icons.event_busy_outlined,
          title: 'No open shifts',
          message: 'There are no open shifts matching your filters right now.',
          scrollable: true,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: controller.refreshSlots,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
        itemCount: slots.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final slot = slots[index];
          return _OpenSlotCard(
            slot: slot,
            onTap: () => _openDetail(context, slot),
          );
        },
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, OpenSlot slot) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailScreen(controller: controller, slot: slot),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    final positions = controller.availablePositions;
    final selectedDate = controller.dateFilter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    selectedDate == null
                        ? 'All upcoming dates'
                        : formatSlotDate(selectedDate),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.surfaceHigh),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              if (selectedDate != null)
                IconButton(
                  tooltip: 'Clear date',
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => controller.setDateFilter(null),
                ),
            ],
          ),
          if (positions.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _RoleChip(
                    label: 'All roles',
                    selected: controller.positionFilter == null,
                    onTap: () => controller.setPositionFilter(null),
                  ),
                  for (final position in positions)
                    _RoleChip(
                      label: position.name,
                      selected: controller.positionFilter == position.id,
                      onTap: () => controller.setPositionFilter(position.id),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    // Bounds are the shop's calendar (Asia/Bangkok, +07:00), not the device's,
    // so a device in another timezone can't offer/seed the wrong shop day around
    // midnight Bangkok. The picked value is a plain calendar day.
    final bangkokNow = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime(bangkokNow.year, bangkokNow.month, bangkokNow.day);
    final existing = controller.dateFilter;
    final initial =
        existing == null || existing.isBefore(today) ? today : existing;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
    );
    if (picked != null) {
      await controller.setDateFilter(picked);
    }
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontSize: 12,
        ),
        side: const BorderSide(color: AppColors.surfaceHigh),
      ),
    );
  }
}

class _OpenSlotCard extends StatelessWidget {
  const _OpenSlotCard({required this.slot, required this.onTap});

  final OpenSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: slot.isBookable ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slot.positionName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatSlotDateString(slot.slotDate),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${slot.startHm} – ${slot.endHm}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        slot.isFull
                            ? 'No seats left'
                            : '${slot.remaining} of ${slot.capacity} seats open',
                        style: TextStyle(
                          color:
                              slot.isFull ? Colors.white38 : AppColors.silver,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _SlotStatusPill(slot: slot),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotStatusPill extends StatelessWidget {
  const _SlotStatusPill({required this.slot});

  final OpenSlot slot;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (slot) {
      _ when slot.isFull => ('Full', AppColors.silver),
      _ when slot.tooSoon => ('Opens 1 wk ahead', AppColors.amber),
      _ => ('Open', AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── My bookings ───────────────────────────────────────────────────────────────

class _MyBookingsView extends StatelessWidget {
  const _MyBookingsView({required this.controller});

  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.bookingsStatus) {
      case BookingLoadStatus.idle:
      case BookingLoadStatus.loading:
        return Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case BookingLoadStatus.error:
        return _ScheduleMessage(
          icon: Icons.error_outline,
          title: 'Could not load your shifts',
          message: controller.bookingsError ?? 'Something went wrong.',
          onRetry: controller.loadMyBookings,
        );
      case BookingLoadStatus.ready:
        break;
    }

    // Active-shop-scoped: a multi-shop staff member only sees and cancels the
    // bookings for the shop they are currently working in.
    final bookings = controller.bookingsForActiveShop;
    if (bookings.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: controller.loadMyBookings,
        child: const _ScheduleMessage(
          icon: Icons.event_note_outlined,
          title: 'No upcoming shifts',
          message: 'Book an open shift and it will show up here.',
          scrollable: true,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: controller.loadMyBookings,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _MyBookingCard(
            booking: bookings[index],
            onCancel: () => _confirmCancel(context, bookings[index]),
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, MyBooking booking) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _CancelSheet(booking: booking),
    );
    if (confirmed != true) return;

    final error = await controller.cancel(
      booking.bookingId,
      shopId: booking.shopId,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Shift cancelled.'),
        backgroundColor: error == null ? AppColors.success : AppColors.primary,
      ),
    );
  }
}

class _MyBookingCard extends StatelessWidget {
  const _MyBookingCard({required this.booking, required this.onCancel});

  final MyBooking booking;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.positionName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            booking.shopName,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            formatSlotDateString(booking.slotDate),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            '${booking.startHm} – ${booking.endHm}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (booking.canCancel)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel shift'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            )
          else
            const Row(
              children: [
                Icon(Icons.lock_clock, size: 14, color: Colors.white38),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Cancellation closed — within 48h of start. Contact your manager.',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CancelSheet extends StatelessWidget {
  const _CancelSheet({required this.booking});

  final MyBooking booking;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cancel this shift?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${booking.positionName} · ${formatSlotDateString(booking.slotDate)}\n'
              '${booking.startHm} – ${booking.endHm} at ${booking.shopName}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your seat reopens for someone else. You can only cancel up to 48 hours before the shift starts.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.surfaceHigh),
                    ),
                    child: const Text('Keep shift'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel shift'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared message view ───────────────────────────────────────────────────────

class _ScheduleMessage extends StatelessWidget {
  const _ScheduleMessage({
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
        final content = Center(
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
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
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
        );
        return SingleChildScrollView(
          physics:
              scrollable
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
