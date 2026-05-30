import 'package:flutter/foundation.dart';

import '../api/api_exceptions.dart';
import '../staff/shop.dart';
import 'attendance_models.dart';
import 'attendance_repository.dart';
import 'location_service.dart';

/// Coarse render state for the attendance card. The detailed sub-states
/// (clocked in vs not, shop missing location) are derived from [data] so the
/// card can branch without extra enum churn.
enum AttendanceCardStatus { noShop, loading, ready, error }

/// Owns attendance state for the currently selected shop.
///
/// Reloads when the active shop changes (mirrors the SOP/recipe controllers)
/// and captures location only when the user actually taps clock in/out.
class AttendanceController extends ChangeNotifier {
  AttendanceController(this._repository, this._locationProvider);

  final AttendanceRepository _repository;
  final LocationProvider _locationProvider;

  AttendanceCardStatus _status = AttendanceCardStatus.noShop;
  AttendanceCardStatus get status => _status;

  AttendanceStatus? _data;
  AttendanceStatus? get data => _data;
  AttendanceOpenSession? get openSession => _data?.openSession;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Transient message from the last clock in/out attempt (out of range,
  /// permission denied, …). Cleared at the start of the next attempt.
  String? _actionMessage;
  String? get actionMessage => _actionMessage;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _loadedShopId;
  int _requestToken = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Loads attendance for [shop]. No-op when the shop is unchanged and already
  /// loaded, unless [force] is set.
  Future<void> loadForShop(Shop? shop, {bool force = false}) async {
    if (shop == null) {
      _loadedShopId = null;
      _data = null;
      _actionMessage = null;
      _errorMessage = null;
      _setStatus(AttendanceCardStatus.noShop);
      return;
    }

    final settled = _status == AttendanceCardStatus.ready;
    final inFlight =
        _status == AttendanceCardStatus.loading && shop.id == _loadedShopId;
    if (!force && shop.id == _loadedShopId && (settled || inFlight)) {
      return;
    }

    final token = ++_requestToken;
    _loadedShopId = shop.id;
    _data = null;
    _actionMessage = null;
    _errorMessage = null;
    _setStatus(AttendanceCardStatus.loading);
    await _fetch(shop.id, token);
  }

  /// Retries the current shop after a load error.
  Future<void> retry() async {
    final shopId = _loadedShopId;
    if (shopId != null) {
      final token = ++_requestToken;
      _setStatus(AttendanceCardStatus.loading);
      await _fetch(shopId, token);
    }
  }

  Future<void> clockIn() => _submit(clockingIn: true);

  Future<void> clockOut() => _submit(clockingIn: false);

  Future<void> _submit({required bool clockingIn}) async {
    final data = _data;
    if (data == null || _isSubmitting) return;

    // Pin the active-shop token so a mid-flight shop switch can't let this
    // action write its message or spinner onto the newly selected shop.
    final token = _requestToken;
    _isSubmitting = true;
    _actionMessage = null;
    _notify();

    final shopId = data.shopId;
    final locationRequired = data.attendanceLocationRequired;
    CapturedLocation? location;

    // Capture location when the shop requires it, or opportunistically when the
    // shop has coordinates so the record carries distance. When it is optional
    // and capture fails, proceed without a location rather than blocking.
    if (locationRequired || data.shopLocationConfigured) {
      final resolution = _resolveLocation(await _locationProvider.capture());
      if (_isStale(token)) {
        _isSubmitting = false;
        return;
      }
      if (resolution.location == null && locationRequired) {
        _actionMessage = resolution.message;
        _isSubmitting = false;
        _notify();
        return;
      }
      location = resolution.location;
    }

    try {
      if (clockingIn) {
        await _repository.clockIn(shopId: shopId, location: location);
      } else {
        await _repository.clockOut(shopId: shopId, location: location);
      }
      await _refreshStatus(shopId);
    } on ClientApiException catch (error) {
      if (!_isStale(token)) _actionMessage = _messageForCode(error);
      // Refresh so the card reflects the true state (e.g. already clocked in).
      await _refreshStatus(shopId);
    } on ApiException catch (error) {
      if (!_isStale(token)) _actionMessage = error.message;
    } finally {
      // The submit flag is owned solely by this method, so always clear it; the
      // status/message writes above are what stay guarded against a stale shop.
      _isSubmitting = false;
      _notify();
    }
  }

  Future<void> _fetch(String shopId, int token) async {
    try {
      final status = await _repository.status(shopId);
      if (_isStale(token)) return;
      _data = status;
      _setStatus(AttendanceCardStatus.ready);
    } on ApiException catch (error) {
      if (_isStale(token)) return;
      _errorMessage = error.message;
      _setStatus(AttendanceCardStatus.error);
    } catch (_) {
      if (_isStale(token)) return;
      _errorMessage = 'Something went wrong. Please try again.';
      _setStatus(AttendanceCardStatus.error);
    }
  }

  /// Re-reads status after an action without flipping the card to a spinner.
  Future<void> _refreshStatus(String shopId) async {
    try {
      final status = await _repository.status(shopId);
      if (_loadedShopId != shopId) return;
      _data = status;
      _errorMessage = null;
      _status = AttendanceCardStatus.ready;
    } on ApiException {
      // Keep the last known data; the action message already explains the issue.
    }
  }

  _LocationResolution _resolveLocation(LocationOutcome outcome) {
    switch (outcome) {
      case LocationCaptured(:final location):
        return _LocationResolution(location: location);
      case LocationServiceDisabled():
        return const _LocationResolution(
          message: 'Turn on location services to clock in/out.',
        );
      case LocationPermissionDenied(permanently: final permanently):
        return _LocationResolution(
          message:
              permanently
                  ? 'Enable location permission in Settings to clock in/out.'
                  : 'Location permission is needed to clock in/out.',
        );
      case LocationCaptureFailed(:final message):
        return _LocationResolution(message: message);
    }
  }

  String _messageForCode(ClientApiException error) {
    switch (error.code) {
      case 'OUT_OF_RANGE':
        final distance = error.distanceMeters;
        final radius = error.allowedRadiusMeters;
        if (distance != null && radius != null) {
          return 'You are ${distance}m away. Move within ${radius}m of the shop and try again.';
        }
        return error.message;
      case 'LOCATION_ACCURACY_TOO_LOW':
        return 'Location accuracy is too low. Move to an open area and try again.';
      case 'LOCATION_TOO_OLD':
        return 'Location reading was too old. Try again.';
      case 'SHOP_LOCATION_NOT_CONFIGURED':
        return 'This shop has no saved location yet. Ask an admin to set it.';
      case 'LOCATION_REQUIRED':
        return 'Location is required to clock in/out at this shop.';
      case 'ALREADY_CLOCKED_IN':
        return 'You are already clocked in.';
      case 'NO_OPEN_ATTENDANCE_SESSION':
        return 'You are not clocked in.';
      default:
        return error.message;
    }
  }

  bool _isStale(int token) => _disposed || token != _requestToken;

  void _setStatus(AttendanceCardStatus status) {
    _status = status;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}

class _LocationResolution {
  const _LocationResolution({this.location, this.message});
  final CapturedLocation? location;
  final String? message;
}
