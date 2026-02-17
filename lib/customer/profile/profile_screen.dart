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
  static const Color secondary = Color(0xFFEFCF6D);

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color.fromARGB(255, 20, 20, 20)),
            ),
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
        final email = user?.email ?? "";
        final photoUrl = (user?.photoUrl ?? "").trim();

        return CustomerScaffold(
          currentIndex: -1,
          title: "Profile",
          // Reverting to standard header as requested
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withOpacity(0.2),
                            width: 4,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: primary,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30), // Space before menu

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildSectionTitle("Account"),
                      _buildGroupContainer([
                        _buildTile(
                          context,
                          icon: Icons.person_outline,
                          title: "Profile Settings",
                          page: const ProfileSettingsPage(),
                        ),
                        _buildDivider(),
                        _buildTile(
                          context,
                          icon: Icons.shopping_bag_outlined,
                          title: "My Orders",
                          page: const MyOrdersPage(),
                        ),
                        _buildDivider(),
                        _buildTile(
                          context,
                          icon: Icons.confirmation_number_outlined,
                          title: "My Passes",
                          page: const MyPassesPage(),
                        ),
                        _buildDivider(),
                        _buildTile(
                          context,
                          icon: Icons.location_on_outlined,
                          title: "Saved Addresses",
                          page: const SavedAddressPage(),
                        ),
                        _buildDivider(),
                        _buildTile(
                          context,
                          icon: Icons.favorite_border,
                          title: "Favourites",
                          page: const FavouritesPage(),
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle("Support & Legal"),
                      _buildGroupContainer([
                        if (user != null && user.uid.isNotEmpty)
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('support_threads')
                                .doc(user.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final data =
                                  snapshot.data?.data()
                                      as Map<String, dynamic>?;
                              final bool unread =
                                  data != null && data['userUnread'] == true;
                              return _buildTile(
                                context,
                                icon: Icons.help_outline,
                                title: "Help & Support",
                                page: const HelpSupportPage(),
                                showBadge: unread,
                              );
                            },
                          )
                        else
                          _buildTile(
                            context,
                            icon: Icons.help_outline,
                            title: "Help & Support",
                            page: const HelpSupportPage(),
                          ),
                        _buildDivider(),
                        _buildTile(
                          context,
                          icon: Icons.info_outline,
                          title: "About / Terms",
                          page: const AboutTermsPage(),
                        ),
                      ]),

                      const SizedBox(height: 30),
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade100, indent: 60);
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    bool showBadge = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Color(0xFF1A1A1A),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBadge)
            Container(
              margin: const EdgeInsets.only(right: 10),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.grey,
          ),
        ],
      ),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton(
      onPressed: () => _logout(context),
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.2)),
        ),
        backgroundColor: Colors.red.withOpacity(0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.logout_rounded, size: 20),
          SizedBox(width: 8),
          Text(
            "Log Out",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
