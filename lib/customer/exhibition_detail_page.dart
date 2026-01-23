import 'dart:io';
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
              child: _image(exhibition.imagePath),
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

  Widget _image(String path) {
    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 220,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }

    return Image.file(
      File(path),
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 220,
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
