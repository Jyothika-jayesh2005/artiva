import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/notification_service.dart';

class AdminNotifyWinner extends StatefulWidget {
  final Auction auction;
  final AppUser winner;
  const AdminNotifyWinner({
    super.key,
    required this.auction,
    required this.winner,
  });

  @override
  State<AdminNotifyWinner> createState() => _AdminNotifyWinnerState();
}

class _AdminNotifyWinnerState extends State<AdminNotifyWinner> {
  final NotificationService _notifService = NotificationService();
  final List<String> _templates = [
    "Please complete payment for your rare piece.",
    "Reminder: Payment pending for auction.",
    "Congratulations! Please finalize your purchase of 'ART_TITLE'.",
  ];

  String _message = "";
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _message = _templates[0].replaceAll("ART_TITLE", widget.auction.artTitle);
  }

  Future<void> _send() async {
    setState(() => _isSending = true);
    try {
      await _notifService.sendToUser(
        uid: widget.winner.uid,
        title: "Payment Reminder",
        body: _message,
        type: NotificationType.reminder,
        auctionId: widget.auction.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notification sent successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Notify Winner",
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sending to: ${widget.winner.name}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Auction: ${widget.auction.artTitle}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text(
              "Select Template:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._templates.map((t) {
              final text = t.replaceAll("ART_TITLE", widget.auction.artTitle);
              return RadioListTile<String>(
                title: Text(text),
                value: text,
                groupValue: _message,
                onChanged: (val) => setState(() => _message = val!),
              );
            }),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C1A),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SEND NOTIFICATION",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
