import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/data/artwork_data.dart';
import 'add_artwork.dart';

class ManageArtworksPage extends StatefulWidget {
  const ManageArtworksPage({super.key});

  @override
  State<ManageArtworksPage> createState() => _ManageArtworksPageState();
}

class _ManageArtworksPageState extends State<ManageArtworksPage> {
  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Manage Artworks",
      showBack: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddArtworkPage()),
            );
            if (!mounted) return;
            setState(() {}); // refresh after add
          },
        ),
      ],
      body: ArtworkData.artworks.isEmpty
          ? const Center(child: Text("No artworks added yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ArtworkData.artworks.length,
              itemBuilder: (context, index) {
                final art = ArtworkData.artworks[index];

                final int total = _toInt(art["totalQuantity"]);
                final int sold = _toInt(art["soldQuantity"]);
                final int remaining = total - sold;

                final String title = (art["title"] ?? "-").toString();
                final String imagePath = (art["image"] ?? "").toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imagePath.startsWith("assets/")
                          ? Image.asset(
                              imagePath,
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 55,
                                height: 55,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            )
                          : Container(
                              width: 55,
                              height: 55,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        remaining > 0
                            ? "In stock ($remaining left)"
                            : "Out of stock",
                        style: TextStyle(
                          color: remaining > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // EDIT
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddArtworkPage(editIndex: index),
                              ),
                            );
                            if (!mounted) return;
                            setState(() {}); // refresh after edit
                          },
                        ),

                        // DELETE
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ✅ Safe conversion for dynamic -> int (fixes your crash)
  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // ================= DELETE CONFIRMATION =================
  void _confirmDelete(int index) {
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
            onPressed: () {
              setState(() {
                ArtworkData.artworks.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
