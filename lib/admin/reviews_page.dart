import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/backend/backend_service.dart';
import 'package:artiva/backend/models.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final BackendService backend = BackendService();

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Artwork Reviews",
      showBack: true,
      body: FutureBuilder<List<ArtworkOrder>>(
        future: backend.getAllOrders(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                "Error: ${snap.error.toString().replaceFirst('Exception: ', '')}",
              ),
            );
          }

          final all = snap.data ?? [];

          // ✅ only orders that have rating OR review text
          final reviews = all.where((o) {
            final hasRating = (o.rating != null);
            final hasText = (o.review ?? "").trim().isNotEmpty;
            return hasRating || hasText;
          }).toList();

          if (reviews.isEmpty) {
            return const Center(child: Text("No reviews yet"));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (_, i) {
                final o = reviews[i];

                final rating = o.rating;
                final reviewText = (o.review ?? "").trim();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.star),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.artTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Customer: ${o.customerName}  •  ${o.customerEmail}",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: "Delete Review",
                              onPressed: () => _confirmDeleteReview(o),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.star_rate_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              rating == null ? "No rating" : "$rating/5",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (o.ratedAt != null)
                              Text(
                                _formatDateTime(o.ratedAt!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),

                        if (reviewText.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            "\"$reviewText\"",
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),
                        Text(
                          "Order: ${o.id}",
                          style: const TextStyle(fontSize: 12, color: Colors.black45),
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

  Future<void> _confirmDeleteReview(ArtworkOrder order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Review"),
        content: const Text(
          "This will remove the customer's rating + review from the order.\n\n"
          "Customer will not get a notification, but they may notice it later.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await backend.deleteOrderReview(order.id);
      if (mounted) setState(() {});
      _snack("Review deleted");
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
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
