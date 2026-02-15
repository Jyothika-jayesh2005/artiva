// ---------------- USER ----------------

import 'package:cloud_firestore/cloud_firestore.dart';

enum Role { admin, user }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final Role role;
  final String photoUrl;
  final String address; // ✅ Added address
  final bool archived;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl = "",
    this.address = "", // ✅ Added default
    this.archived = false,
    this.lastAuctionCheck,
  });

  final DateTime? lastAuctionCheck;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final roleStr = (map["role"] ?? "user").toString().toLowerCase();
    final role = roleStr == "admin" ? Role.admin : Role.user;

    return AppUser(
      uid: uid,
      name: (map["name"] ?? "").toString(),
      email: (map["email"] ?? "").toString(),
      phone: (map["phone"] ?? "").toString(),
      role: role,
      photoUrl: (map["photoUrl"] ?? "").toString(),
      address: (map["address"] ?? "").toString(), // ✅ Map address
      archived: map["archived"] == true,
      lastAuctionCheck: _parseDateTime(map["lastAuctionCheck"]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "email": email.toLowerCase().trim(),
      "phone": phone,
      "role": role == Role.admin ? "admin" : "user",
      "photoUrl": photoUrl,
      "address": address, // ✅ Save address
      "archived": archived,
      "lastAuctionCheck": lastAuctionCheck != null
          ? Timestamp.fromDate(lastAuctionCheck!)
          : null,
      "updatedAt": FieldValue.serverTimestamp(), // needs cloud_firestore import
    };
  }
}

// ---------------- EXHIBITION ----------------

class Exhibition {
  final String id;
  final String title;
  final String venue;
  final DateTime dateTime;
  final String description;
  final int totalSeats;
  final int bookedSeats;
  final int pricePerSeat;
  final String imageUrl;
  final bool isArchived;

  Exhibition({
    required this.id,
    required this.title,
    required this.venue,
    required this.dateTime,
    required this.description,
    required this.totalSeats,
    required this.bookedSeats,
    required this.pricePerSeat,
    required this.imageUrl,
    this.isArchived = false,
  });

  int get remainingSeats => totalSeats - bookedSeats;

  factory Exhibition.fromMap(Map<String, dynamic> map) {
    return Exhibition(
      id: (map["id"] ?? "").toString(),
      title: (map["title"] ?? "").toString(),
      venue: (map["venue"] ?? "").toString(),
      dateTime: _parseDateTime(map["dateTime"]),
      description: (map["description"] ?? "").toString(),
      totalSeats: _toInt(map["totalSeats"]),
      bookedSeats: _toInt(map["bookedSeats"]),
      pricePerSeat: _toInt(map["pricePerSeat"]),
      imageUrl: (map["imageUrl"] ?? map["image"] ?? "").toString(),
      isArchived: map["isArchived"] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "venue": venue,
      "dateTime": Timestamp.fromDate(dateTime),
      "description": description,
      "totalSeats": totalSeats,
      "bookedSeats": bookedSeats,
      "pricePerSeat": pricePerSeat,
      "imageUrl": imageUrl,
      "isArchived": isArchived,
    };
  }
}

// ---------------- EXHIBITION BOOKING ----------------

class ExhibitionBooking {
  final String id;
  final String exhibitionId;
  final String exhibitionTitle;
  final String venue;
  final String customerName;
  final String customerEmail;
  final int seats;
  final int pricePerSeat;
  final int totalAmount;
  final DateTime bookedAt;

  ExhibitionBooking({
    required this.id,
    required this.exhibitionId,
    required this.exhibitionTitle,
    required this.venue,
    required this.customerName,
    required this.customerEmail,
    required this.seats,
    required this.pricePerSeat,
    required this.totalAmount,
    required this.bookedAt,
  });

  // ✅ THIS IS THE REQUIRED ADDITION
  factory ExhibitionBooking.fromMap(String id, Map<String, dynamic> map) {
    return ExhibitionBooking(
      id: id,
      exhibitionId: (map['exhibitionId'] ?? '').toString(),
      exhibitionTitle: (map['exhibitionTitle'] ?? '').toString(),
      venue: (map['venue'] ?? '').toString(),
      customerName: (map['customerName'] ?? '').toString(),
      customerEmail: (map['customerEmail'] ?? '').toString(),
      seats: _toInt(map['seats']),
      pricePerSeat: _toInt(map['pricePerSeat']),
      totalAmount: _toInt(map['totalAmount']),
      bookedAt: _parseDateTime(map['createdAt']),
    );
  }
}

// ---------------- ORDERS ----------------

enum OrderStatus { pending, shipped, delivered }

class ArtworkOrder {
  final String id;
  final String? artId;
  final String artTitle;
  final String customerName;
  final String customerEmail;
  final int quantity;
  final int price;
  final String? imageUrl;
  final String? address;
  final Map<String, dynamic>? addressSnapshot;
  final String? addressId;
  final String? sizeCm;
  final String? sizeIn;
  final OrderStatus status;
  final DateTime orderedAt;
  final int? rating;
  final String? review;
  final DateTime? ratedAt;
  final bool ratingLocked;

