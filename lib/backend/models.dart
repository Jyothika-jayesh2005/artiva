// ---------------- USER ----------------

enum Role { admin, user }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final Role role;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });
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
  final String imagePath;
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
    required this.imagePath,
    required this.isArchived,
  });

  int get remainingSeats => totalSeats - bookedSeats;
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
}

// ---------------- ARTWORK ORDER ----------------

enum OrderStatus { pending, shipped, delivered, cancelled }

class ArtworkOrder {
  final String id;

  // required for relating order -> artwork
  final String? artId;

  final String artTitle;
  final String customerName;
  final String customerEmail;

  final int quantity;
  final int price;

  // ✅ NEW fields you are trying to use
  final String? address;
  final String? imagePath;
  final String? size; // size in cm (example)
  final String? inch; // size in inch (example)

  final OrderStatus status;
  final DateTime orderedAt;

  final int? rating;
  final String? review;
  final DateTime? ratedAt;

  ArtworkOrder({
    required this.id,
    this.artId,
    required this.artTitle,
    required this.customerName,
    required this.customerEmail,
    required this.quantity,
    required this.price,

    this.address,
    this.imagePath,
    this.size,
    this.inch,

    required this.status,
    required this.orderedAt,
    this.rating,
    this.review,
    this.ratedAt,
  });
}

// ---------------- ARTWORK RATING SUMMARY ----------------

class ArtworkRatingSummary {
  final double avg;
  final int count;

  const ArtworkRatingSummary({
    required this.avg,
    required this.count,
  });

  String get label => avg == 0 ? "—" : avg.toStringAsFixed(1);
}
