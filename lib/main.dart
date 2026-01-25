import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:artiva/auth/auth_service.dart';

import 'package:artiva/auth/welcome_screen.dart';
import 'package:artiva/auth/login_screen.dart';
import 'package:artiva/auth/register_screen.dart';
import 'package:artiva/admin/admin_dashboard.dart';
import 'package:artiva/customer/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Force WelcomeScreen every time app starts
  await authService.logout();

  // ✅ Start listener AFTER logout
  authService.startAuthListener();

  runApp(const ArtivaApp());
}

class ArtivaApp extends StatelessWidget {
  const ArtivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ Always start here
      home: const WelcomeScreen(),

      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const ArtHomePage(),
        '/admin': (_) => const AdminDashboard(),
      },
    );
  }
}
