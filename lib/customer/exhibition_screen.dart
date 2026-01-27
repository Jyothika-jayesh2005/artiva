import 'package:flutter/material.dart';

import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/backend/backend_service.dart';
import 'package:artiva/backend/models.dart';

import 'exhibition_detail_page.dart';

class ExhibitionScreen extends StatefulWidget {
  const ExhibitionScreen({super.key});

  @override
  State<ExhibitionScreen> createState() => _ExhibitionScreenState();
}

class _ExhibitionScreenState extends State<ExhibitionScreen> {
  final BackendService backend = BackendService();

  Future<List<Exhibition>> _load() async {
    return backend.getExhibitions(); // active only
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: 2,
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
        if (mounted) setState(() {}); // refresh after booking
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
                child: _image(e.imageUrl),
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

  Widget _image(String urlOrAsset) {
    final p = urlOrAsset.trim();

    if (p.isEmpty) {
      return _imgErr();
    }

    // assets support (optional)
    if (p.startsWith("assets/")) {
      return Image.asset(
        p,
        width: 90,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgErr(),
      );
    }

    // ✅ Cloudinary / network
    if (p.startsWith("http")) {
      return Image.network(
        p,
        width: 90,
        height: 110,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 90,
            height: 110,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (_, __, ___) => _imgErr(),
      );
    }

    return _imgErr(text: "Invalid image");
  }

  Widget _imgErr({String text = "No image"}) {
    return Container(
      width: 90,
      height: 110,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
