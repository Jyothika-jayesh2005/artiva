import 'dart:io';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:artiva/customer/profile/saved_address.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/backend_service.dart';
import 'package:artiva/backend/models.dart';

class ArtworkDetailsPage extends StatefulWidget {
  final Map<String, dynamic> artwork;

  const ArtworkDetailsPage({super.key, required this.artwork});

  @override
  State<ArtworkDetailsPage> createState() => _ArtworkDetailsPageState();
}

class _ArtworkDetailsPageState extends State<ArtworkDetailsPage> {
  final BackendService backend = BackendService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _artId => (widget.artwork["id"] ?? "").toString().trim();

  // ✅ Convert dynamic price to int safely (handles int, "25000", "₹25,000", etc.)
  int _priceAsInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();

    final s = v.toString();
    final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  // ✅ Indian commas + ₹ symbol
  String _formatIndianCurrency(int amount) {
    if (amount <= 0) return "₹ 0";

    final s = amount.toString();
    if (s.length <= 3) return "₹ $s";

    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);

    final reg = RegExp(r'(\d)(?=(\d{2})+(?!\d))');
    final formattedRest = rest.replaceAllMapped(reg, (m) => '${m[1]},');

    return "₹ $formattedRest,$last3";
  }

  DocumentReference<Map<String, dynamic>>? _favRef() {
    final user = authService.currentUser;
    if (user == null) return null;
    if (_artId.isEmpty) return null;

    return _db
        .collection("users")
        .doc(user.uid)
        .collection("favourites")
        .doc(_artId);
  }

  Future<void> _toggleFavourite({
    required String title,
    required String priceText,
    required String imageAny,
  }) async {
    final user = authService.currentUser;
    if (user == null) {
      _snack("Please login first.");
      return;
    }
    if (_artId.isEmpty) {
      _snack("Artwork ID missing.");
      return;
    }

    final ref = _favRef();
    if (ref == null) return;

    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
      _snack("Removed from favourites");
    } else {
      await ref.set({
        "artworkId": _artId,
        "title": title,
        // ✅ standardize: store in "image"
        // (still compatible with old "imageAny")
        "image": imageAny,
        "price": priceText,
        "createdAt": FieldValue.serverTimestamp(),
      });
      _snack("Added to favourites");
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = _artId;
    final user = authService.currentUser;

    final title = (widget.artwork["title"] ?? "Artwork").toString();

    final int priceValue = _priceAsInt(widget.artwork["price"]);
    final String priceText =
        priceValue > 0 ? _formatIndianCurrency(priceValue) : "-";

    // ✅ prefer Firestore URL first
    final imageAny = (widget.artwork["imageUrl"] ??
            widget.artwork["imagePath"] ??
            widget.artwork["image"] ??
            "assets/placeholder.png")
        .toString();

    final category = (widget.artwork["category"] ?? "-").toString();
    final description = (widget.artwork["description"] ?? "").toString();

    final int totalQty =
        int.tryParse((widget.artwork["totalQuantity"] ?? "0").toString()) ?? 0;
    final int soldQty =
        int.tryParse((widget.artwork["soldQuantity"] ?? "0").toString()) ?? 0;
    final int remainingQty = (totalQty - soldQty).clamp(0, totalQty);

    final favRef = _favRef();

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
                          child: _imageWidget(imageAny),
                        ),
                      ),

                      // ❤️ Favourite button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            stream: (favRef == null || id.isEmpty)
                                ? const Stream.empty()
                                : favRef.snapshots(),
                            builder: (context, snap) {
                              final isFav = snap.data?.exists ?? false;

                              return IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: const Color(0xFFE16417),
                                ),
                                onPressed: () => _toggleFavourite(
                                  title: title,
                                  priceText: priceText,
                                  imageAny: imageAny,
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
                            priceText,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE16417),
                            ),
                          ),

                          // ⭐ overall rating
                          FutureBuilder<ArtworkRatingSummary>(
                            future: backend.getArtworkRating(id),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return _badge(Icons.star, "—", Colors.orange);
                              }
                              if (snap.hasError) {
                                return _badge(Icons.star, "—", Colors.orange);
                              }
                              final r = snap.data ??
                                  const ArtworkRatingSummary(avg: 0, count: 0);

                              final text =
                                  r.count == 0 ? "—" : "${r.label} (${r.count})";
                              return _badge(Icons.star, text, Colors.orange);
                            },
                          ),
                        ],
                      ),

                      // 👤 show user's rating (optional)
                      const SizedBox(height: 10),
                      if (user != null && id.isNotEmpty)
                        FutureBuilder<int?>(
                          future: backend.getMyArtworkRating(id, user.email),
                          builder: (context, snap) {
                            final myR = snap.data;
                            if (myR == null) return const SizedBox.shrink();
                            return _badge(Icons.person, "You: $myR/5",
                                Colors.blueGrey);
                          },
                        ),

                      const SizedBox(height: 8),

                      Text(
                        category,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            remainingQty > 0
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color:
                                remainingQty > 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            remainingQty > 0
                                ? "In stock ($remainingQty left)"
                                : "Out of stock",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: remainingQty > 0
                                  ? Colors.green
                                  : Colors.red,
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

                      const SizedBox(height: 32),

                      // ✅ CUSTOMER RATINGS SECTION
                      const Text(
                        "Customer Ratings",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCustomerRatingsSection(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom buy bar
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
                      const Text("Price",
                          style: TextStyle(color: Colors.grey)),
                      Text(
                        priceText,
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
                        horizontal: 36,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      remainingQty == 0 ? "Out of Stock" : "Buy Now",
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
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

  // ✅ supports http, assets, and local file
  Widget _imageWidget(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported, size: 44)),
      );
    }

    if (path.startsWith("http")) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.image_not_supported, size: 44)),
        ),
      );
    }

    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.image_not_supported, size: 44)),
        ),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported, size: 44)),
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
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
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
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ✅ NEW: Build customer ratings section
  Widget _buildCustomerRatingsSection() {
    return FutureBuilder<List<ArtworkOrder>>(
      future: backend.getArtworkReviews(_artId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              "Error loading reviews",
              style: TextStyle(color: Colors.red.shade400),
            ),
          );
        }

        final reviews = snap.data ?? [];

        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "No ratings yet. Be the first to review!",
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (_, i) => _buildReviewCard(reviews[i]),
        );
      },
    );
  }

  // ✅ NEW: Build individual review card
  Widget _buildReviewCard(ArtworkOrder review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Stars and name
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStarsRow(review.rating ?? 0),
                    const SizedBox(height: 4),
                    Text(
                      review.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (review.ratedAt != null)
                Text(
                  _formatReviewDate(review.ratedAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),

          // Rating score
          if (review.rating != null) ...[
            const SizedBox(height: 6),
            Text(
              "${review.rating}/5 Stars",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ],

          // Review text
          if ((review.review ?? "").trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.review!.trim(),
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ✅ NEW: Build stars row for review card
  Widget _buildStarsRow(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: Colors.orange,
        ),
      ),
    );
  }

  // ✅ NEW: Format review date
  String _formatReviewDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return "${diff.inMinutes}m ago";
      }
      return "${diff.inHours}h ago";
    } else if (diff.inDays < 30) {
      return "${diff.inDays}d ago";
    } else if (diff.inDays < 365) {
      return "${(diff.inDays / 30).floor()}mo ago";
    }
    return "${(diff.inDays / 365).floor()}y ago";
  }
}
