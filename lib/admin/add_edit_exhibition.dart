import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/backend_service.dart';
import 'package:artiva/services/cloudinary_service.dart';

class AddEditExhibitionPage extends StatefulWidget {
  final Exhibition? existing; // null = add, not null = edit
  final VoidCallback? onSuccess; // ✅ Callback for tab-based add

  const AddEditExhibitionPage({super.key, this.existing, this.onSuccess});

  @override
  State<AddEditExhibitionPage> createState() => _AddEditExhibitionPageState();
}

class _AddEditExhibitionPageState extends State<AddEditExhibitionPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final BackendService backend = BackendService();

  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _totalSeatsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  DateTime? _selectedDateTime;

  // ✅ NEW
  String? _localImagePath; // picked image (phone path)
  String? _imageUrl; // cloudinary url (saved)

  bool _saving = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final ex = widget.existing;
    if (ex != null) {
      _titleCtrl.text = ex.title;
      _venueCtrl.text = ex.venue;
      _descCtrl.text = ex.description;
      _totalSeatsCtrl.text = ex.totalSeats.toString();
      _priceCtrl.text = ex.pricePerSeat.toString();
      _selectedDateTime = ex.dateTime;

      _imageUrl = ex.imageUrl;
      _localImagePath = null;
    } else {
      _selectedDateTime = DateTime.now().add(const Duration(days: 1));
      _priceCtrl.text = "100";
      _imageUrl = null;
      _localImagePath = null;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    _descCtrl.dispose();
    _totalSeatsCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleCtrl.clear();
    _venueCtrl.clear();
    _descCtrl.clear();
    _totalSeatsCtrl.clear();
    _priceCtrl.text = "100";
    setState(() {
      _selectedDateTime = DateTime.now().add(const Duration(days: 1));
      _localImagePath = null;
      _imageUrl = null;
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024, // ✅ Added to reduce upload time
      maxHeight: 1024, // ✅ Added to reduce upload time
    );
    if (picked != null) {
      setState(() {
        _localImagePath = picked.path; // new picked file
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: isEdit ? "Edit Exhibition" : "Add Exhibition",

      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving ? "SAVING..." : "SAVE",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      body: Stack(
        // ✅ Added Stack for loading overlay
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  GestureDetector(
                    onTap: _saving ? null : _pickImage,
                    child: Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey),
                        color: Colors.white,
                      ),
                      child:
                          (_localImagePath == null &&
                              (_imageUrl == null || _imageUrl!.isEmpty))
                          ? const Center(
                              child: Text("Tap to upload exhibition image"),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _previewImage(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _field(
                    controller: _titleCtrl,
                    label: "Exhibition Title",
                    icon: Icons.title,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Title required"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  _field(
                    controller: _venueCtrl,
                    label: "Venue / Location",
                    icon: Icons.location_on,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Venue required"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  _field(
                    controller: _descCtrl,
                    label: "Description",
                    icon: Icons.description,
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Description required"
                        : null,
                  ),
                  const SizedBox(height: 12),

                  _field(
                    controller: _totalSeatsCtrl,
                    label: "Total Seats",
                    icon: Icons.event_seat,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse((v ?? "").trim());
                      if (n == null || n <= 0)
                        return "Enter a valid seat count";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  _field(
                    controller: _priceCtrl,
                    label: "Price Per Seat (₹)",
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final p = int.tryParse((v ?? "").trim());
                      if (p == null || p <= 0) return "Enter a valid price";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: Colors.white,
                    leading: const Icon(Icons.calendar_month),
                    title: Text(
                      _selectedDateTime == null
                          ? "Select Date & Time"
                          : _formatDateTime(_selectedDateTime!),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _saving ? null : _pickDateTime,
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(
                      isEdit ? "Update Exhibition" : "Add Exhibition",
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_saving)
            // ✅ Loading Overlay
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Saving Exhibition...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _previewImage() {
    // show newly picked file first
    if (_localImagePath != null) {
      return Image.file(
        File(_localImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    // else show saved cloudinary url
    if (_imageUrl != null && _imageUrl!.startsWith("http")) {
      return Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _selectedDateTime ?? now,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) return;

    final totalSeats = int.parse(_totalSeatsCtrl.text.trim());
    final pricePerSeat = int.parse(_priceCtrl.text.trim());

    final old = widget.existing;
    final bookedSeats = old?.bookedSeats ?? 0;

    if (totalSeats < bookedSeats) {
      _snack("Total seats cannot be less than booked ($bookedSeats)");
      return;
    }

    setState(() => _saving = true);

    try {
      // ✅ Upload if admin picked a new image
      String finalImageUrl = (_imageUrl ?? "").trim();

      if (_localImagePath != null && _localImagePath!.trim().isNotEmpty) {
        finalImageUrl = await CloudinaryService.uploadExhibitionImage(
          file: File(_localImagePath!),
        );
      }

      if (finalImageUrl.isEmpty) {
        _snack("Please upload an exhibition image");
        return;
      }

      final ex = Exhibition(
        id: old?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        venue: _venueCtrl.text.trim(),
        dateTime: _selectedDateTime!,
        description: _descCtrl.text.trim(),
        totalSeats: totalSeats,
        bookedSeats: bookedSeats,
        pricePerSeat: pricePerSeat,
        imageUrl: finalImageUrl,
        isArchived: old?.isArchived ?? false,
      );

      await backend.upsertExhibition(ex);

      if (!mounted) return;

      if (widget.onSuccess != null) {
        // ✅ Tab-based mode: clear form and notify
        _clearForm();
        _snack("Exhibition added successfully!");
        widget.onSuccess!();
      } else {
        // ✅ Push-based mode (Edit): pop
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
