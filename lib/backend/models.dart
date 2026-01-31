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
  final bool archived;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl = "",
    this.archived = false,
  });

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
      archived: map["archived"] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "email": email.toLowerCase().trim(),
      "phone": phone,
      "role": role == Role.admin ? "admin" : "user",
      "photoUrl": photoUrl,
      "archived": archived,
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
