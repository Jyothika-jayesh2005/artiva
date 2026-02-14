import 'dart:io';
import 'package:flutter/material.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/customer/exhibition_payment_page.dart';

class ExhibitionDetailPage extends StatefulWidget {
  final Exhibition exhibition;
  const ExhibitionDetailPage({super.key, required this.exhibition});

  @override
  State<ExhibitionDetailPage> createState() => _ExhibitionDetailPageState();
}

class _ExhibitionDetailPageState extends State<ExhibitionDetailPage> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final remaining = widget.exhibition.remainingSeats;
    final image = widget.exhibition.imageUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF1DC),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Full Image Top
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: double.infinity,
                  child: _imageWidget(image, fit: BoxFit.cover),
                ),

                // 2. Info Container (Overlapping)
                Container(
                  transform: Matrix4.translationValues(0, -40, 0),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title
                      Text(
                        widget.exhibition.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A1A),
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Venue & Date Rows
                      _infoRow(
                        Icons.location_on_outlined,
                        widget.exhibition.venue,
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.access_time_outlined,
                        _formatDateTime(widget.exhibition.dateTime),
                      ),
                      const SizedBox(height: 32),

                      // Description
                      const Text(
                        "About the Exhibition",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final description = widget.exhibition.description;
                          const int truncationLimit = 150;
                          final bool isLong =
                              description.length > truncationLimit;
                          final String textToShow =
                              isLong && !_isDescriptionExpanded
                              ? "${description.substring(0, truncationLimit)}..."
                              : description;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                textToShow,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              if (isLong)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded =
                                          !_isDescriptionExpanded;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _isDescriptionExpanded
                                          ? "Show Less"
                                          : "Read More",
                                      style: const TextStyle(
                                        color: Color(0xFFFF8C1A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Specs Chips (Price, Seats)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _specChip(
                              "₹${widget.exhibition.pricePerSeat}",
                              "Price per Seat",
                              true,
                            ),
                            const SizedBox(width: 12),
                            _specChip(
                              remaining > 0 ? "$remaining" : "Sold Out",
                              "Seats Remaining",
                              false,
                              isError: remaining == 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Back Button (Top Left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              radius: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bottom Button (Preserving Flow)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: remaining == 0
                        ? null
                        : () async {
                            final seats = await _pickSeats(context, remaining);
                            if (seats == null) return;
                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExhibitionPaymentPage(
                                  exhibition: widget.exhibition,
                                  seats: seats,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C1A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      remaining == 0 ? "Sold Out" : "Book Seats",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8C1A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFFFF8C1A)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _specChip(
    String label,
    String subLabel,
    bool active, {
    bool isError = false,
  }) {
    Color bg = active ? const Color(0xFFFFF3E0) : Colors.grey.shade50;
    Color border = active ? const Color(0xFFFF8C1A) : Colors.grey.shade200;
    Color text = active ? const Color(0xFFFF8C1A) : Colors.grey.shade800;
    Color subText = active ? Colors.orange.shade800 : Colors.grey.shade500;

    if (isError) {
      bg = Colors.red.shade50;
      border = Colors.red.shade200;
      text = Colors.red;
      subText = Colors.red.shade300;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: active ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 12,
              color: subText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Future<int?> _pickSeats(BuildContext context, int maxSeats) async {
    int selected = 1;

    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text("Select Seats"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Seats: ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: selected,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFFE16417),
                    ),
                    items: List.generate(maxSeats, (i) => i + 1)
                        .map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text(
                              n.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => selected = v ?? 1),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selected),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    color: Color(0xFFE16417),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _imageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.image_not_supported, size: 44)),
      );
    }
    if (path.startsWith("http")) {
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
      );
    }
    if (path.startsWith("assets/")) {
      return Image.asset(path, fit: fit);
    }
    return Image.file(File(path), fit: fit);
  }

  String _formatDateTime(DateTime dt) {
    // Custom simple formatter: "12 Oct 2024, 10:30 AM"
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final String month = months[dt.month - 1];
    final String day = dt.day.toString();
    final String year = dt.year.toString();

    int hour = dt.hour;
    final String ampm = hour >= 12 ? "PM" : "AM";
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final String minute = dt.minute.toString().padLeft(2, '0');

    return "$day $month $year, $hour:$minute $ampm";
  }
}
