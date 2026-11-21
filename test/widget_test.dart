import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wifivoucherapp/main.dart';
import 'package:wifivoucherapp/screens/auth/login_screen.dart';

void main() {
  testWidgets('Renders LoginScreen initially when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WifiVoucherApp());
    await tester.pumpAndSettle();

    // Verify Login Screen components
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('WiFi Voucher Generator'), findsOneWidget);
    expect(find.text('Administrator Portal Sign In'), findsOneWidget);
    expect(find.text('Sign In as Administrator'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
  });

  testWidgets('Opens account creation and rejects mismatched passwords', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WifiVoucherApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create new account'));
    await tester.pumpAndSettle();

    expect(find.text('Create administrator account'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'newadmin@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.enterText(fields.at(2), 'password456');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
