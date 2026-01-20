import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

class AddEditAddressPage extends StatefulWidget {
  final String? name;
  final String? phone;
  final String? address;

  const AddEditAddressPage({super.key, this.name, this.phone, this.address});

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController addressController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name ?? "");
    phoneController = TextEditingController(text: widget.phone ?? "");
    addressController = TextEditingController(text: widget.address ?? "");
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: widget.name == null ? "Add Address" : "Edit Address",
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("Name"),
            _field(
              nameController,
              keyboard: TextInputType.name,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            _label("Phone"),
            _field(
              phoneController,
              keyboard: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 16),

            _label("Address"),
            _field(
              addressController,
              maxLines: 3,
              keyboard: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  disabledBackgroundColor:
                      const Color(0xFFE16417).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _saving ? "Saving..." : "Save Address",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();

    if (name.length < 2) {
      _toast("Enter a valid name");
      return;
    }
    if (phone.length != 10 || int.tryParse(phone) == null) {
      _toast("Enter a valid 10-digit phone number");
      return;
    }
    if (address.length < 8) {
      _toast("Enter a valid address");
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    Navigator.pop<Map<String, String>>(context, {
      "name": name,
      "phone": phone,
      "address": address,
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _field(
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
