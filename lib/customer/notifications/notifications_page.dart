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
        builder: (context, userSnap) {
          return StreamBuilder<List<AppNotification>>(
            stream: NotificationService().getGlobalNotifications(),
            builder: (context, globalSnap) {
              if (userSnap.connectionState == ConnectionState.waiting &&
                  globalSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userNotifs = userSnap.data ?? [];
              final globalNotifs = globalSnap.data ?? [];

              // Merge and sort by date descending
              final allNotifications = [...userNotifs, ...globalNotifs]
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (allNotifications.isEmpty) {
                return const Center(
                  child: Text(
                    "No notifications yet",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: allNotifications.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final n = allNotifications[index];
                  return _NotificationCard(notification: n, uid: uid);
                },
              );
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
    // Icon based on content
    IconData icon = Icons.notifications_none_rounded;
    Color iconColor = Colors.grey;
    Color bgColor = Colors.grey.shade50;

    if (notification.title.toLowerCase().contains("outbid")) {
      icon = Icons.gavel_rounded;
      iconColor = Colors.red;
      bgColor = Colors.red.shade50;
    } else if (notification.title.toLowerCase().contains("won")) {
      icon = Icons.emoji_events_rounded;
      iconColor = const Color(0xFFFF8C1A);
      bgColor = Colors.orange.shade50;
    } else if (notification.title.toLowerCase().contains("live")) {
      icon = Icons.sensors_rounded;
      iconColor = Colors.redAccent;
      bgColor = Colors.redAccent.shade100.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.read ? Colors.white : const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.read
              ? Colors.grey.shade200
              : const Color(0xFFFF8C1A).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: notification.read
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                fontSize: 15,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          if (!notification.read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF8C1A),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat(
                          'MMM d, h:mm a',
                        ).format(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
