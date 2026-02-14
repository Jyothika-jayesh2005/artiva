import 'dart:async';
import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/customer/auctions/my_wins.dart';

class AuctionDetailScreen extends StatefulWidget {
  final Auction auction;
  const AuctionDetailScreen({super.key, required this.auction});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final AuctionService _auctionService = AuctionService();
  final TextEditingController _bidController = TextEditingController();
  late Timer _timer;
  late Duration _remaining;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.auction.endTime.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remaining = widget.auction.endTime.difference(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _bidController.dispose();
    super.dispose();
  }

  void _placeBidSheet() {
    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to place a bid")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Place Your Bid",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Minimum bid: ₹${widget.auction.currentBid + widget.auction.minIncrement}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bidController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  hintText: "Enter amount",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE16417),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Confirm Bid",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitBid() async {
    final user = authService.currentUser!;
    final amount = int.tryParse(_bidController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    Navigator.pop(context); // Close sheet

    try {
      await _auctionService.placeBid(
        auctionId: widget.auction.id,
        amount: amount,
        userId: user.uid,
        userName: user.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bid placed successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _bidController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEnded = _remaining.isNegative;
    final bool isWinner =
        widget.auction.highestBidderId == authService.currentUser?.uid;

    return CustomerScaffold(
      currentIndex: -1,
      title: "Auction Detail",
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Image.network(
                      widget.auction.artImageUrl,
                      width: double.infinity,
                      height: 400,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _buildTimerDisplay(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.auction.artTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasEnded) ...[
                    const SizedBox(height: 16),
                    _buildWinnerFeedback(isWinner),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    "by ${widget.auction.artistName}",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Merged "About the Artwork" section
                  const Text(
                    "About the Artwork",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (widget.auction.description.isNotEmpty) ...[
                    Text(
                      widget.auction.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (widget.auction.size.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.straighten,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Size: ${widget.auction.size}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  if (widget.auction.aboutPiece.isNotEmpty)
                    Text(
                      widget.auction.aboutPiece,
                      style: const TextStyle(
                        fontSize: 16, // Matches the description size
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Current Bid",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          Text(
                            "₹${widget.auction.currentBid}",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE16417),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Starting Bid",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          Text(
                            "₹${widget.auction.startingBid}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  const Text(
                    "Bid History",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBidHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(hasEnded, isWinner),
    );
  }

  Widget? _buildBottomAction(bool hasEnded, bool isWinner) {
    if (hasEnded) {
      if (isWinner && widget.auction.status != AuctionStatus.sold) {
        return _bottomBarButton(
          label: "Go to My Wins to Pay",
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyWinsScreen()),
          ),
        );
      }
      return null;
    }

    return _bottomBarButton(label: "Place Bid", onPressed: _placeBidSheet);
  }

  Widget _bottomBarButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE16417),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerFeedback(bool isWinner) {
    if (isWinner) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE16417), Color(0xFF80431F)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE16417).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text(
              "CONGRATULATIONS!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "You won this auction!",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyWinsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFE16417),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "GO TO MY WINS",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This auction has ended. Better luck next time!",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    if (_remaining.isNegative) {
      return const Text(
        "AUCTION ENDED",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }
    String hours = _remaining.inHours.toString().padLeft(2, '0');
    String minutes = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(
          "$hours:$minutes:$seconds",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBidHistory() {
    return StreamBuilder<List<Bid>>(
      stream: _auctionService.getBids(widget.auction.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final bids = snapshot.data!;
        if (bids.isEmpty) return const Text("No bids yet. Be the first!");

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bids.length > 5 ? 5 : bids.length,
          itemBuilder: (context, index) {
            final bid = bids[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(bid.userName),
              subtitle: Text(bid.createdAt.toString().split('.')[0]),
              trailing: Text(
                "₹${bid.amount}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
