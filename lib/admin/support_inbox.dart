import 'package:artiva/admin/admin_chat_screen.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SupportInboxPage extends StatelessWidget {
  const SupportInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      showBack: true,
      title: "Support Inbox",
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_threads')
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8C1A)),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: Colors.black12),
                  SizedBox(height: 16),
                  Text(
                    "No support threads found.",
                    style: TextStyle(color: Colors.black45, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['userName'] ?? "Unknown User";
              final String lastMsg = data['lastMessage'] ?? "";
              final Timestamp? ts = data['lastTimestamp'] as Timestamp?;
              final String userId = data['userId'] ?? docs[index].id;
              final bool isAdminUnread = data['adminUnread'] ?? false;

              return _ThreadTile(
                name: name,
                lastMsg: lastMsg,
                timestamp: ts?.toDate(),
                isAdminUnread: isAdminUnread,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminChatScreen(userId: userId, userName: name),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final String name;
  final String lastMsg;
  final DateTime? timestamp;
  final VoidCallback onTap;
  final bool isAdminUnread;

  const _ThreadTile({
    required this.name,
    required this.lastMsg,
    this.timestamp,
    required this.onTap,
    this.isAdminUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAdminUnread
            ? Border.all(
                color: const Color(0xFFFF8C1A).withOpacity(0.5),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFF8C1A).withOpacity(0.1),
              child: const Icon(Icons.person, color: Color(0xFFFF8C1A)),
            ),
            if (isAdminUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isAdminUnread ? FontWeight.w900 : FontWeight.bold,
                  fontSize: 16,
                  color: isAdminUnread
                      ? const Color(0xFF2A2A2A)
                      : Colors.black87,
                ),
              ),
            ),
            if (timestamp != null)
              Text(
                DateFormat('MMM d, hh:mm a').format(timestamp!),
                style: TextStyle(
                  fontSize: 11,
                  color: isAdminUnread
                      ? const Color(0xFFFF8C1A)
                      : Colors.black38,
                  fontWeight: isAdminUnread
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            lastMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isAdminUnread ? Colors.black : Colors.black54,
              fontWeight: isAdminUnread ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black26,
        ),
      ),
    );
  }
}
