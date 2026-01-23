import 'dart:math';
import 'backend.dart';
import 'models.dart';

class FakeBackend implements Backend {
  static const String adminEmail = 'admin@artiva.com';
  static const String adminPassword = 'admin123';

  AppUser? _currentUser;

  final List<AppUser> _users = [];
  final List<ArtworkOrder> _orders = [];

  final List<Exhibition> _exhibitions = [];
  final List<ExhibitionBooking> _exhibitionBookings = [];

  @override
  AppUser? get currentUser => _currentUser;

  // ---------------- AUTH ----------------

  @override
  Future<AppUser> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 120));

    // Admin login
    if (email.toLowerCase() == adminEmail.toLowerCase() &&
        password == adminPassword) {
      _currentUser = AppUser(
        id: 'admin',
        name: 'Admin',
        email: adminEmail,
        phone: '-',
        role: Role.admin,
      );
      return _currentUser!;
    }

    // Customer login
    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => throw Exception('No account found. Please register.'),
    );

    // Fake backend: no password stored/checked for customers
    _currentUser = user;
    return user;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final lower = email.toLowerCase();
    final exists = _users.any((u) => u.email.toLowerCase() == lower);
    if (exists) throw Exception('Email already registered. Please login.');

    final user = AppUser(
      id: lower,
      name: name,
      email: email,
      phone: phone,
      role: Role.customer,
    );

    _users.add(user);
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 60));
    _currentUser = null;
  }

  // ---------------- ORDERS ----------------

  @override
  Future<List<ArtworkOrder>> getAllOrders() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _requireAdmin();
    return List.unmodifiable(_orders);
  }

  @override
  Future<List<ArtworkOrder>> getMyOrders(String userEmail) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final me = _currentUser;
    if (me == null) throw Exception('Please login first.');

    final lower = userEmail.toLowerCase();
    return _orders
        .where((o) => o.customerEmail.toLowerCase() == lower)
        .toList(growable: false);
  }

  @override
  Future<String> createOrder({
    required String artworkId,
    required String artTitle,
    required String price,
    required int quantity,
    required String address,
    String? imagePath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));

    final me = _currentUser;
    if (me == null) throw Exception('Please login first.');
    if (me.role != Role.customer) throw Exception('Admin cannot create orders.');

    final id =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    _orders.add(
      ArtworkOrder(
        id: id,
        artworkId: artworkId,
        artTitle: artTitle,
        customerName: me.name,
        customerEmail: me.email,
        quantity: quantity,
        price: price,
        address: address,
        imagePath: imagePath,
        orderedAt: DateTime.now(),
        status: OrderStatus.processing,
      ),
    );

    return id;
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _requireAdmin();

    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) throw Exception('Order not found');

    _orders[idx].status = status;
  }

  // ---------------- RATINGS ----------------

  @override
  Future<void> submitOrderRating({
    required String orderId,
    required int rating,
    String? review,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final me = _currentUser;
    if (me == null) throw Exception('Please login first.');
    if (me.role != Role.customer) throw Exception('Login as customer');

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be 1–5');
    }

    final order = _orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );

    if (order.customerEmail.toLowerCase() != me.email.toLowerCase()) {
      throw Exception('Not your order');
    }

    if (order.status != OrderStatus.delivered) {
      throw Exception('Can rate only after delivery');
    }

    if (order.rating != null) {
      throw Exception('Already rated');
    }

    order.rating = rating;
    final trimmed = (review ?? '').trim();
    order.review = trimmed.isEmpty ? null : trimmed;
    order.ratedAt = DateTime.now();
  }

  @override
  Future<void> deleteOrderReview(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    _requireAdmin();

    final order = _orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw Exception('Order not found'),
    );

    // ✅ Deleting review updates everywhere because UI reads from backend.
    order.rating = null;
    order.review = null;
    order.ratedAt = null;
  }

  @override
  Future<ArtworkRatingSummary> getArtworkRating(String artworkId) async {
    await Future.delayed(const Duration(milliseconds: 60));

    final rated = _orders.where((o) {
      return o.artworkId == artworkId &&
          o.status == OrderStatus.delivered &&
          o.rating != null;
    }).toList();

    if (rated.isEmpty) {
      return const ArtworkRatingSummary(avgRating: 0, ratingCount: 0);
    }

    final sum = rated.fold<int>(0, (acc, o) => acc + (o.rating ?? 0));
    final avg = sum / rated.length;

    return ArtworkRatingSummary(avgRating: avg, ratingCount: rated.length);
  }

  // ---------------- EXHIBITIONS ----------------

  @override
  Future<List<Exhibition>> getExhibitions({bool includeArchived = false}) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final list = includeArchived
        ? List<Exhibition>.from(_exhibitions)
        : _exhibitions.where((e) => !e.isArchived).toList();

    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return List.unmodifiable(list);
  }

  @override
  Future<void> upsertExhibition(Exhibition exhibition) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _requireAdmin();

    final idx = _exhibitions.indexWhere((e) => e.id == exhibition.id);
    if (idx == -1) {
      _exhibitions.add(exhibition);
      return;
    }

    // don’t allow totalSeats < bookedSeats
    final alreadyBooked = _exhibitions[idx].bookedSeats;
    if (exhibition.totalSeats < alreadyBooked) {
      throw Exception('Total seats cannot be less than booked ($alreadyBooked)');
    }

    _exhibitions[idx] = exhibition;
  }

  @override
  Future<void> setExhibitionArchived(String exhibitionId, bool archived) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _requireAdmin();

    final idx = _exhibitions.indexWhere((e) => e.id == exhibitionId);
    if (idx == -1) throw Exception('Exhibition not found');

    _exhibitions[idx].isArchived = archived;
  }

  @override
  Future<String> bookExhibition({
    required String exhibitionId,
    required int seats,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final me = _currentUser;
    if (me == null) throw Exception('Please login first.');
    if (me.role != Role.customer) throw Exception('Admin cannot book.');

    if (seats <= 0) throw Exception('Seats must be at least 1');

    final ex = _exhibitions.firstWhere(
      (e) => e.id == exhibitionId,
      orElse: () => throw Exception('Exhibition not found'),
    );

    if (ex.isArchived) throw Exception('This exhibition is archived');
    if (ex.remainingSeats < seats) throw Exception('Not enough seats available');

    ex.bookedSeats += seats;

    final bookingId =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final total = seats * ex.pricePerSeat;

    _exhibitionBookings.add(
      ExhibitionBooking(
        id: bookingId,
        exhibitionId: ex.id,
        exhibitionTitle: ex.title,
        venue: ex.venue,
        seats: seats,
        pricePerSeat: ex.pricePerSeat,
        totalAmount: total,
        customerName: me.name,
        customerEmail: me.email,
        bookedAt: DateTime.now(),
      ),
    );

    return bookingId;
  }

  @override
  Future<List<ExhibitionBooking>> getAllExhibitionBookings() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _requireAdmin();

    final list = List<ExhibitionBooking>.from(_exhibitionBookings);
    list.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    return List.unmodifiable(list);
  }

  @override
  Future<List<ExhibitionBooking>> getMyExhibitionBookings(String userEmail) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final lower = userEmail.toLowerCase();
    final list = _exhibitionBookings
        .where((b) => b.customerEmail.toLowerCase() == lower)
        .toList();

    list.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    return List.unmodifiable(list);
  }

  // ---------------- helpers ----------------

  void _requireAdmin() {
    final me = _currentUser;
    if (me == null) throw Exception('Please login first.');
    if (me.role != Role.admin) throw Exception('Admin only');
  }
}
