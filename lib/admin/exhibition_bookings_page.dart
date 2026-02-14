import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/backend_service.dart';
import 'package:artiva/backend/models.dart';

class ExhibitionBookingsPage extends StatefulWidget {
  const ExhibitionBookingsPage({super.key});

  @override
  State<ExhibitionBookingsPage> createState() => _ExhibitionBookingsPageState();
}

class _ExhibitionBookingsPageState extends State<ExhibitionBookingsPage> {
  final BackendService backend = BackendService();

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Exhibition Bookings",

      body: FutureBuilder<List<ExhibitionBooking>>(
        future: backend.getAllExhibitionBookings(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                "Error: ${snap.error.toString().replaceFirst('Exception: ', '')}",
              ),
            );
          }

          final bookings = snap.data ?? [];

          if (bookings.isEmpty) {
            return const Center(child: Text("No exhibition bookings yet"));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (_, i) {
                final b = bookings[i];

                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white, // Removes M3 purple tint
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C1A).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.confirmation_number,
                        color: Color(0xFFFF8C1A),
                      ),
                    ),
                    title: Text(
                      b.exhibitionTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "Customer: ${b.customerName}\n"
                        "Email: ${b.customerEmail}\n"
                        "Exhibition ID: ${b.exhibitionId}\n"
                        "Venue: ${b.venue}\n"
                        "Seats: ${b.seats}\n"
                        "Price/Seat: ₹${b.pricePerSeat}  •  Total: ₹${b.totalAmount}\n"
                        "Booked: ${_formatDateTime(b.bookedAt)}",
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
