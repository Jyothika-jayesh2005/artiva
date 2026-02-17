import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/customer/auctions/my_wins.dart';
import 'package:artiva/widgets/auction_list_timer.dart';
import 'package:artiva/customer/profile/profile_settings.dart';

class AuctionDetailScreen extends StatefulWidget {
  final Auction auction;
  const AuctionDetailScreen({super.key, required this.auction});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final AuctionService _auctionService = AuctionService();
  final TextEditingController _bidController = TextEditingController();
  late Stream<Auction> _auctionStream; // ✅ Stream
  late Timer _timer;
  bool _isSubmitting = false;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _auctionStream = _auctionService.getAuctionStream(
      widget.auction.id,
    ); // ✅ Init Stream
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild to update time
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

  void _placeBidSheet(Auction auction) {
    // ✅ Accept current auction
    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to place a bid")),
      );
      return;
    }

    // ✅ Enforce Phone Number
    if (user.phone.isEmpty || user.phone.length < 10) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Phone Number Required"),
          content: const Text(
            "To place a bid, we need a valid phone number for verification. Please update your profile.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsPage(),
                  ),
                );
              },
              child: const Text("Update Profile"),
            ),
          ],
        ),
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
                "Minimum bid: ₹${auction.currentBid + auction.minIncrement}",
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
    return StreamBuilder<Auction>(
      stream: _auctionStream,
      initialData: widget.auction,
      builder: (context, snapshot) {
        final auction = snapshot.data ?? widget.auction;

        // Recalculate remaining time for accurate display if endTime changed
        // (Optional but good for correctness)
        final effectiveRemaining = auction.endTime.difference(DateTime.now());
        final bool hasEnded = effectiveRemaining.isNegative;

        // ✅ Real-time Winner Check
        final bool isWinner =
            auction.highestBidderId == authService.currentUser?.uid;

        final artImage = auction.artImageUrl.isNotEmpty
            ? auction.artImageUrl
            : "";

        return Scaffold(
          backgroundColor: const Color(0xFFFFF1DC),
          body: Stack(
            children: [
              // Content Scroll
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  children: [
                    // 1. Full Image Top
                    SizedBox(
                      width: double.infinity,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.65,
                          minHeight: 200,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _imageWidget(artImage, fit: BoxFit.cover),
                            // Timer Overlay (Top Right of Image)
                            if (auction.status == AuctionStatus.live)
                              Positioned(
                                top: MediaQuery.of(context).padding.top + 10,
                                right: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: AuctionListTimer(
                                    endTime: auction.endTime,
                                    compact: true,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Info Container (Overlapping)
                    Container(
                      transform: Matrix4.translationValues(0, -30, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF1DC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Title
                          Text(
                            auction.artTitle,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Winner Feedback (if ended)
                          if (hasEnded) ...[
                            _buildWinnerFeedback(
                              isWinner,
                            ), // ✅ Uses updated isWinner
                            const SizedBox(height: 24),
                          ],

                          // Artist Section
                          const Text(
                            "Artist",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(
                                    0xFFE16417,
                                  ).withOpacity(0.1),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFFE16417),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        auction.artistName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      Text(
                                        "Creator",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Description & About Piece (Merged)
                          const Text(
                            "About the Artwork",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Merge text
                              String fullDesc = auction.description;
                              if (auction.aboutPiece.isNotEmpty) {
                                fullDesc += "\n\n${auction.aboutPiece}";
                              }

                              const int truncationLimit = 150;
                              final bool isLong =
                                  fullDesc.length > truncationLimit;
                              final String textToShow =
                                  isLong && !_isDescriptionExpanded
                                  ? "${fullDesc.substring(0, truncationLimit)}..."
                                  : fullDesc;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    textToShow,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (isLong)
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isDescriptionExpanded =
                                              !_isDescriptionExpanded;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          _isDescriptionExpanded
                                              ? "Show Less"
                                              : "Read More",
                                          style: const TextStyle(
                                            color: Color(0xFFE16417),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Specs Chips (Size, Start Bid, Incr)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (auction.size.isNotEmpty) ...[
                                  _specChip(auction.size, "Size", false),
                                  const SizedBox(width: 12),
                                ],
                                _specChip(
                                  "₹${auction.startingBid}",
                                  "Start Bid",
                                  true,
                                ),
                                const SizedBox(width: 12),
                                _specChip(
                                  "₹${auction.minIncrement}",
                                  "Increment",
                                  false,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Divider(),
                          const SizedBox(height: 24),

                          // Bid History
                          const Text(
                            "Bid History",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildBidHistory(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Back Button (Top Left)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Bottom Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child:
                    _buildBottomAction(hasEnded, isWinner, auction) ??
                    const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildBottomAction(bool hasEnded, bool isWinner, Auction auction) {
    if (hasEnded) {
      if (isWinner && auction.status != AuctionStatus.sold) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1DC),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyWinsScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Go to My Wins to Pay",
                  style: TextStyle(
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
      return null;
    }

    // Active Auction Bottom Bar
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DC),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Current Bid",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${auction.currentBid}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () => _placeBidSheet(auction),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE16417), Color(0xFFE16417)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE16417).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Place Bid",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _specChip(String label, String subLabel, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE16417) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? const Color(0xFFE16417) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.white70 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.image_not_supported, size: 44)),
      );
    }
    if (path.startsWith("http")) {
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
      );
    }
    if (path.startsWith("assets/")) {
      return Image.asset(path, fit: fit);
    }
    return Image.file(File(path), fit: fit);
  }
}
