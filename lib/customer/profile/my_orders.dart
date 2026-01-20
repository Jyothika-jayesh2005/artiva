import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/home_screen.dart';
import 'package:artiva/data/order_data.dart';

class MyOrdersPage extends StatelessWidget {
  final bool fromPayment;

  const MyOrdersPage({super.key, this.fromPayment = false});

  void _goHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ArtHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = OrderData.orders.reversed.toList(); // latest first

    return WillPopScope(
      onWillPop: () async {
        if (fromPayment) {
          _goHome(context);
          return false;
        }
        return true;
      },
      child: CustomerScaffold(
        currentIndex: -1,
        title: "My Orders",
        body: orders.isEmpty
            ? const Center(child: Text("No orders yet"))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _orderCard(order);
                },
              ),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final DateTime dt = order["date"] is DateTime ? order["date"] : DateTime.now();

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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              (order["image"] ?? "assets/placeholder.png").toString(),
              width: 70,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 90,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (order["title"] ?? "Artwork").toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (order["price"] ?? "-").toString(),
                  style: const TextStyle(
                    color: Color(0xFFE16417),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Ordered on ${_formatDate(dt)}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)} ${_month(dt.month)} ${dt.year}";
  }

  String _month(int m) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return months[m - 1];
  }
}
