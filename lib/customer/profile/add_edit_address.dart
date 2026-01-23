import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

class AddEditAddressPage extends StatefulWidget {
  final String? name;
  final String? phone;
  final String? address;
  final String? city;
  final String? district;
  final String? pincode;

  const AddEditAddressPage({
    super.key,
    this.name,
    this.phone,
    this.address,
    this.city,
    this.district,
    this.pincode,
  });

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _pincodeCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name ?? "");
    _phoneCtrl = TextEditingController(text: widget.phone ?? "");
    _addressCtrl = TextEditingController(text: widget.address ?? "");
    _cityCtrl = TextEditingController(text: widget.city ?? "");
    _districtCtrl = TextEditingController(text: widget.district ?? "");
    _pincodeCtrl = TextEditingController(text: widget.pincode ?? "");
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final district = _districtCtrl.text.trim();
    final pincode = _pincodeCtrl.text.trim();

    if (name.length < 2) {
      _toast("Enter a valid name");
      return;
    }

    if (phone.length != 10 || int.tryParse(phone) == null) {
      _toast("Enter a valid 10-digit phone number");
      return;
    }

    if (address.length < 8) {
      _toast("Enter full address");
      return;
    }

    if (city.length < 2) {
      _toast("Enter city");
      return;
    }

    if (district.length < 2) {
      _toast("Enter district");
      return;
    }

    if (pincode.length != 6 || int.tryParse(pincode) == null) {
      _toast("Enter valid 6-digit pincode");
      return;
    }

    setState(() => _saving = true);

    Navigator.pop<Map<String, String>>(context, {
      "name": name,
      "phone": phone,
      "address": address,
      "city": city,
      "district": district,
      "pincode": pincode,
    });
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.name != null;

    return CustomerScaffold(
      currentIndex: -1,
      title: isEdit ? "Edit Address" : "Add Address",
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
            _field(_nameCtrl, keyboard: TextInputType.name),

            _gap(),
            _label("Phone"),
            _field(
              _phoneCtrl,
              keyboard: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),

            _gap(),
            _label("Address"),
            _field(
              _addressCtrl,
              maxLines: 3,
              keyboard: TextInputType.streetAddress,
            ),

            _gap(),
            _label("City"),
            _field(_cityCtrl),

            _gap(),
            _label("District"),
            _field(_districtCtrl),

            _gap(),
            _label("Pincode"),
            _field(
              _pincodeCtrl,
              keyboard: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _saving ? "Saving..." : "Save Address",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t));

  Widget _gap() => const SizedBox(height: 16);

  Widget _field(
    TextEditingController c, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
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
