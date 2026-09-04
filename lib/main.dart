import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/admin_dashboard.dart';
import 'screens/employee_dashboard.dart';
import 'services/app_service.dart';
import 'theme/app_theme.dart';
import 'database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Connect to MySQL and synchronize database
  MySqlDatabase.connect().then((connected) {
    if (connected) {
      AppService.instance.syncWithDatabase();
    }
  }).catchError((e) {
    debugPrint("MySQL initialization note: $e");
  });

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const CoffeeApp(),
    ),
  );
}

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppService.instance,
      builder: (context, _) {
        return MaterialApp(
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          title: 'Coffee Shop POS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          initialRoute: '/login',
          onGenerateRoute: (settings) {
            final appService = AppService.instance;
            final isLoggedIn = appService.isLoggedIn;
            final isAdmin = appService.isAdmin;

            // Route Guards
            if (settings.name != '/login' && settings.name != '/signup') {
              if (!isLoggedIn) {
                return MaterialPageRoute(builder: (_) => const LoginPage());
              }
            }

            switch (settings.name) {
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginPage());
              case '/signup':
                return MaterialPageRoute(builder: (_) => const SignupPage());
              case '/employee_dashboard':
                return MaterialPageRoute(builder: (_) => const EmployeeDashboard());
              case '/admin_dashboard':
                if (!isAdmin) {
                  return MaterialPageRoute(builder: (_) => const EmployeeDashboard());
                }
                return MaterialPageRoute(builder: (_) => const AdminDashboard());
              default:
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Page Not Found')),
                    body: const Center(
                      child: Text('404 - Route Not Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
