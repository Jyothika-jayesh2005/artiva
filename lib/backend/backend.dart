import 'models.dart';

abstract class Backend {
  // ---------------- Auth ----------------
  AppUser? get currentUser;

  Future<AppUser> login({required String email, required String password});

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> logout();

  // ---------------- Orders ----------------
  Future<List<ArtworkOrder>> getAllOrders(); // admin
  Future<List<ArtworkOrder>> getMyOrders(String userEmail); // customer

  Future<String> createOrder({
    required String artworkId,
    required String artTitle,
    required String price,
    required int quantity,
    required String address,
    String? imagePath,
  });

  Future<void> updateOrderStatus(String orderId, OrderStatus status);

  // ---------------- Ratings ----------------
  Future<void> submitOrderRating({
    required String orderId,
    required int rating, // 1..5
    String? review,
  });

  Future<void> deleteOrderReview(String orderId); // admin

  // ⭐ used in ArtworkDetailsPage
  Future<ArtworkRatingSummary> getArtworkRating(String artworkId);

  // ---------------- EXHIBITIONS ----------------
  Future<List<Exhibition>> getExhibitions({bool includeArchived = false});

  Future<void> upsertExhibition(Exhibition exhibition); // admin create/update

  Future<void> setExhibitionArchived(String exhibitionId, bool archived); // admin

  // ✅ used in ExhibitionPaymentPage
  Future<String> bookExhibition({
    required String exhibitionId,
    required int seats,
  });

  Future<List<ExhibitionBooking>> getAllExhibitionBookings(); // admin
  Future<List<ExhibitionBooking>> getMyExhibitionBookings(String userEmail); // customer
}
