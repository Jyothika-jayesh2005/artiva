import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/backend_service.dart'; // ✅ REQUIRED

class AddEditExhibitionPage extends StatefulWidget {
  final Exhibition? existing; // null = add, not null = edit
  const AddEditExhibitionPage({super.key, this.existing});

  @override
  State<AddEditExhibitionPage> createState() => _AddEditExhibitionPageState();
}

class _AddEditExhibitionPageState extends State<AddEditExhibitionPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final BackendService backend = BackendService(); // ✅ DEFINE backend

  final _titleCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _totalSeatsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  DateTime? _selectedDateTime;
  String? _imagePath;

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
      _imagePath = ex.imagePath;
    } else {
      _selectedDateTime = DateTime.now().add(const Duration(days: 1));
      _priceCtrl.text = "100";
      _imagePath = null;
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

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: isEdit ? "Edit Exhibition" : "Add Exhibition",
      showBack: true,
      actions: [
        TextButton(
          onPressed: _save,
          child: const Text(
            "SAVE",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey),
                    color: Colors.white,
                  ),
                  child: _imagePath == null
                      ? const Center(
                          child: Text("Tap to upload exhibition image"),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _imagePath!.startsWith("assets/")
                              ? Image.asset(_imagePath!, fit: BoxFit.cover)
                              : Image.file(
                                  File(_imagePath!),
                                  fit: BoxFit.cover,
                                ),
                        ),
                ),
              ),
              const SizedBox(height: 14),

              _field(
                controller: _titleCtrl,
                label: "Exhibition Title",
                icon: Icons.title,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Title required" : null,
              ),
              const SizedBox(height: 12),

              _field(
                controller: _venueCtrl,
                label: "Venue / Location",
                icon: Icons.location_on,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Venue required" : null,
              ),
              const SizedBox(height: 12),

              _field(
                controller: _descCtrl,
                label: "Description",
                icon: Icons.description,
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
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
                  final n = int.tryParse(v ?? "");
                  if (n == null || n <= 0) {
                    return "Enter a valid seat count";
                  }
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
                  final p = int.tryParse(v ?? "");
                  if (p == null || p <= 0) {
                    return "Enter a valid price";
                  }
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
                onTap: _pickDateTime,
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label:
                    Text(isEdit ? "Update Exhibition" : "Add Exhibition"),
              ),
            ],
          ),
        ),
      ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) return;

    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload an exhibition image"),
        ),
      );
      return;
    }

    final totalSeats = int.parse(_totalSeatsCtrl.text.trim());
    final pricePerSeat = int.parse(_priceCtrl.text.trim());

    final old = widget.existing;
    final bookedSeats = old?.bookedSeats ?? 0;

    if (totalSeats < bookedSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Total seats cannot be less than booked ($bookedSeats)"),
        ),
      );
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
      imagePath: _imagePath!,
      isArchived: old?.isArchived ?? false,
    );

    try {
      await backend.upsertExhibition(ex); // ✅ NOW VALID
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  "
        "${two(dt.hour)}:${two(dt.minute)}";
  }
}
