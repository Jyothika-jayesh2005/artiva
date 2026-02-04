import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminChatScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    await FirebaseFirestore.instance
        .collection('support_threads')
        .doc(widget.userId)
        .update({'adminUnread': false});
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    final threadRef = FirebaseFirestore.instance
        .collection('support_threads')
        .doc(widget.userId);

    final batch = FirebaseFirestore.instance.batch();

    // Update thread info (last admin reply)
    batch.update(threadRef, {
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'userUnread': true,
    });

    // Add message
    final msgRef = threadRef.collection('messages').doc();
    batch.set(msgRef, {
      'text': text,
      'senderId': 'admin',
      'isAdmin': true,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      showBack: true,
      title: "Chat with ${widget.userName}",
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_threads')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF8C1A)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isAdmin = data['isAdmin'] ?? false;
                    final String text = data['text'] ?? "";
                    final Timestamp? ts = data['timestamp'] as Timestamp?;

                    return _AdminChatBubble(
                      text: text,
                      isAdmin: isAdmin,
                      timestamp: ts?.toDate(),
                    );
                  },
                );
              },
            ),
          ),
          _AdminMessageInput(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}

class _AdminChatBubble extends StatelessWidget {
  final String text;
  final bool isAdmin;
  final DateTime? timestamp;

  const _AdminChatBubble({
    required this.text,
    required this.isAdmin,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = isAdmin; // Admin is "Me" here
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? const Color(0xFFFF8C1A) : const Color(0xFFF0F0F0);
    final textColor = isMe ? Colors.white : Colors.black87;
    final radius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: color, borderRadius: radius),
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 14.5, height: 1.4),
            ),
          ),
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                DateFormat('hh:mm a').format(timestamp!),
                style: const TextStyle(fontSize: 10, color: Colors.black38),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminMessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _AdminMessageInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "Reply to user...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14, color: Colors.black45),
                  ),
                  maxLines: null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onSend,
              icon: const CircleAvatar(
                backgroundColor: Color(0xFFFF8C1A),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
