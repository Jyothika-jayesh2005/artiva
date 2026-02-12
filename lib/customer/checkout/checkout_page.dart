import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'payment_page.dart';

class CheckoutPage extends StatelessWidget {
  final Map<String, dynamic> artwork;
  final String address;
  final Map<String, dynamic> addressSnapshot;
  final String addressId;
  final int quantity; // ✅ NEW

  const CheckoutPage({
    super.key,
    required this.artwork,
    required this.address,
    required this.addressSnapshot,
    required this.addressId,
    this.quantity = 1, // ✅ Default 1
  });

  @override
  Widget build(BuildContext context) {
    final image =
        artwork["imageUrl"] ?? artwork["imagePath"] ?? artwork["image"] ?? "";

    final title = artwork["title"] ?? "Artwork";
    final category = artwork["category"] ?? "";
    final price = artwork["price"] ?? "-";

    // Calculate total price string if possible for display, or just show unit price
    // Note: PaymentPage will do the actual calculation for transaction
    String displayPrice = "₹${price.toString()}";

    // Attempt basic parsing for display purposes if quantity > 1
    if (quantity > 1) {
      // Simple cleaner to parse price
      try {
        final pStr = price.toString().replaceAll(RegExp(r'[^0-9]'), '');
        final pInt = int.tryParse(pStr) ?? 0;
        if (pInt > 0) {
          // Helper to format currency
          final total = pInt * quantity;
          final s = total.toString();
          String formatted;
          if (s.length > 3) {
            final last3 = s.substring(s.length - 3);
            final rest = s.substring(0, s.length - 3);
            final reg = RegExp(r'(\d)(?=(\d{2})+(?!\d))');
            formatted =
                "₹ ${rest.replaceAllMapped(reg, (m) => '${m[1]},')},$last3";
          } else {
            formatted = "₹ $s";
          }
          displayPrice = "$formatted\n(Qty: $quantity)";
        }
      } catch (_) {}
    } else {
      // If quantity is 1, just show regular price
      displayPrice = "₹${price.toString()}";
    }

    return CustomerScaffold(
      currentIndex: -1,
      title: "Checkout",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Artwork"),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _artworkImage(image.toString()),
              ),
              title: Text(title.toString()),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.toString()),
                  if (quantity > 1)
                    Text(
                      "Quantity: $quantity",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
              trailing: Text(
                displayPrice,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 18, // ✅ bigger
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE16417),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle("Delivery Address"),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(address.isEmpty ? "-" : address),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentPage(
                        artwork: artwork,
                        address: address,
                        addressSnapshot: addressSnapshot,
                        addressId: addressId,
                        quantity: quantity, // ✅ Pass quantity
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Proceed to Payment"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED IMAGE HANDLER (INSIDE CLASS)
  Widget _artworkImage(String image) {
    if (image.isEmpty) return _placeholder();

    if (image.startsWith("http")) {
      return Image.network(
        image,
        width: 60,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    if (image.startsWith("assets/")) {
      return Image.asset(
        image,
        width: 60,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 80,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
