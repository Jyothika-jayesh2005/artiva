import 'package:flutter/material.dart';

import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/home_screen.dart';
import 'package:artiva/customer/artwork_detail.dart';

import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/backend_service.dart';
import 'package:artiva/backend/models.dart';

class MyOrdersPage extends StatefulWidget {
  final bool fromPayment;

  const MyOrdersPage({super.key, this.fromPayment = false});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  bool _busy = false;
  final BackendService backend = BackendService();

  List<ArtworkOrder>? _orders; // 🔥 LOCAL STATE
  late Future<List<ArtworkOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadMyOrders();
  }

  void _goHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ArtHomePage()),
      (_) => false,
    );
  }

  Future<List<ArtworkOrder>> _loadMyOrders() async {
    final user = authService.currentUser;
    if (user == null) throw Exception("Please login first.");

    if (_orders != null) return _orders!; // 🔥 NO REFETCH

    final uid = user.uid;
    final list = await backend.getMyOrdersByUid(uid);
    _orders = list;
    return _orders!;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_busy) return false; // 🔥 ADD THIS LINE

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
          future: _ordersFuture,
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

            final orders = _orders ?? [];

            if (orders.isEmpty) {
              return const Center(child: Text("No orders yet"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (_, i) => _orderCard(orders[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _orderCard(ArtworkOrder order) {
    final locked = order.ratingLocked == true;
    final canRate = order.status == OrderStatus.delivered && !locked;
    final hasReview =
        order.rating != null || (order.review ?? "").trim().isNotEmpty;

    return InkWell(
      onTap: () async {
        final artId = order.artId;
        if (artId == null || artId.isEmpty) return;

        setState(() => _busy = true);
        try {
          final art = await backend.getArtworkById(artId);
          if (art != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtworkDetailsPage(artwork: art),
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Artwork no longer available")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${e.toString()}")),
            );
          }
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      },
      child: Container(
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
                _orderImage(order.imageUrl),
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
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _statusChip(order.status),
                    ],
                  ),
                ),
              ],
            ),

            if (hasReview) ...[
              const SizedBox(height: 12),
              const Divider(),
              Row(
                children: [
                  _starsRow(order.rating ?? 0),
                  const SizedBox(width: 8),
                  Text(
                    "${order.rating}/5",
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
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "\"${order.review!.trim()}\"",
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],

            if (canRate) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _openRatingDialog(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE16417),
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _busy ? "PLEASE WAIT..." : "Rate This Order",
                    style: TextStyle(
                      color: _busy ? Colors.black54 : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _orderImage(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 70,
        height: 90,
        color: Colors.grey.shade200,
        child: (url ?? "").isEmpty
            ? const Icon(Icons.image, color: Colors.black38)
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }

  // ⭐ DO NOT TOUCH UI — ONLY LOGIC FIX
  Future<void> _openRatingDialog(ArtworkOrder order) async {
    int selected = 5;
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Rate your order"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return InkWell(
                    onTap: () => setLocal(() => selected = star),
                    child: Icon(
                      star <= selected ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 28,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Write a review (optional)",
                ),
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
      ),
    );

    if (ok != true) return;

    setState(() => _busy = true);

    try {
      await backend.submitOrderRating(
        orderId: order.id,
        rating: selected,
        review: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
      );

      final index = _orders!.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _orders![index] = order.copyWith(
          rating: selected,
          review: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
          ratedAt: DateTime.now(),
          ratingLocked: true,
        );
      }
      if (mounted) setState(() {});


    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Widget _starsRow(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 18,
          color: Colors.orange,
        ),
      ),
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

  String _formatDate(DateTime dt) {
    const m = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${dt.day} ${m[dt.month - 1]} ${dt.year}";
  }
}
