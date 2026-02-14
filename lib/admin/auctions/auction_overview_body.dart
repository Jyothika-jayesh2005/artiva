import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/admin/auctions/admin_auction_detail.dart';

class AuctionOverviewBody extends StatelessWidget {
  const AuctionOverviewBody({super.key});

  static const Color accent = Color(0xFFFF8C1A);

  @override
  Widget build(BuildContext context) {
    final AuctionService auctionService = AuctionService();

    return StreamBuilder<List<Auction>>(
      stream: auctionService.getAuctions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final auctions = snapshot.data ?? [];
        if (auctions.isEmpty) {
          return const Center(child: Text("No auctions found"));
        }

        // We can sort them or just show them all.
        // For overview, maybe just showing them in default order (usually creation or start time) is fine.
        // Or we could stick to the "All" view logic.

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: auctions.length,
          itemBuilder: (context, index) {
            final auction = auctions[index];
            return _buildAuctionCard(context, auction);
          },
        );
      },
    );
  }

  Widget _buildAuctionCard(BuildContext context, Auction auction) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminAuctionDetail(auction: auction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFFF3E8,
                ).withOpacity(0.95), // light orange like exhibition
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black12),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Current Bid: ₹${auction.currentBid}",
                          style: const TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            AuctionStatus displayStatus = auction.status;
                            if (auction.status == AuctionStatus.scheduled ||
                                auction.status == AuctionStatus.live) {
                              if (now.isBefore(auction.startTime))
                                displayStatus = AuctionStatus.scheduled;
                              else if (now.isAfter(auction.endTime))
                                displayStatus = AuctionStatus.ended;
                              else
                                displayStatus = AuctionStatus.live;
                            }

                            return Text(
                              "Status: ${displayStatus.name.toUpperCase()}",
                              style: TextStyle(
                                color: _getStatusColor(displayStatus),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AuctionStatus s) {
    switch (s) {
      case AuctionStatus.scheduled:
        return Colors.blue;
      case AuctionStatus.live:
        return Colors.red;
      case AuctionStatus.ended:
        return Colors.orange;
      case AuctionStatus.sold:
        return Colors.green;
    }
  }
}
