import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/data/artwork_data.dart';

class AddArtworkPage extends StatefulWidget {
  final int? editIndex; // null = add, not null = edit

  const AddArtworkPage({super.key, this.editIndex});

  @override
  State<AddArtworkPage> createState() => _AddArtworkPageState();
}

class _AddArtworkPageState extends State<AddArtworkPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // ✅ fixed category list (admin must choose only from this)
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

  String? imagePath; // asset OR file path
  String selectedMaterial = "Canvas";
  String coa = "Yes";
  String selectedCategory = "Painting";

  @override
  void initState() {
    super.initState();

    if (widget.editIndex != null) {
      final art = ArtworkData.artworks[widget.editIndex!];

      titleCtrl.text = _asString(art["title"]);
      priceCtrl.text = _asString(art["price"]).replaceAll("₹", "").trim();
      descriptionCtrl.text = _asString(art["description"]);

      // ✅ int -> string for controller
      quantityCtrl.text = _asInt(art["totalQuantity"]).toString();

      imagePath = _asString(art["image"]);
      selectedMaterial = _asString(art["paper"]).isEmpty ? "Canvas" : _asString(art["paper"]);
      coa = _asString(art["coa"]).isEmpty ? "Yes" : _asString(art["coa"]);

      final savedCat = _asString(art["category"]);
      selectedCategory = categories.contains(savedCat) ? savedCat : "Painting";
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    priceCtrl.dispose();
    descriptionCtrl.dispose();
    quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => imagePath = picked.path);
  }

  void _saveArtwork() {
    if (!_formKey.currentState!.validate()) return;

    if (imagePath == null || imagePath!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload an image")),
      );
      return;
    }

    final totalQty = int.tryParse(quantityCtrl.text.trim()) ?? 0;
    if (totalQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid quantity")),
      );
      return;
    }

    // ✅ keep soldQuantity on edit, otherwise 0
    final soldQty = widget.editIndex != null
        ? _asInt(ArtworkData.artworks[widget.editIndex!]["soldQuantity"])
        : 0;

    // ✅ don’t allow totalQuantity < soldQuantity when editing
    if (widget.editIndex != null && totalQty < soldQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Total quantity cannot be less than sold ($soldQty)")),
      );
      return;
    }

    final artwork = <String, dynamic>{
      "id": widget.editIndex != null
          ? ArtworkData.artworks[widget.editIndex!]["id"]
          : DateTime.now().millisecondsSinceEpoch.toString(),
      "title": titleCtrl.text.trim(),
      "category": selectedCategory,
      "price": "₹${priceCtrl.text.trim()}",
      "image": imagePath!, // file path or asset path
      "rating": widget.editIndex != null
          ? (ArtworkData.artworks[widget.editIndex!]["rating"] ?? "0.0")
          : "0.0",
      "paper": selectedMaterial,
      "size_cm": "-",
      "size_in": "-",
      "coa": coa,
      "description": descriptionCtrl.text.trim(),

      // ✅ store as int
      "totalQuantity": totalQty,
      "soldQuantity": soldQty,
    };

    if (widget.editIndex != null) {
      ArtworkData.artworks[widget.editIndex!] = artwork;
    } else {
      ArtworkData.artworks.add(artwork);
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.editIndex == null ? "Add Artwork" : "Edit Artwork",
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ IMAGE PICKER
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: (imagePath == null || imagePath!.isEmpty)
                      ? const Center(child: Text("Tap to upload image"))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: imagePath!.startsWith("assets/")
                              ? Image.asset(imagePath!, fit: BoxFit.cover)
                              : Image.file(File(imagePath!), fit: BoxFit.cover),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              _input("Artwork Title", titleCtrl),

              // ✅ CATEGORY DROPDOWN
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v ?? "Painting"),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Select a category" : null,
                  decoration: _decor("Category"),
                ),
              ),

              _input("Price (without ₹)", priceCtrl, keyboard: TextInputType.number),
              _input("Total Quantity", quantityCtrl, keyboard: TextInputType.number),

              const SizedBox(height: 14),

              DropdownButtonFormField(
                value: selectedMaterial,
                items: const [
                  DropdownMenuItem(value: "Canvas", child: Text("Canvas")),
                  DropdownMenuItem(value: "Art Paper", child: Text("Art Paper")),
                ],
                onChanged: (v) => setState(() => selectedMaterial = v!),
                decoration: _decor("Material"),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Radio<String>(
                    value: "Yes",
                    groupValue: coa,
                    onChanged: (v) => setState(() => coa = v!),
                  ),
                  const Text("COA Yes"),
                  Radio<String>(
                    value: "No",
                    groupValue: coa,
                    onChanged: (v) => setState(() => coa = v!),
                  ),
                  const Text("COA No"),
                ],
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: descriptionCtrl,
                maxLines: 4,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                decoration: _decor("Description"),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveArtwork,
                  child: Text(widget.editIndex == null ? "Add Artwork" : "Update Artwork"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController c, {
    TextInputType keyboard = TextInputType.text,
  }) {
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

  // ---------- helpers ----------
  String _asString(dynamic v) => (v ?? "").toString();

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }
}
