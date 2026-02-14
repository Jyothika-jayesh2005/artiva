import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/widgets/artwork_card.dart';
import 'package:artiva/customer/artwork_list.dart';
import 'package:artiva/customer/artwork_detail.dart';
import 'package:artiva/backend/backend_provider.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/notification_service.dart';

class ArtHomePage extends StatefulWidget {
  const ArtHomePage({super.key});

  @override
  State<ArtHomePage> createState() => _ArtHomePageState();
}

class _ArtHomePageState extends State<ArtHomePage> {
  int selectedCategory = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> categories = const [
    "All",
    "Painting",
    "Digital",
    "Sculpture",
    "Abstract",
    "Photography",
    "Sketch",
  ];

  @override
  void initState() {
    super.initState();
    // Start listening for user notifications only when Home Screen loads
    final user = authService.currentUser;
    if (user != null) {
      NotificationService().startUserListener(user.uid);
    }
  }

  @override
  void dispose() {
    // Stop listening when Home Screen is disposed (e.g. logout)
    NotificationService().stopListeners();
    // Restart global listener for safety
    NotificationService().startGlobalListener();

    _searchCtrl.dispose();
    super.dispose();
  }

  void _goToList({String? categoryOverride, String? queryOverride}) {
    final cat = categoryOverride ?? categories[selectedCategory];
    final q = (queryOverride ?? _searchCtrl.text).trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtworkListPage(initialCategory: cat, initialQuery: q),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: 0,
      title: "Artiva",
      headerBottom: Column(
        children: [_searchBar(), const SizedBox(height: 12), _categories()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroCard(),
            const SizedBox(height: 18),
            _sectionTitle("Featured Works"),
            const SizedBox(height: 12),

            // ✅ FROM FIRESTORE
            _artHorizontalList(),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _goToList(),
        decoration: InputDecoration(
          hintText: "Search artworks",
          border: InputBorder.none,
          icon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => _goToList(),
          ),
        ),
      ),
    );
  }

  Widget _categories() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final active = selectedCategory == index;

          return GestureDetector(
            onTap: () {
              setState(() => selectedCategory = index);
              _goToList(categoryOverride: categories[index]);
            },
            child: Container(
              margin: EdgeInsets.only(right: 10, left: index == 0 ? 2 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFF9F1C)
                    : Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: active ? Colors.white : Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE16417), Color(0xFFEFCF6D)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Discover Art",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Original artworks\nfrom creators",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              child: SizedBox(
                width: 130,
                height: double.infinity,
                child: Image.asset(
                  "assets/home1.png",
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artHorizontalList() {
    return SizedBox(
      height: 300,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: backend.watchArtworks(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text("Error: ${snap.error}"));
          }

          final artworks = snap.data ?? [];
          if (artworks.isEmpty) {
            return const Center(child: Text("No artworks added yet"));
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: artworks.length,
            itemBuilder: (context, index) {
              final raw = artworks[index];

              // ✅ IMPORTANT FIX:
              // Your UI expects "image", but Firestore is saving "imagePath"
              final normalized = Map<String, dynamic>.from(raw);
              normalized["image"] ??= normalized["imagePath"];

              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: SizedBox(
                  width: 160,
                  height: 300,
                  child: ArtworkCard(
                    artwork: normalized,
                    onTap: () {
                      final detailArt = normalized.map(
                        (k, v) => MapEntry(k, (v ?? "").toString()),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ArtworkDetailsPage(artwork: detailArt),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
