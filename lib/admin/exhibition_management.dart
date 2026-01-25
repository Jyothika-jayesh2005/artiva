import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/backend_service.dart';

import 'add_edit_exhibition.dart';

class ExhibitionManagementPage extends StatefulWidget {
  const ExhibitionManagementPage({super.key});

  @override
  State<ExhibitionManagementPage> createState() =>
      _ExhibitionManagementPageState();
}

class _ExhibitionManagementPageState extends State<ExhibitionManagementPage> {
  bool _showArchived = false;

  // ✅ DEFINE BACKEND
  final BackendService backend = BackendService();

  Future<List<Exhibition>> _load() async {
    return backend.getExhibitions(includeArchived: true);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Exhibitions",
      showBack: true,
      actions: [
        IconButton(
          onPressed: () async {
            final ok = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const AddEditExhibitionPage(),
              ),
            );
            if (ok == true && mounted) setState(() {});
          },
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ],
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _showArchived ? "Showing: All" : "Showing: Active only",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: _showArchived,
                  onChanged: (v) => setState(() => _showArchived = v),
                ),
              ],
            ),
          ),
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
                      snap.error
                          .toString()
                          .replaceFirst('Exception: ', ''),
                    ),
                  );
                }

                var list = snap.data ?? [];
                if (!_showArchived) {
                  list = list.where((e) => !e.isArchived).toList();
                }

                if (list.isEmpty) {
                  return const Center(child: Text("No exhibitions"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _card(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Exhibition ex) {
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
              color: Colors.white.withOpacity(0.90),
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
                        onPressed: () async {
                          try {
                            await backend.setExhibitionArchived(
                              ex.id,
                              !ex.isArchived,
                            );
                            if (mounted) setState(() {});
                            _snack(
                              ex.isArchived ? "Unarchived" : "Archived",
                            );
                          } catch (e) {
                            _snack(
                              e.toString()
                                  .replaceFirst('Exception: ', ''),
                            );
                          }
                        },
                        icon: Icon(
                          ex.isArchived
                              ? Icons.unarchive
                              : Icons.archive,
                        ),
                        label: Text(
                          ex.isArchived ? "Unarchive" : "Archive",
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

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}-${two(dt.month)}-${dt.year}  "
        "${two(dt.hour)}:${two(dt.minute)}";
  }
}
