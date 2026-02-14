import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:artiva/main.dart'; // for navigatorKey
import 'package:artiva/customer/auctions/my_wins.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          final parts = payload.split(
            '|',
          ); // format: type|auctionId|notifId|uid
          if (parts.length >= 2) {
            final type = parts[0];
            // auctionId is at parts[1] but not used for redirection to MyWins

            // Mark as read if notifId and uid are present
            if (parts.length >= 4) {
              final notifId = parts[2];
              final uid = parts[3];
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('notifications')
                  .doc(notifId)
                  .update({'read': true});
            }

            if (type == "reminder" || type == "win") {
              navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => const MyWinsScreen()),
              );
            }
          }
        }
      },
    );

    // ✅ NEW: Request permissions for Android 13+
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'auction_channel',
          'Auctions',
          channelDescription: 'Notifications for new and live auctions',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
