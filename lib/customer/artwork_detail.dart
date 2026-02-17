import 'dart:io';
import 'package:artiva/customer/artist_info_sheet.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:artiva/customer/profile/saved_address.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/backend_service.dart';

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

  // Quantity state
  int _quantity = 1;
  bool _isDescriptionExpanded = false;

  // Helpers
  int _priceAsInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    final s = v.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(s) ?? 0;
  }

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
    if (user == null || _artId.isEmpty) return null;
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
    if (_artId.isEmpty) return;

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
    final title = (widget.artwork["title"] ?? "Artwork").toString();
    final int priceValue = _priceAsInt(widget.artwork["price"]);
    final String priceText = priceValue > 0
        ? _formatIndianCurrency(priceValue)
        : "-";

    final imageAny =
        (widget.artwork["imageUrl"] ??
                widget.artwork["imagePath"] ??
                widget.artwork["image"] ??
                "assets/placeholder.png")
            .toString();

    final category = (widget.artwork["category"] ?? "-").toString();
    final description = (widget.artwork["description"] ?? "").toString();
    final material = (widget.artwork["paper"] ?? "-").toString();
    final artistName = (widget.artwork["artistName"] ?? "Unknown Artist")
        .toString();
    final artistImage = (widget.artwork["artistImage"] ?? "")
        .toString(); // If available

    final sizeCm = (widget.artwork["size_cm"] ?? "-").toString();
    final sizeIn = (widget.artwork["size_in"] ?? "-").toString();
    final coa = (widget.artwork["coa"] ?? "-").toString();

    final int totalQty =
        int.tryParse((widget.artwork["totalQuantity"] ?? "0").toString()) ?? 0;
    final int soldQty =
        int.tryParse((widget.artwork["soldQuantity"] ?? "0").toString()) ?? 0;
    final int remainingQty = (totalQty - soldQty).clamp(0, totalQty);

    final favRef = _favRef();

    // Rating
    final double avgRating = (widget.artwork["avgRating"] is num)
        ? (widget.artwork["avgRating"] as num).toDouble()
        : double.tryParse((widget.artwork["avgRating"] ?? "").toString()) ??
              0.0;
    final int ratingCount = (widget.artwork["ratingCount"] is num)
        ? (widget.artwork["ratingCount"] as num).toInt()
        : int.tryParse((widget.artwork["ratingCount"] ?? "").toString()) ?? 0;

    return Scaffold(
      backgroundColor: const Color(
        0xFFFFF1DC,
      ), // Changed to cream for image background separation
      body: Stack(
        children: [
          // Content Scroll
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                // 1. Full Image Top
                SizedBox(
                  width: double.infinity,
                  // Remove fixed height, allow image to define height based on width
                  // but constrain max height to prevent it taking over too much
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.65,
                      minHeight: 200,
                    ),
                    child: _imageWidget(imageAny, fit: BoxFit.contain),
                  ),
                ),

                // 2. Info Container (Overlapping)
                Container(
                  transform: Matrix4.translationValues(0, -30, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1DC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Category & Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              color: Colors
                                  .black, // Changed from grey.shade500 based on user request for "not grey" (assumed black for reliability on cream)
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFC107),
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                " ($ratingCount)", // Removed 'reviews' text for cleaner look
                                style: TextStyle(
                                  color: Colors
                                      .black, // Changed from grey.shade500
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Seller / Artist Row
                      const Text(
                        "Artist",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                ArtistInfoSheet(artwork: widget.artwork),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(
                                  0xFFE16417,
                                ).withOpacity(0.1),
                                // Logic for Artist Image if available, else Icon
                                backgroundImage:
                                    artistImage.isNotEmpty &&
                                        artistImage.startsWith('http')
                                    ? NetworkImage(artistImage)
                                    : null,
                                child:
                                    (artistImage.isEmpty ||
                                        !artistImage.startsWith('http'))
                                    ? const Icon(
                                        Icons.person,
                                        color: Color(0xFFE16417),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      artistName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    Text(
                                      "Creator",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 'Know the Artist' Icon Button
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFFE16417),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description
                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description Logic
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const int truncationLimit = 150;
                          final bool isLong =
                              description.length > truncationLimit;
                          final String textToShow =
                              isLong && !_isDescriptionExpanded
                              ? "${description.substring(0, truncationLimit)}..."
                              : description;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                textToShow,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (isLong)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded =
                                          !_isDescriptionExpanded;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      _isDescriptionExpanded
                                          ? "Show Less"
                                          : "Read More",
                                      style: const TextStyle(
                                        color: Color(0xFFE16417),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Specifications (Material, Size CM, Size IN)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _specChip("Material", material, false),
                            const SizedBox(width: 12),
                            // Size Selection-like UI (Display only really)
                            _specChip(sizeCm, "cm", true),
                            const SizedBox(width: 12),
                            _specChip(sizeIn, "inch", false),
                            const SizedBox(width: 12),
                            _specChip("COA", coa, false),
                          ],
                        ),
                      ),

                      if (remainingQty > 0) ...[
                        const SizedBox(height: 24),
                        // Quantity Selector & Stock
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Select Quantity",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$remainingQty left in stock",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: remainingQty < 5
                                        ? Colors.red
                                        : Colors
                                              .green, // Changed to green as requested
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                  ),
                                  Text(
                                    "$_quantity",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: _quantity < remainingQty
                                        ? () => setState(() => _quantity++)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Return & Cancellation Policy
                      const Text(
                        "Cancellation Policy",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _policyItem(
                              "Cancellation",
                              "You can cancel your order before it has been shipped. Once shipped, cancellations are not allowed.",
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Review Section (Enhanced)
                      _buildReviewSummary(id),

                      const SizedBox(height: 20),

                      // Review List
                      _buildCustomerRatingsSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Floating Favorite Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: (favRef == null || id.isEmpty)
                    ? const Stream.empty()
                    : favRef.snapshots(),
                builder: (context, snap) {
                  final isFav = snap.data?.exists ?? false;
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: const Color(0xFFE16417),
                      size: 20,
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

          // Bottom Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Total Price",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _quantity > 1
                            ? _formatIndianCurrency(priceValue * _quantity)
                            : priceText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Custom Gradient Button
                  InkWell(
                    onTap: remainingQty == 0
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
                                    safeStringMap,
                                  ),
                                  quantity: _quantity,
                                ),
                              ),
                            );
                          },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE16417), Color(0xFFE16417)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE16417).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            remainingQty == 0 ? "Out of Stock" : "Add to Cart",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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

  Widget _specChip(String label, String subLabel, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE16417) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFFE16417) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.white70 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to render images safely
  Widget _imageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.image_not_supported, size: 44)),
      );
    }
    if (path.startsWith("http")) {
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
      );
    }
    if (path.startsWith("assets/")) {
      return Image.asset(path, fit: fit);
    }
    return Image.file(File(path), fit: fit);
  }

  Widget _policyItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE16417),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // NEW: Review Summary Bars
  Widget _buildReviewSummary(String artId) {
    return FutureBuilder<List<PublicReview>>(
      future: backend.getArtworkPublicReviews(artId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final reviews = snapshot.data!;
        if (reviews.isEmpty) return const SizedBox();

        // Count logic
        Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        double totalRating = 0;
        for (var r in reviews) {
          counts[r.rating] = (counts[r.rating] ?? 0) + 1;
          totalRating += r.rating;
        }
        final avg = totalRating / reviews.length;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Review",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // See all / or total in brackets
                Text(
                  "(${reviews.length} reviews)",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big Score
                Column(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStarRowStatic(avg.round(), 18),
                    const SizedBox(height: 8),
                    Text(
                      "${reviews.length} Reviews",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Bars
                Expanded(
                  child: Column(
                    children: [
                      _ratingBar(5, counts[5]!, reviews.length),
                      _ratingBar(4, counts[4]!, reviews.length),
                      _ratingBar(3, counts[3]!, reviews.length),
                      _ratingBar(2, counts[2]!, reviews.length),
                      _ratingBar(1, counts[1]!, reviews.length),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _ratingBar(int star, int count, int total) {
    final double pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              "$star",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors
                        .white, // Changed from grey.shade200 to white as requested
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE16417), Color(0xFFE16417)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRowStatic(int rating, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: const Color(0xFFFFC107),
        ),
      ),
    );
  }

  // Review List (Same logic as before, cleaner UI)
  Widget _buildCustomerRatingsSection() {
    return FutureBuilder<List<PublicReview>>(
      future: backend.getArtworkPublicReviews(_artId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final reviews = snap.data ?? [];
        if (reviews.isEmpty) return const SizedBox();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) => _buildReviewRow(reviews[i]),
        );
      },
    );
  }

  Widget _buildReviewRow(PublicReview review) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          radius: 18,
          child: Text(
            review.name.isNotEmpty ? review.name[0].toUpperCase() : "U",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    review.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (review.ratedAt != null)
                    Text(
                      _formatReviewDate(review.ratedAt!),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Rating stars for this review
              _buildStarRowStatic(review.rating, 14),
              const SizedBox(height: 6),
              if (review.review.trim().isNotEmpty)
                Text(
                  review.review,
                  style: TextStyle(
                    color: Colors.black, // Changed to black for visibility
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
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
