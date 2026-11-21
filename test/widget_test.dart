import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wifivoucherapp/main.dart';
import 'package:wifivoucherapp/screens/auth/login_screen.dart';

void main() {
  testWidgets('Renders LoginScreen initially when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const WifiVoucherApp());
    await tester.pumpAndSettle();

    // Verify Login Screen components
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('WiFi Voucher Generator'), findsOneWidget);
    expect(find.text('Administrator Portal Sign In'), findsOneWidget);
    expect(find.text('Sign In as Administrator'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
  });
}
