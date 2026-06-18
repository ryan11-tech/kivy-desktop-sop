import 'package:flutter/foundation.dart';

import '../api/api_exceptions.dart';
import '../staff/shop.dart';
import 'booking_models.dart';
import 'booking_repository.dart';

/// Coarse load state reused by each independently-loaded section.
enum BookingLoadStatus { idle, loading, ready, error }

/// A distinct position (role) offered by the open slots, used for filter chips.
class PositionOption {
  const PositionOption({required this.id, required this.name});
  final String id;
  final String name;
}

/// Owns staff self-service booking state: open slots for the active shop
/// (with role + date filters), the caller's upcoming bookings, and
/// schedule-change alerts.
///
/// Reloads open slots when the active shop changes (mirrors the attendance and
/// catalog controllers). Bookings and alerts are caller-scoped, not shop-scoped,
/// so they load once alongside the first shop and refresh on demand.
class BookingController extends ChangeNotifier {
  BookingController(this._repository);

  final BookingRepository _repository;

  // ── Open slots (shop-scoped) ────────────────────────────────────────────
  BookingLoadStatus _slotsStatus = BookingLoadStatus.idle;
  BookingLoadStatus get slotsStatus => _slotsStatus;

  List<OpenSlot> _allSlots = const <OpenSlot>[];
  String? _slotsError;
  String? get slotsError => _slotsError;

  // Role filter is applied client-side so the chip set stays stable for the
  // selected day; the date filter is pushed to the server (smaller payload).
  String? _positionFilter;
  String? get positionFilter => _positionFilter;
  DateTime? _dateFilter;
  DateTime? get dateFilter => _dateFilter;

  String? _loadedShopId;
  String? get loadedShopId => _loadedShopId;
  int _slotsToken = 0;

  bool _disposed = false;

  /// Open slots after applying the client-side role filter.
  List<OpenSlot> get slots {
    final filter = _positionFilter;
    if (filter == null) return _allSlots;
    return _allSlots
        .where((slot) => slot.positionId == filter)
        .toList(growable: false);
  }

  /// Distinct positions across the loaded slots, for filter chips.
  List<PositionOption> get availablePositions {
    final seen = <String, String>{};
    for (final slot in _allSlots) {
      seen.putIfAbsent(slot.positionId, () => slot.positionName);
    }
    return seen.entries
        .map((e) => PositionOption(id: e.key, name: e.value))
        .toList(growable: false);
  }

  // ── My bookings (caller-scoped) ─────────────────────────────────────────
  BookingLoadStatus _bookingsStatus = BookingLoadStatus.idle;
  BookingLoadStatus get bookingsStatus => _bookingsStatus;
  List<MyBooking> _bookings = const <MyBooking>[];
  List<MyBooking> get bookings => _bookings;

  /// The caller's bookings at the currently loaded (active) shop only. The
  /// schedule card is shop-scoped, so cross-shop bookings are neither shown nor
  /// cancellable here. Empty until a shop is loaded.
  List<MyBooking> get bookingsForActiveShop {
    final shopId = _loadedShopId;
    if (shopId == null) return const <MyBooking>[];
    return _bookings.where((b) => b.shopId == shopId).toList(growable: false);
  }

  String? _bookingsError;
  String? get bookingsError => _bookingsError;
  int _bookingsToken = 0;

  // ── Alerts (caller-scoped) ──────────────────────────────────────────────
  BookingLoadStatus _alertsStatus = BookingLoadStatus.idle;
  BookingLoadStatus get alertsStatus => _alertsStatus;
  List<ScheduleAlert> _alerts = const <ScheduleAlert>[];
  List<ScheduleAlert> get alerts => _alerts;
  String? _alertsError;
  String? get alertsError => _alertsError;
  int _alertsToken = 0;

