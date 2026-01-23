import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/widgets/admin_scaffold.dart';

import 'add_artwork.dart';
import 'exhibition_management.dart';
import 'booking_overview.dart';
import 'users_page.dart';
import 'package:artiva/admin/manage_artworks.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await authService.logout();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Admin Dashboard",
      showBack: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async => await _logout(context),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: ListView(
          children: [
            _card(
              icon: Icons.add_photo_alternate,
              title: "Add Artwork",
              subtitle: "Upload new artwork",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddArtworkPage()),
                );
              },
            ),
            _card(
              icon: Icons.event,
              title: "Exhibitions",
              subtitle: "Manage exhibitions",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExhibitionManagementPage(),
                  ),
                );
              },
            ),
            _card(
              icon: Icons.confirmation_number,
              title: "Bookings",
              subtitle: "View customer bookings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookingOverviewPage(),
                  ),
                );
              },
            ),
            _card(
              icon: Icons.people,
              title: "Users",
              subtitle: "View registered users",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersPage()),
                );
              },
            ),
            _card(
              icon: Icons.brush,
              title: "Manage Artworks",
              subtitle: "View, edit or delete artworks",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageArtworksPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 120,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 26,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2CBF).withOpacity(0.22),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, size: 32, color: const Color(0xFF7B2CBF)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
