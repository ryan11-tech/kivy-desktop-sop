import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zinme_app/core/preferences/user_preferences.dart';
import 'package:zinme_app/core/preferences/user_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('loads defaults for a new user', () async {
    final repository = SharedPreferencesUserPreferencesRepository();

    final preferences = await repository.load('u1');

    expect(preferences.themeMode, UserPreferences.defaults.themeMode);
    expect(preferences.primaryHex, UserPreferences.defaults.primaryHex);
    expect(preferences.fontSize, UserPreferences.defaults.fontSize);
    expect(preferences.language, UserPreferences.defaults.language);
    expect(preferences.pinEnabled, UserPreferences.defaults.pinEnabled);
  });

  test('saves and reloads values by user id', () async {
    final repository = SharedPreferencesUserPreferencesRepository();

    await repository.save(
      'u1',
      const UserPreferences(
        themeMode: 'light',
        primaryHex: '#2278E8',
        fontSize: 'Large',
        language: 'Myanmar',
        pinEnabled: false,
      ),
    );

    final preferences = await repository.load('u1');
    final otherUser = await repository.load('u2');

    expect(preferences.themeMode, 'light');
    expect(preferences.primaryHex, '#2278E8');
    expect(preferences.fontSize, 'Large');
    expect(preferences.language, 'Myanmar');
    expect(preferences.pinEnabled, isFalse);
    expect(otherUser.primaryHex, UserPreferences.defaults.primaryHex);
  });
}
