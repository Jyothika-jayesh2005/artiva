import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/backend_service.dart';
import 'package:artiva/backend/models.dart';

class ArtworkOrdersPage extends StatefulWidget {
  const ArtworkOrdersPage({super.key});

  @override
  State<ArtworkOrdersPage> createState() => _ArtworkOrdersPageState();
}

class _ArtworkOrdersPageState extends State<ArtworkOrdersPage> {
  final BackendService backend = BackendService();

  // ✅ UI filter state (PAID removed)
  String _statusFilter = "All"; // All / Pending / Shipped / Delivered

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }

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

  // ✅ Match your OrderStatus enum to chip labels
  String _statusName(OrderStatus s) => s.name; // pending/shipped/delivered...

  bool _matchesStatus(ArtworkOrder o) {
    if (_statusFilter == "All") return true;

    final s = _statusName(o.status).toLowerCase().trim();
    final want = _statusFilter.toLowerCase().trim();

    return s == want;
  }

  List<ArtworkOrder> _applyFilters(List<ArtworkOrder> orders) {
    return orders.where(_matchesStatus).toList();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        // ✅ Paid removed
        final options = ["All", "Pending", "Shipped", "Delivered"];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Filter by Status",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((t) {
                  final selected = _statusFilter == t;
                  return ListTile(
                    title: Text(t),
                    trailing: selected ? const Icon(Icons.check) : null,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _statusFilter = t);
                    },
                  );
                }),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Artwork Orders",
      
      body: FutureBuilder<List<ArtworkOrder>>(
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
          final filtered = _applyFilters(orders);

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ✅ FILTER UI HEADER (Search removed)
                _filterHeader(total: orders.length, shown: filtered.length),

                const SizedBox(height: 14),

                if (orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text("No artwork orders yet")),
                  )
                else if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        "No orders found.\nTry changing filters.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...filtered.map(_orderCard).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterHeader({required int total, required int shown}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Filter button only (Search removed)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.filter_alt_rounded, color: Colors.black54),
                    SizedBox(width: 10),
                    Text(
                      "Filter orders",
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.tune, color: Colors.black54),
              tooltip: "Filter",
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ✅ Status chips row (Paid removed)
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip("All"),
              const SizedBox(width: 10),
              _chip("Pending"),
              const SizedBox(width: 10),
              _chip("Shipped"),
              const SizedBox(width: 10),
              _chip("Delivered"),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Showing $shown of $total",
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _chip(String text) {
    final active = _statusFilter == text;
    const accent = Color(0xFFFF8C1A);

    return GestureDetector(
      onTap: () => setState(() => _statusFilter = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? accent.withOpacity(0.18) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? accent : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? accent : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _orderCard(ArtworkOrder o) {
    final addressText = _formatOrderAddress(o);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
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
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  try {
                    await backend.updateOrderStatus(o.id, v);
                    if (mounted) setState(() {});
                    _snack("Status updated to ${v.name}");
                  } catch (e) {
                    _snack(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
              ),
            ),
            const Divider(),
            const Text("Delivery Address", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(addressText),
            if ((o.addressId ?? "").trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "Address ID: ${o.addressId}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
