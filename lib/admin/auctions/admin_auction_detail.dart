import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/backend/user_service.dart';
import 'package:artiva/admin/auctions/admin_notify_winner.dart';

class AdminAuctionDetail extends StatefulWidget {
  final Auction auction;
  const AdminAuctionDetail({super.key, required this.auction});

  @override
  State<AdminAuctionDetail> createState() => _AdminAuctionDetailState();
}

class _AdminAuctionDetailState extends State<AdminAuctionDetail> {
  final AuctionService _auctionService = AuctionService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool isEndedByTime = now.isAfter(widget.auction.endTime);
    final bool hasWinner =
        widget.auction.highestBidderId != null &&
        (widget.auction.status == AuctionStatus.ended ||
            widget.auction.status == AuctionStatus.sold ||
            isEndedByTime);

    return AdminScaffold(
      title: "Auction Detail",
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.auction.artImageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.auction.artTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Current Bid: ₹${widget.auction.currentBid}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFFF8C1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Starts: ${widget.auction.startTime.toString().split('.')[0]}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "Ends: ${widget.auction.endTime.toString().split('.')[0]}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (hasWinner) _buildWinnerPanel(),
            const SizedBox(height: 32),
            const Text(
              "Bid History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildBidHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final now = DateTime.now();
    AuctionStatus displayStatus = widget.auction.status;

    if (displayStatus == AuctionStatus.scheduled ||
        displayStatus == AuctionStatus.live) {
      if (now.isBefore(widget.auction.startTime)) {
        displayStatus = AuctionStatus.scheduled;
      } else if (now.isAfter(widget.auction.endTime)) {
        displayStatus = AuctionStatus.ended;
      } else {
        displayStatus = AuctionStatus.live;
      }
    }

    final Color statusColor = _getStatusColor(displayStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 12, color: statusColor),
          const SizedBox(width: 8),
          Text(
            displayStatus.name.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerPanel() {
    return StreamBuilder<AppUser?>(
      stream: _userService.watchUserProfile(widget.auction.highestBidderId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final winner = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Winner Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _uInfo(Icons.person, "Name", winner.name),
              _uInfo(Icons.email, "Email", winner.email),
              _uInfo(Icons.phone, "Phone", winner.phone),
              const SizedBox(height: 24),
              if (widget.auction.status != AuctionStatus.sold)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminNotifyWinner(
                          auction: widget.auction,
                          winner: winner,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text(
                      "NOTIFY UNPAID WINNER",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C1A),
                    ),
                  ),
                )
              else
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "PAYMENT COMPLETED",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _uInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBidHistory() {
    return StreamBuilder<List<Bid>>(
      stream: _auctionService.getBids(widget.auction.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final bids = snapshot.data!;
        if (bids.isEmpty) return const Text("No bids yet.");

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bids.length,
          itemBuilder: (context, index) {
            final b = bids[index];
            return ListTile(
              title: Text(b.userName),
              subtitle: Text(b.createdAt.toString().split('.')[0]),
              trailing: Text(
                "₹${b.amount}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
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
