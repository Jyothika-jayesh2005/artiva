import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:artiva/auth/auth_service.dart';

import 'package:artiva/auth/welcome_screen.dart';
import 'package:artiva/auth/login_screen.dart';
import 'package:artiva/auth/register_screen.dart';
import 'package:artiva/admin/admin_dashboard.dart';
import 'package:artiva/customer/home_screen.dart';

import 'package:artiva/auth/splash_screen.dart';

import 'package:artiva/customer/notifications/notifications_page.dart';
import 'package:artiva/backend/notification_service.dart';
import 'package:artiva/services/local_notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.init();
  NotificationService().startGlobalListener();

  authService.startAuthListener();

  // ✅ NEW: Handle user-specific notification listener
  authService.userNotifier.addListener(() {
    final user = authService.currentUser;
    if (user != null) {
      NotificationService().startUserListener(user.uid);
    } else {
      NotificationService().stopListeners();
      NotificationService().startGlobalListener();
    }
  });

  runApp(const ArtivaApp());
}

class ArtivaApp extends StatelessWidget {
  const ArtivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),

        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const ArtHomePage(),
        '/admin': (_) => const AdminDashboard(),
        '/notifications': (_) => const NotificationsPage(),
      },
    );
  }
}
