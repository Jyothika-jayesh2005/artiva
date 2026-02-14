import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/customer/auctions/auction_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/customer/auctions/my_wins.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuctionService _auctionService = AuctionService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: 2, // Auctions tab is at index 2
      title: "Art Auctions",
      body: Column(
        children: [
          _buildTopBar(),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFE16417),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFE16417),
            tabs: const [
              Tab(text: "Live"),
              Tab(text: "Ended"),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Auction>>(
              stream: _auctionService.getAuctions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final auctions = snapshot.data ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAuctionList(
                      auctions.where((a) {
                        final now = DateTime.now();
                        final isLiveTime =
                            now.isAfter(a.startTime) && now.isBefore(a.endTime);
                        return (a.status == AuctionStatus.live ||
                                a.status == AuctionStatus.scheduled) &&
                            isLiveTime;
                      }).toList(),
                    ),
                    _buildAuctionList(
                      auctions.where((a) {
                        final now = DateTime.now();
                        return a.status == AuctionStatus.ended ||
                            a.status == AuctionStatus.sold ||
                            now.isAfter(a.endTime);
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: const Text(
              "Bid on Rare Pieces",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(authService.currentUser?.uid)
                    .collection('notifications')
                    .where('read', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final bool hasUnread =
                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return IconButton(
                    icon: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFFE16417),
                        ),
                        if (hasUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 8,
                                minHeight: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/notifications'),
                  );
                },
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyWinsScreen()),
                  );
                },
                icon: const Icon(Icons.emoji_events, color: Color(0xFFE16417)),
                label: const Text(
                  "My Wins",
                  style: TextStyle(color: Color(0xFFE16417)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionList(List<Auction> auctions) {
    if (auctions.isEmpty) {
      return const Center(child: Text("No auctions available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: auctions.length,
      itemBuilder: (context, index) {
        final auction = auctions[index];
        return _buildAuctionCard(auction);
      },
    );
  }

  Widget _buildAuctionCard(Auction auction) {
    final now = DateTime.now();
    final bool isTimeLive =
        now.isAfter(auction.startTime) && now.isBefore(auction.endTime);
    final bool isLive =
        (auction.status == AuctionStatus.live ||
            auction.status == AuctionStatus.scheduled) &&
        isTimeLive;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuctionDetailScreen(auction: auction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    auction.artImageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLive ? Colors.red : Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLive ? "LIVE" : "ENDED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.artTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Current Bid",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            "₹${auction.currentBid}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE16417),
                            ),
                          ),
                        ],
                      ),
                      if (isLive)
                        _buildCountdown(auction.endTime)
                      else if (auction.status == AuctionStatus.sold)
                        const Text(
                          "SOLD",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          "CLOSED",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown(DateTime endTime) {
    final now = DateTime.now();
    final diff = endTime.difference(now);

    if (diff.isNegative) return const Text("Ending soon...");

    String hours = diff.inHours.toString().padLeft(2, '0');
    String minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          "Ends in",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Text(
          "$hours:$minutes:$seconds",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
