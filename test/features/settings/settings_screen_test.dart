import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:zinme_app/core/preferences/user_preferences.dart';
import 'package:zinme_app/core/preferences/user_preferences_controller.dart';
import 'package:zinme_app/core/preferences/user_preferences_repository.dart';
import 'package:zinme_app/core/staff/shop.dart';
import 'package:zinme_app/core/staff/staff_session_controller.dart';
import 'package:zinme_app/core/staff/staff_session_state.dart';
import 'package:zinme_app/core/staff/staff_user.dart';
import 'package:zinme_app/features/settings/settings_screen.dart';

class _MockSession extends Mock implements StaffSessionController {}

class _FakePrefsRepo implements UserPreferencesRepository {
  @override
  Future<UserPreferences> load(String userId) async => UserPreferences.defaults;

  @override
  Future<void> save(String userId, UserPreferences preferences) async {}
}

void main() {
  testWidgets('account section exposes View Profile entry', (tester) async {
    final session = _MockSession();
    when(() => session.state).thenReturn(
      const StaffSessionState(
        status: StaffSessionStatus.ready,
        user: StaffUser(
          id: 'u1',
          email: 'su@example.com',
          displayName: 'Su Su',
          requiresPasswordChange: false,
        ),
        shops: <Shop>[Shop(id: 's1', name: 'Wat Ket')],
        activeShop: Shop(id: 's1', name: 'Wat Ket'),
      ),
    );
    final preferences = UserPreferencesController(repository: _FakePrefsRepo());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StaffSessionController>.value(value: session),
          ChangeNotifierProvider<UserPreferencesController>.value(
            value: preferences,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen(embedded: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Profile'), findsOneWidget);
  });
}
