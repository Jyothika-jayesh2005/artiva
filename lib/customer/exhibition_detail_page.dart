import 'package:flutter/material.dart';

import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'exhibition_payment_page.dart';

class ExhibitionDetailPage extends StatelessWidget {
  final Exhibition exhibition;
  const ExhibitionDetailPage({super.key, required this.exhibition});

  @override
  Widget build(BuildContext context) {
    final remaining = exhibition.remainingSeats;

    return CustomerScaffold(
      currentIndex: -1,
      title: "Exhibition Details",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 220,
                child: _image(exhibition.imageUrl),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              exhibition.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(exhibition.venue, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              _formatDateTime(exhibition.dateTime),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),

            const Text(
              "Description",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(exhibition.description),
            const SizedBox(height: 16),

            Text(
              "Price per seat: ₹${exhibition.pricePerSeat}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),

            Text(
              remaining > 0 ? "Remaining seats: $remaining" : "Sold out",
              style: TextStyle(
                color: remaining > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: remaining == 0
                    ? null
                    : () async {
                        final seats = await _pickSeats(context, remaining);
                        if (seats == null) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExhibitionPaymentPage(
                              exhibition: exhibition,
                              seats: seats,
                            ),
                          ),
                        );
                      },
                child: Text(remaining == 0 ? "Sold Out" : "Book Seats"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _pickSeats(BuildContext context, int maxSeats) async {
    int selected = 1;

    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text("Select Seats"),
            content: Row(
              children: [
                const Text("Seats: "),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: selected,
                  items: List.generate(maxSeats, (i) => i + 1)
                      .map((n) => DropdownMenuItem(
                            value: n,
                            child: Text(n.toString()),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => selected = v ?? 1),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selected),
                child: const Text("Continue"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _image(String urlOrAsset) {
    final p = urlOrAsset.trim();
    if (p.isEmpty) return _imgError();

    // assets support (optional)
    if (p.startsWith("assets/")) {
      return Image.asset(
        p,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgError(),
      );
    }

    // ✅ Cloudinary / network url
    if (p.startsWith("http")) {
      return Image.network(
        p,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => _imgError(),
      );
    }

    // if someone accidentally stored local path again
    return _imgError(text: "Invalid image url (not http/asset)");
  }

  Widget _imgError({String text = "Image not available"}) {
    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_not_supported),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