  ArtworkOrder({
    required this.id,
    this.artId,
    required this.artTitle,
    required this.customerName,
    required this.customerEmail,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.address,
    this.addressSnapshot,
    this.addressId,
    this.sizeCm,
    this.sizeIn,
    required this.status,
    required this.orderedAt,
    this.rating,
    this.review,
    this.ratedAt,
    this.ratingLocked = false,
  });

  // ✅ HELPERS for UI
  DateTime get estimatedDeliveryDate => orderedAt.add(const Duration(days: 7));
  DateTime get shippedDate => orderedAt.add(const Duration(days: 2));
  OrderStatus get effectiveStatus {
    final now = DateTime.now();
    // Normalize to date-only (midnight) to strictly compare dates
    final today = DateTime(now.year, now.month, now.day);

    final shipDt = shippedDate;
    final shipDay = DateTime(shipDt.year, shipDt.month, shipDt.day);

    final delDt = estimatedDeliveryDate;
    final delDay = DateTime(delDt.year, delDt.month, delDt.day);

    // If explicitly delivered, stay delivered
    if (status == OrderStatus.delivered) return OrderStatus.delivered;

    // Auto-update logic: If today is ON or AFTER the target date
    if (!today.isBefore(delDay)) return OrderStatus.delivered;
    if (!today.isBefore(shipDay)) return OrderStatus.shipped;

    return status;
  }

  // ✅ THIS IS THE MISSING PIECE (CRITICAL)
  ArtworkOrder copyWith({
    int? rating,
    String? review,
    DateTime? ratedAt,
    bool? ratingLocked,
    OrderStatus? status,
  }) {
    return ArtworkOrder(
      id: id,
      artId: artId,
      artTitle: artTitle,
      customerName: customerName,
      customerEmail: customerEmail,
      quantity: quantity,
      price: price,
      imageUrl: imageUrl,
      address: address,
      addressSnapshot: addressSnapshot,
      addressId: addressId,
      sizeCm: sizeCm,
      sizeIn: sizeIn,
      status: status ?? this.status,
      orderedAt: orderedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      ratedAt: ratedAt ?? this.ratedAt,
      ratingLocked: ratingLocked ?? this.ratingLocked,
    );
  }
}

// ---------------- ARTWORK RATING SUMMARY ----------------

class ArtworkRatingSummary {
  final double avg;
  final int count;

  const ArtworkRatingSummary({required this.avg, required this.count});

  String get label => avg == 0 ? "—" : avg.toStringAsFixed(1);
}

// ---------------- AUCTION ----------------

enum AuctionStatus { scheduled, live, ended, sold, pending_payment, unsold }

class Auction {
  final String id;
  final String artId;
  final String artTitle;
  final String artImageUrl;
  final String artistName;
  final String description;
  final String size;
  final String aboutPiece;
  final DateTime startTime;
  final DateTime endTime;
  final int startingBid;
  final int minIncrement;
  final int currentBid;
  final String? highestBidderId;
  final String? highestBidderName;
  final AuctionStatus status;
  final DateTime createdAt;
  final String createdBy;

  final int? finalPrice;
  final DateTime? paymentDueAt; // ✅ Restored
  final bool reminderSent; // ✅ Restored
  final Map<String, dynamic>? shippingAddress; // ✅ Restored
  final OrderStatus deliveryStatus;
  final DateTime? paymentDate;

  Auction({
    required this.id,
    required this.artId,
    required this.artTitle,
    required this.artImageUrl,
    required this.artistName,
    required this.description,
    required this.size,
    required this.aboutPiece,
    required this.startTime,
    required this.endTime,
    required this.startingBid,
    required this.minIncrement,
    required this.currentBid,
    this.highestBidderId,
    this.highestBidderName,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.finalPrice,
    this.paymentDueAt,
    this.reminderSent = false,
    this.shippingAddress,
    this.deliveryStatus = OrderStatus.pending,
    this.paymentDate, // ✅ Added
  });

  // ✅ AUTO-STATUS LOGIC
  // Updated: Paid+1 = Shipped, Paid+2 = Delivered
  DateTime? get estimatedDeliveryDate =>
      paymentDate?.add(const Duration(days: 2));
  DateTime? get shippedDate => paymentDate?.add(const Duration(days: 1));

  OrderStatus get effectiveDeliveryStatus {
    if (status != AuctionStatus.sold) return OrderStatus.pending;
    if (deliveryStatus == OrderStatus.delivered) return OrderStatus.delivered;
    if (paymentDate == null)
      return OrderStatus.pending; // Should accept payment first

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final delDt = estimatedDeliveryDate!;
    final delDay = DateTime(delDt.year, delDt.month, delDt.day);

    final shipDt = shippedDate!;
    final shipDay = DateTime(shipDt.year, shipDt.month, shipDt.day);

    if (!today.isBefore(delDay)) return OrderStatus.delivered;
    if (!today.isBefore(shipDay)) return OrderStatus.shipped;

    return deliveryStatus;
  }

