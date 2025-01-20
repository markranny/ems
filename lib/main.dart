import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/superadmin_dashboard.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/student_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Add this for initialization
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Management',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Add some custom theme settings
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.all(8),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // First check if authenticated
          if (!authProvider.isAuthenticated) {
            return const LoginScreen();
          }

          // Then route based on user role
          switch (authProvider.user?.role) {
            case 'superadmin':
              return const SuperAdminDashboard();
            case 'admin':
              return const AdminDashboard();
            case 'student':
              return const StudentDashboard();
            default:
              // Handle unknown role or error case
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Invalid user role'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => authProvider.logout(),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}
