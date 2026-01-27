import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> pages = [
    {
      "image": "assets/onboard1.png",
      "title": "Discover Curated Art",
      "desc": "Browse paintings, digital art, sculpture, photography, and more.",
    },
    {
      "image": "assets/onboard3.png",
      "title": "Buy Original Pieces",
      "desc": "View details, ratings, price, and place orders securely.",
    },
    {
      "image": "assets/onboard2.png",
      "title": "Book Exhibitions Easily",
      "desc": "Check seats, pricing, and book passes in seconds.",
    },
  ];

  void _goWelcome() {
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  void _next() {
    if (_currentIndex < pages.length - 1) {
      _controller.animateToPage(
        _currentIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _goWelcome();
    }
  }

  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: active ? 18 : 8,
      decoration: BoxDecoration(
        color: active
            ? Colors.orange
            : Colors.orange.withValues(alpha: 89), // no withOpacity
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _currentIndex == pages.length - 1;

    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        itemCount: pages.length,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, index) {
          final page = pages[index];

          return Stack(
            children: [
              // ✅ Background image
              Positioned.fill(
                child: Image.asset(
                  page["image"]!,
                  fit: BoxFit.cover,
                ),
              ),

              // ✅ Bottom overlay
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          page["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5A2E1C),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          page["desc"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFF7A5A4A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            pages.length,
                            (i) => _dot(i == _currentIndex),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // buttons (ONE skip only)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _goWelcome,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                    color: Colors.orange
                                        .withValues(alpha: 153),
                                  ),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 153),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  "Skip",
                                  style: TextStyle(
                                    color: Colors.brown,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _next,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  isLast ? "Get Started" : "Next",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
