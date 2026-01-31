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
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.confirmation_number),
                    ),
                    title: Text(
                      b.exhibitionTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Customer: ${b.customerName}\n"
                      "Email: ${b.customerEmail}\n"
                      "Exhibition ID: ${b.exhibitionId}\n"
                      "Venue: ${b.venue}\n"
                      "Seats: ${b.seats}\n"
                      "Price/Seat: ₹${b.pricePerSeat}  •  Total: ₹${b.totalAmount}\n"
                      "Booked: ${_formatDateTime(b.bookedAt)}",
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
