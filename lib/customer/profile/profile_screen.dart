import 'package:artiva/customer/profile/my_passes.dart';
import 'package:flutter/material.dart';

import 'profile_settings.dart';
import 'my_orders.dart';
import 'saved_address.dart';
import 'favourites.dart';
import 'help_support.dart';
import 'about_terms.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

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
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // ✅ If you use any auth later (FirebaseAuth, shared_preferences, etc.)
    // clear it here.
    //
    // Example later:
    // await FirebaseAuth.instance.signOut();
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();

    // ✅ IMPORTANT: reset the whole navigation stack
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/', // or '/login' if you want to go directly to login page
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Profile",
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),

          // Avatar + name
          Center(
            child: Column(
              children: const [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 42,
                    color: primary,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "John Doe",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "john@example.com",
                  style: TextStyle(color: Colors.grey),
                ),
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
          _cardItem(
            context,
            icon: Icons.help_outline,
            title: "Help & Support",
            page: const HelpSupportPage(),
          ),
          _cardItem(
            context,
            icon: Icons.info_outline,
            title: "About / Terms",
            page: const AboutTermsPage(),
          ),

          const SizedBox(height: 20),

          // ✅ Logout (WORKING)
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
  }

  Widget _cardItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
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
        leading: CircleAvatar(
          backgroundColor: primary.withOpacity(0.12),
          child: Icon(icon, color: primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}
