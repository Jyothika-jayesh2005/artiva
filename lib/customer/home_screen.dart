import 'dart:async';
import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/widgets/artwork_card.dart';
import 'package:artiva/customer/artwork_list.dart';
import 'package:artiva/customer/artwork_detail.dart';
import 'package:artiva/backend/backend_provider.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/notification_service.dart';
import 'package:artiva/customer/auctions/auction_screen.dart';
import 'package:artiva/customer/exhibition_screen.dart';

class ArtHomePage extends StatefulWidget {
  const ArtHomePage({super.key});

  @override
  State<ArtHomePage> createState() => _ArtHomePageState();
}

class _ArtHomePageState extends State<ArtHomePage> {
  int selectedCategory = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  // Slideshow variables
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  late Stream<List<Map<String, dynamic>>> _artworksStream;

  final List<String> categories = const [
    "All",
    "Painting",
    "Digital",
    "Sculpture",
    "Abstract",
    "Photography",
    "Sketch",
  ];

  final List<Map<String, String>> _heroSlides = [
    {
      "image": "assets/heroartwork.png",
      "title": "Discover Art",
      "subtitle": "Original artworks from creators",
      "route": "home",
    },
    {
      "image": "assets/heroauction.png",
      "title": "Exclusive Auctions",
      "subtitle": "Bid on premium masterpieces",
      "route": "auction",
    },
    {
      "image": "assets/heroexhibhition.png",
      "title": "Live Exhibitions",
      "subtitle": "Experience art in person",
      "route": "exhibition",
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = authService.currentUser;
    if (user != null) {
      NotificationService().startUserListener(user.uid);
    }

    _artworksStream = backend.watchArtworks();

    // Start auto-play
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _heroSlides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    NotificationService().stopListeners();
    NotificationService().startGlobalListener();
    _searchCtrl.dispose();
    _pageController.dispose();
    _timer?.cancel();
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

  void _handleSlideTap(String route) {
    if (route == "auction") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuctionScreen()),
      );
    } else if (route == "exhibition") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExhibitionScreen()),
      );
    }
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
            _heroSlideshow(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Featured Works",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _goToList(categoryOverride: "All"),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE16417),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text("See All"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Artworks List
            _artHorizontalList(),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _goToList(),
          decoration: InputDecoration(
            hintText: "Search artworks...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: const Color(0xFFE16417).withOpacity(0.8),
              ),
              onPressed: () => _goToList(),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _categories() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final active = selectedCategory == index;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(categories[index]),
              labelStyle: TextStyle(
                color: active ? Colors.white : const Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              selected: active,
              onSelected: (bool selected) {
                setState(() {
                  selectedCategory = index;
                });
                _goToList(categoryOverride: categories[index]);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFE16417),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: active
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              elevation: 0,
              pressElevation: 0,
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _heroSlideshow() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _heroSlides.length,
            itemBuilder: (context, index) {
              final slide = _heroSlides[index];
              return GestureDetector(
                onTap: () => _handleSlideTap(slide["route"]!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          slide["image"]!,
                          fit: BoxFit.fill,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE16417),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        // Text Content
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE16417),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "FEATURED",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slide["title"]!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                slide["subtitle"]!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _heroSlides.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFFE16417)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _artHorizontalList() {
    return SizedBox(
      height: 290, // Adjusted height for vertical cards
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _artworksStream,
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

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: artworks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final raw = artworks[index];

              // Normalize image path
              final normalized = Map<String, dynamic>.from(raw);
              normalized["image"] ??= normalized["imagePath"];

              return SizedBox(
                width: 180, // Fixed width for vertical card
                child: ArtworkCard(
                  artwork: normalized,
                  onTap: () {
                    final detailArt = normalized.map(
                      (k, v) => MapEntry(k, (v ?? "").toString()),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtworkDetailsPage(artwork: detailArt),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
