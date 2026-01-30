import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'payment_page.dart';

class CheckoutPage extends StatelessWidget {
  final Map<String, dynamic> artwork;
  final String address;
  final Map<String, dynamic> addressSnapshot;
  final String addressId;

  const CheckoutPage({
    super.key,
    required this.artwork,
    required this.address,
    required this.addressSnapshot,
    required this.addressId,
  });

  @override
  Widget build(BuildContext context) {
    final image =
        artwork["imageUrl"] ?? artwork["imagePath"] ?? artwork["image"] ?? "";

    final title = artwork["title"] ?? "Artwork";
    final category = artwork["category"] ?? "";
    final price = artwork["price"] ?? "-";

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
              subtitle: Text(category.toString()),
              trailing: Text(
                price.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
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
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
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
