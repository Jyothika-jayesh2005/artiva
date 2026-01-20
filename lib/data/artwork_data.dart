class ArtworkData {
  // ✅ Single source of truth
  static List<Map<String, dynamic>> artworks = [
    {
      "id": "1",
      "title": "Abstract Face",
      "category": "Painting",
      "price": "₹12,000",
      "image": "assets/art1.jpeg",
      "rating": "4.6",
      "paper": "Canvas",
      "size_cm": "60 × 80 cm",
      "size_in": "24 × 32 in",
      "coa": "Yes",
      "description":
          "A bold abstract portrait exploring emotion and identity through color and form.",
      "totalQuantity": "5",
      "soldQuantity": "2",
    },
    {
      "id": "2",
      "title": "Modern Portrait",
      "category": "Digital",
      "price": "₹9,500",
      "image": "assets/art2.jpeg",
      "rating": "4.4",
      "paper": "Art Paper",
      "size_cm": "50 × 70 cm",
      "size_in": "20 × 28 in",
      "coa": "No",
      "description": "A modern digital portrait with clean lines and subtle tones.",
      "totalQuantity": "1",
      "soldQuantity": "1",
    },
    {
      "id": "3",
      "title": "Creative Expression",
      "category": "Abstract",
      "price": "₹15,000",
      "image": "assets/art3.jpeg",
      "rating": "4.8",
      "paper": "Canvas",
      "size_cm": "70 × 90 cm",
      "size_in": "28 × 36 in",
      "coa": "Yes",
      "description":
          "An expressive abstract composition that blends emotion and movement.",
      "totalQuantity": "2",
      "soldQuantity": "2",
    },
  ];

  // ================= STOCK =================
  static void reduceStock(String id) {
    final index =
        artworks.indexWhere((art) => (art["id"] ?? "").toString() == id);
    if (index == -1) return;

    final sold =
        int.tryParse((artworks[index]["soldQuantity"] ?? "0").toString()) ?? 0;
    final total =
        int.tryParse((artworks[index]["totalQuantity"] ?? "0").toString()) ?? 0;

    if (sold < total) {
      artworks[index]["soldQuantity"] = (sold + 1).toString();
    }
  }

  static void addArtwork(Map<String, dynamic> artwork) {
    artworks.add(artwork);
  }

  // ================= ✅ FAVOURITES (WISHLIST) =================
  // In-memory only (because no backend). It will reset if app restarts.
  static final Set<String> _favouriteIds = {};

  static String _idOf(Map<String, dynamic> art) => (art["id"] ?? "").toString();

  static bool isFavourite(String artworkId) => _favouriteIds.contains(artworkId);

  static void toggleFavourite(String artworkId) {
    if (_favouriteIds.contains(artworkId)) {
      _favouriteIds.remove(artworkId);
    } else {
      _favouriteIds.add(artworkId);
    }
  }

  static List<Map<String, dynamic>> favouriteArtworks() {
    return artworks.where((a) => _favouriteIds.contains(_idOf(a))).toList();
  }
}
