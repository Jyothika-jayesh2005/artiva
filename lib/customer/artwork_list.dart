import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/widgets/artwork_card.dart';
import 'package:artiva/customer/artwork_detail.dart';
import 'package:artiva/backend/backend_service.dart';

class ArtworkListPage extends StatefulWidget {
  final String initialQuery;
  final String initialCategory;

  const ArtworkListPage({
    super.key,
    this.initialQuery = "",
    this.initialCategory = "All",
  });

  @override
  State<ArtworkListPage> createState() => _ArtworkListPageState();
}

class _ArtworkListPageState extends State<ArtworkListPage> {
  late final TextEditingController _searchCtrl;
  late String _selectedCategory;

  final BackendService backend = BackendService();

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.initialQuery);
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> list) {
    final q = _searchCtrl.text.trim().toLowerCase();

    return list.where((art) {
      final title = (art["title"] ?? "").toString().toLowerCase();
      final cat = (art["category"] ?? "").toString();

      final categoryOk = (_selectedCategory == "All")
          ? true
          : (cat == _selectedCategory);

      final searchOk = q.isEmpty ? true : title.contains(q);

      return categoryOk && searchOk;
    }).toList();
  }

  Map<String, dynamic> _normalizeArtwork(Map<String, dynamic> art) {
    final image = (art["imageUrl"] ?? art["imagePath"] ?? art["image"] ?? "")
        .toString()
        .trim();

    return {...art, "image": image, "imagePath": image, "imageUrl": image};
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      title: "Artworks",
      currentIndex: 1,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Search artworks...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Filters (Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children:
                  [
                    "All",
                    "Painting",
                    "Digital",
                    "Sculpture",
                    "Abstract",
                    "Photography",
                    "Sketch",
                  ].map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChip(
                        label: Text(category),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFFE16417),
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.shade200,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        elevation: 0,
                        pressElevation: 0,
                      ),
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Grid List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: backend.watchArtworks(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      "Something went wrong",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                final all = (snap.data ?? []).map(_normalizeArtwork).toList();
                final filtered = _applyFilter(all);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No artworks found",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72, // Tuned for vertical cards
                  ),
                  itemBuilder: (context, index) {
                    final art = filtered[index];

                    return ArtworkCard(
                      artwork: art,
                      onTap: () {
                        final detailArt = art.map(
                          (k, v) => MapEntry(k, (v ?? "").toString()),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ArtworkDetailsPage(artwork: detailArt),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
