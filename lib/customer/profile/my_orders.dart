import 'package:flutter/material.dart';

import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/home_screen.dart';

import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/backend_service.dart'; // ✅ FIXED
import 'package:artiva/backend/models.dart';

class MyOrdersPage extends StatefulWidget {
  final bool fromPayment;

  const MyOrdersPage({super.key, this.fromPayment = false});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  bool _busy = false;

  // ✅ DEFINE BACKEND
  final BackendService backend = BackendService();

  void _goHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ArtHomePage()),
      (route) => false,
    );
  }

  Future<List<ArtworkOrder>> _loadMyOrders() async {
    final user = authService.currentUser;
    if (user == null) throw Exception("Please login first.");
    return await backend.getMyOrders(user.email);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.fromPayment) {
          _goHome(context);
          return false;
        }
        return true;
      },
      child: CustomerScaffold(
        currentIndex: -1,
        title: "My Orders",
        body: FutureBuilder<List<ArtworkOrder>>(
          future: _loadMyOrders(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Text(
                  snap.error.toString().replaceFirst('Exception: ', ''),
                ),
              );
            }

            final orders = (snap.data ?? []).reversed.toList();

            if (orders.isEmpty) {
              return const Center(child: Text("No orders yet"));
            }

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _orderCard(order);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _orderCard(ArtworkOrder order) {
    final canRate =
        order.status == OrderStatus.delivered && order.rating == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.image, color: Colors.black38),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.artTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "₹${order.price}",
                      style: const TextStyle(
                        color: Color(0xFFE16417),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Ordered on ${_formatDate(order.orderedAt)}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _statusChip(order.status),
                  ],
                ),
              ),
            ],
          ),

          if (order.rating != null ||
              (order.review ?? "").trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                _starsRow(order.rating ?? 0),
                const SizedBox(width: 8),
                Text(
                  order.rating == null ? "" : "${order.rating}/5",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (order.ratedAt != null)
                  Text(
                    _formatDate(order.ratedAt!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            if ((order.review ?? "").trim().isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "\"${order.review!.trim()}\"",
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],

          if (canRate) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed:
                    _busy ? null : () async => _openRatingDialog(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _busy ? "PLEASE WAIT..." : "Rate This Order",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- RATING ----------------

  Future<void> _openRatingDialog(ArtworkOrder order) async {
    int selected = 5;
    final reviewCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rate your order"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 4,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => selected = star,
                  icon: Icon(
                    star <= selected ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                  ),
                );
              }),
            ),
            TextField(
              controller: reviewCtrl,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: "Write a review (optional)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);

    try {
      await backend.submitOrderRating(
        orderId: order.id,
        rating: selected,
        review: reviewCtrl.text.trim().isEmpty
            ? null
            : reviewCtrl.text.trim(),
      );
      if (mounted) setState(() {});
      _snack("Thanks! Rating submitted.");
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      reviewCtrl.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------- HELPERS ----------------

  Widget _starsRow(int rating) {
    rating = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 18,
          color: Colors.orange,
        );
      }),
    );
  }

  Widget _statusChip(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.05),
      ),
      child: Text(
        "Status: ${status.name}",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDate(DateTime dt) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }
}
