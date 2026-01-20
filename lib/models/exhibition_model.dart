class Exhibition {
  final String id;
  final String title;
  final String venue;
  final DateTime dateTime;
  final String description;
  final int totalSeats;
  final int bookedSeats;
  final int pricePerSeat;
  final bool isArchived;

  // ✅ NEW
  final String imagePath; // assets/... OR file path

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
    this.isArchived = false,
  });

  int get remainingSeats => totalSeats - bookedSeats;
  bool get isFull => remainingSeats <= 0;
  bool get isClosed => DateTime.now().isAfter(dateTime);

  Exhibition copyWith({
    int? bookedSeats,
    bool? isArchived,
    String? imagePath,
  }) {
    return Exhibition(
      id: id,
      title: title,
      venue: venue,
      dateTime: dateTime,
      description: description,
      totalSeats: totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      pricePerSeat: pricePerSeat,
      imagePath: imagePath ?? this.imagePath,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
