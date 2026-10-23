import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:zinme_app/core/api/admin_api_models.dart';
import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/api/staff_api_client.dart';
import 'package:zinme_app/core/staff/staff_session_controller.dart';
import 'package:zinme_app/core/staff/staff_session_state.dart';
import 'package:zinme_app/core/staff/staff_user.dart';
import 'package:zinme_app/features/admin_users/admin_users_screen.dart';

class _MockApi extends Mock implements StaffApiClient {}

class _MockSession extends Mock implements StaffSessionController {}

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

const _aye = PortalStaffAccount(
  id: 'profile-2',
  userId: 'user-2',
  name: 'Aye',
  email: 'aye@example.com',
  accountRole: 'admin',
  status: 'active',
  staffCode: null,
  mustChangePassword: false,
  shops: [],
);

const _sai = PortalStaffAccount(
  id: 'profile-3',
  userId: 'user-3',
  name: 'Sai',
  email: 'sai@example.com',
  accountRole: 'staff',
  status: 'suspended',
  staffCode: null,
  mustChangePassword: false,
  shops: [
    PortalStaffMembership(shopId: 'shop-1', shopName: 'Silom', role: 'cashier'),
  ],
);

StaffUser _signedIn({required String staffProfileId, String role = 'admin'}) {
  return StaffUser(
    id: 'user-signed-in',
    email: 'me@example.com',
    displayName: 'Me',
    requiresPasswordChange: false,
    accountRole: role,
    staffProfileId: staffProfileId,
  );
}

/// Pumps the screen pushed on top of a 'Home' route, so leaving it can be
/// tested. With [signedIn], a session reporting that user is provided.
Future<_MockApi> _pumpScreen(
  WidgetTester tester, {
  List<PortalStaffAccount> accounts = const [_mya],
  StaffUser? signedIn,
}) async {
  final api = _MockApi();
  when(() => api.listPortalShops()).thenAnswer((_) async => [_shop]);
  when(() => api.listPortalStaffAccounts()).thenAnswer((_) async => accounts);
  final navigatorKey = GlobalKey<NavigatorState>();
  Widget app = Provider<StaffApiClient>.value(
    value: api,
    child: MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('Home')),
    ),
  );
  if (signedIn != null) {
    final session = _MockSession();
    when(() => session.state).thenReturn(
      StaffSessionState(status: StaffSessionStatus.ready, user: signedIn),
    );
    when(() => session.addListener(any())).thenReturn(null);
    when(() => session.removeListener(any())).thenReturn(null);
    app = ChangeNotifierProvider<StaffSessionController>.value(
      value: session,
      child: app,
    );
  }
  await tester.pumpWidget(app);
  navigatorKey.currentState!.push(
    MaterialPageRoute<void>(builder: (_) => const AdminUsersScreen()),
  );
  await tester.pumpAndSettle();
  return api;
}

/// Simulates the system back button / gesture.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

final _keyButton = find.byWidgetPredicate(
  (widget) => widget is IconButton && widget.tooltip == 'New one-time password',
);

