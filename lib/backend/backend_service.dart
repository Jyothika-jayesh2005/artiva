import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/backend/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:flutter/foundation.dart';

class PublicReview {
  final String uid;
  final String name;
  final int rating;
  final String review;
  final DateTime? ratedAt;

  const PublicReview({
    required this.uid,
    required this.name,
    required this.rating,
    required this.review,
    required this.ratedAt,
  });
}

class BackendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- HELPERS ----------------

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  bool _asBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
  }

  String _asString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    return v.toString();
  }

  DateTime _asDate(dynamic v, {DateTime? fallback}) {
    if (v == null) return fallback ?? DateTime.now();
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      final dt = DateTime.tryParse(v);
      if (dt != null) return dt;
    }
    return fallback ?? DateTime.now();
  }

  OrderStatus _statusFromString(String s) {
    final cleaned = s.toLowerCase().trim();
    switch (cleaned) {
      case 'pending':
        return OrderStatus.pending;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;

      default:
        return OrderStatus.pending;
    }
  }

  String _statusToString(OrderStatus status) => status.name;

  // ---------------- ARTWORKS ----------------

  Future<void> upsertArtwork(Map<String, dynamic> artwork) async {
    final String id = (artwork["id"] ?? "").toString().trim();
    if (id.isEmpty) throw Exception("Artwork id missing");

    await _db.collection('artworks').doc(id).set({
      ...artwork,
      "updatedAt": FieldValue.serverTimestamp(),
      "createdAt": artwork["createdAt"] ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteArtwork(String artworkId) async {
    await _db.collection('artworks').doc(artworkId).delete();
  }

  Stream<List<Map<String, dynamic>>> watchArtworks() {
    return _db
        .collection('artworks')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {...d.data(), "id": d.id}).toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getArtworksOnce() async {
    final snap = await _db
        .collection('artworks')
        .orderBy('updatedAt', descending: true)
        .get();

    return snap.docs.map((d) => {...d.data(), "id": d.id}).toList();
  }

  Future<Map<String, dynamic>?> getArtworkById(String id) async {
    final doc = await _db.collection('artworks').doc(id).get();
    if (!doc.exists) return null;
    return {...doc.data()!, "id": doc.id};
  }

  Future<void> reduceStockAfterOrder({
    required String artworkId,
    required int qty,
  }) async {
    if (qty <= 0) throw Exception("Invalid quantity");

    final artRef = _db.collection('artworks').doc(artworkId);

    await _db.runTransaction<void>((tx) async {
      final snap = await tx.get(artRef);
      if (!snap.exists) throw Exception("Artwork not found");

      final data = snap.data() as Map<String, dynamic>;

      final total = _asInt(data['totalQuantity']);
      final sold = _asInt(data['soldQuantity']);

      final remaining = total - sold;
      if (remaining < qty) {
        throw Exception("Out of stock. Only $remaining left.");
      }

      tx.update(artRef, {
        'soldQuantity': sold + qty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------- EXHIBITIONS ----------------

  Future<void> upsertExhibition(Exhibition ex) async {
    await _db.collection('exhibitions').doc(ex.id).set({
      'id': ex.id,
      'title': ex.title,
      'venue': ex.venue,
      'dateTime': Timestamp.fromDate(ex.dateTime),
      'description': ex.description,
      'totalSeats': ex.totalSeats,
      'bookedSeats': ex.bookedSeats,
      'pricePerSeat': ex.pricePerSeat,
      'imageUrl': ex.imageUrl,
      'isArchived': ex.isArchived,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteExhibition(String exhibitionId) async {
    await _db.collection('exhibitions').doc(exhibitionId).delete();
  }

  Stream<List<Exhibition>> watchExhibitions({bool includeArchived = false}) {
    return _db.collection('exhibitions').orderBy('dateTime').snapshots().map((
      snap,
    ) {
      final now = DateTime.now();
      final list = snap.docs.map((d) {
        final data = d.data();
        return Exhibition(
          id: d.id,
          title: _asString(data['title']),
          venue: _asString(data['venue']),
          dateTime: _asDate(data['dateTime'], fallback: DateTime.now()),
          description: _asString(data['description']),
          totalSeats: _asInt(data['totalSeats']),
          bookedSeats: _asInt(data['bookedSeats']),
          pricePerSeat: _asInt(data['pricePerSeat']),
          imageUrl: _asString(
            data['imageUrl'],
            fallback: _asString(data['imagePath']),
          ),
          isArchived: _asBool(data['isArchived']),
        );
      }).toList();

      if (includeArchived) return list;
      return list
          .where((e) => !e.isArchived && e.dateTime.isAfter(now))
          .toList();
    });
  }

  Future<List<Exhibition>> getExhibitions({
    bool includeArchived = false,
  }) async {
    final snap = await _db.collection('exhibitions').orderBy('dateTime').get();
    final now = DateTime.now();

    final list = snap.docs.map((d) {
      final data = d.data();
      return Exhibition(
        id: d.id,
        title: _asString(data['title']),
        venue: _asString(data['venue']),
        dateTime: _asDate(data['dateTime'], fallback: DateTime.now()),
        description: _asString(data['description']),
        totalSeats: _asInt(data['totalSeats']),
        bookedSeats: _asInt(data['bookedSeats']),
        pricePerSeat: _asInt(data['pricePerSeat']),
        imageUrl: _asString(
          data['imageUrl'],
          fallback: _asString(data['imagePath']),
        ),
        isArchived: _asBool(data['isArchived']),
      );
    }).toList();

    if (includeArchived) return list;
    return list.where((e) => !e.isArchived && e.dateTime.isAfter(now)).toList();
  }

  Future<void> setExhibitionArchived(String exhibitionId, bool archived) async {
    await _db.collection('exhibitions').doc(exhibitionId).update({
      'isArchived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Automatically archives exhibitions that have already passed.
  Future<void> syncExhibitionArchiveStatus() async {
    try {
      final now = DateTime.now();
      // ✅ SIMPLIFIED QUERY: Only filter by isArchived (equality)
      final snap = await _db
          .collection('exhibitions')
          .where('isArchived', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) return;

      int count = 0;
      WriteBatch batch = _db.batch();
      bool hasUpdates = false;

      for (var doc in snap.docs) {
        final date = _asDate(doc.data()['dateTime']);
        if (date.isBefore(now)) {
          batch.update(doc.reference, {
            'isArchived': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          hasUpdates = true;
          count++;

          // Firestore batch limit is 500 operations
          if (count >= 450) {
            await batch.commit();
            batch = _db.batch();
            count = 0;
          }
        }
      }

      if (hasUpdates && count > 0) {
        await batch.commit();
      }
    } catch (e) {
      // ✅ Fail silently for the user but log for debugging
      debugPrint("Error syncing exhibition archive status: $e");
    }
  }

  // ---------------- EXHIBITION BOOKINGS ----------------

  Future<String> bookExhibition({
    required String exhibitionId,
    required int seats,
    required String customerName,
    required String customerEmail,
  }) async {
    final exRef = _db.collection('exhibitions').doc(exhibitionId);
    final passRef = _db.collection('passes').doc(); // or bookings

    return _db.runTransaction((tx) async {
      final exSnap = await tx.get(exRef);

      if (!exSnap.exists) {
        throw Exception("Exhibition not found");
      }

      final data = exSnap.data()!;

      // ✅ CHECK IF PASSED
      final DateTime date = _asDate(data['dateTime']);
      if (date.isBefore(DateTime.now())) {
        throw Exception(
          "This exhibition has already passed and cannot be booked.",
        );
      }

      final int totalSeats = data['totalSeats'] ?? 0;
      final int bookedSeats = data['bookedSeats'] ?? 0;

      final int available = totalSeats - bookedSeats;

      if (available < seats) {
        throw Exception("Not enough seats available");
      }

      // ✅ UPDATE SEATS
      tx.update(exRef, {'bookedSeats': bookedSeats + seats});

      // ✅ CREATE PASS / BOOKING
      tx.set(passRef, {
        'exhibitionId': exhibitionId,
        'exhibitionTitle': data['title'],
        'venue': data['venue'],
        'pricePerSeat': data['pricePerSeat'],
        'seats': seats,
        'totalAmount': seats * (data['pricePerSeat'] ?? 0),
        'customerName': customerName,
        'customerEmail': customerEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return passRef.id;
    });
  }

  Future<List<ExhibitionBooking>> getAllExhibitionBookings() async {
    final snap = await _db
        .collection('passes') // ✅ Simplified for no index
        .get();

    final list = snap.docs.map((d) {
      final data = d.data();
      return ExhibitionBooking(
        id: d.id,
        exhibitionId: _asString(data['exhibitionId']),
        exhibitionTitle: _asString(data['exhibitionTitle']),
        venue: _asString(data['venue']),
        customerName: _asString(data['customerName']),
        customerEmail: _asString(data['customerEmail']),
        seats: _asInt(data['seats']),
        pricePerSeat: _asInt(data['pricePerSeat']),
        totalAmount: _asInt(data['totalAmount']),
        bookedAt: _asDate(data['createdAt'], fallback: DateTime.now()),
      );
    }).toList();

    // Sort in-memory to avoid composite index
    list.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    return list;
  }

  Future<List<ExhibitionBooking>> getMyExhibitionBookings(
    String customerEmail,
  ) async {
    final snap = await _db
        .collection('passes')
        .where('customerEmail', isEqualTo: customerEmail)
        // .orderBy('createdAt', descending: true) // REMOVED to avoid index
        .get();

    final list = snap.docs.map((d) {
      final data = d.data();
      return ExhibitionBooking(
        id: d.id,
        exhibitionId: _asString(data['exhibitionId']),
        exhibitionTitle: _asString(data['exhibitionTitle']),
        venue: _asString(data['venue']),
        customerName: _asString(data['customerName']),
        customerEmail: _asString(data['customerEmail']),
        seats: _asInt(data['seats']),
        pricePerSeat: _asInt(data['pricePerSeat']),
        totalAmount: _asInt(data['totalAmount']),
        bookedAt: _asDate(data['createdAt'], fallback: DateTime.now()),
      );
    }).toList();

    // Sort in-memory
    list.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    return list;
  }

  // ---------------- ORDERS ----------------

  Future<int?> getMyArtworkRating(
    String artworkId,
    String customerEmail,
  ) async {
    final snap = await _db
        .collection('orders')
        .where('artId', isEqualTo: artworkId)
        .where('customerEmail', isEqualTo: customerEmail)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final r = snap.docs.first.data()['rating'];
    return (r is num && r > 0) ? r.toInt() : null; // ✅ FIXED
  }

  Future<List<ArtworkOrder>> getAllOrders() async {
    final snap = await _db
        .collection('orders')
        .orderBy('orderedAt', descending: true)
        .get();
    return snap.docs.map(_orderFromDoc).toList();
  }

  // ✅ NEW: Stream for real-time updates (admin notification)
  Stream<List<ArtworkOrder>> watchOrders() {
    return _db
        .collection('orders')
        .orderBy('orderedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_orderFromDoc).toList());
  }

  Future<List<ArtworkOrder>> getMyOrdersByUid(String uid) async {
    final snap = await _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        // .orderBy('orderedAt', descending: true) // REMOVED to avoid index
        .get();

    final list = snap.docs.map(_orderFromDoc).toList();

    // Sort in-memory
    list.sort((a, b) => b.orderedAt.compareTo(a.orderedAt));
    return list;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': _statusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ NEW: Automatic Status Update
  Future<void> syncOrderStatuses() async {
    try {
      final snap = await _db
          .collection('orders')
          .where('status', whereIn: ['pending', 'shipped'])
          .get(); // Only active

      if (snap.docs.isEmpty) return;

      final now = DateTime.now();
      final batch = _db.batch();
      bool changed = false;

      for (var doc in snap.docs) {
        final data = doc.data();
        final statusStr = _asString(data['status']);
        final status = _statusFromString(statusStr);
        final orderedAt = _asDate(data['orderedAt']);

        final days = now.difference(orderedAt).inDays;

        // Logic:
        // Pending -> Shipped (after 2 days)
        // Shipped -> Delivered (after 7 days from ORDER date, or 5 days from shipped)
        // We use orderedAt as base.

        if (status == OrderStatus.pending && days >= 2) {
          batch.update(doc.reference, {
            'status': _statusToString(OrderStatus.shipped),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          changed = true;
        } else if (status == OrderStatus.shipped && days >= 4) {
          batch.update(doc.reference, {
            'status': _statusToString(OrderStatus.delivered),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          changed = true;
        }
      }

      if (changed) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint("Error syncing order statuses: $e");
    }
  }

  Future<void> deleteOrderReview(String orderId) async {
    final orderRef = _db.collection('orders').doc(orderId);

    await _db.runTransaction<void>((tx) async {
      // 🔹 READS FIRST (MANDATORY)
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw Exception("Order not found.");

      final data = orderSnap.data()!;
      final artId = (data['artId'] ?? '').toString().trim();
      final rating = data['rating'];

      DocumentSnapshot<Map<String, dynamic>>? artSnap;
      DocumentReference<Map<String, dynamic>>? artRef;

      if (rating is num && rating > 0 && artId.isNotEmpty) {
        artRef = _db.collection('artworks').doc(artId);
        artSnap = await tx.get(artRef); // ✅ READ BEFORE WRITE
      }

      // 🔹 NOW WRITES (SAFE)
      tx.update(orderRef, {
        'rating': FieldValue.delete(),
        'review': FieldValue.delete(),
        'ratedAt': FieldValue.delete(),
        'reviewDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (artSnap != null && artRef != null) {
        final oldAvg = (artSnap.data()?['avgRating'] ?? 0).toDouble();
        final oldCount = (artSnap.data()?['ratingCount'] ?? 0).toInt();

        final newCount = (oldCount - 1).clamp(0, oldCount);
        final newAvg = newCount == 0
            ? 0.0
            : ((oldAvg * oldCount) - rating.toDouble()) / newCount;

        tx.update(artRef, {
          'avgRating': newAvg,
          'ratingCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (artId.isNotEmpty) {
        tx.delete(
          _db
              .collection('artworks')
              .doc(artId)
              .collection('user_ratings')
              .doc(orderId), // ✅ Use orderId instead of userId
        );
      }
    });
  }

  Future<void> submitOrderRating({
    required String orderId,
    required int rating,
    String? review,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception("Rating must be between 1 and 5.");
    }

    final orderRef = _db.collection('orders').doc(orderId);
    String artId = "";

    await _db.runTransaction<void>((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw Exception("Order not found.");

      final data = orderSnap.data() as Map<String, dynamic>;

      final statusStr = _asString(data['status'], fallback: 'pending');
      final status = _statusFromString(statusStr);

      // ✅ REQUIREMENT 1: Only allow rating if order is delivered
      if (status != OrderStatus.delivered) {
        throw Exception("You can rate only after the order is delivered.");
      }

      final locked = data['ratingLocked'] == true;
      final reviewDeleted = data['reviewDeleted'] == true;

      // ✅ REQUIREMENT 3: If admin deleted review, customer cannot review again
      if (reviewDeleted) {
        throw Exception(
          "Your previous review was removed by admin. You cannot submit another review.",
        );
      }

      // ✅ REQUIREMENT 2: Customer can review only once
      if (locked) {
        throw Exception("You already rated this order.");
      }

      final alreadyRated =
          (data['ratedAt'] != null) || (data['rating'] != null);
      if (alreadyRated) {
        tx.update(orderRef, {'ratingLocked': true});
        throw Exception("You already rated this order.");
      }

      artId = (data['artId'] ?? '').toString().trim();

      tx.update(orderRef, {
        'rating': rating,
        'review': review,
        'ratedAt': FieldValue.serverTimestamp(),
        'ratingLocked': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    if (artId.isEmpty) return;

    // Recompute avg rating
    final artRef = _db.collection('artworks').doc(artId);

    await _db.runTransaction<void>((tx) async {
      final snap = await tx.get(artRef);

      final double oldAvg = (snap.data()?['avgRating'] ?? 0).toDouble();
      final int oldCount = (snap.data()?['ratingCount'] ?? 0).toInt();

      final newCount = oldCount + 1;
      final newAvg = ((oldAvg * oldCount) + rating) / newCount;

      tx.update(artRef, {
        'avgRating': newAvg,
        'ratingCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // optional user_ratings

    // ✅ WRITE PUBLIC REVIEW DOC (for ArtworkDetailsPage)
    // We need the customerName from the order.
    final finalOrderSnap = await orderRef.get();
    final finalOrderData = finalOrderSnap.data();

    // Resolve name: Order Name -> User Profile Name -> Fallback
    String reviewerName = (finalOrderData?['customerName'] ?? '')
        .toString()
        .trim();
    if (reviewerName.isEmpty) {
      final appUser = authService.currentUser;
      reviewerName = appUser?.name ?? 'Customer';
    }

    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      await _db
          .collection('artworks')
          .doc(artId)
          .collection('user_ratings')
          .doc(
            orderId,
          ) // ✅ Use orderId as DOC ID so multiple orders = multiple reviews
          .set({
            'uid': u.uid,
            'email': u.email,
            'name': reviewerName,
            'rating': rating,
            'review': review,
            'ratedAt': FieldValue.serverTimestamp(),
            'orderId': orderId,
          }, SetOptions(merge: true));
    }
  }

  // ✅ SECURE TRANSACTION: Create Order + Reduce Stock + Verify Price
  Future<String> placeOrderTransaction({
    required String userId,
    required String artworkId,
    required int quantity,
    required String address,
    String? addressId,
    Map<String, dynamic>? addressSnapshot,
    required String customerName,
    required String customerEmail,
    String? sizeCm,
    String? sizeIn,
  }) async {
    return _db.runTransaction<String>((tx) async {
      // 1. Get Artwork (Lock it)
      final artRef = _db.collection('artworks').doc(artworkId);
      final artSnap = await tx.get(artRef);

      if (!artSnap.exists) {
        throw Exception("Artwork not found.");
      }

      final data = artSnap.data()!;
      final title = _asString(data['title'], fallback: 'Artwork');
      final price = _asInt(data['price']); // Trust DB price
      final total = _asInt(data['totalQuantity']);
      final sold = _asInt(data['soldQuantity']);
      final image = _asString(
        data['imageUrl'],
        fallback: _asString(data['imagePath']),
      );

      // 2. Check Stock
      if ((total - sold) < quantity) {
        throw Exception("Out of stock. Only ${total - sold} left.");
      }

      // 3. Prepare Order
      final orderRef = _db.collection('orders').doc();
      final payload = <String, dynamic>{
        'userId': userId,
        'artId': artworkId,
        'artTitle': title,
        'price': price,
        'quantity': quantity,
        'address': address,
        'imageUrl': image,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'size_cm': sizeCm,
        'size_in': sizeIn,
        'status': _statusToString(OrderStatus.pending),
        'orderedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'ratingLocked': false,
      };

      if (addressId != null) payload['addressId'] = addressId;
      if (addressSnapshot != null) payload['addressSnapshot'] = addressSnapshot;

      // 4. Writes
      tx.set(orderRef, payload);

      // 5. Update artwork stock (atomic)
      tx.update(artRef, {
        'soldQuantity': FieldValue.increment(quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return orderRef.id;
    });
  }

  Future<String> createOrder({
    required String userId,
    required String artworkId,
    required String artTitle,
    required int price,
    required int quantity,
    required String address,
    String? addressId,
    Map<String, dynamic>? addressSnapshot,
    String? imageUrl,
    required String customerName,
    required String customerEmail,
    String? sizeCm,
    String? sizeIn,
  }) async {
    final ref = _db.collection('orders').doc();

    final payload = <String, dynamic>{
      'userId': userId,
      'artId': artworkId,
      'artTitle': artTitle,
      'price': price,
      'quantity': quantity,
      'address': address,
      'imageUrl': imageUrl,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'size_cm': sizeCm,
      'size_in': sizeIn,
      'status': _statusToString(OrderStatus.pending),
      'orderedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'ratingLocked': false,
    };

    if ((addressId ?? "").trim().isNotEmpty) {
      payload['addressId'] = addressId!.trim();
    }
    if (addressSnapshot != null && addressSnapshot.isNotEmpty) {
      payload['addressSnapshot'] = addressSnapshot;
    }

    await ref.set(payload);
    return ref.id;
  }

  Future<List<ArtworkOrder>> getArtworkReviews(String artworkId) async {
    final snap = await _db
        .collection('orders')
        .where('artId', isEqualTo: artworkId)
        .where('ratingLocked', isEqualTo: true)
        // .orderBy('ratedAt', descending: true) // REMOVED to avoid index
        .get();

    final list = snap.docs
        .map(_orderFromDoc)
        .where(
          (order) =>
              order.rating != null || (order.review ?? "").trim().isNotEmpty,
        )
        .toList();

    // Sort in-memory
    list.sort((a, b) {
      final da = a.ratedAt ?? DateTime(2000);
      final db = b.ratedAt ?? DateTime(2000);
      return db.compareTo(da);
    });

    return list;
  }

  // ✅ NEW: PUBLIC REVIEWS (from artworks/{artId}/user_ratings)
  Future<List<PublicReview>> getArtworkPublicReviews(String artworkId) async {
    final snap = await _db
        .collection('artworks')
        .doc(artworkId)
        .collection('user_ratings')
        .orderBy('ratedAt', descending: true)
        .get();

    return snap.docs
        .map((d) {
          final data = d.data();
          final ts = data['ratedAt'];

          return PublicReview(
            uid: d.id,
            name: (data['name'] ?? 'Customer').toString(),
            rating: (data['rating'] is num)
                ? (data['rating'] as num).toInt()
                : 0,
            review: (data['review'] ?? '').toString(),
            ratedAt: ts is Timestamp ? ts.toDate() : null,
          );
        })
        .where((r) => r.rating > 0 || r.review.trim().isNotEmpty)
        .toList();
  }

  Future<ArtworkRatingSummary> getArtworkRatingFromArtworkDoc(
    String artworkId,
  ) async {
    final doc = await _db.collection('artworks').doc(artworkId).get();
    if (!doc.exists) return const ArtworkRatingSummary(avg: 0, count: 0);

    final data = doc.data()!;
    final avg = (data['avgRating'] is num)
        ? (data['avgRating'] as num).toDouble()
        : 0.0;
    final count = (data['ratingCount'] is num)
        ? (data['ratingCount'] as num).toInt()
        : 0;

    return ArtworkRatingSummary(avg: avg, count: count);
  }

  ArtworkOrder _orderFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();

    final statusStr = _asString(data['status'], fallback: 'pending');
    final status = _statusFromString(statusStr);

    final orderedAt = data['orderedAt'];
    final orderedDate = orderedAt is Timestamp
        ? orderedAt.toDate()
        : DateTime.now();

    final String imgUrl = _asString(
      data['imageUrl'],
      fallback: _asString(data['imagePath']),
    );

    final address = _asString(data['address']);
    final addressId = data['addressId']?.toString();

    final addressSnapshot = data['addressSnapshot'];
    final Map<String, dynamic>? addressSnap = addressSnapshot is Map
        ? Map<String, dynamic>.from(addressSnapshot)
        : null;

    final bool ratingLocked = data['ratingLocked'] == true;

    return ArtworkOrder(
      id: d.id,
      artId: data['artId']?.toString(),
      artTitle: _asString(data['artTitle']),
      customerName: _asString(data['customerName']),
      customerEmail: _asString(data['customerEmail']),
      quantity: _asInt(data['quantity']),
      price: _asInt(data['price']),
      imageUrl: imgUrl.isEmpty ? null : imgUrl,
      address: address.isEmpty ? null : address,
      addressId: addressId,
      addressSnapshot: addressSnap,
      sizeCm:
          _asString(
            data['size_cm'],
            fallback: _asString(data['sizeCm']),
          ).isEmpty
          ? null
          : _asString(data['size_cm'], fallback: _asString(data['sizeCm'])),
      sizeIn:
          _asString(
            data['size_in'],
            fallback: _asString(data['sizeIn']),
          ).isEmpty
          ? null
          : _asString(data['size_in'], fallback: _asString(data['sizeIn'])),
      status: status,
      orderedAt: orderedDate,
      rating: data['rating'] is num ? (data['rating'] as num).toInt() : null,
      review: data['review']?.toString(),
      ratedAt: data['ratedAt'] is Timestamp
          ? (data['ratedAt'] as Timestamp).toDate()
          : null,
      ratingLocked: ratingLocked,
    );
  }
}
