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
  String? _error;
  bool _saving = false;
  String? _saveError;
  bool _disposed = false;

  StaffProfileStatus get status => _status;
  StaffProfile? get profile => _profile;
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

  /// Loads the profile from the backend. Safe to call repeatedly (e.g. retry).
  Future<void> load() async {
    _status = StaffProfileStatus.loading;
    _error = null;
    _notify();
    try {
      _profile = await _api.getStaffProfile();
      _status = StaffProfileStatus.loaded;
    } on ApiException catch (e) {
      _error = e.message;
      _status = StaffProfileStatus.error;
    } catch (_) {
      _error = 'Could not load your profile.';
      _status = StaffProfileStatus.error;
    }
    _notify();
  }

  /// Saves [update]. Returns the updated profile on success, or null on failure
  /// (with [saveError] set).
  Future<StaffProfile?> save(StaffProfileUpdate update) async {
    _saving = true;
    _saveError = null;
    _notify();
    try {
      final updated = await _api.updateStaffProfile(update);
      _profile = updated;
      _status = StaffProfileStatus.loaded;
      _saving = false;
      _notify();
      return updated;
    } on ApiException catch (e) {
      _saveError = e.message;
      _saving = false;
      _notify();
      return null;
    } catch (_) {
      _saveError = 'Could not save your profile.';
      _saving = false;
      _notify();
      return null;
    }
  }
}
