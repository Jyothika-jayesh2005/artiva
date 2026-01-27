import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/checkout/payment_success_page.dart';

import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/backend_service.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> artwork;
  final String address;
  final Map<String, dynamic>? addressSnapshot;
  final String? addressId;

  const PaymentPage({
    super.key,
    required this.artwork,
    required this.address,
    this.addressSnapshot,
    this.addressId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _loading = false;
  final BackendService backend = BackendService();

  @override
  Widget build(BuildContext context) {
    final title = (widget.artwork["title"] ?? "-").toString();
    final priceText = (widget.artwork["price"] ?? "-").toString();

    return CustomerScaffold(
      currentIndex: -1,
      title: "Payment",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Artwork"),
            _infoRow("Title", title),

            // ✅ Bigger orange price (requested)
            const SizedBox(height: 6),
            const Text("Price", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              priceText,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFFE16417), // ✅ orange
              ),
            ),

            const SizedBox(height: 18),

            // ✅ QR UI like ExhibitionPaymentPage (icon-style, not image)
            const Text(
              "Scan the QR code using any UPI app",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

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
                  color: Color(0xFFE16417), // ✅ orange
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Google Pay • PhonePe • Paytm • BHIM",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle("Deliver To"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(widget.address),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _success,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417), // ✅ orange
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

  // 🔥 THIS IS WHERE STOCK MUST REDUCE
  Future<void> _success() async {
    final user = authService.currentUser;
    if (user == null) {
      _snack("Please login first.");
      return;
    }

    final artworkId = (widget.artwork["id"] ?? "").toString().trim();
    if (artworkId.isEmpty) {
      _snack("Artwork ID missing.");
      return;
    }

    final title = (widget.artwork["title"] ?? "Artwork").toString();
    final priceStr = (widget.artwork["price"] ?? "0").toString();
    final imageUrl =
        (widget.artwork["imageUrl"] ?? widget.artwork["image"] ?? "").toString();

    final int price =
        int.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    if (price <= 0) {
      _snack("Invalid artwork price.");
      return;
    }

    setState(() => _loading = true);

    try {
      // 1️⃣ Create order
      final String orderId = await backend.createOrder(
        userId: user.uid,
        artworkId: artworkId,
        artTitle: title,
        price: price,
        quantity: 1,
        address: widget.address,
        addressId: widget.addressId,
        addressSnapshot: widget.addressSnapshot,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        customerName: user.name,
        customerEmail: user.email,
      );

      // 2️⃣ 🔥 REDUCE STOCK
      await backend.reduceStockAfterOrder(
        artworkId: artworkId,
        qty: 1,
      );

      if (!mounted) return;

      // 3️⃣ Go to success page
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
