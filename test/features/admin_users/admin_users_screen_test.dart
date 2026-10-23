import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:zinme_app/core/api/admin_api_models.dart';
import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/features/admin_users/admin_users_screen.dart';

class _MockApi extends Mock implements StaffApiClient {}

const _shop = PortalShop(
  id: 'shop-1',
  slug: 'silom',
  name: 'Silom',
  status: 'active',
);

const _mya = PortalStaffAccount(
  id: 'profile-1',
  userId: 'user-1',
  name: 'Mya',
  email: 'mya@example.com',
  accountRole: 'staff',
  status: 'active',
  staffCode: null,
  mustChangePassword: false,
  shops: [
    PortalStaffMembership(shopId: 'shop-1', shopName: 'Silom', role: 'cashier'),
  ],
);

const _otp = PortalOneTimePassword(
  password: 'K7QM-4XPA',
  expiresAt: null,
  expiresAtText: '2026-10-31T07:05:00.000Z',
);

Future<_MockApi> _pumpScreen(WidgetTester tester) async {
  final api = _MockApi();
  when(() => api.listPortalShops()).thenAnswer((_) async => [_shop]);
  when(() => api.listPortalStaffAccounts()).thenAnswer((_) async => [_mya]);
  await tester.pumpWidget(
    Provider<StaffApiClient>.value(
      value: api,
      child: const MaterialApp(home: AdminUsersScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const PortalStaffMutation(
        accountRole: 'staff',
        email: '',
        name: '',
        shopMemberships: [],
      ),
    );
  });

  testWidgets('create has no password field and shows the one-time password', (
    tester,
  ) async {
    final api = await _pumpScreen(tester);
    when(() => api.createPortalStaffAccount(any())).thenAnswer(
      (_) async =>
          const PortalStaffCreateResult(staff: _mya, oneTimePassword: _otp),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Temporary password'), findsNothing);
    expect(find.text('Force password change'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Mya');
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'mya@example.com',
    );
    await tester.tap(find.text('Silom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('One-time password'), findsOneWidget);
    expect(find.text('K7QM-4XPA'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('K7QM-4XPA'), findsNothing);
  });

  testWidgets('suspending needs a reason and sends status + statusReason', (
    tester,
  ) async {
    final api = await _pumpScreen(tester);
    when(
      () => api.updatePortalStaffAccount(any(), any()),
    ).thenAnswer((_) async => _mya);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suspended'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verifyNever(() => api.updatePortalStaffAccount(any(), any()));
    expect(
      find.text('Give a reason of at least 5 characters.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Reason'),
      'Left the shop',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final sent =
        verify(
              () => api.updatePortalStaffAccount('profile-1', captureAny()),
            ).captured.single
            as PortalStaffMutation;
    expect(sent.status, 'suspended');
    expect(sent.statusReason, 'Left the shop');
  });

  testWidgets('saving without a status change sends no status', (tester) async {
    final api = await _pumpScreen(tester);
    when(
      () => api.updatePortalStaffAccount(any(), any()),
    ).thenAnswer((_) async => _mya);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final sent =
        verify(
              () => api.updatePortalStaffAccount('profile-1', captureAny()),
            ).captured.single
            as PortalStaffMutation;
    expect(sent.status, isNull);
    expect(sent.toUpdateJson().containsKey('status'), isFalse);
  });

  testWidgets('new one-time password confirms first and shows server errors', (
    tester,
  ) async {
    final api = await _pumpScreen(tester);
    when(() => api.issuePortalStaffOneTimePassword('profile-1')).thenThrow(
      const ClientApiException(
        'Store managers cannot update another store manager',
        statusCode: 403,
      ),
    );

    await tester.tap(find.byTooltip('New one-time password'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('signs Mya out on every device'),
      findsOneWidget,
    );

    await tester.tap(find.text('New password'));
    await tester.pumpAndSettle();

    expect(
      find.text('Store managers cannot update another store manager'),
      findsOneWidget,
    );
  });
}
