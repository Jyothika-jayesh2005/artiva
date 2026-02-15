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
  static const String _uploadPreset =
      "profiles_unsigned"; // <-- create this preset

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated")));

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
                  TextButton.icon(
                    onPressed: _saving ? null : _pickPhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                    label: const Text("Change Photo"),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE16417),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
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
            Center(
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
                    onTap: _saving ? null : _save,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon,
    bool editable, {
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        decoration: BoxDecoration(
          color: editable ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          readOnly: !editable,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE16417),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
