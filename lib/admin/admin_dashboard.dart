import 'package:artiva/admin/add_edit_exhibition.dart';
import 'package:artiva/admin/users_page.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:artiva/auth/auth_service.dart';

// Pages
import 'manage_artworks.dart';
import 'exhibition_management.dart';
import 'package:artiva/admin/reviews_page.dart';

// Separate booking pages
import 'exhibition_bookings_page.dart';
import 'artwork_orders_page.dart';

enum AdminMode { exhibition, artwork }

enum ExhibitionDashFilter { all, active, unarchive, soldOut }

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color accent = Color(0xFFFF8C1A);

  AdminMode _mode = AdminMode.exhibition;
  int _index = 0;

  Future<void> _logout() async {
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
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _setMode(AdminMode next) {
    if (_mode == next) return;
    setState(() {
      _mode = next;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _NavConfig nav = _buildNavConfig(_mode);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: IndexedStack(index: _index, children: nav.pages),
      bottomNavigationBar: _BottomNav(
        items: nav.items,
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }

  _NavConfig _buildNavConfig(AdminMode mode) {
    final dashboardPage = _AdminDashboardHome(
      mode: mode,
      onModeChanged: _setMode,
      onLogout: _logout,
    );

    final Widget bookingsPage = (mode == AdminMode.exhibition)
        ? const ExhibitionBookingsPage()
        : const ArtworkOrdersPage();

    if (mode == AdminMode.artwork) {
      return _NavConfig(
        pages: [
          dashboardPage,
          bookingsPage,
          const ManageArtworksPage(),
          const ReviewsPage(),
        ],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image_rounded),
            label: "Artworks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_rounded),
            label: "Reviews",
          ),
        ],
      );
    }

    return _NavConfig(
      pages: [
        dashboardPage,
        bookingsPage,
        const AddEditExhibitionPage(), // ✅ third tab now opens add exhibition form
      ],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: "Dashboard",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_rounded),
          label: "Bookings",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box_rounded),
          label: "Add",
        ),
      ],
    );
  }
}

class _NavConfig {
  final List<Widget> pages;
  final List<BottomNavigationBarItem> items;

  _NavConfig({required this.pages, required this.items});
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<BottomNavigationBarItem> items;

  const _BottomNav({
    required this.index,
    required this.onChanged,
    required this.items,
  });

  static const Color accent = Color(0xFFFF8C1A);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: index,
      onTap: onChanged,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: accent,
      unselectedItemColor: Colors.black45,
      showUnselectedLabels: true,
      items: items,
    );
  }
}

/// ================= DASHBOARD HOME =================

class _AdminDashboardHome extends StatefulWidget {
  final AdminMode mode;
  final ValueChanged<AdminMode> onModeChanged;
  final Future<void> Function() onLogout;

  const _AdminDashboardHome({
    required this.mode,
    required this.onModeChanged,
    required this.onLogout,
  });

  static const Color accent = Color(0xFFFF8C1A);

  @override
  State<_AdminDashboardHome> createState() => _AdminDashboardHomeState();

  static Widget _segTab(
    String text, {
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardHomeState extends State<_AdminDashboardHome> {
  UserFilter _userFilter = UserFilter.all;
  ExhibitionDashFilter _exFilter = ExhibitionDashFilter.all;

  Stream<int> _totalUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user')
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> _totalOrders() {
    return FirebaseFirestore.instance
        .collection('orders')
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> _totalBookings() {
    return FirebaseFirestore.instance
        .collection('passes')
        .snapshots()
        .map((s) => s.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final bool isExhibition = widget.mode == AdminMode.exhibition;
    final bool isArtwork = widget.mode == AdminMode.artwork;

    return AdminScaffold(
      title: "Booking Overview",
      showBack: false,
      actions: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Color(0xFFFF7A18)),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () async => await widget.onLogout(),
          icon: const Icon(Icons.logout, color: Colors.white),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          // Segmented switch
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _AdminDashboardHome._segTab(
                  "Exhibition Bookings",
                  active: isExhibition,
                  onTap: () => widget.onModeChanged(AdminMode.exhibition),
                ),
                _AdminDashboardHome._segTab(
                  "Artwork Orders",
                  active: isArtwork,
                  onTap: () => widget.onModeChanged(AdminMode.artwork),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ✅ STATS — LOGIC ONLY CHANGED
          Row(
            children: [
              _StatCounter(
                icon: Icons.people_rounded,
                label: "Total Users",
                stream: _totalUsers(),
              ),
              const SizedBox(width: 10),
              _StatCounter(
                icon: Icons.shopping_bag_rounded,
                label: "Total Orders",
                stream: _totalOrders(),
              ),
              const SizedBox(width: 10),
              _StatCounter(
                icon: Icons.today_rounded,
                label: "Total Bookings",
                stream: _totalBookings(),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Status chips (UNCHANGED)
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(width: 10),
                if (isExhibition) ...[
                  _ChipLike(
                    text: "All",
                    active: _exFilter == ExhibitionDashFilter.all,
                    onTap: () =>
                        setState(() => _exFilter = ExhibitionDashFilter.all),
                  ),
                  const SizedBox(width: 10),
                  _ChipLike(
                    text: "Active",
                    active: _exFilter == ExhibitionDashFilter.active,
                    onTap: () =>
                        setState(() => _exFilter = ExhibitionDashFilter.active),
                  ),
                  const SizedBox(width: 10),
                  _ChipLike(
                    text: "Unarchive",
                    active: _exFilter == ExhibitionDashFilter.unarchive,
                    onTap: () => setState(
                      () => _exFilter = ExhibitionDashFilter.unarchive,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ChipLike(
                    text: "Sold Out",
                    active: _exFilter == ExhibitionDashFilter.soldOut,
                    onTap: () => setState(
                      () => _exFilter = ExhibitionDashFilter.soldOut,
                    ),
                  ),
                ],

                if (isArtwork) ...[
                  _ChipLike(
                    text: "All",
                    active: _userFilter == UserFilter.all,
                    onTap: () => setState(() => _userFilter = UserFilter.all),
                  ),
                  const SizedBox(width: 10),
                  _ChipLike(
                    text: "Active",
                    active: _userFilter == UserFilter.active,
                    onTap: () =>
                        setState(() => _userFilter = UserFilter.active),
                  ),
                  const SizedBox(width: 10),
                  _ChipLike(
                    text: "Archived",
                    active: _userFilter == UserFilter.archived,
                    onTap: () =>
                        setState(() => _userFilter = UserFilter.archived),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          Container(
            height: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: (isArtwork)
                ? UsersListBody(filter: _userFilter)
                : ExhibitionManagementBody(filter: _exFilter),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  static const Color accent = Color(0xFFFF8C1A);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.10), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: accent),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCounter extends StatelessWidget {
  final IconData icon;
  final String label;
  final Stream<int> stream;

  const _StatCounter({
    required this.icon,
    required this.label,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        return _StatCard(
          icon: icon,
          value: snapshot.data?.toString() ?? "0",
          label: label,
        );
      },
    );
  }
}

class _ChipLike extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback? onTap;

  const _ChipLike({required this.text, required this.active, this.onTap});

  static const Color accent = Color(0xFFFF8C1A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? accent.withOpacity(0.18) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? accent : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? accent : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
