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

  static const Color accent = Color(0xFFE16417);

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

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _exhibitionCard(list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _exhibitionCard(Exhibition e) {
    final remaining = e.remainingSeats;
    final soldOut = remaining <= 0;

    final totalSeats = e.totalSeats;

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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- IMAGE TOP --------
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: _imageWide(e.imageUrl),
                  ),

                  // Status pill
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _statusPill(
                      text: soldOut ? "Sold out" : "Active",
                      color: soldOut ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // -------- DETAILS --------
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Date row
                  _metaRow(
                    icon: Icons.calendar_month,
                    text: _formatDateTime(e.dateTime),
                  ),
                  const SizedBox(height: 6),

                  // Venue row
                  _metaRow(
                    icon: Icons.location_on,
                    text: e.venue,
                  ),

                  const SizedBox(height: 12),
                  Divider(color: Colors.black.withOpacity(0.08), height: 1),
                  const SizedBox(height: 10),

                  // Bottom stats
                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          icon: Icons.event_seat,
                          label: soldOut
                              ? "Seats: 0 / $totalSeats"
                              : "Seats: $remaining / $totalSeats",
                          valueColor: soldOut ? Colors.red : Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _stat(
                          icon: Icons.payments,
                          label: "₹${e.pricePerSeat} / seat",
                          valueColor: accent,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _metaRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat({
    required IconData icon,
    required String label,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: valueColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w800,
              color: valueColor == accent ? const Color(0xFF1F2937) : valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _imageWide(String urlOrAsset) {
    final p = urlOrAsset.trim();

    if (p.isEmpty) {
      return _imgErrWide();
    }

    if (p.startsWith("assets/")) {
      return Image.asset(
        p,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgErrWide(),
      );
    }

    if (p.startsWith("http")) {
      return Image.network(
        p,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => _imgErrWide(),
      );
    }

    return _imgErrWide(text: "Invalid image");
  }

  Widget _imgErrWide({String text = "No image"}) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
