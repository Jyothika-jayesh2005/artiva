import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import '../data/booking_data.dart';
import '../data/order_data.dart';

class BookingOverviewPage extends StatefulWidget {
  const BookingOverviewPage({super.key});

  @override
  State<BookingOverviewPage> createState() => _BookingOverviewPageState();
}

class _BookingOverviewPageState extends State<BookingOverviewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Customer Activity",
      showBack: true,
      body: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tab,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.black.withOpacity(0.06),
              ),
              tabs: const [
                Tab(text: "Exhibition Bookings"),
                Tab(text: "Artwork Orders"),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _exhibitionBookingsTab(),
                _artworkOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ EXHIBITION BOOKINGS (READ ONLY) ------------------
  Widget _exhibitionBookingsTab() {
    final bookings = BookingData.exhibitionBookings;

    if (bookings.isEmpty) {
      return const Center(child: Text("No exhibition bookings yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final b = bookings[i];

        final customerName = _asString(b["customerName"], "Unknown");
        final customerEmail = _asString(b["customerEmail"], "-");

        // Your saved map uses "exhibitionTitle"
        final exhibitionTitle = _asString(b["exhibitionTitle"], "Exhibition");
        final exhibitionId = _asString(b["exhibitionId"], "-");
        final venue = _asString(b["venue"], "-");

        final seats = _asInt(b["seats"], 0);
        final pricePerSeat = _asInt(b["pricePerSeat"], 0);
        final totalAmount = _asInt(b["totalAmount"], 0);

        final bookedAt = _toDateTime(b["bookedAt"]);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.confirmation_number),
              ),
              title: Text(
                exhibitionTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Customer: $customerName\n"
                  "Email: $customerEmail\n"
                  "Exhibition ID: $exhibitionId\n"
                  "Venue: $venue\n"
                  "Seats: $seats\n"
                  "Price/Seat: ₹$pricePerSeat  •  Total: ₹$totalAmount\n"
                  "Booked: ${_formatDateTime(bookedAt)}",
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------ ARTWORK ORDERS (READ ONLY) ------------------
  Widget _artworkOrdersTab() {
    final orders = OrderData.orders;

    if (orders.isEmpty) {
      return const Center(child: Text("No artwork orders yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];

        final customerName = _asString(o["customerName"], "Unknown");
        final customerEmail = _asString(o["customerEmail"], "-");
        final artTitle = _asString(o["artTitle"], "Artwork");
        final quantity = _asInt(o["quantity"], 1);
        final price = _asString(o["price"], "-");

        final orderedAt = _toDateTime(o["orderedAt"]);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
            title: Text(
              artTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "Customer: $customerName\n"
                "Email: $customerEmail\n"
                "Qty: $quantity  •  Price: $price\n"
                "Ordered: ${_formatDateTime(orderedAt)}",
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------ HELPERS ------------------

  String _asString(dynamic v, String fallback) {
    final s = (v ?? "").toString().trim();
    return s.isEmpty ? fallback : s;
  }

  int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  // Handles DateTime, ISO String, or null safely
  DateTime _toDateTime(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
