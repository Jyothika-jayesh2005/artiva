import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/backend_provider.dart';
import 'package:artiva/services/cloudinary_service.dart';

class AddArtworkPage extends StatefulWidget {
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

  // Artist fields (New)
  final artistNameCtrl = TextEditingController();
  final artistStatementCtrl = TextEditingController();

  // Behind the Artwork fields
  final inspirationCtrl = TextEditingController();
  final meaningCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final symbolismCtrl = TextEditingController();

  // From the Artist fields
  final artistQuoteCtrl = TextEditingController();
  final howMadeItCtrl = TextEditingController();
  final viewerFeelCtrl = TextEditingController();

  String? imagePath;
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

    imageUrl = (art["imageUrl"] ?? "").toString().trim();
    imagePath = (art["imagePath"] ?? "").toString().trim();

    final cat = (art["category"] ?? "").toString();
    if (categories.contains(cat)) selectedCategory = cat;

    final paper = (art["paper"] ?? "").toString();
    if (paper.isNotEmpty) selectedMaterial = paper;

    final coaVal = (art["coa"] ?? "").toString();
    if (coaVal == "Yes" || coaVal == "No") coa = coaVal;

    sizeCmCtrl.text = (art["size_cm"] ?? "")
        .toString()
        .replaceAll("-", "")
        .trim();
    sizeInCtrl.text = (art["size_in"] ?? "")
        .toString()
        .replaceAll("-", "")
        .trim();

    // Load Artist Info (New)
    artistNameCtrl.text = (art["artistName"] ?? "").toString();
    artistStatementCtrl.text = (art["artistStatement"] ?? "").toString();

    // Load Behind the Artwork fields
    inspirationCtrl.text = (art["inspiration"] ?? "").toString();
    meaningCtrl.text = (art["meaning"] ?? "").toString();
    processCtrl.text = (art["process"] ?? "").toString();
    symbolismCtrl.text = (art["symbolism"] ?? "").toString();

    // Load From the Artist fields
    artistQuoteCtrl.text = (art["artistQuote"] ?? "").toString();
    howMadeItCtrl.text = (art["howMadeItNote"] ?? "").toString();
    viewerFeelCtrl.text = (art["viewerFeelNote"] ?? "").toString();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    priceCtrl.dispose();
    descriptionCtrl.dispose();
    quantityCtrl.dispose();
    sizeCmCtrl.dispose();
    sizeInCtrl.dispose();
    // Disposal New fields
    artistNameCtrl.dispose();
    artistStatementCtrl.dispose();

