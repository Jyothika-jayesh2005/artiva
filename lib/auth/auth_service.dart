import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:artiva/backend/models.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final ValueNotifier<AppUser?> userNotifier = ValueNotifier<AppUser?>(null);

  AppUser? get currentUser => userNotifier.value;

  bool _isListening = false;

  /// Call this ONCE after Firebase.initializeApp() in main()
  void startAuthListener() {
    if (_isListening) return;
    _isListening = true;

    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        userNotifier.value = null;
        return;
      }
      userNotifier.value = await _getOrCreateUserDoc(user);
    });
  }

  Future<AppUser> _getOrCreateUserDoc(User user) async {
    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection('users').doc(user.uid);

    final DocumentSnapshot snap = await ref.get();

    // If user doc not exists -> create as normal user
    if (!snap.exists) {
      final newUser = AppUser(
        uid: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        phone: '',
        role: Role.user,
        photoUrl: "", // ✅ ADD
      );

      await ref.set({
        'name': newUser.name,
        'email': newUser.email,
        'phone': newUser.phone,
        'role': 'user',
        'photoUrl': newUser.photoUrl, // ✅ ADD
        'createdAt': FieldValue.serverTimestamp(),
      });

      return newUser;
    }

    final Map<String, dynamic> data =
        (snap.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final roleStr = (data['role'] ?? 'user').toString().toLowerCase();

    return AppUser(
      uid: user.uid,
      name: (data['name'] ?? user.displayName ?? 'User').toString(),
      email: (data['email'] ?? user.email ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      role: roleStr == 'admin' ? Role.admin : Role.user,
      photoUrl: (data['photoUrl'] ?? '').toString(), // ✅ ADD
    );
  }

  /// Forces Firestore role = admin for a specific admin email.
  Future<void> ensureAdminRole(String adminEmail) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in.");

    final email = (user.email ?? "").trim().toLowerCase();
    if (email != adminEmail.trim().toLowerCase()) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection('users').doc(user.uid);

    await ref.set({
      'email': user.email ?? adminEmail,
      'name': user.displayName ?? 'Admin',
      'role': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    userNotifier.value = await _getOrCreateUserDoc(user);
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) throw Exception('Registration failed. Try again.');

      await user.updateDisplayName(name);

      final DocumentReference<Map<String, dynamic>> ref =
          _db.collection('users').doc(user.uid);

      await ref.set({
        'name': name,
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'user',
        'photoUrl': '', // ✅ ADD
        'createdAt': FieldValue.serverTimestamp(),
      });

      final appUser = AppUser(
        uid: user.uid,
        name: name,
        email: email.trim(),
        phone: phone.trim(),
        role: Role.user,
        photoUrl: "", // ✅ ADD
      );

      userNotifier.value = appUser;
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<AppUser> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) throw Exception('Login failed. Try again.');

      final appUser = await _getOrCreateUserDoc(user);
      userNotifier.value = appUser;
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    userNotifier.value = null;
  }

  Future<AppUser> updateProfile({
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in.');

    await user.updateDisplayName(name);

    final DocumentReference<Map<String, dynamic>> ref =
        _db.collection('users').doc(user.uid);

    await ref.update({
      'name': name,
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updated = await _getOrCreateUserDoc(user);
    userNotifier.value = updated;
    return updated;
  }

  // ✅ ADD THIS METHOD (this fixes your ProfileSettingsPage errors)
  Future<AppUser> updateProfilePhoto({required String photoUrl}) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('Not logged in.');

    final ref = _db.collection('users').doc(fbUser.uid);

    await ref.update({
      'photoUrl': photoUrl.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updated = await _getOrCreateUserDoc(fbUser);
    userNotifier.value = updated;
    return updated;
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak (min 6 chars).';
      case 'network-request-failed':
        return 'Network error. Check your internet.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }
}

final AuthService authService = AuthService.instance;
