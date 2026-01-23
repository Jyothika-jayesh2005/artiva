import 'dart:io'; // ✅ REQUIRED for File()

import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

import 'package:artiva/backend/backend_provider.dart';
import 'package:artiva/backend/models.dart';

import 'exhibition_detail_page.dart';

class ExhibitionScreen extends StatefulWidget {
  const ExhibitionScreen({super.key});

  @override
  State<ExhibitionScreen> createState() => _ExhibitionScreenState();
}

class _ExhibitionScreenState extends State<ExhibitionScreen> {
  Future<List<Exhibition>> _load() async {
    return backend.getExhibitions(); // active only
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Exhibitions",
      body: FutureBuilder<List<Exhibition>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                snap.error.toString().replaceFirst('Exception: ', ''),
              ),
            );
          }

          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text("No exhibitions yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _exhibitionCard(list[i]),
          );
        },
      ),
    );
  }

  Widget _exhibitionCard(Exhibition e) {
    final remaining = e.remainingSeats;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExhibitionDetailPage(exhibition: e),
          ),
        );
        if (mounted) setState(() {}); // refresh seats after booking
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _image(e.imagePath),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(e.venue, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(e.dateTime),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      remaining > 0 ? "Seats left: $remaining" : "Sold out",
                      style: TextStyle(
                        color: remaining > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(String path) {
    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        width: 90,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 90,
          height: 110,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }

    // ✅ file path (picked image)
    return Image.file(
      File(path),
      width: 90,
      height: 110,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 90,
        height: 110,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
