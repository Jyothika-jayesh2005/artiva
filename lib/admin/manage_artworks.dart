import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/backend_provider.dart';
import 'add_artwork.dart';

enum StockFilter { all, inStock, outOfStock }

class ManageArtworksPage extends StatefulWidget {
  const ManageArtworksPage({super.key});

  @override
  State<ManageArtworksPage> createState() => _ManageArtworksPageState();
}

class _ManageArtworksPageState extends State<ManageArtworksPage> {
  StockFilter _stockFilter = StockFilter.all;

  final TextEditingController _search = TextEditingController();

  static const Color accent = Color(0xFFFF8C1A);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddArtworkPage()),
    );
  }

  bool _matchesSearch(Map<String, dynamic> art) {
    final q = _search.text.toLowerCase().trim();
    if (q.isEmpty) return true;

    final title = (art["title"] ?? "").toString();
    final category = (art["category"] ?? "").toString();
    final price = (art["price"] ?? "").toString();

    final hay = "$title $category $price".toLowerCase();
    return hay.contains(q);
  }

  bool _matchesStockFilter(Map<String, dynamic> art) {
    if (_stockFilter == StockFilter.all) return true;

    final int total = _toInt(art["totalQuantity"]);
    final int sold = _toInt(art["soldQuantity"]);
    final int remaining = (total - sold) < 0 ? 0 : (total - sold);
    final bool inStock = remaining > 0;

    if (_stockFilter == StockFilter.inStock) return inStock;
    if (_stockFilter == StockFilter.outOfStock) return !inStock;
    return true;
  }

  Widget _chip(String text, StockFilter value) {
    final bool active = _stockFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _stockFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? accent.withOpacity(0.18) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? accent : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? accent : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Manage Artworks",

      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              const SizedBox(height: 12),

              // ✅ Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          cursorColor: accent, // ✅ Orange cursor
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: "Search by title...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_search.text.trim().isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _chip("All", StockFilter.all),
                    const SizedBox(width: 10),
                    _chip("In Stock", StockFilter.inStock),
                    const SizedBox(width: 10),
                    _chip("Out of Stock", StockFilter.outOfStock),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ✅ List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: backend.watchArtworks(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return Center(child: Text("Error: ${snap.error}"));
                    }

                    var artworks = snap.data ?? [];

                    // Apply both filters
                    artworks = artworks
                        .where(_matchesSearch)
                        .where(_matchesStockFilter)
                        .toList();

                    if (artworks.isEmpty) {
                      return const Center(child: Text("No artworks found"));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: artworks.length,
                      itemBuilder: (context, index) {
                        final art = artworks[index];

                        final String id = (art["id"] ?? "").toString().trim();
                        final String title = (art["title"] ?? "-").toString();
                        final String category = (art["category"] ?? "")
                            .toString();

                        final int total = _toInt(art["totalQuantity"]);
                        final int sold = _toInt(art["soldQuantity"]);
                        final int remaining = (total - sold) < 0
                            ? 0
                            : (total - sold);

                        final String image =
                            (art["imageUrl"] ??
                                    art["imagePath"] ??
                                    art["image"] ??
                                    "")
                                .toString()
                                .trim();

                        final int price = _toIntPrice(art["price"]);

                        return _artCard(
                          art: art,
                          id: id,
                          title: title,
                          category: category,
                          remaining: remaining,
                          price: price,
                          image: image,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // ✅ Floating + button (opens AddArtworkPage)
          Positioned(
            right: 18,
            bottom: 18,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openAdd,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _artCard({
    required Map<String, dynamic> art,
    required String id,
    required String title,
    required String category,
    required int remaining,
    required int price,
    required String image,
  }) {
    final bool inStock = remaining > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _thumbBig(image),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (category.trim().isNotEmpty)
                            Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            inStock ? "Stock: $remaining" : "Out of Stock",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: inStock
                                  ? Colors.green.shade700
                                  : Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: inStock
                                ? const Color(0xFF7BAA3A)
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            inStock ? "In Stock" : "Sold Out",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "₹$price",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.black.withOpacity(0.08), height: 1),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddArtworkPage(editArtwork: art),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: accent, // ✅ Orange text
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Edit"),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(id),
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbBig(String path) {
    const w = 76.0;
    const h = 76.0;

    if (path.isEmpty) return _imgErrSized(w, h);

    if (path.startsWith("http")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          path,
          width: w,
          height: h,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: w,
              height: h,
              alignment: Alignment.center,
              color: Colors.grey.shade100,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _imgErrSized(w, h),
        ),
      );
    }

    if (path.startsWith("assets/")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          path,
          width: w,
          height: h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imgErrSized(w, h),
        ),
      );
    }

    final f = File(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        f,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgErrSized(w, h),
      ),
    );
  }

  Widget _imgErrSized(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported),
    );
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  int _toIntPrice(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    final s = v.toString().replaceAll("₹", "").replaceAll(",", "").trim();
    return int.tryParse(s) ?? 0;
  }

  void _confirmDelete(String artworkId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Artwork"),
        content: const Text("Are you sure you want to delete this artwork?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await backend.deleteArtwork(artworkId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Artwork deleted")),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
