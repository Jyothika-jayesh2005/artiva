import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/auth/auth_service.dart';

import 'add_edit_address.dart';
import '../checkout/checkout_page.dart';

class SavedAddressPage extends StatefulWidget {
  final bool isFromCheckout;
  final Map<String, String>? artwork;
  final int quantity; // ✅ NEW

  const SavedAddressPage({
    super.key,
    this.isFromCheckout = false,
    this.artwork,
    this.quantity = 1, // ✅ Default 1
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
            quantity: widget.quantity, // ✅ Pass quantity
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
      title: "Saved Addresses",
      body: Padding(
        padding: const EdgeInsets.all(20),
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
                          return Center(
                            child: Text(
                              snap.error.toString().replaceFirst(
                                "Exception: ",
                                "",
                              ),
                            ),
                          );
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text("No saved addresses"),
                          );
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final d = docs[index];
                            final a = d.data();

                            final name = (a["name"] ?? "").toString().trim();
                            final phone = (a["phone"] ?? "").toString().trim();
                            final address = (a["address"] ?? "")
                                .toString()
                                .trim();
                            final city = (a["city"] ?? "").toString().trim();
                            final district = (a["district"] ?? "")
                                .toString()
                                .trim();
                            final pincode = (a["pincode"] ?? "")
                                .toString()
                                .trim();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _addressCard(
                                docId: d.id,
                                addressSnap: a,
                                name: name,
                                phone: phone,
                                address: address,
                                city: city,
                                district: district,
                                pincode: pincode,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            OutlinedButton.icon(
              onPressed: _addAddress,
              icon: const Icon(Icons.add),
              label: const Text("Add New Address"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE16417),
                side: const BorderSide(color: Color(0xFFE16417)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressCard({
    required String docId,
    required Map<String, dynamic> addressSnap,
    required String name,
    required String phone,
    required String address,
    required String city,
    required String district,
    required String pincode,
  }) {
    final line2Parts = <String>[
      if (city.isNotEmpty) city,
      if (district.isNotEmpty) district,
      if (pincode.isNotEmpty) pincode,
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectAddressForCheckout(
          addressId: docId,
          addressSnap: addressSnap,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name.isEmpty ? "-" : name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: "Edit",
                        onPressed: () =>
                            _editAddress(docId: docId, current: addressSnap),
                        icon: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Color(0xFFE16417),
                        ),
                      ),
                      IconButton(
                        tooltip: "Delete",
                        onPressed: () => _deleteAddress(docId: docId),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(phone.isEmpty ? "-" : phone),
              const SizedBox(height: 8),
              Text(
                address.isEmpty ? "-" : address,
                style: const TextStyle(color: Colors.grey),
              ),
              if (line2Parts.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  line2Parts.join(", "),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (widget.isFromCheckout)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    "Tap to deliver to this address",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
