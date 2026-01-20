import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/widgets/artwork_card.dart';
import 'package:artiva/customer/artwork_detail.dart';
import 'package:artiva/data/artwork_data.dart';

class ArtworkListPage extends StatefulWidget {
  final String initialQuery;
  final String initialCategory; // "All" or specific

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

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();

    return ArtworkData.artworks.where((raw) {
      final art = Map<String, dynamic>.from(raw);

      final title = (art["title"] ?? "").toString().toLowerCase();
      final cat = (art["category"] ?? "").toString();

      final categoryOk =
          (_selectedCategory == "All") ? true : (cat == _selectedCategory);

      final searchOk = q.isEmpty ? true : title.contains(q);

      return categoryOk && searchOk;
    }).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return CustomerScaffold(
      title: "Artworks",
      currentIndex: 1,
      body: Column(
        children: [
          // Top filter bar
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: list.isEmpty
                  ? const Center(child: Text("No artworks found"))
                  : GridView.builder(
                      itemCount: list.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        // IMPORTANT: tune for your ArtworkCard (prevents overflow)
                        childAspectRatio: 0.62,
                      ),
                      itemBuilder: (context, index) {
                        final art = list[index];

                        return ArtworkCard(
                          artwork: art,
                          onTap: () {
                            // If your ArtworkDetailsPage expects Map<String,String>,
                            // convert safely:
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
            ),
          ),
        ],
      ),
    );
  }
}
