import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

class PassDetailPage extends StatelessWidget {
  final Map<String, dynamic> pass;

  const PassDetailPage({super.key, required this.pass});

  @override
  Widget build(BuildContext context) {
    final title = (pass["title"] ?? "-").toString();
    final venue = (pass["venue"] ?? "-").toString();
    final seats = (pass["seats"] ?? 0).toString();
    final pricePerSeat = (pass["pricePerSeat"] ?? 0).toString();
    final totalAmount = (pass["totalAmount"] ?? 0).toString();

    final DateTime? dt = pass["dateTime"] is DateTime ? pass["dateTime"] : null;
    final DateTime? paidAt = pass["paidAt"] is DateTime ? pass["paidAt"] : null;

    return CustomerScaffold(
      currentIndex: -1,
      title: "Your Pass",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _row(Icons.location_on, venue),
              const SizedBox(height: 8),
              _row(Icons.calendar_today, dt == null ? "-" : _formatDateTime(dt)),
              const SizedBox(height: 8),
              _row(Icons.event_seat, "Seats: $seats"),

              const SizedBox(height: 16),
              const Divider(),

              const SizedBox(height: 10),
              const Text("Payment", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _kv("Price / Seat", "₹$pricePerSeat"),
              _kv("Total", "₹$totalAmount"),
              _kv("Paid At", paidAt == null ? "-" : _formatDateTime(paidAt)),

              const SizedBox(height: 18),

              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    size: 140,
                    color: Color(0xFFE16417),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Show this QR at the entry gate",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.black54)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
