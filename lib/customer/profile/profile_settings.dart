import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/auth/auth_service.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = authService.currentUser;

    _nameController = TextEditingController(text: user?.name ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
    _phoneController = TextEditingController(text: user?.phone ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final user = authService.currentUser;
    if (user == null) {
      _toast("Please login first.");
      return;
    }

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

    setState(() => _saving = true);

    try {
      await authService.updateProfile(name: name, phone: phone);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Profile updated")));

      Navigator.pop(context);
    } catch (e) {
      _toast(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Profile Settings",
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          children: [
            _field("Name", _nameController, Icons.person, true),
            _field("Email", _emailController, Icons.email, false),
            _field(
              "Phone",
              _phoneController,
              Icons.phone,
              true,
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
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE16417),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _saving ? "SAVING..." : "Save Changes",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon,
    bool editable, {
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        readOnly: !editable,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: editable ? Colors.white : Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
