import 'dart:ui';
import 'package:artiva/admin/admin_dashboard.dart';
import 'package:flutter/material.dart';

import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/backend_service.dart';

import 'add_edit_exhibition.dart';

/// ✅ Use this inside AdminDashboard (no AdminScaffold here)
class ExhibitionManagementBody extends StatefulWidget {
  final ExhibitionDashFilter filter;

  const ExhibitionManagementBody({super.key, required this.filter});

  @override
  State<ExhibitionManagementBody> createState() =>
      _ExhibitionManagementBodyState();
}

class _ExhibitionManagementBodyState extends State<ExhibitionManagementBody> {
  final BackendService backend = BackendService();
  static const Color accent = Color(0xFFFF8C1A);

  Future<List<Exhibition>> _load() async {
    return backend.getExhibitions(includeArchived: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<Exhibition>>(
            future: _load(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    snap.error.toString().replaceFirst('Exception: ', ''),
                  ),
                );
              }

              var list = snap.data ?? [];
              final now = DateTime.now();

              if (widget.filter == ExhibitionDashFilter.active) {
                list = list
                    .where((e) => !e.isArchived && e.dateTime.isAfter(now))
                    .toList();
              } else if (widget.filter == ExhibitionDashFilter.unarchive) {
                list = list
                    .where((e) => e.isArchived || e.dateTime.isBefore(now))
                    .toList();
              } else if (widget.filter == ExhibitionDashFilter.soldOut) {
                list = list.where((e) => e.remainingSeats <= 0).toList();
              }
              // all = no filtering

              if (list.isEmpty) {
                return const Center(child: Text("No exhibitions"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _card(context, list[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, Exhibition ex) {
    final remaining = ex.remainingSeats;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E8).withOpacity(0.95), // light orange
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${ex.venue} • ${_formatDateTime(ex.dateTime)}",
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  "Seats: ${ex.bookedSeats}/${ex.totalSeats}  •  Remaining: $remaining  •  ₹${ex.pricePerSeat}/seat",
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: const BorderSide(color: accent),
                        ),

                        onPressed: () async {
                          final ok = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddEditExhibitionPage(existing: ex),
                            ),
                          );
                          if (ok == true && mounted) setState(() {});
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ex.isArchived
                              ? Colors.green
                              : Colors.red,
                          foregroundColor: Colors.white,
                        ),

                        onPressed: () async {
                          try {
                            await backend.setExhibitionArchived(
                              ex.id,
                              !ex.isArchived,
                            );
                            if (mounted) setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ex.isArchived ? "Unarchived" : "Archived",
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          ex.isArchived ? Icons.unarchive : Icons.archive,
                        ),
                        label: Text(
                          ex.isArchived ? "Unarchive" : "Archive",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  ${two(dt.hour)}:${two(dt.minute)}";
  }
}
