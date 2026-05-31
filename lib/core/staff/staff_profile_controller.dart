import 'package:flutter/foundation.dart';

import '../api/api_exceptions.dart';
import '../api/staff_api_client.dart';
import 'staff_profile.dart';

/// Load lifecycle for the self-service profile screen.
enum StaffProfileStatus { initial, loading, loaded, error }

/// Owns the staff self-service profile and exposes it as a [ChangeNotifier].
///
/// The profile screen listens via Provider; the edit screen drives [save].
/// Loading and saving are tracked separately so the edit form can show a saving
/// spinner without discarding the already-loaded profile.
class StaffProfileController extends ChangeNotifier {
  StaffProfileController({required StaffApiClient apiClient})
    : _api = apiClient;

  final StaffApiClient _api;

  StaffProfileStatus _status = StaffProfileStatus.initial;
  StaffProfile? _profile;
  String? _sessionUserId;
  String? _profileUserId;
  String? _loadingUserId;
  String? _error;
  bool _saving = false;
  String? _saveError;
  bool _disposed = false;

  StaffProfileStatus get status => _status;
  StaffProfile? get profile => profileForUser(_sessionUserId);
  String? get profileUserId => _profileUserId;
  String? get error => _error;
  bool get loading => _status == StaffProfileStatus.loading;
  bool get saving => _saving;
  String? get saveError => _saveError;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  String? _normalizeUserId(String? userId) {
    final value = userId?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  StaffProfile? profileForUser(String? userId) {
    final normalized = _normalizeUserId(userId);
    if (normalized == null) {
      return _profileUserId == null ? _profile : null;
    }
    return _profileUserId == normalized ? _profile : null;
  }

  bool isLoadingFor(String? userId) {
    return _status == StaffProfileStatus.loading &&
        _loadingUserId == _normalizeUserId(userId);
  }

  void setSessionUserId(String? userId, {bool notify = true}) {
    final normalized = _normalizeUserId(userId);
    if (_sessionUserId == normalized) return;

    _sessionUserId = normalized;
    if (_profileUserId == normalized && normalized != null) return;

    final hadState =
        _profile != null ||
        _profileUserId != null ||
        _status != StaffProfileStatus.initial ||
        _error != null ||
        _saveError != null ||
        _saving;
    _profile = null;
    _profileUserId = null;
    _loadingUserId = null;
    _status = StaffProfileStatus.initial;
    _error = null;
    _saveError = null;
    _saving = false;

    if (hadState && notify) _notify();
  }

  /// Loads the profile from the backend. Safe to call repeatedly (e.g. retry).
  Future<void> load({String? userId}) async {
    final requestUserId = _normalizeUserId(userId ?? _sessionUserId);
    if (userId != null) {
      setSessionUserId(requestUserId);
    }

    _status = StaffProfileStatus.loading;
    _loadingUserId = requestUserId;
    _error = null;
    if (_profileUserId != requestUserId) {
      _profile = null;
      _profileUserId = null;
    }
    _notify();
    try {
      final loaded = await _api.getStaffProfile();
      if (_sessionUserId != requestUserId) return;
      _profile = loaded;
      _profileUserId = requestUserId;
      _status = StaffProfileStatus.loaded;
    } on ApiException catch (e) {
      if (_sessionUserId != requestUserId) return;
      _error = e.message;
      _status = StaffProfileStatus.error;
    } catch (_) {
      if (_sessionUserId != requestUserId) return;
      _error = 'Could not load your profile.';
      _status = StaffProfileStatus.error;
    } finally {
      if (_sessionUserId == requestUserId) {
        _loadingUserId = null;
      }
    }
    _notify();
  }

  /// Saves [update]. Returns the updated profile on success, or null on failure
  /// (with [saveError] set).
  Future<StaffProfile?> save(StaffProfileUpdate update) async {
    final requestUserId = _sessionUserId;
    _saving = true;
    _saveError = null;
    _notify();
    try {
      final updated = await _api.updateStaffProfile(update);
      if (_sessionUserId != requestUserId) return null;
      _profile = updated;
      _profileUserId = requestUserId;
      _status = StaffProfileStatus.loaded;
      _saving = false;
      _notify();
      return updated;
    } on ApiException catch (e) {
      if (_sessionUserId != requestUserId) return null;
      _saveError = e.message;
      _saving = false;
      _notify();
      return null;
    } catch (_) {
      if (_sessionUserId != requestUserId) return null;
      _saveError = 'Could not save your profile.';
      _saving = false;
      _notify();
      return null;
    }
  }
}
