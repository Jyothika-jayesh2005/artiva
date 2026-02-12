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
  final int quantity; // ✅ NEW

  const PaymentPage({
    super.key,
    required this.artwork,
    required this.address,
    this.addressSnapshot,
    this.addressId,
    this.quantity = 1, // ✅ Default 1
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
    final priceStr = (widget.artwork["price"] ?? "0").toString();

    // Parse price for calculation
    int priceVal = 0;
    try {
      priceVal = int.parse(priceStr.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (_) {}

    final int quantity = widget.quantity;
    final int totalVal = priceVal * quantity;

    // specific formatter for indian currency if needed
    // reuse logic or just standard format
    String _formatCurrency(int amount) {
      final s = amount.toString();
      if (s.length <= 3) return "₹$s";
      final last3 = s.substring(s.length - 3);
      final rest = s.substring(0, s.length - 3);
      final reg = RegExp(r'(\d)(?=(\d{2})+(?!\d))');
      return "₹${rest.replaceAllMapped(reg, (m) => '${m[1]},')},$last3";
    }

    final String displayPrice = _formatCurrency(totalVal);
    final String unitPrice = _formatCurrency(priceVal);

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
            if (quantity > 1) _infoRow("Quantity", "$quantity"),

            // ✅ Bigger orange price (requested)
            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  quantity > 1 ? "Total Price" : "Price",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        fontSize: 20, // ✅ smaller
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE16417), // ✅ orange
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (quantity > 1)
                      Text(
                        "($unitPrice x $quantity)",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
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

    final priceStr = (widget.artwork["price"] ?? "0").toString();

    final int price =
        int.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    if (price <= 0) {
      _snack("Invalid artwork price.");
      return;
    }

    setState(() => _loading = true);

    try {
      // 1️⃣ Atomic Order Transaction (Secure)
      final String orderId = await backend.placeOrderTransaction(
        userId: user.uid,
        artworkId: artworkId,
        quantity: widget.quantity, // ✅ Pass correct quantity
        address: widget.address,
        addressId: widget.addressId,
        addressSnapshot: widget.addressSnapshot,
        customerName: user.name,
        customerEmail: user.email,
        // Optional sizes not used in this flow yet
        sizeCm: null,
        sizeIn: null,
      );

      if (!mounted) return;

      // 3️⃣ Go to success page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PaymentSuccessPage(orderId: orderId)),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
