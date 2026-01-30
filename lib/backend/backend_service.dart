import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/backend/models.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Stream<List<Exhibition>> watchExhibitions() {
    return _db.collection('exhibitions').orderBy('dateTime').snapshots().map((
      snap,
    ) {
      return snap.docs.map((d) {
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
    });
  }

  Future<List<Exhibition>> getExhibitions({
    bool includeArchived = false,
  }) async {
    final snap = await _db.collection('exhibitions').orderBy('dateTime').get();

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
    return list.where((e) => !e.isArchived).toList();
  }

  Future<void> setExhibitionArchived(String exhibitionId, bool archived) async {
    await _db.collection('exhibitions').doc(exhibitionId).update({
      'isArchived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
        .collection('passes') // ✅ FIXED
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) {
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
  }

  Future<List<ExhibitionBooking>> getMyExhibitionBookings(
    String customerEmail,
  ) async {
    final snap = await _db
        .collection('passes') // ✅ FIXED
        .where('customerEmail', isEqualTo: customerEmail)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) {
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

  Future<List<ArtworkOrder>> getMyOrdersByUid(String uid) async {
    final snap = await _db
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('orderedAt', descending: true)
        .get();

    return snap.docs.map(_orderFromDoc).toList();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': _statusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOrderReview(String orderId) async {
    final orderRef = _db.collection('orders').doc(orderId);

    await _db.runTransaction<void>((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw Exception("Order not found.");

      final data = orderSnap.data() as Map<String, dynamic>;
      final artId = (data['artId'] ?? '').toString().trim();
      final rating = data['rating'];
      

      // ✅ Mark as deleted so customer cannot review again
      tx.update(orderRef, {
        'rating': FieldValue.delete(),
        'review': FieldValue.delete(),
        'ratedAt': FieldValue.delete(),
        'reviewDeleted': true, // ✅ NEW: Track that review was deleted
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Recompute average rating if there was a rating
      if (rating is num && rating > 0 && artId.isNotEmpty) {
        final artRef = _db.collection('artworks').doc(artId);
        final artSnap = await tx.get(artRef);

        final double oldAvg = (artSnap.data()?['avgRating'] ?? 0).toDouble();
        final int oldCount = (artSnap.data()?['ratingCount'] ?? 0).toInt();

        if (oldCount > 0) {
          final newCount = oldCount - 1;
          final newAvg = newCount == 0
              ? 0.0
              : ((oldAvg * oldCount) - rating.toDouble()) / newCount;

          tx.update(artRef, {
            'avgRating': newAvg,
            'ratingCount': newCount,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        final userId = _asString(data['userId']).trim();

        // ✅ Remove from user_ratings subcollection (doc id = uid)
        if (userId.isNotEmpty && artId.isNotEmpty) {
          tx.delete(
            _db
                .collection('artworks')
                .doc(artId)
                .collection('user_ratings')
                .doc(userId),
          );
        }
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
    

    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      await _db
          .collection('artworks')
          .doc(artId)
          .collection('user_ratings')
          .doc(u.uid)
          .set({
            'uid': u.uid,
            'email': u.email, // optional
            'rating': rating,
            'review': review,
            'ratedAt': FieldValue.serverTimestamp(),
            'orderId': orderId,
          }, SetOptions(merge: true));
    }
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
        .orderBy('ratedAt', descending: true)
        .get();

    return snap.docs
        .map(_orderFromDoc)
        .where(
          (order) =>
              order.rating != null || (order.review ?? "").trim().isNotEmpty,
        )
        .toList();
  }

  Future<ArtworkRatingSummary> getArtworkRating(String artworkId) async {
    final snap = await _db
        .collection('orders')
        .where('artId', isEqualTo: artworkId)
        .get(); // ✅ REMOVED .where('rating', isGreaterThan: 0)

    if (snap.docs.isEmpty) return const ArtworkRatingSummary(avg: 0, count: 0);

    double sum = 0;
    int count = 0;

    for (final doc in snap.docs) {
      final r = doc.data()['rating'];
      if (r is num && r > 0) {
        // ✅ ADDED: && r > 0
        sum += r.toDouble();
        count++;
      }
    }

    if (count == 0) return const ArtworkRatingSummary(avg: 0, count: 0);
    return ArtworkRatingSummary(avg: sum / count, count: count);
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
