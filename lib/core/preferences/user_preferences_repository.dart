import 'package:shared_preferences/shared_preferences.dart';

import 'user_preferences.dart';

abstract class UserPreferencesRepository {
  Future<UserPreferences> load(String userId);
  Future<void> save(String userId, UserPreferences preferences);
}

class SharedPreferencesUserPreferencesRepository
    implements UserPreferencesRepository {
  SharedPreferencesUserPreferencesRepository({
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferencesProvider;

  static const _prefix = 'zinme.userPreferences';

  @override
  Future<UserPreferences> load(String userId) async {
    final prefs = await _preferencesProvider();
    final key = _key(userId);
    return UserPreferences(
      themeMode:
          prefs.getString('$key.themeMode') ??
          UserPreferences.defaults.themeMode,
      primaryHex:
          prefs.getString('$key.primaryHex') ??
          UserPreferences.defaults.primaryHex,
      fontSize:
          prefs.getString('$key.fontSize') ?? UserPreferences.defaults.fontSize,
      language:
          prefs.getString('$key.language') ?? UserPreferences.defaults.language,
      pinEnabled:
          prefs.getBool('$key.pinEnabled') ??
          UserPreferences.defaults.pinEnabled,
    );
  }

  @override
  Future<void> save(String userId, UserPreferences preferences) async {
    final prefs = await _preferencesProvider();
    final key = _key(userId);
    await Future.wait([
      prefs.setString('$key.themeMode', preferences.themeMode),
      prefs.setString('$key.primaryHex', preferences.primaryHex),
      prefs.setString('$key.fontSize', preferences.fontSize),
      prefs.setString('$key.language', preferences.language),
      prefs.setBool('$key.pinEnabled', preferences.pinEnabled),
    ]);
  }

  String _key(String userId) => '$_prefix.$userId';
}