  int get unreadAlertCount => _alerts.where((a) => a.isUnread).length;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Loads open slots for [shop] and, on the first shop, the caller's bookings
  /// and alerts. No-op when the shop is unchanged and already loaded unless
  /// [force] is set.
  Future<void> loadForShop(Shop? shop, {bool force = false}) async {
    if (shop == null) {
      // Invalidate any in-flight fetch for the previous shop so it cannot
      // restore stale slots after the scope is cleared.
      _slotsToken++;
      _loadedShopId = null;
      _allSlots = const <OpenSlot>[];
      _positionFilter = null;
      _dateFilter = null;
      _slotsError = null;
      _setSlotsStatus(BookingLoadStatus.idle);
      return;
    }

    final settled = _slotsStatus == BookingLoadStatus.ready;
    final inFlight =
        _slotsStatus == BookingLoadStatus.loading && shop.id == _loadedShopId;
    if (!force && shop.id == _loadedShopId && (settled || inFlight)) {
      return;
    }

    // A new shop resets the role filter (its positions differ) and drops the
    // previous shop's slots immediately so the role chips — derived from
    // _allSlots — never show another shop's roles during the load. The date
    // filter is kept.
    if (shop.id != _loadedShopId) {
      _positionFilter = null;
      _allSlots = const <OpenSlot>[];
    }
    _loadedShopId = shop.id;
    await _fetchSlots();

    // Caller-scoped sections load lazily on the first shop.
    if (_bookingsStatus == BookingLoadStatus.idle) {
      await loadMyBookings();
    }
    if (_alertsStatus == BookingLoadStatus.idle) {
      await loadAlerts();
    }
  }

  /// Re-fetches open slots for the current shop (e.g. pull-to-refresh).
  Future<void> refreshSlots() => _fetchSlots();

  Future<void> setPositionFilter(String? positionId) async {
    if (_positionFilter == positionId) return;
    _positionFilter = positionId;
    _notify();
  }

  Future<void> setDateFilter(DateTime? date) async {
    if (_sameYmd(_dateFilter, date)) return;
    _dateFilter = date;
    await _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    final shopId = _loadedShopId;
    if (shopId == null) return;
    final token = ++_slotsToken;
    _slotsError = null;
    _setSlotsStatus(BookingLoadStatus.loading);
    try {
      final result = await _repository.openSlots(
        shopId: shopId,
        date: _dateFilter,
      );
      if (_isStaleSlots(token)) return;
      _allSlots = result;
      _setSlotsStatus(BookingLoadStatus.ready);
    } on ApiException catch (error) {
      if (_isStaleSlots(token)) return;
      _slotsError = error.message;
      _setSlotsStatus(BookingLoadStatus.error);
    } catch (_) {
      if (_isStaleSlots(token)) return;
      _slotsError = 'Something went wrong. Please try again.';
      _setSlotsStatus(BookingLoadStatus.error);
    }
  }

  Future<void> loadMyBookings() async {
    final token = ++_bookingsToken;
    _bookingsError = null;
    _bookingsStatus = BookingLoadStatus.loading;
    _notify();
    try {
      final result = await _repository.myBookings();
      if (_isStale(token, _bookingsToken)) return;
      _bookings = result;
      _bookingsStatus = BookingLoadStatus.ready;
    } on ApiException catch (error) {
      if (_isStale(token, _bookingsToken)) return;
      _bookingsError = error.message;
      _bookingsStatus = BookingLoadStatus.error;
    } catch (_) {
      if (_isStale(token, _bookingsToken)) return;
      _bookingsError = 'Something went wrong. Please try again.';
      _bookingsStatus = BookingLoadStatus.error;
    } finally {
      _notify();
    }
  }

