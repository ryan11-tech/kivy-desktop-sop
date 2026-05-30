import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:zinme_app/core/staff/staff_session_controller.dart';
import 'package:zinme_app/features/no_access/no_access_screen.dart';

class _MockSessionController extends Mock implements StaffSessionController {}

void main() {
  testWidgets('buttons call refreshSession and signOut', (tester) async {
    final controller = _MockSessionController();
    when(() => controller.refreshSession()).thenAnswer((_) async {});
    when(() => controller.signOut()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ChangeNotifierProvider<StaffSessionController>.value(
        value: controller,
        child: const MaterialApp(
          home: NoAccessScreen(email: 'staff@example.com'),
        ),
      ),
    );

    await tester.tap(find.text('Check again'));
    await tester.tap(find.text('Sign out'));

    verify(() => controller.refreshSession()).called(1);
    verify(() => controller.signOut()).called(1);
  });
}
