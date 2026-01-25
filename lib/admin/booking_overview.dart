import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';

import 'package:artiva/backend/backend_service.dart'; // ✅ FIXED
import 'package:artiva/backend/models.dart';

class BookingOverviewPage extends StatefulWidget {
  const BookingOverviewPage({super.key});

  @override
  State<BookingOverviewPage> createState() => _BookingOverviewPageState();
}

class _BookingOverviewPageState extends State<BookingOverviewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // ✅ DEFINE BACKEND
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

              final hasReview =
                  (o.rating != null) || ((o.review ?? "").trim().isNotEmpty);

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
                          value: o.status,
                          underline: const SizedBox(),
                          items: OrderStatus.values
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

                      if (hasReview) ...[
                        const Divider(),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              o.rating == null
                                  ? "No rating"
                                  : "${o.rating}/5",
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (o.ratedAt != null)
                              Text(
                                _formatDateTime(o.ratedAt!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        if ((o.review ?? "").trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            "\"${o.review!.trim()}\"",
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async =>
                                await _confirmDeleteReview(o),
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              "Delete Review",
                              style: TextStyle(color: Colors.red),
                            ),
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

  Future<void> _confirmDeleteReview(ArtworkOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Review"),
        content: const Text(
          "This will remove the customer's rating and review. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await backend.deleteOrderReview(order.id);
      if (mounted) setState(() {});
      _snack("Review deleted");
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  "
        "${two(dt.hour)}:${two(dt.minute)}";
  }
}
