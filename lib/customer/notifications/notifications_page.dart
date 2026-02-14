import 'package:flutter/material.dart';
import 'package:artiva/backend/notification_service.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:artiva/customer/auctions/auction_payment.dart';
import 'package:artiva/backend/auction_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(child: Text("Please login to view notifications")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService().getUserNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationCard(notification: n, uid: uid);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String uid;
  const _NotificationCard({required this.notification, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: notification.read ? Colors.white : Colors.orange.shade50,
      child: ListTile(
        onTap: () async {
          await NotificationService().markAsRead(uid, notification.id);
          if (notification.auctionId != null) {
            final auction = await AuctionService().getAuction(
              notification.auctionId!,
            );
            if (auction != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AuctionPaymentPage(auction: auction),
                ),
              );
            }
          }
        },
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, h:mm a').format(notification.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        trailing: !notification.read
            ? const Icon(Icons.circle, size: 10, color: Colors.orange)
            : null,
      ),
    );
  }
}