void main() {
  setUpAll(() {
    registerFallbackValue(() {});
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

  testWidgets('own account has no key button and no status switch', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      accounts: const [_mya, _aye],
      signedIn: _signedIn(staffProfileId: 'profile-1'),
    );

    // Only Aye's row (not the signed-in Mya's) offers a new password.
    expect(_keyButton, findsOneWidget);
    final ayeCard = find.ancestor(
      of: find.text('aye@example.com'),
      matching: find.byType(Card),
    );
    expect(find.descendant(of: ayeCard, matching: _keyButton), findsOneWidget);

    await tester.tap(find.byTooltip('Edit').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit staff'), findsOneWidget);
    expect(find.text('NOW ACTIVE'), findsOneWidget);
    expect(find.text('Suspended'), findsNothing);
    expect(find.text('Active'), findsNothing);
  });

  testWidgets('lift-suspension hint shows for non-admins only', (tester) async {
    Future<void> openAndLift() async {
      await tester.tap(find.byTooltip('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
    }

    await _pumpScreen(
      tester,
      accounts: const [_sai],
      signedIn: _signedIn(staffProfileId: 'profile-9', role: 'staff'),
    );
    await openAndLift();
    expect(find.text('Only an admin can lift a suspension.'), findsOneWidget);

    await _pumpScreen(
      tester,
      accounts: const [_sai],
      signedIn: _signedIn(staffProfileId: 'profile-9'),
    );
    await openAndLift();
    expect(find.text('Only an admin can lift a suspension.'), findsNothing);
  });

  testWidgets('edit dialog survives barrier taps and back while saving', (
    tester,
  ) async {
    final api = await _pumpScreen(tester);
    final pending = Completer<PortalStaffAccount>();
    when(
      () => api.updatePortalStaffAccount(any(), any()),
    ).thenAnswer((_) => pending.future);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    // Not dismissible by the barrier even before saving.
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Edit staff'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    await _systemBack(tester);
    expect(find.text('Edit staff'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
          .onPressed,
      isNull,
    );

    pending.complete(_mya);
    await tester.pumpAndSettle();
    expect(find.text('Edit staff'), findsNothing);
    expect(find.text('User access'), findsOneWidget);
  });

  testWidgets('back closes the edit dialog when nothing is pending', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await _systemBack(tester);
    await tester.pumpAndSettle();
    expect(find.text('Edit staff'), findsNothing);
    expect(find.text('User access'), findsOneWidget);
  });

  testWidgets('new one-time password blocks repeats and leaving until shown', (
    tester,
  ) async {
    final api = await _pumpScreen(tester);
    final pending = Completer<PortalOneTimePassword>();
    when(
      () => api.issuePortalStaffOneTimePassword('profile-1'),
    ).thenAnswer((_) => pending.future);

    await tester.tap(_keyButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final spinner = find.descendant(
      of: _keyButton,
      matching: find.byType(CircularProgressIndicator),
    );
    expect(spinner, findsOneWidget);
    expect(tester.widget<IconButton>(_keyButton).onPressed, isNull);

    // A second tap does nothing; back does not leave the screen.
    await tester.tap(_keyButton, warnIfMissed: false);
    await tester.pump();
    expect(find.text('New one-time password?'), findsNothing);
    await _systemBack(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('User access'), findsOneWidget);

    pending.complete(_otp);
    await tester.pumpAndSettle();
    expect(find.text('K7QM-4XPA'), findsOneWidget);
    verify(() => api.issuePortalStaffOneTimePassword('profile-1')).called(1);
    expect(spinner, findsNothing);

    // Back does not close the password dialog; only Done does.
    await _systemBack(tester);
    await tester.pumpAndSettle();
    expect(find.text('K7QM-4XPA'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('K7QM-4XPA'), findsNothing);

    // Nothing pending any more: back leaves the screen.
    await _systemBack(tester);
    await tester.pumpAndSettle();
    expect(find.text('User access'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('reason counter counts trimmed UTF-16 and refuses over 500', (
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
    final reason = find.widgetWithText(TextField, 'Reason');
    expect(find.text('0/500'), findsOneWidget);

    // 501 is not truncated by the field but is refused on Save.
    await tester.enterText(reason, 'a' * 501);
    await tester.pump();
    expect(find.text('501/500'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    verifyNever(() => api.updatePortalStaffAccount(any(), any()));
    expect(
      find.text('Keep the reason to at most 500 characters.'),
      findsOneWidget,
    );

    // 250 emoji = 500 UTF-16 code units (+ trimmed spaces): exactly allowed.
    const emoji = '\u{1F600}';
    await tester.enterText(reason, '  ${emoji * 250}  ');
    await tester.pumpAndSettle();
    expect(find.text('500/500'), findsOneWidget);
    expect(
      find.text('Keep the reason to at most 500 characters.'),
      findsNothing,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final sent =
        verify(
              () => api.updatePortalStaffAccount('profile-1', captureAny()),
            ).captured.single
            as PortalStaffMutation;
    expect(sent.statusReason, emoji * 250);
  });
}
