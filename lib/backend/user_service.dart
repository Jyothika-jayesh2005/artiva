import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/backend/models.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch a user profile by UID
  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  // Stream a user profile by UID
  Stream<AppUser?> watchUserProfile(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromMap(doc.id, doc.data()!) : null);
  }
}
