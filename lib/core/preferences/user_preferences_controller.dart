import 'package:flutter/foundation.dart';

import 'user_preferences.dart';
import 'user_preferences_repository.dart';

class UserPreferencesController extends ChangeNotifier {
  UserPreferencesController({required UserPreferencesRepository repository})
    : _repository = repository;

  final UserPreferencesRepository _repository;

  UserPreferences _preferences = UserPreferences.defaults;
  UserPreferences get preferences => _preferences;

  String? _loadedUserId;
  bool _loading = false;
  bool get loading => _loading;

  Future<UserPreferences> loadForUser(
    String userId, {
    bool force = false,
  }) async {
    if (!force && _loadedUserId == userId) {
      return _preferences;
    }
    _loading = true;
    final next = await _repository.load(userId);
    _loadedUserId = userId;
    _preferences = next;
    _loading = false;
    notifyListeners();
    return next;
  }

  Future<void> saveForUser(String userId, UserPreferences preferences) async {
    _loadedUserId = userId;
    _preferences = preferences;
    notifyListeners();
    await _repository.save(userId, preferences);
  }

  void clearLoadedUser() {
    _loadedUserId = null;
    _preferences = UserPreferences.defaults;
    _loading = false;
    notifyListeners();
  }
}
