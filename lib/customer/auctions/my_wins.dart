import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/customer/auctions/auction_payment.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              auction.artImageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Winning Bid: ₹${auction.currentBid}",
                  style: const TextStyle(
                    color: Color(0xFFE16417),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isPending)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AuctionPaymentPage(auction: auction),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE16417),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                "PAY NOW",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }
}