  Future<void> loadAlerts() async {
    final token = ++_alertsToken;
    _alertsError = null;
    _alertsStatus = BookingLoadStatus.loading;
    _notify();
    try {
      final result = await _repository.alerts();
      if (_isStale(token, _alertsToken)) return;
      _alerts = result;
      _alertsStatus = BookingLoadStatus.ready;
    } on ApiException catch (error) {
      if (_isStale(token, _alertsToken)) return;
      _alertsError = error.message;
      _alertsStatus = BookingLoadStatus.error;
    } catch (_) {
      if (_isStale(token, _alertsToken)) return;
      _alertsError = 'Something went wrong. Please try again.';
      _alertsStatus = BookingLoadStatus.error;
    } finally {
      _notify();
    }
  }

  /// Fetches a slot's detail, including the `overlap` flag versus the caller's
  /// existing bookings (the list response omits it).
  Future<OpenSlot> slotDetail(String slotId) => _repository.slot(slotId);

  /// Books [slotId]. [shopId] is the slot's shop — the call is rejected if it no
  /// longer matches the active shop (a detail route can outlive a shop switch),
  /// so a stale cross-shop booking is never POSTed. Returns null on success, or a
  /// user-facing message.
  Future<String?> book(String slotId, {required String shopId}) async {
    if (shopId != _loadedShopId) {
      return 'Your active shop changed. Reopen this shift to book it.';
    }
    try {
      await _repository.book(slotId);
    } on ClientApiException catch (error) {
      return _bookingMessageForCode(error);
    } on ApiException catch (error) {
      return error.message;
    }
    await _fetchSlots();
    await loadMyBookings();
    return null;
  }

  /// Cancels [bookingId]. [shopId] is the booking's shop — the call is rejected
  /// if it no longer matches the active shop (a cancel sheet can outlive a shop
  /// switch), so a stale cross-shop cancellation never DELETEs and reopens a seat
  /// in the wrong shop. Returns null on success, or a user-facing message.
  Future<String?> cancel(String bookingId, {required String shopId}) async {
    if (shopId != _loadedShopId) {
      return 'Your active shop changed. Reopen My Shifts to manage this booking.';
    }
    try {
      await _repository.cancel(bookingId);
    } on ClientApiException catch (error) {
      return _cancelMessageForCode(error);
    } on ApiException catch (error) {
      return error.message;
    }
    await loadMyBookings();
    if (_loadedShopId != null) await _fetchSlots();
    return null;
  }

  Future<void> markAlertRead(String alertId) async {
    try {
      await _repository.markAlertRead(alertId);
    } on ApiException {
      return; // Best-effort; the badge will correct on next load.
    }
    _alerts = _alerts
        .map(
          (a) =>
              a.id == alertId && a.isUnread
                  ? ScheduleAlert(
                    id: a.id,
                    type: a.type,
                    createdAt: a.createdAt,
                    payload: a.payload,
                    readAt: DateTime.now().toUtc(),
                  )
                  : a,
        )
        .toList(growable: false);
    _notify();
  }

  String _bookingMessageForCode(ClientApiException error) {
    switch (error.code) {
      case 'TOO_SOON':
        return 'Shifts open for booking one week ahead. Try a later date.';
      case 'SLOT_FULL':
        return 'This shift is already full.';
      case 'OVERLAP':
        return 'This overlaps another shift you have booked that day.';
      case 'ALREADY_BOOKED':
        return 'You have already booked this shift.';
      case 'SLOT_NOT_PUBLISHED':
        return 'This shift is no longer open for booking.';
      case 'SHOP_NOT_ASSIGNED':
        return 'You are not an active staff member at this shop.';
      default:
        return error.message;
    }
  }

  String _cancelMessageForCode(ClientApiException error) {
    switch (error.code) {
      case 'CANCEL_WINDOW_CLOSED':
        return 'Cancellation closes 48 hours before the shift. Contact your manager.';
      case 'NOT_FOUND':
        return 'That booking is no longer active.';
      default:
        return error.message;
    }
  }

  bool _isStaleSlots(int token) => _disposed || token != _slotsToken;
  bool _isStale(int token, int current) => _disposed || token != current;

  bool _sameYmd(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _setSlotsStatus(BookingLoadStatus status) {
    _slotsStatus = status;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
