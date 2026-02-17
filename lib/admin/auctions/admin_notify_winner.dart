import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/notification_service.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    "Final Warning: Payment due within 2 hours or bid will be cancelled.",
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

      // Check if this is a "Final Warning"
      if (_message.startsWith("Final Warning")) {
        // Automatically shorten deadline to 2 hours from now
        await AuctionService().updatePaymentDeadline(
          widget.auction.id,
          DateTime.now().add(const Duration(hours: 2)),
          markReminderSent: true,
        );
      }
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
      showBack: true, // ✅ Show back arrow
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("auctions")
            .doc(widget.auction.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final Auction liveAuction = Auction.fromMap(
            snapshot.data!.id,
            snapshot.data!.data() as Map<String, dynamic>,
          );

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sending to: ${widget.winner.name}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Email: ${widget.winner.email}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    "Phone: ${widget.winner.phone.isEmpty ? "Not Provided" : widget.winner.phone}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Auction: ${liveAuction.artTitle}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Deadline Status",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (liveAuction.paymentDueAt != null)
                          Text(
                            "Payment Due: ${liveAuction.paymentDueAt.toString().split('.')[0]}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          )
                        else
                          const Text("No specific deadline set (Standard 24h)"),
                        if (liveAuction.reminderSent)
                          const Text(
                            "✅ Final Reminder Sent",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Select Template:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._templates.map((t) {
                    final isFinalWarning = t.startsWith("Final Warning");
                    final alreadySent =
                        isFinalWarning && liveAuction.reminderSent;
                    final text =
                        t.replaceAll("ART_TITLE", liveAuction.artTitle) +
                        (alreadySent ? " (Already Sent)" : "");

                    return RadioListTile<String>(
                      activeColor: const Color(
                        0xFFFF8C1A,
                      ), // ✅ Changed to orange
                      title: Text(
                        text,
                        style: TextStyle(
                          color: alreadySent ? Colors.grey : null,
                        ),
                      ),
                      value: text,
                      groupValue: _message,
                      onChanged: alreadySent
                          ? null
                          : (val) => setState(() => _message = val!),
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
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    "Manual Override Actions",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Use these only if the winner is unresponsive or refuses to pay.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Bid>>(
                    stream: AuctionService().getBids(liveAuction.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final bids = snapshot.data!;
                      bids.sort((a, b) => b.amount.compareTo(a.amount));

                      final currentWinnerId = liveAuction.highestBidderId;
                      final otherBids = bids
                          .where((b) => b.userId != currentWinnerId)
                          .toList();
                      final nextBidder = otherBids.isNotEmpty
                          ? otherBids.first
                          : null;

                      return Column(
                        children: [
                          if (nextBidder != null) ...[
                            OutlinedButton.icon(
                              onPressed: _isSending
                                  ? null
                                  : () => _reaward(nextBidder),
                              icon: const Icon(Icons.person_add),
                              label: Text(
                                "Assign to Next Bidder (${nextBidder.userName} - ₹${nextBidder.amount})",
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton.icon(
                            onPressed: _isSending ? null : _cancelWin,
                            icon: const Icon(Icons.cancel),
                            label: const Text("Cancel Win & Mark Unsold"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancelWin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Cancellation"),
        content: const Text(
          "Are you sure you want to cancel this win? The auction will be marked as 'Unsold' and the current winner removed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);
    try {
      await AuctionService().cancelWin(widget.auction.id);
      if (mounted) {
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Win cancelled. Auction marked Unsold."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _reaward(Bid nextBidder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Re-award"),
        content: Text(
          "Assign win to ${nextBidder.userName} for ₹${nextBidder.amount}?\n\nThis will remove the current winner.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSending = true);
    try {
      await AuctionService().reawardAuction(
        widget.auction.id,
        nextBidder.userId,
        nextBidder.userName,
        nextBidder.amount,
      );
      if (mounted) {
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Auction re-awarded to ${nextBidder.userName}."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
