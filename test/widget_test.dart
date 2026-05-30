import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zinme_app/app.dart';
import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/core/attendance/attendance_models.dart';
import 'package:zinme_app/core/attendance/attendance_repository.dart';
import 'package:zinme_app/core/attendance/location_service.dart';
import 'package:zinme_app/core/auth/pin_credential_store.dart';
import 'package:zinme_app/core/firestore/favorites_repository.dart';
import 'package:zinme_app/core/models/content_item.dart';
import 'package:zinme_app/core/preferences/user_preferences.dart';
import 'package:zinme_app/core/preferences/user_preferences_controller.dart';
import 'package:zinme_app/core/preferences/user_preferences_repository.dart';
import 'package:zinme_app/core/recipes/recipe_repository.dart';
import 'package:zinme_app/core/sops/sop_repository.dart';
import 'package:zinme_app/core/staff/connectivity_probe.dart';
import 'package:zinme_app/core/staff/secure_session_store.dart';
import 'package:zinme_app/core/staff/shop.dart';
import 'package:zinme_app/core/staff/staff_session_controller.dart';
import 'package:zinme_app/core/staff/staff_user.dart';

class _MockApi extends Mock implements StaffApiClient {}

class _MockStore extends Mock implements SecureSessionStore {}

class _MockConnectivity extends Mock implements ConnectivityProbe {}

class _FakeSopRepository implements SopRepository {
  @override
  Future<List<ContentItem>> listShopSops(String shopId) async =>
      const <ContentItem>[];
}

class _FakeRecipeRepository implements RecipeRepository {
  @override
  Future<List<ContentItem>> listShopRecipes(String shopId) async =>
      const <ContentItem>[];
}

class _FakeAttendanceRepository implements AttendanceRepository {
  @override
  Future<AttendanceStatus> status(String shopId) async => AttendanceStatus(
    shopId: shopId,
    shopName: 'Shop',
    isClockedIn: false,
    shopLocationConfigured: false,
    attendanceRadiusMeters: 500,
    attendanceLocationRequired: false,
  );

  @override
  Future<ClockInResult> clockIn({
    required String shopId,
    CapturedLocation? location,
  }) async => ClockInResult(
    sessionId: 's',
    clockInAt: DateTime.now().toUtc(),
    allowedRadiusMeters: 500,
  );

  @override
  Future<ClockOutResult> clockOut({
    required String shopId,
    CapturedLocation? location,
  }) async => ClockOutResult(
    sessionId: 's',
    clockOutAt: DateTime.now().toUtc(),
    totalMinutes: 0,
    allowedRadiusMeters: 500,
  );

  @override
  Future<List<AttendanceSession>> history({
    DateTime? from,
    DateTime? to,
  }) async => const <AttendanceSession>[];
}

class _FakeLocationProvider implements LocationProvider {
  @override
  Future<LocationOutcome> capture() async => const LocationPermissionDenied();
}

class _MemoryUserPreferencesRepository implements UserPreferencesRepository {
  final Map<String, UserPreferences> values = <String, UserPreferences>{};

  @override
  Future<UserPreferences> load(String userId) async =>
      values[userId] ?? UserPreferences.defaults;

  @override
  Future<void> save(String userId, UserPreferences preferences) async {
    values[userId] = preferences;
  }
}

class _ReadyAppHarness {
  _ReadyAppHarness({
    required this.controller,
    required this.preferencesRepository,
    required this.pinStore,
  });

  final StaffSessionController controller;
  final _MemoryUserPreferencesRepository preferencesRepository;
  final InMemoryPinCredentialStore pinStore;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const StaffUser(
        id: 'fallback',
        email: 'fallback@example.com',
        displayName: 'Fallback',
        requiresPasswordChange: false,
      ),
    );
    registerFallbackValue(const <Shop>[]);
  });

  testWidgets('renders home when staff session is ready', (tester) async {
    await _pumpReadyApp(tester);

    expect(find.text('Enter PIN to continue'), findsNothing);
    expect(find.text('Food & Beverage SOP'), findsOneWidget);
  });

  testWidgets('lock returns configured users to PIN', (tester) async {
    await _pumpReadyApp(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lock'));
    await tester.pumpAndSettle();

    expect(find.text('Enter PIN to continue'), findsOneWidget);
  });

  testWidgets('sign out clears unlocked state and returns to login', (
    tester,
  ) async {
    await _pumpReadyApp(tester);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Zinme Staff'), findsOneWidget);
  });

  testWidgets('settings values survive close and reopen', (tester) async {
    await _pumpReadyApp(tester);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '#2278E8');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('#2278E8'), findsOneWidget);
  });

  testWidgets('bottom nav switches tabs without stacking routes', (
    tester,
  ) async {
    await _pumpReadyApp(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    expect(navigator.canPop(), isFalse);

    await tester.tap(find.text('Schedule').last);
    await tester.pumpAndSettle();
    expect(find.text('Staff Schedule'), findsOneWidget);
    expect(navigator.canPop(), isFalse);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(navigator.canPop(), isFalse);
  });
}

Future<_ReadyAppHarness> _pumpReadyApp(WidgetTester tester) async {
  final api = _MockApi();
  final store = _MockStore();
  final connectivity = _MockConnectivity();
  final preferencesRepository = _MemoryUserPreferencesRepository();
  final pinStore = InMemoryPinCredentialStore();

  when(() => connectivity.isOnline()).thenAnswer((_) async => true);
  when(() => store.readUser()).thenAnswer((_) async => null);
  when(() => store.readShops()).thenAnswer((_) async => const <Shop>[]);
  when(() => store.readActiveShopId()).thenAnswer((_) async => null);
  when(() => store.saveUser(any())).thenAnswer((_) async {});
  when(() => store.saveShops(any())).thenAnswer((_) async {});
  when(() => store.saveActiveShopId(any())).thenAnswer((_) async {});
  when(() => store.clear()).thenAnswer((_) async {});
  when(() => api.clearSession()).thenAnswer((_) async {});
  when(() => api.me()).thenAnswer(
    (_) async => const StaffUser(
      id: 'u',
      email: 'a@b.c',
      displayName: 'A',
      requiresPasswordChange: false,
    ),
  );
  when(
    () => api.myShops(),
  ).thenAnswer((_) async => const [Shop(id: 's1', name: 'Shop One')]);

  final controller = StaffSessionController(
    apiClient: api,
    store: store,
    connectivity: connectivity,
  );

  await tester.pumpWidget(
    ZinmeApp(
      apiClient: api,
      sessionController: controller,
      sopRepository: _FakeSopRepository(),
      recipeRepository: _FakeRecipeRepository(),
      attendanceRepository: _FakeAttendanceRepository(),
      locationProvider: _FakeLocationProvider(),
      favoritesRepository: InMemoryFavoritesRepository(),
      userPreferencesController: UserPreferencesController(
        repository: preferencesRepository,
      ),
      pinCredentialStore: pinStore,
      autoLockEnabled: false,
    ),
  );
  await controller.bootstrap();
  await tester.pumpAndSettle();

  expect(find.text('Enter PIN to continue'), findsOneWidget);

  await tester.tap(find.text('2'));
  await tester.pump();
  await tester.tap(find.text('2'));
  await tester.pump();
  await tester.tap(find.text('2'));
  await tester.pump();
  await tester.tap(find.text('2'));
  await tester.pumpAndSettle();

  return _ReadyAppHarness(
    controller: controller,
    preferencesRepository: preferencesRepository,
    pinStore: pinStore,
  );
}
