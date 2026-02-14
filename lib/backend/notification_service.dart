import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/services/local_notification_service.dart';
import 'package:artiva/main.dart'; // for scaffoldMessengerKey and navigatorKey
import 'package:artiva/customer/auctions/my_wins.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();
  factory NotificationService() => instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _userSubscription;
  StreamSubscription? _globalSubscription;

  // Stream of user-specific notifications
  Stream<List<AppNotification>> getUserNotifications(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Stream of global notifications
  Stream<List<AppNotification>> getGlobalNotifications() {
    return _db
        .collection("notifications")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Send a notification to a specific user
  Future<void> sendToUser({
    required String uid,
    required String title,
    required String body,
    required NotificationType type,
    String? auctionId,
  }) async {
    await _db.collection("users").doc(uid).collection("notifications").add({
      "title": title,
      "body": body,
      "type": type.name,
      "auctionId": auctionId,
      "read": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // Send a global notification
  Future<void> sendGlobal({
    required String title,
    required String body,
    required NotificationType type,
    String? auctionId,
  }) async {
    await _db.collection("notifications").add({
      "title": title,
      "body": body,
      "type": type.name,
      "auctionId": auctionId,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String uid, String notifId) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .doc(notifId)
        .update({"read": true});
  }

  // Listen to the global notification stream and show local alerts
  void startGlobalListener() {
    _globalSubscription?.cancel();
    bool isFirstLoad = true;
    _globalSubscription = _db
        .collection("notifications")
        .orderBy("createdAt", descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
          if (isFirstLoad) {
            isFirstLoad = false;
            return;
          }
          for (var change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                final title = data["title"] ?? "New Update";
                final body = data["body"] ?? "";
                final auctionId = data["auctionId"]?.toString();
                final type = data["type"]?.toString() ?? "new_auction";

                LocalNotificationService.showNotification(
                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  title: title,
                  body: body,
                  payload: "$type|$auctionId",
                );
              }
            }
          }
        });
  }

  // ✅ NEW: Listen to user-specific notifications and show local alerts
  void startUserListener(String uid) {
    _userSubscription?.cancel();
    bool isFirstLoad = true;
    _userSubscription = _db
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("createdAt", descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
          final now = DateTime.now();
          for (var change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                final title = data["title"] ?? "Message for you";
                final body = data["body"] ?? "";
                final auctionId = data["auctionId"]?.toString();
                final type = data["type"]?.toString() ?? "reminder";
                final isRead = data["read"] == true;
                final createdAt = (data["createdAt"] as Timestamp?)?.toDate();

                // On first load, only alert for recent unread messages (< 15 mins)
                // On subsequent updates, always alert (isFirstLoad is false)
                bool shouldAlert = !isRead;
                if (isFirstLoad && createdAt != null) {
                  shouldAlert = now.difference(createdAt).inMinutes < 15;
                }

                if (shouldAlert && !isRead) {
                  LocalNotificationService.showNotification(
                    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                    title: title,
                    body: body,
                    payload: "$type|$auctionId|${change.doc.id}|$uid",
                  );

                  // Show foreground SnackBar for wins/reminders
                  if (type == "win" || type == "reminder") {
                    _showForegroundAlert(
                      title,
                      body,
                      auctionId,
                      change.doc.id,
                      uid,
                    );
                  }
                }
              }
            }
          }
          isFirstLoad = false;
        });
  }

  void _showForegroundAlert(
    String title,
    String body,
    String? auctionId,
    String notifId,
    String uid,
  ) {
    if (scaffoldMessengerKey.currentState != null) {
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(body),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: "PAY NOW",
            textColor: Colors.white,
            onPressed: () async {
              try {
                await markAsRead(uid, notifId);
              } catch (e) {
                debugPrint("Error marking as read: $e");
              }

              if (navigatorKey.currentState != null) {
                navigatorKey.currentState!.push(
                  MaterialPageRoute(builder: (_) => const MyWinsScreen()),
                );
              } else {
                debugPrint("Navigator key is null!");
              }
            },
          ),
          backgroundColor: const Color(0xFFFF8C1A),
        ),
      );
    }
  }

  void stopListeners() {
    _userSubscription?.cancel();
    _globalSubscription?.cancel();
  }
}
