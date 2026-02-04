import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/models.dart';

import 'profile_settings.dart';
import 'my_orders.dart';
import 'saved_address.dart';
import 'favourites.dart';
import 'help_support.dart';
import 'about_terms.dart';
import 'my_passes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primary = Color(0xFFE16417);
  static const Color cardBg = Colors.white;

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await authService.logout();
    if (!context.mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authService.userNotifier,
      builder: (context, AppUser? user, _) {
        final name = user?.name ?? "Guest";
        final email = user?.email ?? "-";
        final photoUrl = (user?.photoUrl ?? "").trim();

        return CustomerScaffold(
          currentIndex: -1,
          title: "Profile",
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 10),

              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 42, color: primary)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(email, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _cardItem(
                context,
                icon: Icons.person_outline,
                title: "Profile Settings",
                page: const ProfileSettingsPage(),
              ),
              _cardItem(
                context,
                icon: Icons.shopping_bag_outlined,
                title: "My Orders",
                page: const MyOrdersPage(),
              ),
              _cardItem(
                context,
                icon: Icons.confirmation_number_outlined,
                title: "My Passes",
                page: const MyPassesPage(),
              ),
              _cardItem(
                context,
                icon: Icons.location_on_outlined,
                title: "Saved Addresses",
                page: const SavedAddressPage(),
              ),
              _cardItem(
                context,
                icon: Icons.favorite_border,
                title: "Favourites",
                page: const FavouritesPage(),
              ),
              if (user != null && user.uid.isNotEmpty)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('support_threads')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final bool unread =
                        data != null && data['userUnread'] == true;

                    return _cardItem(
                      context,
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      page: const HelpSupportPage(),
                      showBadge: unread,
                    );
                  },
                )
              else
                _cardItem(
                  context,
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  page: const HelpSupportPage(),
                  showBadge: false,
                ),
              _cardItem(
                context,
                icon: Icons.info_outline,
                title: "About / Terms",
                page: const AboutTermsPage(),
              ),

              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _logout(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    bool showBadge = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: Icon(icon, color: primary),
            ),
            if (showBadge)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: showBadge ? FontWeight.bold : FontWeight.w600,
            color: showBadge ? primary : Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }
}
