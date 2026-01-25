import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/backend_provider.dart'; // ✅ ADD THIS
import 'package:artiva/backend/models.dart';

class ExhibitionPaymentPage extends StatefulWidget {
  final Exhibition exhibition;
  final int seats;

  const ExhibitionPaymentPage({
    super.key,
    required this.exhibition,
    required this.seats,
  });

  @override
  State<ExhibitionPaymentPage> createState() => _ExhibitionPaymentPageState();
}

class _ExhibitionPaymentPageState extends State<ExhibitionPaymentPage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.seats * widget.exhibition.pricePerSeat;

    return CustomerScaffold(
      currentIndex: -1,
      title: "Payment",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("Exhibition"),
            _row("Title", widget.exhibition.title),
            _row("Venue", widget.exhibition.venue),
            _row("Seats", widget.seats.toString()),
            _row("Price/Seat", "₹${widget.exhibition.pricePerSeat}"),
            _row("Total", "₹$total"),
            const SizedBox(height: 18),

            const Text(
              "Scan the QR code using any UPI app",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 140,
                  color: Color(0xFFE16417),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Google Pay • PhonePe • Paytm • BHIM",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _loading ? "PLEASE WAIT..." : "Confirm Payment",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.grey)),
            Flexible(
              child: Text(
                v,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Future<void> _confirmPayment() async {
    final user = authService.currentUser;
    if (user == null) {
      _snack("Please login first.");
      return;
    }

    setState(() => _loading = true);

    try {
      final bookingId = await backend.bookExhibition(
        exhibitionId: widget.exhibition.id,
        seats: widget.seats,
        customerName: user.name,
        customerEmail: user.email,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Booking Confirmed"),
          content: Text("Your seats are booked.\n\nBooking ID: $bookingId"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.pop(context); // back to detail
      Navigator.pop(context); // back to list
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
