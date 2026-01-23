import 'dart:io';
import 'package:artiva/customer/profile/saved_address.dart';
import 'package:flutter/material.dart';
import '../widgets/customer_scaffold.dart';
import 'package:artiva/data/artwork_data.dart';

import 'package:artiva/backend/backend_provider.dart';
import 'package:artiva/backend/models.dart';

class ArtworkDetailsPage extends StatefulWidget {
  final Map<String, dynamic> artwork;

  const ArtworkDetailsPage({super.key, required this.artwork});

  @override
  State<ArtworkDetailsPage> createState() => _ArtworkDetailsPageState();
}

class _ArtworkDetailsPageState extends State<ArtworkDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final id = (widget.artwork["id"] ?? "").toString();

    final title = (widget.artwork["title"] ?? "Artwork").toString();
    final price = (widget.artwork["price"] ?? "-").toString();
    final imagePath =
        (widget.artwork["image"] ?? "assets/placeholder.png").toString();
    final category = (widget.artwork["category"] ?? "-").toString();
    final description = (widget.artwork["description"] ?? "").toString();

    final int totalQty =
        int.tryParse((widget.artwork["totalQuantity"] ?? "0").toString()) ?? 0;
    final int soldQty =
        int.tryParse((widget.artwork["soldQuantity"] ?? "0").toString()) ?? 0;
    final int remainingQty = (totalQty - soldQty).clamp(0, totalQty);

    final bool isWishlisted = ArtworkData.isFavourite(id);

    return CustomerScaffold(
      currentIndex: -1,
      title: title,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _imageWidget(imagePath),
                        ),
                      ),

                      // ✅ HEART BUTTON (REAL WISHLIST)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: const Color(0xFFE16417),
                            ),
                            onPressed: () {
                              setState(() {
                                ArtworkData.toggleFavourite(id);
                              });

                              final nowWishlisted = ArtworkData.isFavourite(id);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    nowWishlisted
                                        ? "Added to favourites"
                                        : "Removed from favourites",
                                  ),
                                  duration: const Duration(milliseconds: 900),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE16417),
                            ),
                          ),

                          // ✅ REAL rating from backend
                          FutureBuilder<ArtworkRatingSummary>(
                            future: backend.getArtworkRating(id),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return _badge(Icons.star, "—", Colors.orange);
                              }
                              final r = snap.data!;
                              final text = r.count == 0
                                  ? "—"
                                  : "${r.label} (${r.count})";
                              return _badge(Icons.star, text, Colors.orange);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        category,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            remainingQty > 0 ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: remainingQty > 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            remainingQty > 0
                                ? "In stock ($remainingQty left)"
                                : "Out of stock",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  remainingQty > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Product Highlights",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _highlight(
                        Icons.layers,
                        "Material",
                        (widget.artwork["paper"] ?? "—").toString(),
                        Colors.orange,
                      ),

                      _highlight(
                        Icons.verified,
                        "Certificate of Authenticity",
                        (widget.artwork["coa"] ?? "No").toString() == "Yes"
                            ? "Available"
                            : "Not Available",
                        (widget.artwork["coa"] ?? "No").toString() == "Yes"
                            ? Colors.green
                            : Colors.grey,
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          _spec("Size (cm)",
                              (widget.artwork["size_cm"] ?? "-").toString()),
                          _spec("Size (inch)",
                              (widget.artwork["size_in"] ?? "-").toString()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BUY BAR
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Price", style: TextStyle(color: Colors.grey)),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE16417),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: remainingQty == 0
                        ? null
                        : () {
                            final safeStringMap = widget.artwork.map(
                              (k, v) =>
                                  MapEntry(k.toString(), (v ?? "").toString()),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SavedAddressPage(
                                  isFromCheckout: true,
                                  artwork: Map<String, String>.from(
                                      safeStringMap),
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE16417),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      remainingQty == 0 ? "Out of Stock" : "Buy Now",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageWidget(String path) {
    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 44),
          ),
        ),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 44),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _highlight(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _spec(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
