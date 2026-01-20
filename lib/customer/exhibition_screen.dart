import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/customer_scaffold.dart';
import '../data/exhibition_data.dart';
import '../models/exhibition_model.dart';
import 'exhibition_detail_page.dart';

class ExhibitionScreen extends StatefulWidget {
  const ExhibitionScreen({super.key});

  @override
  State<ExhibitionScreen> createState() => _ExhibitionScreenState();
}

class _ExhibitionScreenState extends State<ExhibitionScreen> {
  @override
  Widget build(BuildContext context) {
    final visible =
        ExhibitionData.exhibitions.where((e) => !e.isArchived).toList();

    return CustomerScaffold(
      title: "Exhibitions",
      currentIndex: 2,
      body: visible.isEmpty
          ? const Center(child: Text("No exhibitions available"))
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final ex = visible[index];

                return GestureDetector(
                  onTap: () async {
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExhibitionDetailPage(
                          exhibitionId: ex.id,
                          imagePath: ex.imagePath, // ✅ from model
                        ),
                      ),
                    );
                    if (changed == true) setState(() {});
                  },
                  child: _exhibitionCard(exhibition: ex),
                );
              },
            ),
    );
  }

  Widget _exhibitionCard({required Exhibition exhibition}) {
    final remaining = exhibition.remainingSeats;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ SAME HEIGHT ALWAYS
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: _img(exhibition.imagePath, height: 170),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exhibition.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(_formatDateTime(exhibition.dateTime),
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exhibition.venue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  exhibition.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  "Remaining seats: $remaining",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tap to view & book",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _img(String path, {required double height}) {
    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(height),
      );
    }
    return Image.file(
      File(path),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(height),
    );
  }

  Widget _fallback(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
