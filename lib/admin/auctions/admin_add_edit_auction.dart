import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/backend_provider.dart';
import 'package:artiva/backend/notification_service.dart';
import 'package:artiva/services/cloudinary_service.dart';

class AdminAddEditAuction extends StatefulWidget {
  final Auction? auction;
  const AdminAddEditAuction({super.key, this.auction});

  @override
  State<AdminAddEditAuction> createState() => _AdminAddEditAuctionState();
}

class _AdminAddEditAuctionState extends State<AdminAddEditAuction> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController titleCtrl;
  late TextEditingController artistCtrl;
  // late TextEditingController descCtrl; // Removed
  late TextEditingController sizeCtrl;
  late TextEditingController aboutCtrl;
  late TextEditingController startBidCtrl;
  late TextEditingController incrementCtrl;

  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now().add(const Duration(days: 1));

  String? selectedArtId;
  String? selectedArtTitle;
  String? artImageUrl;
  String? localImagePath;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.auction?.artTitle ?? "");
    artistCtrl = TextEditingController(text: widget.auction?.artistName ?? "");
    // descCtrl = TextEditingController(text: widget.auction?.description ?? ""); // Removed
    sizeCtrl = TextEditingController(text: widget.auction?.size ?? "");
    aboutCtrl = TextEditingController(text: widget.auction?.aboutPiece ?? "");
    startBidCtrl = TextEditingController(
      text: widget.auction?.startingBid.toString() ?? "1000",
    );
    incrementCtrl = TextEditingController(
      text: widget.auction?.minIncrement.toString() ?? "100",
    );

    if (widget.auction != null) {
      startTime = widget.auction!.startTime;
      endTime = widget.auction!.endTime;
      selectedArtId = widget.auction!.artId;
      selectedArtTitle = widget.auction!.artTitle;
      artImageUrl = widget.auction!.artImageUrl;
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    artistCtrl.dispose();
    // descCtrl.dispose(); // Removed
    sizeCtrl.dispose();
    aboutCtrl.dispose();
    startBidCtrl.dispose();
    incrementCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => localImagePath = picked.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (artImageUrl == null && localImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select or upload an artwork image"),
        ),
      );
      return;
    }

    if (endTime.isBefore(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String finalImageUrl = artImageUrl ?? "";
      if (localImagePath != null) {
        finalImageUrl = await CloudinaryService.uploadAuctionImage(
          file: File(localImagePath!),
        );
      }

      final String id =
          widget.auction?.id ??
          FirebaseFirestore.instance.collection("auctions").doc().id;
      final int startBid = int.parse(startBidCtrl.text);

      final auctionData = {
        "artId":
            selectedArtId ?? "custom_${DateTime.now().millisecondsSinceEpoch}",
        "artTitle": titleCtrl.text,
        "artImageUrl": finalImageUrl,
        "artistName": artistCtrl.text,
        "description": aboutCtrl.text, // Use about text as description
        "size": sizeCtrl.text,
        "aboutPiece": aboutCtrl.text,
        "startTime": Timestamp.fromDate(startTime),
        "endTime": Timestamp.fromDate(endTime),
        "startingBid": startBid,
        "minIncrement": int.parse(incrementCtrl.text),
        "currentBid": widget.auction?.currentBid ?? startBid,
        "highestBidderId": widget.auction?.highestBidderId,
        "highestBidderName": widget.auction?.highestBidderName,
        "status": widget.auction?.status.name ?? _calculateInitialStatus(),
        "createdAt": widget.auction?.createdAt != null
            ? Timestamp.fromDate(widget.auction!.createdAt)
            : FieldValue.serverTimestamp(),
        "createdBy": "admin",
      };

      await FirebaseFirestore.instance
          .collection("auctions")
          .doc(id)
          .set(auctionData);

      if (widget.auction == null) {
        // Send global notification for new auction
        await NotificationService().sendGlobal(
          title: "New Auction Alert!",
          body: "Rare piece '${titleCtrl.text}' is now open for bidding.",
          type: NotificationType.new_auction,
          auctionId: id,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _calculateInitialStatus() {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return "ended";
    if (now.isAfter(startTime)) return "live";
    return "scheduled";
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.auction == null ? "Add Auction" : "Edit Auction",
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Auction Title / Rare Piece Name",
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: artistCtrl,
                decoration: const InputDecoration(labelText: "Artist Name"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              // TextFormField(
              //   controller: descCtrl,
              //   decoration: const InputDecoration(
              //     labelText: "Short Description",
              //   ),
              //   maxLines: 2,
              // ),
              // const SizedBox(height: 16),
              TextFormField(
                controller: sizeCtrl,
                decoration: const InputDecoration(
                  labelText: "Size (e.g. 60x80 cm)",
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: aboutCtrl,
                decoration: const InputDecoration(
                  labelText: "Enter about the page / Details",
                  hintText: "Behind the artwork, techniques used, etc.",
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildArtPicker(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: startBidCtrl,
                      decoration: const InputDecoration(
                        labelText: "Starting Bid (₹)",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: incrementCtrl,
                      decoration: const InputDecoration(
                        labelText: "Min Increment (₹)",
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDateTimePicker(
                "Start Time",
                startTime,
                (val) => setState(() => startTime = val),
              ),
              const SizedBox(height: 16),
              _buildDateTimePicker(
                "End Time",
                endTime,
                (val) => setState(() => endTime = val),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C1A),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.auction == null
                              ? "CREATE AUCTION"
                              : "UPDATE AUCTION",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: localImagePath != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(localImagePath!), fit: BoxFit.cover),
              )
            : artImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(artImageUrl!, fit: BoxFit.cover),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    "Upload Auction Image",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildArtPicker() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: backend.watchArtworks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final artworks = snapshot.data!;

        return DropdownButtonFormField<String>(
          value: selectedArtId,
          decoration: const InputDecoration(
            labelText: "Link to Existing Artwork (Optional)",
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text("Custom Rare Piece (No link)"),
            ),
            ...artworks.map(
              (art) => DropdownMenuItem(
                value: art["id"].toString(),
                child: Text(art["title"].toString()),
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              final art = artworks.firstWhere((a) => a["id"].toString() == val);
              setState(() {
                selectedArtId = val;
                selectedArtTitle = art["title"].toString();
                titleCtrl.text = selectedArtTitle!;
                artImageUrl = art["imageUrl"].toString();
                artistCtrl.text = (art["artistName"] ?? art["artist"] ?? "")
                    .toString();
                // descCtrl.text = (art["description"] ?? "").toString(); // Removed
                sizeCtrl.text = (art["sizeCm"] ?? art["size"] ?? "").toString();
              });
            } else {
              setState(() => selectedArtId = null);
            }
          },
        );
      },
    );
  }

  Widget _buildDateTimePicker(
    String label,
    DateTime value,
    Function(DateTime) onSelect,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null && mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value),
          );
          if (time != null) {
            onSelect(
              DateTime(date.year, date.month, date.day, time.hour, time.minute),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(
              value.toString().split('.')[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
