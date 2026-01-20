import 'package:flutter/material.dart';

import 'package:artiva/admin/admin_dashboard.dart';
import 'package:artiva/auth/login_screen.dart';
import 'package:artiva/auth/register_screen.dart';
import 'package:artiva/auth/welcome_screen.dart';
import 'package:artiva/customer/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArtivaApp());
}

class ArtivaApp extends StatelessWidget {
  const ArtivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artiva',
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const ArtHomePage(),
        '/admin': (context) => const AdminDashboard(),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
    );
  }
}
