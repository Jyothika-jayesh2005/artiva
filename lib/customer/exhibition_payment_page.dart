import 'package:artiva/customer/profile/my_passes.dart';
import 'package:flutter/material.dart';
import '../widgets/customer_scaffold.dart';
import '../data/pass_data.dart';
import '../data/booking_data.dart';

class ExhibitionPaymentPage extends StatelessWidget {
  final String exhibitionId;
  final String title;
  final String venue;
  final DateTime dateTime;
  final int seats;
  final int pricePerSeat;
  final int totalAmount;

  const ExhibitionPaymentPage({
    super.key,
    required this.exhibitionId,
    required this.title,
    required this.venue,
    required this.dateTime,
    required this.seats,
    required this.pricePerSeat,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Payment",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Exhibition Pass"),
            _infoRow("Event", title),
            _infoRow("Venue", venue),
            _infoRow("Seats", seats.toString()),
            _infoRow("Date", _formatDateTime(dateTime)),
            const SizedBox(height: 6),
            _infoRow("Price / Seat", "₹$pricePerSeat"),
            _infoRow("Total Amount", "₹$totalAmount"),
            const SizedBox(height: 24),
            const Text(
              "Scan the QR code using any UPI app",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "Google Pay • PhonePe • Paytm • BHIM",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Complete the payment and tap Confirm",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _success(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Confirm Payment",
                  style: TextStyle(
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

  void _success(BuildContext context) {
    final now = DateTime.now();

    // ✅ STOP DUPLICATE SAVE (if already paid for same exhibition at same time)
    final alreadySaved = PassData.myPasses.any((p) =>
        p["exhibitionId"] == exhibitionId &&
        p["dateTime"] == dateTime &&
        p["seats"] == seats);

    if (alreadySaved) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Already Confirmed"),
          content: const Text("This pass is already saved."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // ✅ CUSTOMER SIDE (My Passes)
    PassData.myPasses.add({
      "exhibitionId": exhibitionId,
      "title": title,
      "venue": venue,
      "dateTime": dateTime,
      "seats": seats,
      "pricePerSeat": pricePerSeat,
      "totalAmount": totalAmount,
      "paidAt": now,
    });

    // ✅ ADMIN SIDE (Booking Overview)
    BookingData.exhibitionBookings.add({
      "customerName": "Demo User", // replace later with real user session
      "customerEmail": "demo@example.com",
      "exhibitionId": exhibitionId,
      "exhibitionTitle": title,
      "venue": venue,
      "seats": seats,
      "pricePerSeat": pricePerSeat,
      "totalAmount": totalAmount,
      "bookedAt": now,
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Payment Successful"),
        content: const Text("Your exhibition pass is confirmed."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MyPassesPage()),
                (route) => route.isFirst,
              );
            },
            child: const Text(
              "View Passes",
              style: TextStyle(color: Color(0xFFE16417)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
