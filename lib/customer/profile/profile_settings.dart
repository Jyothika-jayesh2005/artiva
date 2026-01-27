import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/auth/auth_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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

  File? _pickedImageFile;
  String _photoUrl = "";

  // ✅ FIXED: use your real Cloudinary config
  static const String _cloudName = "dblfdal0u";
  static const String _uploadPreset = "profiles_unsigned"; // <-- create this preset

  @override
  void initState() {
    super.initState();
    final user = authService.currentUser;

    _nameController = TextEditingController(text: user?.name ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
    _phoneController = TextEditingController(text: user?.phone ?? "");

    _photoUrl = (user?.photoUrl ?? "").trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final user = authService.currentUser;
    if (user == null) {
      _toast("Please login first.");
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (x == null) return;

      setState(() {
        _pickedImageFile = File(x.path);
      });
    } catch (e) {
      _toast("Failed to pick image: $e");
    }
  }

  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
      );

      final req = http.MultipartRequest("POST", uri);
      req.fields["upload_preset"] = _uploadPreset;
      req.fields["folder"] = "profiles"; // keep clean

      req.files.add(await http.MultipartFile.fromPath("file", file.path));

      final res = await req.send();
      final body = await res.stream.bytesToString();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        _toast("Cloudinary upload failed (${res.statusCode}): $body");
        return null;
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = (json["secure_url"] ?? "").toString().trim();

      if (secureUrl.isEmpty) {
        _toast("Cloudinary did not return secure_url.");
        return null;
      }

      return secureUrl;
    } catch (e) {
      _toast("Cloudinary upload error: $e");
      return null;
    }
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
      String? newPhotoUrl;
      if (_pickedImageFile != null) {
        newPhotoUrl = await _uploadToCloudinary(_pickedImageFile!);
        if (newPhotoUrl == null) return;
      }

      await authService.updateProfile(name: name, phone: phone);

      if (newPhotoUrl != null && newPhotoUrl.isNotEmpty) {
        await authService.updateProfilePhoto(photoUrl: newPhotoUrl);
        _photoUrl = newPhotoUrl;
        _pickedImageFile = null;
      }

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
    final ImageProvider? previewImageProvider = _pickedImageFile != null
        ? FileImage(_pickedImageFile!)
        : (_photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null);

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
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                    backgroundImage: previewImageProvider,
                    child: previewImageProvider == null
                        ? const Icon(
                            Icons.person,
                            size: 46,
                            color: Color(0xFFE16417),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickPhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text("Change Photo"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
