import 'package:flutter/material.dart';

import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/home_screen.dart';

import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/backend_provider.dart';
import 'package:artiva/backend/models.dart';

class MyOrdersPage extends StatefulWidget {
  final bool fromPayment;

  const MyOrdersPage({super.key, this.fromPayment = false});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  bool _busy = false;

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

            final orders = (snap.data ?? []).reversed.toList(); // latest first

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
    final canRate = order.status == OrderStatus.delivered && order.rating == null;

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
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 70,
                  height: 90,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.black38),
                ),
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
                      order.price,
                      style: const TextStyle(
                        color: Color(0xFFE16417),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Ordered on ${_formatDate(order.orderedAt)}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _statusChip(order.status),
                  ],
                ),
              ),
            ],
          ),

          // ⭐ Rating display (if already rated)
          if (order.rating != null || (order.review ?? "").trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            if ((order.review ?? "").trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "\"${order.review!.trim()}\"",
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ],

          // ✅ Rate button (only after delivered, only once)
          if (canRate) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _busy ? null : () async => await _openRatingDialog(order),
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

  Future<void> _openRatingDialog(ArtworkOrder order) async {
    int selected = 5;
    final reviewCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text("Rate your order"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      final filled = star <= selected;

                      return InkResponse(
                        onTap: () => setLocal(() => selected = star),
                        radius: 22,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 28,
                            color: filled ? Colors.orange : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$selected/5",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reviewCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Write a review (optional)",
                    ),
                  ),
                ],
              ),
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
          );
        },
      ),
    );

    if (result != true) {
      reviewCtrl.dispose();
      return;
    }

    setState(() => _busy = true);

    try {
      await backend.submitOrderRating(
        orderId: order.id,
        rating: selected,
        review: reviewCtrl.text.trim().isEmpty ? null : reviewCtrl.text.trim(),
      );

      if (!mounted) return;
      _snack("Thanks! Rating submitted.");
      setState(() {}); // refresh orders
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      reviewCtrl.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _starsRow(int rating) {
    rating = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 18,
          color: filled ? Colors.orange : Colors.grey,
        );
      }),
    );
  }

  Widget _statusChip(OrderStatus status) {
    final label = status.name; // processing/shipped/delivered
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withOpacity(0.05),
      ),
      child: Text(
        "Status: $label",
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)} ${_month(dt.month)} ${dt.year}";
  }

  String _month(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[m - 1];
  }
}
