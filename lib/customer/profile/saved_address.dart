import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/auth/auth_service.dart';

import 'add_edit_address.dart';
import '../checkout/checkout_page.dart';

class SavedAddressPage extends StatefulWidget {
  final bool isFromCheckout;
  final bool isSelectionMode; // ✅ Added
  final Map<String, String>? artwork;
  final int quantity;

  const SavedAddressPage({
    super.key,
    this.isFromCheckout = false,
    this.isSelectionMode = false, // ✅ Default false
    this.artwork,
    this.quantity = 1,
  });

  @override
  State<SavedAddressPage> createState() => _SavedAddressPageState();
}

class _SavedAddressPageState extends State<SavedAddressPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ use this everywhere -> no yellow unused warning
  String get _uid {
    final u = authService.currentUser;
    if (u == null) throw Exception("Please login first.");
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> get _addrCol =>
      _db.collection("users").doc(_uid).collection("addresses");

  Stream<QuerySnapshot<Map<String, dynamic>>> get _watchAddresses =>
      _addrCol.orderBy("createdAt", descending: true).snapshots();

  Future<void> _addAddress() async {
    final user = authService.currentUser;
    if (user == null) {
      _toast("Please login first.");
      return;
    }

    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAddressPage()),
    );
    if (result == null) return;

    await _addrCol.add({
      ...result,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    _toast("Address saved");
  }

  Future<void> _editAddress({
    required String docId,
    required Map<String, dynamic> current,
  }) async {
    final user = authService.currentUser;
    if (user == null) {
      _toast("Please login first.");
      return;
    }

    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAddressPage(
          name: (current["name"] ?? "").toString(),
          phone: (current["phone"] ?? "").toString(),
          address: (current["address"] ?? "").toString(),
          city: (current["city"] ?? "").toString(),
          district: (current["district"] ?? "").toString(),
          pincode: (current["pincode"] ?? "").toString(),
        ),
      ),
    );

    if (result == null) return;

    await _addrCol.doc(docId).update({
      ...result,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    _toast("Address updated");
  }

  Future<void> _deleteAddress({required String docId}) async {
    final user = authService.currentUser;
    if (user == null) {
      _toast("Please login first.");
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Address"),
        content: const Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _addrCol.doc(docId).delete();

    if (!mounted) return;
    _toast("Address deleted");
  }

  void _selectAddressForCheckout({
    required String addressId,
    required Map<String, dynamic> addressSnap,
  }) {
    // ✅ Handle basic selection mode (for auctions)
    if (widget.isSelectionMode) {
      Navigator.pop(context, addressSnap);
      return;
    }

    if (widget.isFromCheckout && widget.artwork != null) {
      final full = _formatFullAddress(addressSnap);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutPage(
            artwork: widget.artwork!,
            address: full,
            addressSnapshot: Map<String, dynamic>.from(addressSnap),
            addressId: addressId,
            quantity: widget.quantity,
          ),
        ),
      );
      return;
    }

    _toast("Open checkout to select an address");
  }

  String _formatFullAddress(Map<String, dynamic> a) {
    final name = (a["name"] ?? "").toString().trim();
    final phone = (a["phone"] ?? "").toString().trim();
    final address = (a["address"] ?? "").toString().trim();
    final city = (a["city"] ?? "").toString().trim();
    final district = (a["district"] ?? "").toString().trim();
    final pincode = (a["pincode"] ?? "").toString().trim();

    final line2Parts = <String>[
      if (city.isNotEmpty) city,
      if (district.isNotEmpty) district,
      if (pincode.isNotEmpty) pincode,
    ];

    return [
      if (name.isNotEmpty) "$name, $phone",
      if (address.isNotEmpty) address,
      if (line2Parts.isNotEmpty) line2Parts.join(", "),
    ].join("\n");
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return CustomerScaffold(
      currentIndex: -1,
      title: widget.isSelectionMode
          ? "Select Delivery Address"
          : "Saved Addresses",
      body: Container(
        color: const Color(0xFFFFF1DC), // Custom background color
        child: Column(
          children: [
            Expanded(
              child: user == null
                  ? const Center(child: Text("Please login first."))
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _watchAddresses,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return Center(child: Text("Error: ${snap.error}"));
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_off_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No saved addresses",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final d = docs[index];
                            final a = d.data();
                            return _addressCard(d.id, a);
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE16417), Color(0xFF80431F)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE16417).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _addAddress,
                      borderRadius: BorderRadius.circular(30),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "ADD NEW ADDRESS",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _addressCard(String docId, Map<String, dynamic> data) {
    final name = (data["name"] ?? "").toString().trim();
    final phone = (data["phone"] ?? "").toString().trim();
    final address = (data["address"] ?? "").toString().trim();
    final city = (data["city"] ?? "").toString().trim();
    final district = (data["district"] ?? "").toString().trim();
    final pincode = (data["pincode"] ?? "").toString().trim();

    final fullAddress = [
      address,
      if (city.isNotEmpty) city,
      if (district.isNotEmpty) district,
      if (pincode.isNotEmpty) "PIN: $pincode",
    ].where((s) => s.isNotEmpty).join(", ");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              _selectAddressForCheckout(addressId: docId, addressSnap: data),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C1A).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFF8C1A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name.isEmpty ? "Address" : name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              if (widget.isSelectionMode)
                                const Icon(
                                  Icons.touch_app_outlined,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phone,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fullAddress,
                            style: const TextStyle(
                              color: Color(0xFF4A4A4A),
                              height: 1.4,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _editAddress(docId: docId, current: data),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteAddress(docId: docId),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text("Delete"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[400],
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
                if (widget.isFromCheckout)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Tap to deliver here",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
