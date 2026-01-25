import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/widgets/artwork_card.dart';
import 'package:artiva/customer/artwork_detail.dart';
import 'package:artiva/backend/backend_provider.dart'; // global backend

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

      final categoryOk =
          (_selectedCategory == "All") ? true : (cat == _selectedCategory);

      final searchOk = q.isEmpty ? true : title.contains(q);

      return categoryOk && searchOk;
    }).toList();
  }

  // ✅ Normalize Firestore artwork map so UI always gets the image in a common key
  Map<String, dynamic> _normalizeArtwork(Map<String, dynamic> art) {
    final image = (art["imageUrl"] ?? art["imagePath"] ?? art["image"] ?? "")
        .toString()
        .trim();

    return {
      ...art,
      // Many widgets use "image" key. Force it.
      "image": image,
      "imagePath": image, // keep both for safety
      "imageUrl": image,  // keep both for safety
    };
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      title: "Artworks",
      currentIndex: 1,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: "Search artworks",
                        border: InputBorder.none,
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButtonHideUnderline(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      items: const [
                        "All",
                        "Painting",
                        "Digital",
                        "Sculpture",
                        "Abstract",
                        "Photography",
                        "Sketch",
                      ].map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedCategory = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

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

                final all = (snap.data ?? []).map(_normalizeArtwork).toList();
                final filtered = _applyFilter(all);

                if (filtered.isEmpty) {
                  return const Center(child: Text("No artworks found"));
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.62,
                    ),
                    itemBuilder: (context, index) {
                      final art = filtered[index];

                      return ArtworkCard(
                        artwork: art, // ✅ now has image/imagePath/imageUrl
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
