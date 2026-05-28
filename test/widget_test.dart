import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:zinme_app/app.dart';
import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/core/staff/connectivity_probe.dart';
import 'package:zinme_app/core/staff/secure_session_store.dart';
import 'package:zinme_app/core/staff/shop.dart';
import 'package:zinme_app/core/staff/staff_session_controller.dart';
import 'package:zinme_app/core/staff/staff_user.dart';

class _MockApi extends Mock implements StaffApiClient {}

class _MockStore extends Mock implements SecureSessionStore {}

class _MockConnectivity extends Mock implements ConnectivityProbe {}

void main() {
  testWidgets('renders home when staff session is ready', (tester) async {
    final api = _MockApi();
    final store = _MockStore();
    final connectivity = _MockConnectivity();

    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    when(() => store.readUser()).thenAnswer((_) async => null);
    when(() => store.readShops()).thenAnswer((_) async => const <Shop>[]);
    when(() => store.readActiveShopId()).thenAnswer((_) async => null);
    when(() => store.saveUser(any())).thenAnswer((_) async {});
    when(() => store.saveShops(any())).thenAnswer((_) async {});
    when(() => store.saveActiveShopId(any())).thenAnswer((_) async {});
    when(() => api.me()).thenAnswer((_) async => const StaffUser(
          id: 'u',
          email: 'a@b.c',
          displayName: 'A',
          requiresPasswordChange: false,
          requiresOtp: false,
        ));
    when(() => api.myShops())
        .thenAnswer((_) async => const [Shop(id: 's1', name: 'Shop One')]);

    final controller = StaffSessionController(
      apiClient: api,
      store: store,
      connectivity: connectivity,
    );

    await tester.pumpWidget(ZinmeApp(sessionController: controller));
    await controller.bootstrap();
    await tester.pumpAndSettle();

    // HomeScreen renders the "Kitchen Guide" title.
    expect(find.text('Kitchen Guide'), findsOneWidget);
  });
}
