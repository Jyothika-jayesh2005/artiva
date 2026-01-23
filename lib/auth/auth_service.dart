import 'package:artiva/backend/backend_provider.dart';
import 'package:artiva/backend/models.dart';

class AuthService {
  AppUser? get currentUser => backend.currentUser;

  Future<AppUser> login(String email, String password) async {
    return await backend.login(
      email: email,
      password: password,
    );
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return await backend.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<void> logout() async {
    await backend.logout();
  }
}

final AuthService authService = AuthService();
