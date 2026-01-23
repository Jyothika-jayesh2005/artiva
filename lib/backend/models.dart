class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final Role role;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  AppUser copyWith({
    String? name,
    String? phone,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
    );
  }
}

enum Role { admin, customer }

// ----------------- ARTWORK ORDERS + REVIEWS -----------------

enum OrderStatus { processing, shipped, delivered }

class ArtworkOrder {
  final String id;
  final String artworkId;
  final String artTitle;

  final String customerName;
  final String customerEmail;

  final int quantity;
  final String price;
  final String address;

  final String? imagePath;
  final DateTime orderedAt;

  OrderStatus status;

  int? rating;
  String? review;
  DateTime? ratedAt;

  ArtworkOrder({
    required this.id,
    required this.artworkId,
    required this.artTitle,
    required this.customerName,
    required this.customerEmail,
    required this.quantity,
    required this.price,
    required this.address,
    required this.orderedAt,
    required this.status,
    this.imagePath,
    this.rating,
    this.review,
    this.ratedAt,
  });
}

class ArtworkRatingSummary {
  final double avgRating;
  final int ratingCount;

  const ArtworkRatingSummary({
    required this.avgRating,
    required this.ratingCount,
  });

  String get label => avgRating == 0 ? "0.0" : avgRating.toStringAsFixed(1);
  int get count => ratingCount;
}

// ----------------- EXHIBITIONS -----------------

class Exhibition {
  final String id;
  final String title;
  final String venue;
  final DateTime dateTime;
  final String description;

  int totalSeats;
  int bookedSeats;
  int pricePerSeat;

  String imagePath;
  bool isArchived;

  Exhibition({
    required this.id,
    required this.title,
    required this.venue,
    required this.dateTime,
    required this.description,
    required this.totalSeats,
    required this.bookedSeats,
    required this.pricePerSeat,
    required this.imagePath,
    required this.isArchived,
  });

  int get remainingSeats => (totalSeats - bookedSeats).clamp(0, totalSeats);
}

class ExhibitionBooking {
  final String id;

  final String exhibitionId;
  final String exhibitionTitle;
  final String venue;

  final int seats;
  final int pricePerSeat;
  final int totalAmount;

  final String customerName;
  final String customerEmail;

  final DateTime bookedAt;

  ExhibitionBooking({
    required this.id,
    required this.exhibitionId,
    required this.exhibitionTitle,
    required this.venue,
    required this.seats,
    required this.pricePerSeat,
    required this.totalAmount,
    required this.customerName,
    required this.customerEmail,
    required this.bookedAt,
  });
}
