import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/backend_service.dart'; // ✅ REQUIRED
import 'package:artiva/backend/models.dart';

import 'pass_detail_page.dart';

class MyPassesPage extends StatefulWidget {
  const MyPassesPage({super.key});

  @override
  State<MyPassesPage> createState() => _MyPassesPageState();
}

class _MyPassesPageState extends State<MyPassesPage> {
  // ✅ DEFINE BACKEND
  final BackendService backend = BackendService();

  Future<List<ExhibitionBooking>> _load() async {
    final user = authService.currentUser;
    if (user == null) throw Exception("Please login first.");
    return backend.getMyExhibitionBookings(user.email);
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "My Passes",
      body: FutureBuilder<List<ExhibitionBooking>>(
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

          final passes = snap.data ?? [];
          if (passes.isEmpty) {
            return const Center(child: Text("No passes booked yet"));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: passes.length,
              itemBuilder: (context, index) {
                final pass = passes[index];

                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PassDetailPage(pass: pass),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE16417).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.confirmation_number_outlined,
                            color: Color(0xFFE16417),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pass.exhibitionTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                pass.venue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Seats: ${pass.seats}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
