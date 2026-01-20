import '../models/exhibition_model.dart';

class ExhibitionData {
  static final List<Exhibition> exhibitions = [
    Exhibition(
      id: "ex1",
      title: "Modern Art Showcase",
      venue: "City Gallery, Kochi",
      dateTime: DateTime.now().add(const Duration(days: 2)),
      description: "A curated collection of modern paintings and sculptures.",
      totalSeats: 120,
      bookedSeats: 35,
      pricePerSeat: 250,
      imagePath: "assets/exbhi1.jpg", // ✅
      isArchived: false,
    ),
    Exhibition(
      id: "ex2",
      title: "Watercolor Weekend",
      venue: "Art Hall, Trivandrum",
      dateTime: DateTime.now().add(const Duration(hours: 5)),
      description: "Live watercolor demos and featured artists.",
      totalSeats: 80,
      bookedSeats: 80,
      pricePerSeat: 150,
      imagePath: "assets/exbhi2.jpg", // ✅
      isArchived: false,
    ),
    Exhibition(
      id: "ex3",
      title: "Classic Portrait Exhibition",
      venue: "Museum Auditorium, Calicut",
      dateTime: DateTime.now().add(const Duration(days: 3)),
      description: "Portraits from emerging and established artists.",
      totalSeats: 60,
      bookedSeats: 20,
      pricePerSeat: 200,
      imagePath: "assets/exbhi3.jpg", // ✅
      isArchived: false,
    ),
  ];
}
