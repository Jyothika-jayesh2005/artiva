import 'dart:io';
import 'package:flutter/material.dart';

class ArtworkCard extends StatelessWidget {
  final Map<String, dynamic> artwork;
  final VoidCallback? onTap;

  const ArtworkCard({super.key, required this.artwork, this.onTap});

  static const _titleColor = Color(0xFF1F1F1F);
  static const _categoryColor = Color(0xFF7A7A7A);
  static const _priceColor = Color(0xFFE16417);

  @override
  Widget build(BuildContext context) {
    final String title = artwork["title"]?.toString() ?? "Artwork";
    final String category = artwork["category"]?.toString() ?? "";

    final int price = int.tryParse(
          (artwork["price"] ?? "0")
              .toString()
              .replaceAll("₹", "")
              .replaceAll(",", "")
              .trim(),
        ) ??
        0;

    // ✅ Rating values from artwork map (Firestore fields)
    final double avgRating = (artwork["avgRating"] is num)
        ? (artwork["avgRating"] as num).toDouble()
        : double.tryParse((artwork["avgRating"] ?? "").toString()) ?? 0.0;

    final int ratingCount = (artwork["ratingCount"] is num)
        ? (artwork["ratingCount"] as num).toInt()
        : int.tryParse((artwork["ratingCount"] ?? "").toString()) ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, c) {
            const double textAreaH = 78.0;

            final double maxH = c.maxHeight.isFinite ? c.maxHeight : 260.0;
            final double imageH = (maxH - textAreaH).clamp(120.0, 220.0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: imageH,
                  width: double.infinity,
                  child: _image(artwork["image"]),
                ),
                SizedBox(
                  height: textAreaH,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _titleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _categoryColor,
                          ),
                        ),
                        const Spacer(),

                        // ✅ Price left, Rating right (rating does NOT take extra space)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "₹$price",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _priceColor,
                                ),
                              ),
                            ),

                            // ✅ ALWAYS show rating UI so you can see the change
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFFFB300),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  ratingCount == 0
                                      ? "—"
                                      : avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _titleColor,
                                  ),
                                ),
                                if (ratingCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    "($ratingCount)",
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: _categoryColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _image(dynamic img) {
    if (img is String && img.isNotEmpty) {
      if (img.startsWith("assets/")) {
        return Image.asset(
          img,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => _fallback(),
        );
      }
      return Image.file(
        File(img),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (img is File) {
      return Image.file(
        img,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.image, color: Colors.black45)),
    );
  }
}
