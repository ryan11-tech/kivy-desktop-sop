import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/app.dart';

void main() {
  testWidgets('shows the mocked shop catalog', (tester) async {
    await tester.pumpWidget(const ZinmeApp());
    await tester.pumpAndSettle();

    expect(find.text('ZinmeAPP'), findsOneWidget);
    expect(find.text('Classic Milk Tea'), findsOneWidget);
    expect(find.text('Opening Counter Checklist'), findsOneWidget);
  });
}
