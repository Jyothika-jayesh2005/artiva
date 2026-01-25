import 'dart:io';
import 'package:flutter/material.dart';

import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/backend_provider.dart';
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
          },
        ),
      ],
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: backend.watchArtworks(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final artworks = snap.data ?? [];
          if (artworks.isEmpty) {
            return const Center(child: Text("No artworks added yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: artworks.length,
            itemBuilder: (context, index) {
              final art = artworks[index];

              final String id = (art["id"] ?? "").toString();
              final String title = (art["title"] ?? "-").toString();

              final int total = _toInt(art["totalQuantity"]);
              final int sold = _toInt(art["soldQuantity"]);
              final int remaining = total - sold;

              final String imagePath =
                  (art["imagePath"] ?? art["image"] ?? "").toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: _thumb(imagePath),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      remaining > 0 ? "In stock ($remaining left)" : "Out of stock",
                      style: TextStyle(
                        color: remaining > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddArtworkPage(editArtwork: art),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _thumb(String path) {
    if (path.isEmpty) {
      return _imgErr();
    }

    if (path.startsWith("assets/")) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          path,
          width: 55,
          height: 55,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imgErr(),
        ),
      );
    }

    final f = File(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        f,
        width: 55,
        height: 55,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgErr(),
      ),
    );
  }

  Widget _imgErr() {
    return Container(
      width: 55,
      height: 55,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported),
    );
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Delete failed: $e")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
