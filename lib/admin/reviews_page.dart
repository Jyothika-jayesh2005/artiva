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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Artwork Reviews",
      body: StreamBuilder<List<ArtworkOrder>>(
        stream: backend.watchOrders(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8C1A)),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Text(
                "Error: ${snap.error.toString().replaceFirst('Exception: ', '')}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allOrders = snap.data ?? [];

          // 1. Filter: Only orders with ratings or reviews
          var reviews = allOrders.where((o) {
            final hasRating = (o.rating != null);
            final hasText = (o.review ?? "").trim().isNotEmpty;
            return hasRating || hasText;
          }).toList();

          // Calculate stats
          final totalReviews = reviews.length;
          double avgRating = 0;
          if (totalReviews > 0) {
            final sum = reviews.fold(0, (p, c) => p + (c.rating ?? 0));
            avgRating =
                sum /
                totalReviews; // This might be skewed if some have review text but no rating, but typically they go together
            // More accurate: count only those with rating > 0
            final ratedCount = reviews.where((r) => (r.rating ?? 0) > 0).length;
            if (ratedCount > 0) {
              final ratedSum = reviews.fold(0, (p, c) => p + (c.rating ?? 0));
              avgRating = ratedSum / ratedCount;
            }
          }

          return Column(
            children: [
              // --- HEADER STATS & SEARCH ---
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _StatCard(
                      label: "Total Reviews",
                      value: totalReviews.toString(),
                      icon: Icons.rate_review_rounded,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: "Avg Rating",
                      value: avgRating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      color: const Color(0xFFFF8C1A),
                      isRating: true,
                    ),
                  ],
                ),
              ),

              // --- LIST ---
              Expanded(
                child: reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No reviews found",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          return _ReviewCard(
                            order: reviews[index],
                            onDelete: () =>
                                _confirmDeleteReview(reviews[index]),
                          );
                        },
                      ),
              ),
            ],
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
          "This will remove the rating and review from this order.\n\n"
          "This action cannot be undone.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await backend.deleteOrderReview(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Review deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isRating;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ArtworkOrder order;
  final VoidCallback onDelete;

  const _ReviewCard({required this.order, required this.onDelete});

  String _formatDate(DateTime dt) {
    const m = [
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
    return "${dt.day} ${m[dt.month - 1]} ${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final rating = order.rating ?? 0;
    final reviewText = (order.review ?? "").trim();
    final hasImage = (order.imageUrl ?? "").isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Section: Image + Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artwork Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    image: hasImage
                        ? DecorationImage(
                            image: NetworkImage(order.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasImage
                      ? Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.artTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFF8C1A),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "by ${order.customerName}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete Button
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.red.shade400,
                  tooltip: "Delete Review",
                ),
              ],
            ),
          ),

          // Divider
          if (reviewText.isNotEmpty)
            Divider(height: 1, color: Colors.grey.shade100),

          // Review Text
          if (reviewText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0), // Light orange background
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: Color(0xFFFF8C1A),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reviewText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      order.ratedAt != null ? _formatDate(order.ratedAt!) : "",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
