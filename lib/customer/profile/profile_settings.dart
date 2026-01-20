import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _nameController = TextEditingController(text: "John Doe");
  final _emailController = TextEditingController(text: "john@example.com");
  final _phoneController = TextEditingController(text: "9876543210");

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus(); // hide keyboard

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.length < 2) {
      _toast("Enter a valid name");
      return;
    }

    if (phone.length != 10 || int.tryParse(phone) == null) {
      _toast("Enter a valid 10-digit phone number");
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );

    // Later: save to Firebase
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Profile Settings",
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          children: [
            _field(
              label: "Name",
              controller: _nameController,
              icon: Icons.person,
              editable: true,
              keyboard: TextInputType.name,
              textCapitalization: TextCapitalization.words,
            ),
            _field(
              label: "Email",
              controller: _emailController,
              icon: Icons.email,
              editable: false, // ✅ readOnly, not disabled
              keyboard: TextInputType.emailAddress,
            ),
            _field(
              label: "Phone",
              controller: _phoneController,
              icon: Icons.phone,
              editable: true,
              keyboard: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool editable,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: !editable, // ✅ better than enabled:false
            keyboardType: keyboard,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              prefixIcon: Icon(icon),
              suffixIcon: editable ? const Icon(Icons.edit, size: 18) : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
