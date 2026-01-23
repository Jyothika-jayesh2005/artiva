import 'package:flutter/foundation.dart';
import 'package:artiva/backend/backend_provider.dart';
import 'package:artiva/backend/models.dart';

class AuthService {
  final ValueNotifier<AppUser?> userNotifier = ValueNotifier<AppUser?>(null);

  AppUser? get currentUser => userNotifier.value;

  Future<AppUser> login(String email, String password) async {
    final u = await backend.login(email: email, password: password);
    userNotifier.value = u;
    return u;
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final u = await backend.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    userNotifier.value = u;
    return u;
  }

  Future<void> logout() async {
    await backend.logout();
    userNotifier.value = null;
  }

  Future<AppUser> updateProfile({
    required String name,
    required String phone,
  }) async {
    final u = await backend.updateProfile(name: name, phone: phone);
    userNotifier.value = u;
    return u;
  }
}

final AuthService authService = AuthService();
