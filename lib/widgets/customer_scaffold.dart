import 'package:artiva/customer/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:artiva/customer/artwork_list.dart';
import 'package:artiva/customer/exhibition_screen.dart';
import 'package:artiva/customer/home_screen.dart';

class CustomerScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final String title;

  // lets any page override what back arrow does
  final VoidCallback? onBack;

  // ✅ NEW: optional widget shown under the header title row (inside gradient)
  // Example: search bar, category chips, etc.
  final Widget? headerBottom;

  const CustomerScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.title = "Artiva",
    this.onBack,
    this.headerBottom,
  });

  void _onNavTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const ArtHomePage();
        break;
      case 1:
        page = const ArtworkListPage();
        break;
      case 2:
        page = const ExhibitionScreen();
        break;
      default:
        page = const ArtHomePage();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  void _defaultBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ArtHomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1DC),
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              padding: const EdgeInsets.fromLTRB(12, 18, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE16417), Color(0xFF80431F)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Back button only for inner pages
                      if (currentIndex == -1)
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: onBack ?? () => _defaultBack(context),
                        ),

                      // ✅ title constrained (prevents overflow)
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Profile icon only on main tabs
                      if (currentIndex != -1)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person_outline,
                                color: Colors.black),
                          ),
                        ),
                    ],
                  ),

                  // ✅ NEW: extra header content (search/categories/etc)
                  if (headerBottom != null) ...[
                    const SizedBox(height: 12),
                    headerBottom!,
                  ],
                ],
              ),
            ),

            // ================= BODY =================
            Expanded(child: body),
          ],
        ),
      ),

      // ================= BOTTOM NAV =================
      bottomNavigationBar: currentIndex == -1
          ? null
          : Container(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navIcon(context, Icons.home, 0),
                  _navIcon(context, Icons.palette, 1),
                  _navIcon(context, Icons.event, 2),
                ],
              ),
            ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, int index) {
    final active = currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(context, index),
      child: Icon(
        icon,
        size: 26,
        color: active ? const Color(0xFFFF9F1C) : Colors.grey,
      ),
    );
  }
}