    inspirationCtrl.dispose();
    meaningCtrl.dispose();
    processCtrl.dispose();
    symbolismCtrl.dispose();
    artistQuoteCtrl.dispose();
    howMadeItCtrl.dispose();
    viewerFeelCtrl.dispose();

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
      if (picked != null) {
        setState(() => imagePath = picked.path);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<String> _uploadToCloudinary(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception("Selected image file not found.");
    }
    return CloudinaryService.uploadArtworkImage(file: file);
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

    // 🔥 FIX STARTS HERE
    final int prevTotal = _isEdit
        ? _toInt(widget.editArtwork?["totalQuantity"])
        : 0;
    final int prevSold = _isEdit
        ? _toInt(widget.editArtwork?["soldQuantity"])
        : 0;

    final bool wasOutOfStock = _isEdit && prevSold >= prevTotal;

    final int soldQty = wasOutOfStock ? 0 : prevSold;

    if (_isEdit && !wasOutOfStock && totalQty < soldQty) {
      _snack("Total quantity cannot be less than sold ($soldQty)");
      return;
    }
    // 🔥 FIX ENDS HERE

    setState(() => _saving = true);

    try {
      final String id = _isEdit
          ? (widget.editArtwork?["id"] ?? "").toString()
          : DateTime.now().millisecondsSinceEpoch.toString();

      String finalUrl = imageUrl?.trim() ?? "";

      final pickedPath = (imagePath ?? "").trim();
      if (pickedPath.isNotEmpty &&
          !pickedPath.startsWith("http") &&
          !pickedPath.startsWith("assets/")) {
        finalUrl = await _uploadToCloudinary(pickedPath);
      }

      if (finalUrl.isEmpty) {
        _snack("Please upload an image");
        return;
      }

      final artwork = <String, dynamic>{
        "id": id,
        "title": titleCtrl.text.trim(),
        "category": selectedCategory,
        "price": price,
        "imageUrl": finalUrl,
        "paper": selectedMaterial,
        "coa": coa,
        "description": descriptionCtrl.text.trim(),
        "size_cm": sizeCmCtrl.text.trim().isEmpty
            ? "-"
            : sizeCmCtrl.text.trim(),
        "size_in": sizeInCtrl.text.trim().isEmpty
            ? "-"
            : sizeInCtrl.text.trim(),
        "totalQuantity": totalQty,
        "soldQuantity": soldQty,
        "createdAt":
            widget.editArtwork?["createdAt"] ??
            DateTime.now().toIso8601String(),
        // New fields
        "artistName": artistNameCtrl.text.trim(),
        "artistStatement": artistStatementCtrl.text.trim(),
        // Behind the Artwork
        "inspiration": inspirationCtrl.text.trim(),
        "meaning": meaningCtrl.text.trim(),
        "process": processCtrl.text.trim(),
        "symbolism": symbolismCtrl.text.trim(),
        // From the Artist
        "artistQuote": artistQuoteCtrl.text.trim(),
        "howMadeItNote": howMadeItCtrl.text.trim(),
        "viewerFeelNote": viewerFeelCtrl.text.trim(),
      };

      await backend.upsertArtwork(artwork);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = imagePath?.trim().isNotEmpty == true
        ? imagePath!
        : imageUrl ?? "";

    return AdminScaffold(
      title: _isEdit ? "Edit Artwork" : "Add Artwork",
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Modern Image Uplader
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF8C1A).withOpacity(0.5),
                      width: 2,
                      style: BorderStyle
                          .solid, // Using solid for cleaner look, could be dotted with package
                    ),
                  ),
                  child: preview.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C1A).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 40,
                                color: Color(0xFFFF8C1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Tap to upload artwork image",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _previewImage(preview),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Color(0xFFFF8C1A),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // 2. Core Details Section
              const Text(
                "Core Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _input("Artwork Title", titleCtrl, icon: Icons.title),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _input(
                      "Price (₹)",
                      priceCtrl,
                      keyboard: TextInputType.number,
                      icon: Icons.currency_rupee,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _input(
                      "Quantity",
                      quantityCtrl,
                      keyboard: TextInputType.number,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Dropdowns Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _dropdown(
                      label: "Category",
                      value: selectedCategory,
                      items: categories,
                      onChanged: (v) => setState(() => selectedCategory = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _dropdown(
                      label: "Material",
                      value: selectedMaterial,
                      items: const [
                        "Canvas",
                        "Paper",
                        "Wood",
                        "Acrylic Sheet",
                        "Other",
                      ],
                      onChanged: (v) => setState(() => selectedMaterial = v),
                    ),
                  ),
                ],
              ),
              _dropdown(
                label: "COA Included?",
                value: coa,
                items: const ["Yes", "No"],
                onChanged: (v) => setState(() => coa = v),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _input(
                      "Size (cm)",
                      sizeCmCtrl,
                      icon: Icons.straighten,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _input(
                      "Size (in)",
                      sizeInCtrl,
                      icon: Icons.straighten,
                    ),
                  ),
                ],
              ),

              _input(
                "Description",
                descriptionCtrl,
                keyboard: TextInputType.multiline,
                maxLines: 4,
                icon: Icons.description_outlined,
              ),

              const SizedBox(height: 24),
              const Divider(thickness: 1, height: 40),

              // 3. Artist Info
              const Text(
                "Artist Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _input("Artist Name", artistNameCtrl, icon: Icons.person_outline),
              _input(
                "Artist Statement",
                artistStatementCtrl,
                keyboard: TextInputType.multiline,
                maxLines: 3,
                icon: Icons.format_quote_rounded,
              ),

              const SizedBox(height: 24),
              const Divider(thickness: 1, height: 40),

              // 4. Behind the Artwork
              const Text(
                "Behind the Artwork",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _input(
                "Inspiration",
                inspirationCtrl,
                maxLines: 2,
                icon: Icons.lightbulb_outline,
              ),
              _input(
                "Meaning",
                meaningCtrl,
                maxLines: 2,
                icon: Icons.psychology_outlined,
              ),
              _input(
                "Process",
                processCtrl,
                maxLines: 2,
                icon: Icons.build_outlined,
              ),
              _input(
                "Symbolism",
                symbolismCtrl,
                maxLines: 2,
                icon: Icons.auto_awesome_outlined,
              ),

              const SizedBox(height: 24),
              const Divider(thickness: 1, height: 40),

              // 5. From the Artist
              const Text(
                "From the Artist",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _input(
                "Artist Quote",
                artistQuoteCtrl,
                maxLines: 2,
                icon: Icons.record_voice_over_outlined,
              ),
              _input(
                "How it was made",
                howMadeItCtrl,
                maxLines: 3,
                icon: Icons.handyman_outlined,
              ),
              _input(
                "What viewers should feel",
                viewerFeelCtrl,
                maxLines: 2,
                icon: Icons.mood,
              ),

              const SizedBox(height: 40),

              // 6. Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C1A),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFFFF8C1A).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saveArtwork,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? "UPDATE ARTWORK" : "PUBLISH ARTWORK",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewImage(String path) {
    if (path.startsWith("http")) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  Widget _input(
    String label,
    TextEditingController c, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        cursorColor: const Color(0xFFFF8C1A),
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFFF8C1A),
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xFFFF8C1A))
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF8C1A), width: 2),
            // Light shadow effect for focus?
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true, // ✅ Prevents text overflow
        items: items
            .map(
              (e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle: const TextStyle(
            color: Color(0xFFFF8C1A),
            fontWeight: FontWeight.bold,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF8C1A), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
