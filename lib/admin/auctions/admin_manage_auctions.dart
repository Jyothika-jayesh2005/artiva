import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/admin/auctions/admin_add_edit_auction.dart';
import 'package:artiva/admin/auctions/admin_auction_detail.dart';

class AdminManageAuctions extends StatefulWidget {
  const AdminManageAuctions({super.key});

  @override
  State<AdminManageAuctions> createState() => _AdminManageAuctionsState();
}

class _AdminManageAuctionsState extends State<AdminManageAuctions>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuctionService _auctionService = AuctionService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _auctionService.updateEndedAuctions(); // ✅ Lazy update on init
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Manage Auctions",
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFFF8C1A),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFFF8C1A),
            indicatorSize:
                TabBarIndicatorSize.tab, // Ensure full width indicator
            tabs: const [
              Tab(text: "Scheduled"),
              Tab(text: "Live"),
              Tab(text: "Ended"),
              Tab(text: "Sold"),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Auction>>(
              stream: _auctionService.getAuctions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final auctions = snapshot.data!;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAuctionGrid(
                      auctions
                          .where(
                            (a) =>
                                (a.status == AuctionStatus.scheduled ||
                                    a.status == AuctionStatus.live) &&
                                DateTime.now().isBefore(a.startTime),
                          )
                          .toList(),
                    ),
                    _buildAuctionGrid(
                      auctions.where((a) {
                        final now = DateTime.now();
                        return (a.status == AuctionStatus.live ||
                                a.status == AuctionStatus.scheduled) &&
                            now.isAfter(a.startTime) &&
                            now.isBefore(a.endTime);
                      }).toList(),
                    ),
                    _buildAuctionGrid(
                      auctions.where((a) {
                        final now = DateTime.now();
                        return a.status == AuctionStatus.ended ||
                            (a.status != AuctionStatus.sold &&
                                now.isAfter(a.endTime));
                      }).toList(),
                    ),
                    _buildAuctionGrid(
                      auctions
                          .where((a) => a.status == AuctionStatus.sold)
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAddEditAuction()),
        ),
        backgroundColor: const Color(0xFFFF8C1A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAuctionGrid(List<Auction> auctions) {
    if (auctions.isEmpty) {
      return const Center(child: Text("No auctions in this category"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70, // Slightly taller for badges
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: auctions.length,
      itemBuilder: (context, index) {
        final a = auctions[index];
        return _buildAuctionCard(a);
      },
    );
  }

  Widget _buildAuctionCard(Auction a) {
    final now = DateTime.now();
    AuctionStatus displayStatus = a.status;
    if (a.status == AuctionStatus.scheduled || a.status == AuctionStatus.live) {
      if (now.isBefore(a.startTime))
        displayStatus = AuctionStatus.scheduled;
      else if (now.isAfter(a.endTime))
        displayStatus = AuctionStatus.ended;
      else
        displayStatus = AuctionStatus.live;
    }

    final bool isEnded =
        displayStatus == AuctionStatus.ended ||
        displayStatus == AuctionStatus.sold;

    // Determine Final Price
    final int displayPrice = isEnded
        ? (a.finalPrice ??
              (a.highestBidderId != null ? a.currentBid : a.startingBid))
        : a.currentBid;

    // Determine Badge
    Widget? badge;
    if (isEnded && displayStatus != AuctionStatus.sold) {
      if (a.highestBidderId != null) {
        badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            "WINNER",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        );
      } else {
        badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey),
          ),
          child: const Text(
            "NO PARTICIPANTS",
            style: TextStyle(
              fontSize: 9, // Slightly smaller to fit
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminAuctionDetail(auction: a)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  a.artImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.artTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEnded
                        ? "Final: ₹$displayPrice"
                        : "Current: ₹$displayPrice",
                    style: TextStyle(
                      color: isEnded ? Colors.black87 : const Color(0xFFFF8C1A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (badge != null) ...[badge, const SizedBox(height: 4)],
                  if (badge == null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          displayStatus.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getStatusColor(displayStatus),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  if (badge != null)
                    // Show date time for ended if badge is present as per request
                    Text(
                      "Ended: ${_formatDate(a.endTime)}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
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
