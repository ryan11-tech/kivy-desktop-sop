import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/core/staff/shop.dart';
import 'package:zinme_app/core/staff/staff_profile.dart';
import 'package:zinme_app/core/staff/staff_profile_controller.dart';
import 'package:zinme_app/core/staff/staff_session_controller.dart';
import 'package:zinme_app/core/staff/staff_session_state.dart';
import 'package:zinme_app/features/staff_profile/staff_profile_screen.dart';

class _MockApi extends Mock implements StaffApiClient {}

class _MockSession extends Mock implements StaffSessionController {}

StaffProfile _profile() {
  return const StaffProfile(
    id: 'p1',
    email: 'su@example.com',
    displayName: 'Su Su',
    preferredName: 'Su',
    phone: '0801234567',
    lineId: 'su_line',
    accountRole: 'staff',
    status: 'active',
    staffCode: 'CS1234',
    shops: <StaffProfileShop>[
      StaffProfileShop(id: 's1', name: 'Wat Ket', role: 'cashier'),
    ],
  );
}

void main() {
  testWidgets('renders read-only profile without manager-only fields', (
    tester,
  ) async {
    final api = _MockApi();
    when(() => api.getStaffProfile()).thenAnswer((_) async => _profile());
    final controller = StaffProfileController(apiClient: api);

    final session = _MockSession();
    when(() => session.state).thenReturn(
      const StaffSessionState(
        status: StaffSessionStatus.ready,
        activeShop: Shop(id: 's1', name: 'Wat Ket'),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StaffProfileController>.value(
            value: controller,
          ),
          ChangeNotifierProvider<StaffSessionController>.value(value: session),
        ],
        child: const MaterialApp(home: StaffProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Su Su'), findsOneWidget);
    expect(find.text('su@example.com'), findsOneWidget);
    expect(find.text('CS1234'), findsOneWidget);
    expect(
      find.text('Work information is managed by your manager.'),
      findsOneWidget,
    );

    // The self-service view must not expose manager-controlled data.
    expect(find.textContaining('membershipStatus'), findsNothing);
    expect(find.textContaining('Emergency'), findsNothing);
    expect(find.textContaining('preferredLanguage'), findsNothing);
    expect(find.text('Language'), findsNothing);

    controller.dispose();
  });
}
