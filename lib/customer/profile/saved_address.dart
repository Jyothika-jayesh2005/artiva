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
  final List<Map<String, String>> _addresses = [
    {
      "name": "John Doe",
      "phone": "9876543210",
      "address": "12, MG Road, Bangalore, Karnataka - 560001",
    },
  ];

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
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      _addresses[index] = result;
    });
  }

  void _deleteAddress(int index) {
    setState(() {
      _addresses.removeAt(index);
    });
  }

  void _selectAddressForCheckout(String address) {
    // This page should only behave like a picker if opened from checkout flow
    if (widget.isFromCheckout && widget.artwork != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutPage(
            artwork: widget.artwork!,
            address: address,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Open checkout to select an address")),
    );
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _addressCard(
                            index: index,
                            name: a["name"] ?? "",
                            phone: a["phone"] ?? "",
                            address: a["address"] ?? "",
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressCard({
    required int index,
    required String name,
    required String phone,
    required String address,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _selectAddressForCheckout(address),
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
                      name,
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
              Text(phone),
              const SizedBox(height: 6),
              Text(
                address,
                style: const TextStyle(color: Colors.grey),
              ),

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
