import 'package:artiva/customer/exhibition_payment_page.dart';
import 'package:flutter/material.dart';
import '../widgets/customer_scaffold.dart';
import '../data/exhibition_data.dart';
import '../data/booking_data.dart';
import '../models/exhibition_model.dart';

class ExhibitionDetailPage extends StatefulWidget {
  final String exhibitionId;
  final String imagePath;

  const ExhibitionDetailPage({
    super.key,
    required this.exhibitionId,
    required this.imagePath,
  });

  @override
  State<ExhibitionDetailPage> createState() => _ExhibitionDetailPageState();
}

class _ExhibitionDetailPageState extends State<ExhibitionDetailPage> {
  @override
  Widget build(BuildContext context) {
    final index =
        ExhibitionData.exhibitions.indexWhere((e) => e.id == widget.exhibitionId);

    if (index == -1) {
      return CustomerScaffold(
        title: "Exhibition",
        currentIndex: -1,
        body: const Center(child: Text("Exhibition not found")),
      );
    }

    final Exhibition ex = ExhibitionData.exhibitions[index];
    final remaining = ex.remainingSeats;
    final totalAmount = ex.pricePerSeat * 1;

    return CustomerScaffold(
      title: ex.title,
      currentIndex: -1,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          // ✅ SPACE BELOW HEADER
          const SizedBox(height: 14),

          // ✅ IMAGE WITH PADDING + SAME LOOK AS YOUR CARDS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                widget.imagePath,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 230,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 44),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(ex.venue)),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(_formatDateTime(ex.dateTime)),
                  ],
                ),

                const SizedBox(height: 16),

                Text(ex.description, style: const TextStyle(fontSize: 14)),

                const SizedBox(height: 16),

                Text(
                  "Price / Seat: ₹${ex.pricePerSeat}",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  "Starting Total (1 seat): ₹$totalAmount",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 16),

                Text(
                  "Seats: ${ex.bookedSeats}/${ex.totalSeats}  •  Remaining: $remaining",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (ex.isClosed || ex.isFull)
                        ? null
                        : () => _bookSeats(context, index),
                    child: Text(
                      ex.isFull ? "Full" : (ex.isClosed ? "Closed" : "Book Pass"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bookSeats(BuildContext context, int index) async {
    final ex = ExhibitionData.exhibitions[index];
    final seatsCtrl = TextEditingController(text: "1");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Book Pass"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Available: ${ex.remainingSeats}"),
            const SizedBox(height: 12),
            TextField(
              controller: seatsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Number of seats",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final seats = int.tryParse(seatsCtrl.text.trim()) ?? 0;

              if (seats <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enter a valid seat count")),
                );
                return;
              }

              final latest = ExhibitionData.exhibitions[index];
              final remaining = latest.remainingSeats;

              if (seats > remaining) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Only $remaining seats available")),
                );
                return;
              }

              final totalAmount = seats * latest.pricePerSeat;

              ExhibitionData.exhibitions[index] =
                  latest.copyWith(bookedSeats: latest.bookedSeats + seats);

              Navigator.pop(context);

              final paid = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExhibitionPaymentPage(
                    exhibitionId: latest.id,
                    title: latest.title,
                    venue: latest.venue,
                    dateTime: latest.dateTime,
                    seats: seats,
                    pricePerSeat: latest.pricePerSeat,
                    totalAmount: totalAmount,
                  ),
                ),
              );

              if (!mounted) return;

              if (paid == true) {
                BookingData.exhibitionBookings.add({
                  "customerName": "Demo User",
                  "exhibitionTitle": latest.title,
                  "seats": seats,
                  "pricePerSeat": latest.pricePerSeat,
                  "totalAmount": totalAmount,
                  "bookedAt": DateTime.now(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pass confirmed")),
                );

                Navigator.pop(context, true);
              } else {
                final currentBooked =
                    ExhibitionData.exhibitions[index].bookedSeats;
                final newBooked =
                    (currentBooked - seats) < 0 ? 0 : (currentBooked - seats);

                ExhibitionData.exhibitions[index] =
                    ExhibitionData.exhibitions[index].copyWith(bookedSeats: newBooked);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment cancelled")),
                );

                setState(() {});
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
