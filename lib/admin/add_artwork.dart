import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/backend_provider.dart'; // global backend

class AddArtworkPage extends StatefulWidget {
  /// null => add mode
  /// not null => edit mode (Firestore artwork map)
  final Map<String, dynamic>? editArtwork;

  const AddArtworkPage({super.key, this.editArtwork});

  @override
  State<AddArtworkPage> createState() => _AddArtworkPageState();
}

class _AddArtworkPageState extends State<AddArtworkPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  static const List<String> categories = [
    "Painting",
    "Digital",
    "Sculpture",
    "Abstract",
    "Photography",
    "Sketch",
  ];

  final titleCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();
  final sizeCmCtrl = TextEditingController();
  final sizeInCtrl = TextEditingController();

  // Old local path (still used for preview immediately after picking)
  String? imagePath;

  // ✅ NEW: firestore storage url (permanent)
  String? imageUrl;

  String selectedMaterial = "Canvas";
  String coa = "Yes";
  String selectedCategory = "Painting";

  bool _picking = false;
  bool _saving = false;

  bool get _isEdit => widget.editArtwork != null;

  @override
  void initState() {
    super.initState();
    final art = widget.editArtwork;
    if (art == null) return;

    titleCtrl.text = (art["title"] ?? "").toString();
    priceCtrl.text = (art["price"] ?? "").toString();
    descriptionCtrl.text = (art["description"] ?? "").toString();
    quantityCtrl.text = (art["totalQuantity"] ?? 0).toString();

    // ✅ if artwork already saved, use url
    imageUrl = (art["imageUrl"] ?? "").toString().trim();

    // keep old field just in case (for preview fallback)
    imagePath = (art["imagePath"] ?? "").toString().trim();

    final cat = (art["category"] ?? "").toString();
    if (categories.contains(cat)) selectedCategory = cat;

    final paper = (art["paper"] ?? "").toString();
    if (paper.isNotEmpty) selectedMaterial = paper;

    final coaVal = (art["coa"] ?? "").toString();
    if (coaVal == "Yes" || coaVal == "No") coa = coaVal;

    sizeCmCtrl.text =
        (art["size_cm"] ?? "").toString().replaceAll("-", "").trim();
    sizeInCtrl.text =
        (art["size_in"] ?? "").toString().replaceAll("-", "").trim();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    priceCtrl.dispose();
    descriptionCtrl.dispose();
    quantityCtrl.dispose();
    sizeCmCtrl.dispose();
    sizeInCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (picked == null) return;

      // ✅ local preview path
      setState(() {
        imagePath = picked.path;
        // If you choose new image, we will re-upload and overwrite imageUrl
        // so don't keep old url as "final"
      });
    } catch (e) {
      if (!mounted) return;
      _snack("Image pick failed: $e");
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  // ✅ Upload picked local image to Firebase Storage and return download URL
  Future<String> _uploadToStorage({
    required String artworkId,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception("Selected image file not found. Pick again.");
    }

    // Basic ext detection
    final ext = localPath.toLowerCase().endsWith(".png") ? "png" : "jpg";

    final storageRef = FirebaseStorage.instance
        .ref()
        .child("artworks")
        .child("$artworkId.$ext");

    // Upload
    final task = await storageRef.putFile(file);

    // Get URL
    final url = await task.ref.getDownloadURL();
    return url;
  }

  Future<void> _saveArtwork() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final int price = int.tryParse(priceCtrl.text.trim()) ?? 0;
    if (price <= 0) {
      _snack("Enter a valid price");
      return;
    }

    final int totalQty = int.tryParse(quantityCtrl.text.trim()) ?? 0;
    if (totalQty <= 0) {
      _snack("Enter a valid quantity");
      return;
    }

    final soldQty = _isEdit ? _toInt(widget.editArtwork?["soldQuantity"]) : 0;
    if (_isEdit && totalQty < soldQty) {
      _snack("Total quantity cannot be less than sold ($soldQty)");
      return;
    }

    setState(() => _saving = true);

    try {
      final String id = _isEdit
          ? (widget.editArtwork?["id"] ?? "").toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      if (id.trim().isEmpty) {
        throw Exception("Artwork id missing (cannot edit without id)");
      }

      // ✅ Decide final imageUrl
      String finalUrl = imageUrl?.trim() ?? "";

      // If admin picked a new local image (not assets, not http), upload it
      final pickedPath = (imagePath ?? "").trim();

      final bool hasNewLocalPicked =
          pickedPath.isNotEmpty && !pickedPath.startsWith("assets/") && !pickedPath.startsWith("http");

      if (hasNewLocalPicked) {
        finalUrl = await _uploadToStorage(artworkId: id, localPath: pickedPath);
      }

      // If adding new artwork, must have image
      if (!_isEdit && finalUrl.isEmpty) {
        _snack("Please upload an image");
        return;
      }

      // If editing, allow keeping old URL
      if (_isEdit && finalUrl.isEmpty) {
        _snack("Image missing. Pick image again.");
        return;
      }

      final artwork = <String, dynamic>{
        "id": id,
        "title": titleCtrl.text.trim(),
        "category": selectedCategory,
        "price": price, // store number
        "imageUrl": finalUrl, // ✅ permanent URL (THIS FIXES YOUR ISSUE)
        "paper": selectedMaterial,
        "coa": coa,
        "description": descriptionCtrl.text.trim(),
        "size_cm": sizeCmCtrl.text.trim().isEmpty ? "-" : sizeCmCtrl.text.trim(),
        "size_in": sizeInCtrl.text.trim().isEmpty ? "-" : sizeInCtrl.text.trim(),
        "totalQuantity": totalQty,
        "soldQuantity": soldQty,
        "createdAt": widget.editArtwork?["createdAt"], // keep old if exists
      };

      await backend.upsertArtwork(artwork);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // For preview: prefer local picked path, else url, else old path
    final preview = (imagePath != null && imagePath!.trim().isNotEmpty)
        ? imagePath!.trim()
        : (imageUrl != null && imageUrl!.trim().isNotEmpty)
            ? imageUrl!.trim()
            : "";

    return AdminScaffold(
      title: _isEdit ? "Edit Artwork" : "Add Artwork",
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _picking ? null : _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey),
                    color: Colors.white,
                  ),
                  child: preview.isEmpty
                      ? Center(
                          child: Text(
                            _picking
                                ? "Opening gallery..."
                                : "Tap to upload image",
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _previewImage(preview),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              _input("Artwork Title", titleCtrl),

              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedCategory = v ?? "Painting"),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Select a category"
                      : null,
                  decoration: _decor("Category"),
                ),
              ),

              _input("Price (numbers only)", priceCtrl,
                  keyboard: TextInputType.number),
              _input("Total Quantity", quantityCtrl,
                  keyboard: TextInputType.number),
              _input("Size (cm) e.g. 30 x 40", sizeCmCtrl),
              _input("Size (in) e.g. 12 x 16", sizeInCtrl),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: selectedMaterial,
                items: const [
                  DropdownMenuItem(value: "Canvas", child: Text("Canvas")),
                  DropdownMenuItem(value: "Art Paper", child: Text("Art Paper")),
                ],
                onChanged: (v) =>
                    setState(() => selectedMaterial = v ?? "Canvas"),
                decoration: _decor("Material"),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Radio<String>(
                    value: "Yes",
                    groupValue: coa,
                    onChanged: (v) => setState(() => coa = v ?? "Yes"),
                  ),
                  const Text("COA Yes"),
                  Radio<String>(
                    value: "No",
                    groupValue: coa,
                    onChanged: (v) => setState(() => coa = v ?? "No"),
                  ),
                  const Text("COA No"),
                ],
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: descriptionCtrl,
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
                decoration: _decor("Description"),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveArtwork,
                  child: Text(_saving
                      ? "SAVING..."
                      : (_isEdit ? "Update Artwork" : "Add Artwork")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewImage(String path) {
    if (path.startsWith("http")) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => _imgError(),
      );
    }

    if (path.startsWith("assets/")) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgError(),
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imgError(),
    );
  }

  Widget _imgError() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _input(String label, TextEditingController c,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
        decoration: _decor(label),
      ),
    );
  }

  InputDecoration _decor(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }
}