  factory Auction.fromMap(String id, Map<String, dynamic> map) {
    return Auction(
      id: id,
      artId: (map["artId"] ?? "").toString(),
      artTitle: (map["artTitle"] ?? "").toString(),
      artImageUrl: (map["artImageUrl"] ?? "").toString(),
      artistName: (map["artistName"] ?? "").toString(),
      description: (map["description"] ?? "").toString(),
      size: (map["size"] ?? "").toString(),
      aboutPiece: (map["aboutPiece"] ?? "").toString(),
      startTime: _parseDateTime(map["startTime"]),
      endTime: _parseDateTime(map["endTime"]),
      startingBid: _toInt(map["startingBid"]),
      minIncrement: _toInt(map["minIncrement"]),
      currentBid: _toInt(map["currentBid"]),
      highestBidderId: map["highestBidderId"]?.toString(),
      highestBidderName: map["highestBidderName"]?.toString(),
      status: _parseAuctionStatus(map["status"]),
      createdAt: _parseDateTime(map["createdAt"]),
      createdBy: (map["createdBy"] ?? "").toString(),
      finalPrice: map["finalPrice"] != null ? _toInt(map["finalPrice"]) : null,
      paymentDueAt: _parseDateTime(map["paymentDueAt"]),
      reminderSent: map["reminderSent"] == true,
      shippingAddress: map["shippingAddress"] is Map
          ? Map<String, dynamic>.from(map["shippingAddress"])
          : null,
      deliveryStatus: _parseOrderStatus(map["deliveryStatus"]),
      paymentDate: _parseDateTime(map["paymentDate"]), // ✅ Added
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "artId": artId,
      "artTitle": artTitle,
      "artImageUrl": artImageUrl,
      "artistName": artistName,
      "description": description,
      "size": size,
      "aboutPiece": aboutPiece,
      "startTime": Timestamp.fromDate(startTime),
      "endTime": Timestamp.fromDate(endTime),
      "startingBid": startingBid,
      "minIncrement": minIncrement,
      "currentBid": currentBid,
      "highestBidderId": highestBidderId,
      "highestBidderName": highestBidderName,
      "status": status.name,
      "createdAt": Timestamp.fromDate(createdAt),
      "createdBy": createdBy,
      "finalPrice": finalPrice,
      "paymentDueAt": paymentDueAt != null
          ? Timestamp.fromDate(paymentDueAt!)
          : null,
      "reminderSent": reminderSent,
      "shippingAddress": shippingAddress,
      "deliveryStatus": deliveryStatus.name,
      "paymentDate": paymentDate != null
          ? Timestamp.fromDate(paymentDate!)
          : null, // ✅ Added
    };
  }
}

AuctionStatus _parseAuctionStatus(dynamic v) {
  final s = v?.toString().toLowerCase() ?? "";
  if (s == "live") return AuctionStatus.live;
  if (s == "ended") return AuctionStatus.ended;
  if (s == "sold") return AuctionStatus.sold;
  if (s == "pending_payment") return AuctionStatus.pending_payment;
  if (s == "unsold") return AuctionStatus.unsold;
  return AuctionStatus.scheduled;
}

OrderStatus _parseOrderStatus(dynamic v) {
  final s = v?.toString().toLowerCase() ?? "";
  if (s == "shipped") return OrderStatus.shipped;
  if (s == "delivered") return OrderStatus.delivered;
  return OrderStatus.pending;
}

// ---------------- BID ----------------

class Bid {
  final String id;
  final int amount;
  final String userId;
  final String userName;
  final DateTime createdAt;

  Bid({
    required this.id,
    required this.amount,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory Bid.fromMap(String id, Map<String, dynamic> map) {
    return Bid(
      id: id,
      amount: _toInt(map["amount"]),
      userId: (map["userId"] ?? "").toString(),
      userName: (map["userName"] ?? "").toString(),
      createdAt: _parseDateTime(map["createdAt"]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "amount": amount,
      "userId": userId,
      "userName": userName,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }
}

// ---------------- NOTIFICATION ----------------

enum NotificationType { new_auction, win, reminder }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? auctionId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.auctionId,
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: (map["title"] ?? "").toString(),
      body: (map["body"] ?? "").toString(),
      type: _parseNotifType(map["type"]),
      auctionId: map["auctionId"]?.toString(),
      read: map["read"] == true,
      createdAt: _parseDateTime(map["createdAt"]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "body": body,
      "type": type.name,
      "auctionId": auctionId,
      "read": read,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }
}

NotificationType _parseNotifType(dynamic v) {
  final s = v?.toString().toLowerCase() ?? "";
  if (s == "win") return NotificationType.win;
  if (s == "reminder") return NotificationType.reminder;
  return NotificationType.new_auction;
}

// ---------------- HELPERS ----------------

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? 0;
  return 0;
}

DateTime _parseDateTime(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is DateTime) return v;
  if (v is Timestamp) return v.toDate(); // ✅ Firestore Timestamp support
  if (v is String) {
    final dt = DateTime.tryParse(v);
    if (dt != null) return dt;
  }
  return DateTime.now();
}
