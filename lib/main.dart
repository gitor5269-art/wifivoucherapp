import 'package:material_ui/material_ui.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_layout.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService().initialize();
  runApp(const WifiVoucherApp());
}

class WifiVoucherApp extends StatelessWidget {
  const WifiVoucherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Voucher Generator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ValueListenableBuilder<String?>(
        valueListenable: AuthService().currentAdminEmailNotifier,
        builder: (context, adminEmail, _) {
          if (adminEmail == null) {
            return const LoginScreen();
          }
          return const MainLayout();
        },
      ),
    );
  }
}
