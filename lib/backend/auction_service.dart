import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/backend/models.dart';

class AuctionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of all active/scheduled auctions
  Stream<List<Auction>> getAuctions() {
    return _db
        .collection("auctions")
        .orderBy("startTime", descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Auction.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Stream of bids for a specific auction
  Stream<List<Bid>> getBids(String auctionId) {
    return _db
        .collection("auctions")
        .doc(auctionId)
        .collection("bids")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Bid.fromMap(doc.id, doc.data())).toList(),
        );
  }

  // Place a bid using a transaction
  Future<void> placeBid({
    required String auctionId,
    required int amount,
    required String userId,
    required String userName,
  }) async {
    final auctionRef = _db.collection("auctions").doc(auctionId);
    final bidsRef = auctionRef.collection("bids");

    return _db.runTransaction((tx) async {
      final auctionDoc = await tx.get(auctionRef);
      if (!auctionDoc.exists) throw Exception("Auction not found.");

      final auction = Auction.fromMap(auctionDoc.id, auctionDoc.data()!);

      // Validate auction status
      // We allow bidding if it's Live or if it's Scheduled but the time has passed
      final now = DateTime.now();
      if (now.isBefore(auction.startTime))
        throw Exception("Auction hasn't started yet.");
      if (now.isAfter(auction.endTime)) throw Exception("Auction has ended.");
      if (auction.status == AuctionStatus.ended ||
          auction.status == AuctionStatus.sold) {
        throw Exception("Auction is already closed.");
      }

      // Validate bid amount
      if (amount <= auction.currentBid) {
        throw Exception(
          "Bid must be higher than current bid (₹${auction.currentBid}).",
        );
      }
      if (amount < (auction.currentBid + auction.minIncrement)) {
        throw Exception(
          "Minimum increment is ₹${auction.minIncrement}. Minimum bid: ₹${auction.currentBid + auction.minIncrement}.",
        );
      }

      // Update auction doc
      tx.update(auctionRef, {
        "currentBid": amount,
        "highestBidderId": userId,
        "highestBidderName": userName,
        "status": "live", // Ensure status is live once bidding starts
      });

      // Add bid doc
      final newBidRef = bidsRef.doc();
      tx.set(newBidRef, {
        "amount": amount,
        "userId": userId,
        "userName": userName,
        "createdAt": FieldValue.serverTimestamp(),
      });
    });
  }

  // Mark auction as sold (post-payment)
  Future<void> markAsSold(String auctionId) async {
    await _db.collection("auctions").doc(auctionId).update({
      "status": AuctionStatus.sold.name,
    });
  }

  Future<Auction?> getAuction(String id) async {
    final doc = await _db.collection("auctions").doc(id).get();
    if (!doc.exists) return null;
    return Auction.fromMap(doc.id, doc.data()!);
  }

  // Lazy update for ended auctions
  Future<void> updateEndedAuctions() async {
    final now = DateTime.now();

    // Query auctions that are supposedly live/scheduled but time passed
    // Note: complex queries might need composite index.
    // We'll fetch active ones and filter in memory if list is small,
    // or use a query. Here we rely on 'live' or 'scheduled' status.
    final snap = await _db
        .collection("auctions")
        .where("status", whereIn: ["live", "scheduled"])
        .get();

    final batch = _db.batch();
    bool changed = false;

    for (var doc in snap.docs) {
      final a = Auction.fromMap(doc.id, doc.data());
      if (now.isAfter(a.endTime)) {
        // Needs update
        int finalPrice = a.startingBid;
        if (a.highestBidderId != null && a.currentBid > 0) {
          finalPrice = a.currentBid;
        }

        batch.update(doc.reference, {
          "status": "ended",
          "finalPrice": finalPrice,
        });
        changed = true;
      }
    }

    if (changed) {
      await batch.commit();
    }
  }
}
