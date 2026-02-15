import 'package:flutter/material.dart';

import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/home_screen.dart';
import 'package:artiva/customer/profile/order_detail_page.dart';

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
    // 🔥 FILTER: Regular orders only (no auction ID check necessary if model doesn't support it yet, but user code had it. Checking model... ArtworkOrder doesn't have auctionId. Removing check.)
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
    final status = order.effectiveStatus;
    final locked = order.ratingLocked == true;
    final canRate = status == OrderStatus.delivered && !locked;
    final hasReview =
        order.rating != null || (order.review ?? "").trim().isNotEmpty;

    // Calculate display date (Estimated or Delivered)
    final isDelivered = status == OrderStatus.delivered;
    final displayDate = isDelivered
        ? order.estimatedDeliveryDate
        : order.estimatedDeliveryDate;
    final dateLabel = isDelivered ? "Delivered" : "Est. Delivery";
    final statusColor = isDelivered ? Colors.green : const Color(0xFF2196F3);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: ID and Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order #${order.id.substring(0, 6).toUpperCase()}",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDelivered
                                ? Icons.check_circle
                                : Icons.local_shipping_outlined,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDelivered ? "Delivered" : "In Transit",
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _orderImage(order.imageUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.artTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${order.price}",
                            style: const TextStyle(
                              color: Color(0xFFE16417),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$dateLabel: ${_formatDate(displayDate)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (hasReview || canRate) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                ],

                if (hasReview) ...[
                  Row(
                    children: [
                      _starsRow(order.rating ?? 0),
                      const SizedBox(width: 8),
                      Text(
                        "${order.rating}.0",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const Spacer(),
                      if (order.ratedAt != null)
                        Text(
                          "Rated on ${_formatDate(order.ratedAt!)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                  if ((order.review ?? "").trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "\"${order.review!.trim()}\"",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],

                if (canRate)
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE16417), Color(0xFF80431F)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE16417).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _busy ? null : () => _openRatingDialog(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        _busy ? "Please wait..." : "Rate Order",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderImage(String? url) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        image: (url != null && url.isNotEmpty)
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: (url == null || url.isEmpty)
          ? Icon(Icons.image_outlined, color: Colors.grey[400])
          : null,
    );
  }

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
                      star <= selected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFFFC107),
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Write a review (optional)",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Submit",
                style: TextStyle(
                  color: Color(0xFFE16417),
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 20,
          color: const Color(0xFFFFC107),
        ),
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
