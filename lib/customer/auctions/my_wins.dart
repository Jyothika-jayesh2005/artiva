import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/customer/auctions/auction_payment.dart';
import 'package:artiva/customer/auctions/order_tracking_page.dart'; // ✅ Added import

class MyWinsScreen extends StatefulWidget {
  const MyWinsScreen({super.key});

  @override
  State<MyWinsScreen> createState() => _MyWinsScreenState();
}

class _MyWinsScreenState extends State<MyWinsScreen> {
  final AuctionService _auctionService = AuctionService();

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    if (user == null) {
      return const CustomerScaffold(
        currentIndex: -1,
        title: "My Wins",
        body: Center(child: Text("Please login to see your wins")),
      );
    }

    return CustomerScaffold(
      currentIndex: 2, // Highlight Auctions tab
      title: "My Auction Wins",
      showBackButton: true,
      body: StreamBuilder<List<Auction>>(
        stream: _auctionService.getAuctions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final myWins = snapshot.data!
              .where(
                (a) =>
                    a.highestBidderId == user.uid &&
                    (a.status == AuctionStatus.ended ||
                        a.status == AuctionStatus.pending_payment ||
                        a.status == AuctionStatus.sold ||
                        (a.status == AuctionStatus.live &&
                            DateTime.now().isAfter(a.endTime))),
              )
              .toList();

          if (myWins.isEmpty) {
            return const Center(
              child: Text("You haven't won any auctions yet."),
            );
          }

          final pending = myWins
              .where((a) => a.status != AuctionStatus.sold)
              .toList();
          final purchased = myWins
              .where((a) => a.status == AuctionStatus.sold)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _buildHeader("Pending Payment"),
                ...pending.map((a) => _buildWinCard(a, isPending: true)),
                const SizedBox(height: 24),
              ],
              if (purchased.isNotEmpty) ...[
                _buildHeader("Purchased"),
                ...purchased.map((a) => _buildWinCard(a, isPending: false)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWinCard(Auction auction, {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPending
            ? Border.all(
                color: const Color(0xFFFF8C1A).withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    auction.artImageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPending
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPending ? "PAYMENT PENDING" : "PURCHASED",
                          style: TextStyle(
                            color: isPending
                                ? const Color(0xFFFF8C1A)
                                : Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        auction.artTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Winning Bid",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "₹${auction.currentBid}",
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C1A).withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuctionPaymentPage(auction: auction),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C1A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Complete Payment",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            )
          else
            _buildTrackingInfo(auction), // ✅ Added Tracking info
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "-";
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  Widget _buildTrackingInfo(Auction auction) {
    final status = auction.effectiveDeliveryStatus;
    Color color = Colors.green;
    String statusText = "Order Confirmed";

    if (status == OrderStatus.shipped) {
      statusText = "Shipped";
      color = Colors.blue;
    } else if (status == OrderStatus.delivered) {
      statusText = "Delivered";
      color = Colors.green;
    } else if (status == OrderStatus.pending) {
      statusText = "Processing";
      color = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingPage(auction: auction),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: color.withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sold On",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDate(auction.paymentDate ?? auction.createdAt),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end, // Align to right
                  children: [
                    Text(
                      "Est. Delivery",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatDate(auction.estimatedDeliveryDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
