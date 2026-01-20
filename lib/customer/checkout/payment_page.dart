import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/profile/my_orders.dart';
import 'package:artiva/data/artwork_data.dart';
import 'package:artiva/data/order_data.dart';

class PaymentPage extends StatelessWidget {
  final Map<String, String> artwork;
  final String address;

  const PaymentPage({super.key, required this.artwork, required this.address});

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Payment",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Artwork"),
            _infoRow("Title", artwork["title"] ?? "-"),
            _infoRow("Price", artwork["price"] ?? "-"),
            const SizedBox(height: 20),

            _sectionTitle("Deliver To"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(address, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 24),

            const Text(
              "Scan the QR code using any UPI app",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 140,
                  color: Color(0xFFE16417),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Center(
              child: Text(
                "Google Pay • PhonePe • Paytm • BHIM",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),

            const Center(
              child: Text(
                "Complete the payment and tap Confirm",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _success(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Confirm Payment",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _success(BuildContext context) {
    // ✅ 1. REDUCE STOCK
    final index = ArtworkData.artworks.indexWhere(
      (a) => a["title"] == artwork["title"],
    );

    if (index != -1) {
      final currentSold =
          int.tryParse(ArtworkData.artworks[index]["soldQuantity"] ?? "0") ?? 0;

      ArtworkData.artworks[index]["soldQuantity"] = (currentSold + 1)
          .toString();
    }

    // ✅ 2. SAVE ORDER (THIS IS WHAT YOU ASKED)
    OrderData.orders.add({
      "artTitle": artwork["title"] ?? "Artwork",
      "price": artwork["price"] ?? "-",
      "image": artwork["image"] ?? "",
      "quantity": 1,
      "customerName": "Demo User",
      "orderedAt": DateTime.now(),
    });

    // ✅ 3. SHOW SUCCESS DIALOG
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Payment Successful"),
        content: const Text("Your order has been placed."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              // ✅ 4. GO TO MY ORDERS SAFELY
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyOrdersPage(fromPayment: true),
                ),
                (route) => false,
              );
            },
            child: const Text(
              "View Orders",
              style: TextStyle(color: Color(0xFFE16417)),
            ),
          ),
        ],
      ),
    );
  }
}
