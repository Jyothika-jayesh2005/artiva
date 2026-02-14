import 'dart:io';
import 'package:flutter/material.dart';

class ArtworkCard extends StatelessWidget {
  final Map<String, dynamic> artwork;
  final VoidCallback? onTap;

  const ArtworkCard({super.key, required this.artwork, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String title = artwork["title"]?.toString() ?? "Artwork";
    final String category = artwork["category"]?.toString() ?? "";

    final int price =
        int.tryParse(
          (artwork["price"] ?? "0")
              .toString()
              .replaceAll("₹", "")
              .replaceAll(",", "")
              .trim(),
        ) ??
        0;

    // Rating values
    final double avgRating = (artwork["avgRating"] is num)
        ? (artwork["avgRating"] as num).toDouble()
        : double.tryParse((artwork["avgRating"] ?? "").toString()) ?? 0.0;

    final int ratingCount = (artwork["ratingCount"] is num)
        ? (artwork["ratingCount"] as num).toInt()
        : int.tryParse((artwork["ratingCount"] ?? "").toString()) ?? 0;

    // Image
    final String image =
        (artwork["imageUrl"] ?? artwork["image"] ?? artwork["imagePath"] ?? "")
            .toString()
            .trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (Vertical Aspect Ratio)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _image(image),
                    // Optional: Subtle gradient at bottom of image for depth
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price & Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹$price",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE16417),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFFFB300),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          if (ratingCount > 0)
                            Text(
                              " ($ratingCount)",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(String img) {
    if (img.isEmpty) return _fallback();

    if (img.startsWith("http")) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade50,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (img.startsWith("assets/")) {
      return Image.asset(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return Image.file(
      File(img),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade300,
        size: 32,
      ),
    );
  }
}
