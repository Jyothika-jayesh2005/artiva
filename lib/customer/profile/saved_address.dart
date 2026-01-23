import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

import 'add_edit_address.dart';
import '../checkout/checkout_page.dart';

class SavedAddressPage extends StatefulWidget {
  final bool isFromCheckout;
  final Map<String, String>? artwork;

  const SavedAddressPage({
    super.key,
    this.isFromCheckout = false,
    this.artwork,
  });

  @override
  State<SavedAddressPage> createState() => _SavedAddressPageState();
}

class _SavedAddressPageState extends State<SavedAddressPage> {
  // ✅ START EMPTY (no dummy address)
  final List<Map<String, String>> _addresses = [];

  Future<void> _addAddress() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAddressPage()),
    );

    if (result == null) return;

    setState(() {
      _addresses.add(result);
    });
  }

  Future<void> _editAddress(int index) async {
    final current = _addresses[index];

    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAddressPage(
          name: current["name"],
          phone: current["phone"],
          address: current["address"],
          city: current["city"],
          district: current["district"],
          pincode: current["pincode"],
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _addresses[index] = result;
    });
  }

  Future<void> _deleteAddress(int index) async {
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
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _addresses.removeAt(index);
    });
  }

  void _selectAddressForCheckout(Map<String, String> a) {
    // ✅ behaves like a picker only if opened from checkout
    if (widget.isFromCheckout && widget.artwork != null) {
      final full = _formatFullAddress(a);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutPage(
            artwork: widget.artwork!,
            address: full,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Open checkout to select an address")),
    );
  }

  String _formatFullAddress(Map<String, String> a) {
    final name = (a["name"] ?? "").trim();
    final phone = (a["phone"] ?? "").trim();
    final address = (a["address"] ?? "").trim();
    final city = (a["city"] ?? "").trim();
    final district = (a["district"] ?? "").trim();
    final pincode = (a["pincode"] ?? "").trim();

    // clean formatting (no extra commas)
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

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Saved Addresses",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: _addresses.isEmpty
                  ? const Center(child: Text("No saved addresses"))
                  : ListView.builder(
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) {
                        final a = _addresses[index];

                        final name = (a["name"] ?? "").trim();
                        final phone = (a["phone"] ?? "").trim();
                        final address = (a["address"] ?? "").trim();
                        final city = (a["city"] ?? "").trim();
                        final district = (a["district"] ?? "").trim();
                        final pincode = (a["pincode"] ?? "").trim();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _addressCard(
                            index: index,
                            addressMap: a,
                            name: name,
                            phone: phone,
                            address: address,
                            city: city,
                            district: district,
                            pincode: pincode,
                          ),
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
    required int index,
    required Map<String, String> addressMap,
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
        onTap: () => _selectAddressForCheckout(addressMap),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NAME + ACTIONS
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
                        onPressed: () => _editAddress(index),
                        icon: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Color(0xFFE16417),
                        ),
                      ),
                      IconButton(
                        tooltip: "Delete",
                        onPressed: () => _deleteAddress(index),
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
