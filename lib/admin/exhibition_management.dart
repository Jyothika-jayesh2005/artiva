import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import '../data/exhibition_data.dart';
import '../models/exhibition_model.dart';
import 'add_edit_exhibition.dart';

class ExhibitionManagementPage extends StatefulWidget {
  const ExhibitionManagementPage({super.key});

  @override
  State<ExhibitionManagementPage> createState() =>
      _ExhibitionManagementPageState();
}

class _ExhibitionManagementPageState extends State<ExhibitionManagementPage> {
  // ✅ Dummy images for admin list (UI-only)
  final List<String> _images = const [
    "assets/exbhi1.jpg",
    "assets/exbhi2.jpg",
    "assets/exbhi3.jpg",
  ];

  @override
  Widget build(BuildContext context) {
    // ✅ Show only active (not archived)
    final activeExhibitions =
        ExhibitionData.exhibitions.where((e) => !e.isArchived).toList();

    return AdminScaffold(
      title: "Exhibitions",
      showBack: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () async {
            final changed = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddEditExhibitionPage()),
            );
            if (changed == true) setState(() {});
          },
        ),
      ],
      body: activeExhibitions.isEmpty
          ? const Center(child: Text("No exhibitions added yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeExhibitions.length,
              itemBuilder: (_, i) {
                final ex = activeExhibitions[i];

                // ✅ Find original index (because we filtered)
                final originalIndex = ExhibitionData.exhibitions
                    .indexWhere((x) => x.id == ex.id);

                // ✅ Pick an image (UI only)
                final imagePath = _images[i % _images.length];

                return _exhibitionCard(context, ex, originalIndex, imagePath);
              },
            ),
    );
  }

  Widget _exhibitionCard(
    BuildContext context,
    Exhibition ex,
    int index,
    String imagePath,
  ) {
    final remaining = ex.remainingSeats;
    final canEdit = !ex.isClosed;
    final hasBookings = ex.bookedSeats > 0;

    String label;
    Color labelColor;

    if (ex.isClosed) {
      label = "Closed";
      labelColor = Colors.red;
    } else if (ex.isFull) {
      label = "Full";
      labelColor = Colors.orange;
    } else {
      label = "Upcoming";
      labelColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // ✅ important for image corners
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ IMAGE TOP
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title + badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ex.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: labelColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: labelColor.withOpacity(0.6)),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(ex.venue, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),

                Text(
                  _formatDateTime(ex.dateTime),
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 10),

                Text(
                  ex.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87),
                ),

                const SizedBox(height: 12),

                // Seats
                Text(
                  "Seats: ${ex.bookedSeats}/${ex.totalSeats}  •  Remaining: $remaining",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 10),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // EDIT
                    TextButton.icon(
                      onPressed: canEdit
                          ? () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddEditExhibitionPage(editIndex: index),
                                ),
                              );
                              if (changed == true) setState(() {});
                            }
                          : null,
                      icon:
                          Icon(Icons.edit, color: canEdit ? null : Colors.grey),
                      label: Text(
                        "Edit",
                        style: TextStyle(color: canEdit ? null : Colors.grey),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // DELETE if no bookings, otherwise ARCHIVE
                    TextButton.icon(
                      onPressed: () {
                        if (hasBookings) {
                          _confirmArchive(index);
                        } else {
                          _confirmDelete(index);
                        }
                      },
                      icon: Icon(
                        hasBookings ? Icons.archive : Icons.delete,
                        color: hasBookings ? Colors.orange : Colors.red,
                      ),
                      label: Text(
                        hasBookings ? "Archive" : "Delete",
                        style: TextStyle(
                          color: hasBookings ? Colors.orange : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HARD delete (only when bookedSeats == 0)
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Exhibition"),
        content: const Text("Are you sure you want to delete this exhibition?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                ExhibitionData.exhibitions.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ARCHIVE (when bookings exist)
  void _confirmArchive(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Archive Exhibition"),
        content: const Text(
          "This exhibition has bookings, so it cannot be deleted.\n\n"
          "Archiving will hide it from customers but keep booking history.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final ex = ExhibitionData.exhibitions[index];
                ExhibitionData.exhibitions[index] = ex.copyWith(isArchived: true);
              });
              Navigator.pop(context);
            },
            child: const Text("Archive"),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
