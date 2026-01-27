import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';

import 'package:artiva/backend/backend_service.dart';
import 'package:artiva/backend/models.dart';

class BookingOverviewPage extends StatefulWidget {
  const BookingOverviewPage({super.key});

  @override
  State<BookingOverviewPage> createState() => _BookingOverviewPageState();
}

class _BookingOverviewPageState extends State<BookingOverviewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final BackendService backend = BackendService();

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

  // ---------------- EXHIBITION BOOKINGS ----------------

  Widget _exhibitionBookingsTab() {
    return FutureBuilder<List<ExhibitionBooking>>(
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
    );
  }

  // ---------------- ARTWORK ORDERS ----------------

  List<OrderStatus> _allowedOrderStatuses() {
    return OrderStatus.values;
  }

  OrderStatus _safeDropdownValue(OrderStatus current) {
    final allowed = _allowedOrderStatuses();
    if (allowed.contains(current)) return current;
    return allowed.isNotEmpty ? allowed.first : current;
  }

  Widget _artworkOrdersTab() {
    return FutureBuilder<List<ArtworkOrder>>(
      future: backend.getAllOrders(),
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

        final orders = snap.data ?? [];

        if (orders.isEmpty) {
          return const Center(child: Text("No artwork orders yet"));
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];

              final addressText = _formatOrderAddress(o);
              final allowedStatuses = _allowedOrderStatuses();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.shopping_bag),
                        ),
                        title: Text(
                          o.artTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Customer: ${o.customerName}\n"
                          "Email: ${o.customerEmail}\n"
                          "Qty: ${o.quantity}  •  Price: ${o.price}\n"
                          "Status: ${o.status.name}\n"
                          "Ordered: ${_formatDateTime(o.orderedAt)}",
                        ),
                        trailing: DropdownButton<OrderStatus>(
                          value: _safeDropdownValue(o.status),
                          underline: const SizedBox(),
                          items: allowedStatuses
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) async {
                            if (v == null) return;
                            try {
                              await backend.updateOrderStatus(o.id, v);
                              if (mounted) setState(() {});
                              _snack("Status updated to ${v.name}");
                            } catch (e) {
                              _snack(
                                e.toString()
                                    .replaceFirst('Exception: ', ''),
                              );
                            }
                          },
                        ),
                      ),

                      const Divider(),
                      const Text(
                        "Delivery Address",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(addressText),

                      if ((o.addressId ?? "").trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          "Address ID: ${o.addressId}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------- HELPERS ----------------

  String _formatOrderAddress(ArtworkOrder o) {
    final snap = o.addressSnapshot;

    if (snap != null && snap.isNotEmpty) {
      final name = (snap["name"] ?? "").toString().trim();
      final phone = (snap["phone"] ?? "").toString().trim();
      final address = (snap["address"] ?? "").toString().trim();
      final city = (snap["city"] ?? "").toString().trim();
      final district = (snap["district"] ?? "").toString().trim();
      final pincode = (snap["pincode"] ?? "").toString().trim();

      final line2Parts = <String>[
        if (city.isNotEmpty) city,
        if (district.isNotEmpty) district,
        if (pincode.isNotEmpty) pincode,
      ];

      final built = [
        if (name.isNotEmpty) "$name${phone.isNotEmpty ? ", $phone" : ""}",
        if (address.isNotEmpty) address,
        if (line2Parts.isNotEmpty) line2Parts.join(", "),
      ].join("\n");

      if (built.trim().isNotEmpty) return built;
    }

    return (o.address ?? "-");
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
