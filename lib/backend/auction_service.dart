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
          auction.status == AuctionStatus.sold ||
          auction.status == AuctionStatus.pending_payment ||
          auction.status == AuctionStatus.unsold) {
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
  Future<void> markAsSold(
    String auctionId, {
    Map<String, dynamic>? shippingAddress,
  }) async {
    final data = <String, dynamic>{
      "status": "sold",
      "paymentDueAt": FieldValue.delete(), // Remove deadline
      "paymentDate": FieldValue.serverTimestamp(), // ✅ Added
    };

    if (shippingAddress != null) {
      data["shippingAddress"] = shippingAddress;
    }

    await _db.collection("auctions").doc(auctionId).update(data);
  }

  Future<Auction?> getAuction(String id) async {
    final doc = await _db.collection("auctions").doc(id).get();
    if (!doc.exists) return null;
    return Auction.fromMap(doc.id, doc.data()!);
  }

  // updateEndedAuctions is now handled by Cloud Functions

  // Update payment deadline (e.g. for final warning)
  Future<void> updatePaymentDeadline(
    String auctionId,
    DateTime newDeadline, {
    bool markReminderSent = false,
  }) async {
    final data = <String, dynamic>{
      "paymentDueAt": Timestamp.fromDate(newDeadline),
    };
    if (markReminderSent) {
      data["reminderSent"] = true;
    }
    await _db.collection("auctions").doc(auctionId).update(data);
  }

  // ✅ Manual Cancellation: Cancel the current win (e.g. non-payment)
  Future<void> cancelWin(String auctionId) async {
    await _db.collection("auctions").doc(auctionId).update({
      "status": "unsold",
      "highestBidderId": null,
      "highestBidderName": null,
      "currentBid":
          0, // Optional: Reset bid or keep it? Usually reset if unsold.
      "paymentDueAt": FieldValue.delete(),
    });
  }

  // ✅ Manual Re-award: Assign to a specific bidder (e.g. 2nd highest)
  Future<void> reawardAuction(
    String auctionId,
    String userId,
    String userName,
    int amount,
  ) async {
    // 1. Get current auction to preserve/check validity if needed
    // 2. Update with new winner info
    await _db.collection("auctions").doc(auctionId).update({
      "status": "pending_payment",
      "highestBidderId": userId,
      "highestBidderName": userName,
      "currentBid": amount,
      "paymentDueAt": Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 1)),
      ), // Reset deadline
      "reminderSent": false, // Reset reminder flag for new winner
    });
  }

  // ✅ Update Delivery Status
  Future<void> updateDeliveryStatus(
    String auctionId,
    OrderStatus status,
  ) async {
    await _db.collection("auctions").doc(auctionId).update({
      "deliveryStatus": status.name,
    });
  }
}
