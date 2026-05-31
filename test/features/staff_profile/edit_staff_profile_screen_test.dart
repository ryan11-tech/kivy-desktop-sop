import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/core/staff/staff_profile.dart';
import 'package:zinme_app/core/staff/staff_profile_controller.dart';
import 'package:zinme_app/core/staff/staff_session_controller.dart';
import 'package:zinme_app/features/staff_profile/edit_staff_profile_screen.dart';

class _MockApi extends Mock implements StaffApiClient {}

class _MockSession extends Mock implements StaffSessionController {}

const _profile = StaffProfile(
  id: 'p1',
  email: 'su@example.com',
  displayName: 'Su Su',
  accountRole: 'staff',
  status: 'active',
  staffCode: 'CS1234',
);

void main() {
  setUpAll(() {
    registerFallbackValue(const StaffProfileUpdate(displayName: 'x'));
  });

  testWidgets('blocks save and shows error when display name is empty', (
    tester,
  ) async {
    final api = _MockApi();
    final controller = StaffProfileController(apiClient: api);
    final session = _MockSession();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StaffProfileController>.value(
            value: controller,
          ),
          ChangeNotifierProvider<StaffSessionController>.value(value: session),
        ],
        child: const MaterialApp(
          home: EditStaffProfileScreen(profile: _profile),
        ),
      ),
    );

    // Clear the (first) display-name field, then try to save.
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    expect(find.text('Display name is required'), findsOneWidget);
    verifyNever(() => api.updateStaffProfile(any()));

    controller.dispose();
  });

  testWidgets('saves valid edits and updates the session user', (tester) async {
    final api = _MockApi();
    when(() => api.updateStaffProfile(any())).thenAnswer(
      (_) async => const StaffProfile(
        id: 'p1',
        email: 'su@example.com',
        displayName: 'Su Updated',
        preferredName: 'Su',
        accountRole: 'staff',
        status: 'active',
        staffCode: 'CS1234',
      ),
    );
    final controller = StaffProfileController(apiClient: api);

    final session = _MockSession();
    when(
      () => session.applyProfileUpdate(
        displayName: any(named: 'displayName'),
        preferredName: any(named: 'preferredName'),
        phone: any(named: 'phone'),
        lineId: any(named: 'lineId'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StaffProfileController>.value(
            value: controller,
          ),
          ChangeNotifierProvider<StaffSessionController>.value(value: session),
        ],
        child: const MaterialApp(
          home: EditStaffProfileScreen(profile: _profile),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Su Updated');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    verify(() => api.updateStaffProfile(any())).called(1);
    verify(
      () => session.applyProfileUpdate(
        displayName: 'Su Updated',
        preferredName: 'Su',
        phone: null,
        lineId: null,
      ),
    ).called(1);

    controller.dispose();
  });
}
