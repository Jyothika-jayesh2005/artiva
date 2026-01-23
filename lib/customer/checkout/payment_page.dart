import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/checkout/payment_success_page.dart';

import 'package:artiva/data/artwork_data.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/backend_provider.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, String> artwork;
  final String address;

  const PaymentPage({super.key, required this.artwork, required this.address});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _loading = false;

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
            _infoRow("Title", widget.artwork["title"] ?? "-"),
            _infoRow("Price", widget.artwork["price"] ?? "-"),
            const SizedBox(height: 20),

            _sectionTitle("Deliver To"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(widget.address, style: const TextStyle(fontSize: 14)),
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
                onPressed: _loading ? null : _success,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _loading ? "PLEASE WAIT..." : "Confirm Payment",
                  style: const TextStyle(
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _success() async {
    final user = authService.currentUser;
    if (user == null) {
      _snack("Please login first.");
      return;
    }

    final artworkId = (widget.artwork["id"] ?? "").trim();
    if (artworkId.isEmpty) {
      _snack("Artwork ID missing. Add an 'id' field to each artwork.");
      return;
    }

    final title = widget.artwork["title"] ?? "Artwork";
    final price = widget.artwork["price"] ?? "-";
    final imagePath = widget.artwork["image"];

    setState(() => _loading = true);

    try {
      // local stock update (dummy)
      ArtworkData.reduceStock(artworkId);

      // create order
      final String orderId = await backend.createOrder(
        artworkId: artworkId,
        artTitle: title,
        price: price,
        quantity: 1,
        address: widget.address,
        imagePath: imagePath,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(orderId: orderId),
        ),
      );
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
