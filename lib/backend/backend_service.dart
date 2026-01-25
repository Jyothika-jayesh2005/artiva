import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/backend/models.dart';

class BackendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------
  // helpers
  // -------------------------
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
    if (v is Timestamp) return v.toDate();
    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
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
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String _statusToString(OrderStatus status) => status.name;

  // =====================================================
  // ARTWORKS (ADMIN + CUSTOMER)
  // Collection: artworks
  // =====================================================

  Future<void> upsertArtwork(Map<String, dynamic> artwork) async {
    final String id = (artwork["id"] ?? "").toString().trim();
    if (id.isEmpty) {
      throw Exception("Artwork id missing");
    }

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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) {
            return {
              ...d.data(),
              "id": d.id, // ✅ VERY IMPORTANT
            };
          }).toList();
        });
  }

  Future<List<Map<String, dynamic>>> getArtworksOnce() async {
    final snap = await _db
        .collection('artworks')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) {
      return {...d.data(), "id": d.id};
    }).toList();
  }

  // =====================================================
  // EXHIBITIONS (ADMIN + CUSTOMER)
  // =====================================================

  Future<void> upsertExhibition(Exhibition ex) async {
    await _db.collection('exhibitions').doc(ex.id).set({
      'title': ex.title,
      'venue': ex.venue,
      'dateTime': Timestamp.fromDate(ex.dateTime),
      'description': ex.description,
      'totalSeats': ex.totalSeats,
      'bookedSeats': ex.bookedSeats,
      'pricePerSeat': ex.pricePerSeat,
      'imagePath': ex.imagePath,
      'isArchived': ex.isArchived,
      'updatedAt': FieldValue.serverTimestamp(),
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
          dateTime: _asDate(data['dateTime']),
          description: _asString(data['description']),
          totalSeats: _asInt(data['totalSeats']),
          bookedSeats: _asInt(data['bookedSeats']),
          pricePerSeat: _asInt(data['pricePerSeat']),
          imagePath: _asString(data['imagePath']),
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
        dateTime: _asDate(data['dateTime']),
        description: _asString(data['description']),
        totalSeats: _asInt(data['totalSeats']),
        bookedSeats: _asInt(data['bookedSeats']),
        pricePerSeat: _asInt(data['pricePerSeat']),
        imagePath: _asString(data['imagePath']),
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

  // =====================================================
  // BOOK EXHIBITION (CUSTOMER)
  // =====================================================

  Future<String> bookExhibition({
    required String exhibitionId,
    required int seats,
    required String customerName,
    required String customerEmail,
  }) async {
    if (seats <= 0) throw Exception("Invalid seat count.");

    final exRef = _db.collection('exhibitions').doc(exhibitionId);
    final bookingRef = _db.collection('exhibition_bookings').doc();

    return _db.runTransaction((tx) async {
      final exSnap = await tx.get(exRef);
      if (!exSnap.exists) throw Exception("Exhibition not found.");

      final data = exSnap.data() as Map<String, dynamic>;

      final totalSeats = _asInt(data['totalSeats']);
      final bookedSeats = _asInt(data['bookedSeats']);
      final pricePerSeat = _asInt(data['pricePerSeat']);
      final title = _asString(data['title']);
      final venue = _asString(data['venue']);

      final remaining = totalSeats - bookedSeats;
      if (remaining < seats) {
        throw Exception("Not enough seats. Only $remaining left.");
      }

      final totalAmount = seats * pricePerSeat;

      tx.update(exRef, {
        'bookedSeats': bookedSeats + seats,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(bookingRef, {
        'exhibitionId': exhibitionId,
        'exhibitionTitle': title,
        'venue': venue,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'seats': seats,
        'pricePerSeat': pricePerSeat,
        'totalAmount': totalAmount,
        'bookedAt': FieldValue.serverTimestamp(),
      });

      return bookingRef.id;
    });
  }

  // =====================================================
  // EXHIBITION BOOKINGS (ADMIN)
  // =====================================================

  Future<List<ExhibitionBooking>> getAllExhibitionBookings() async {
    final snap = await _db
        .collection('exhibition_bookings')
        .orderBy('bookedAt', descending: true)
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
        bookedAt: _asDate(data['bookedAt'], fallback: DateTime.now()),
      );
    }).toList();
  }

  // =====================================================
  // EXHIBITION BOOKINGS (CUSTOMER)
  // =====================================================

  Future<List<ExhibitionBooking>> getMyExhibitionBookings(
    String customerEmail,
  ) async {
    final snap = await _db
        .collection('exhibition_bookings')
        .where('customerEmail', isEqualTo: customerEmail)
        .orderBy('bookedAt', descending: true)
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
        bookedAt: _asDate(data['bookedAt'], fallback: DateTime.now()),
      );
    }).toList();
  }

  // =====================================================
  // ARTWORK ORDERS (ADMIN)
  // =====================================================

  Future<List<ArtworkOrder>> getAllOrders() async {
    final snap = await _db
        .collection('orders')
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
    await _db.collection('orders').doc(orderId).update({
      'rating': FieldValue.delete(),
      'review': FieldValue.delete(),
      'ratedAt': FieldValue.delete(),
    });
  }

  // =====================================================
  // ARTWORK ORDERS (CUSTOMER)
  // =====================================================

  Future<List<ArtworkOrder>> getMyOrders(String customerEmail) async {
    final snap = await _db
        .collection('orders')
        .where('customerEmail', isEqualTo: customerEmail)
        .orderBy('orderedAt', descending: true)
        .get();

    return snap.docs.map(_orderFromDoc).toList();
  }

  Future<void> submitOrderRating({
    required String orderId,
    required int rating,
    String? review,
  }) async {
    // 1) Save rating into the order
    await _db.collection('orders').doc(orderId).update({
      'rating': rating,
      'review': review,
      'ratedAt': FieldValue.serverTimestamp(),
    });

    // 2) Read order -> get artId
    final orderSnap = await _db.collection('orders').doc(orderId).get();
    final orderData = orderSnap.data();
    final String artId = (orderData?['artId'] ?? '').toString().trim();
    if (artId.isEmpty) return;

    // 3) Get all rated orders for this artId
    final ratedOrdersSnap = await _db
        .collection('orders')
        .where('artId', isEqualTo: artId)
        .where('rating', isGreaterThan: 0)
        .get();

    double sum = 0.0;
    int count = 0;

    for (final doc in ratedOrdersSnap.docs) {
      final r = doc.data()['rating'];
      if (r is num) {
        sum += r.toDouble();
        count++;
      }
    }

    final double avg = count == 0 ? 0.0 : (sum / count);

    // 4) Save summary into artworks/{artId} so cards can show rating
    await _db.collection('artworks').doc(artId).set({
      'avgRating': avg,
      'ratingCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =====================================================
  // CREATE ORDER (CUSTOMER)
  // =====================================================

  Future<String> createOrder({
    required String userId,
    required String artworkId,
    required String artTitle,
    required int price,
    required int quantity,
    required String address,
    String? imagePath,
    required String customerName,
    required String customerEmail,
    String? size,
    String? inch,
  }) async {
    final ref = _db.collection('orders').doc();

    await ref.set({
      'userId': userId,
      'artId': artworkId,
      'artTitle': artTitle,
      'price': price,
      'quantity': quantity,
      'address': address,
      'imagePath': imagePath,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'size': size,
      'inch': inch,
      'status': _statusToString(OrderStatus.pending),
      'orderedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  // =====================================================
  // ARTWORK RATING SUMMARY
  // =====================================================

  Future<ArtworkRatingSummary> getArtworkRating(String artworkId) async {
    final snap = await _db
        .collection('orders')
        .where('artId', isEqualTo: artworkId)
        .where('rating', isGreaterThan: 0)
        .get();

    if (snap.docs.isEmpty) {
      return const ArtworkRatingSummary(avg: 0, count: 0);
    }

    double sum = 0;
    int count = 0;

    for (final doc in snap.docs) {
      final data = doc.data();
      final r = data['rating'];
      if (r is num) {
        sum += r.toDouble();
        count++;
      }
    }

    if (count == 0) return const ArtworkRatingSummary(avg: 0, count: 0);

    return ArtworkRatingSummary(avg: sum / count, count: count);
  }

  // =====================================================
  // PRIVATE HELPER
  // =====================================================

  ArtworkOrder _orderFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();

    final statusStr = _asString(data['status'], fallback: 'pending');
    final status = _statusFromString(statusStr);

    final orderedAt = data['orderedAt'];
    final orderedDate = orderedAt is Timestamp
        ? orderedAt.toDate()
        : DateTime.now();

    // NOTE:
    // I only use fields that exist in YOUR models.dart you posted earlier.
    // If your ArtworkOrder model doesn’t have address/imagePath/size/inch,
    // do NOT force them here (it will cause compile errors).
    return ArtworkOrder(
      id: d.id,
      artId: data['artId']?.toString(),
      artTitle: _asString(data['artTitle']),
      customerName: _asString(data['customerName']),
      customerEmail: _asString(data['customerEmail']),
      quantity: _asInt(data['quantity']),
      price: _asInt(data['price']),
      status: status,
      orderedAt: orderedDate,
      rating: data['rating'] is num ? (data['rating'] as num).toInt() : null,
      review: data['review']?.toString(),
      ratedAt: data['ratedAt'] is Timestamp
          ? (data['ratedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
