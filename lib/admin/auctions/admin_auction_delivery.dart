import 'package:flutter/material.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/widgets/admin_scaffold.dart';

class AdminAuctionDeliveryPage extends StatefulWidget {
  const AdminAuctionDeliveryPage({super.key});

  @override
  State<AdminAuctionDeliveryPage> createState() =>
      _AdminAuctionDeliveryPageState();
}

class _AdminAuctionDeliveryPageState extends State<AdminAuctionDeliveryPage> {
  final AuctionService _service = AuctionService();
  String _statusFilter = "All"; // All / Pending / Shipped / Delivered

  // Filter logic using effectiveDeliveryStatus
  bool _matchesFilter(Auction a) {
    if (a.status != AuctionStatus.sold) return false;
    if (_statusFilter == "All") return true;

    final status = a.effectiveDeliveryStatus.name.toLowerCase();
    return status == _statusFilter.toLowerCase();
  }

  // ✅ Modern Stat Card
  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Dashboard Overview Section
  Widget _buildOverview(List<Auction> auctions) {
    int pending = 0;
    int shipped = 0;
    int delivered = 0;

    for (var a in auctions) {
      final s = a.effectiveDeliveryStatus;
      if (s == OrderStatus.pending) pending++;
      if (s == OrderStatus.shipped) shipped++;
      if (s == OrderStatus.delivered) delivered++;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          _buildStatCard(
            "Pending",
            pending,
            Colors.orange,
            Icons.timer_outlined,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            "Shipped",
            shipped,
            Colors.blue,
            Icons.local_shipping_outlined,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            "Delivered",
            delivered,
            Colors.green,
            Icons.check_circle_outlined,
          ),
        ],
      ),
    );
  }

  // ✅ Modern Filter Header
  Widget _buildHeader(int total, int shown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Removed redundant "Recent Deliveries" text as per design
            const SizedBox(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                "$shown / $total",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Delivery Details",
      body: StreamBuilder<List<Auction>>(
        stream: _service.getAuctions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final allAuctions = snapshot.data ?? [];
          final soldAuctions = allAuctions
              .where((a) => a.status == AuctionStatus.sold)
              .toList();

          final filtered = soldAuctions.where(_matchesFilter).toList();

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                _buildOverview(soldAuctions), // ✅ Added Stats
                _buildHeader(soldAuctions.length, filtered.length),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No orders found",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        final auction = filtered[index];
                        return _DeliveryCard(auction: auction);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text) {
    final active = _statusFilter == text;
    const accent = Color(0xFFFF8C1A);

    return GestureDetector(
      onTap: () => setState(() => _statusFilter = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? accent : Colors.grey.shade300),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Auction auction;

  const _DeliveryCard({required this.auction});

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return "-";
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}";
  }

  String _formatAddress(Map<String, dynamic>? addr) {
    if (addr == null) return "No address provided";
    return "${addr['name']}, ${addr['address']}\n${addr['city']} - ${addr['pincode']}\nPhone: ${addr['phone']}";
  }

  @override
  Widget build(BuildContext context) {
    final status = auction.effectiveDeliveryStatus;

    Color statusColor = Colors.grey;
    if (status == OrderStatus.shipped) statusColor = Colors.blue;
    if (status == OrderStatus.delivered) statusColor = Colors.green;
    if (status == OrderStatus.pending) statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // ✅ Added Shadow for lift
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300), // ✅ Darker border
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    auction.artImageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auction.artTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Winner: ${auction.highestBidderName}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        "₹${auction.currentBid}",
                        style: const TextStyle(
                          color: Color(0xFFE16417),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // ✅ Modern Dates Row
            Row(
              children: [
                Expanded(
                  child: _dateItem(
                    "Sold On",
                    _formatDateTime(auction.paymentDate ?? auction.createdAt),
                    Icons.calendar_today_outlined,
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey[200]),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _dateItem(
                      "Est. Delivery",
                      _formatDateTime(auction.estimatedDeliveryDate),
                      Icons.local_shipping_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              "SHIPPING ADDRESS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatAddress(auction.shippingAddress),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
