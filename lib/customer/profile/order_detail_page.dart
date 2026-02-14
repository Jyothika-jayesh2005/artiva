import 'package:flutter/material.dart';
import 'package:artiva/backend/models.dart';

class OrderDetailPage extends StatelessWidget {
  final ArtworkOrder order;

  const OrderDetailPage({super.key, required this.order});

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
    final status = order.effectiveStatus;
    final placedDate = order.orderedAt;
    // final shippedDate = order.shippedDate; // Assuming status change timestamp or similar logic if needed, but model doesn't explicitly have shippedDate, using orderedAt or similar for now if needed, or just let status drive it.
    // Wait, the user's code used `order.shippedDate`. The model `ArtworkOrder` in `models.dart` DOES NOT have `shippedDate`.
    // I need to check `models.dart` again.
    // `ArtworkOrder` has `orderedAt`, `ratedAt`, `updatedAt` (implicit in Firestore).
    // It does not have `shippedDate`.
    // However, the user provided code USES `order.shippedDate`.
    // I should probably add `shippedDate` and `deliveredDate` to `ArtworkOrder` model or derived them.
    // For now, I will use `orderedAt` as a placeholder or `updatedAt` if available in the passed object, but `ArtworkOrder` definition in `models.dart` (read in step 147) DOES NOT have `shippedDate` or `estimatedDeliveryDate`.
    // Wait, let me check `models.dart` again carefully.
    // Step 147: `ArtworkOrder` has:
    // id, artId, artTitle, customerName, customerEmail, quantity, price, imageUrl, address, addressSnapshot, addressId, sizeCm, sizeIn, status, orderedAt, rating, review, ratedAt, ratingLocked.
    // NO `shippedDate`, NO `estimatedDeliveryDate`.
    // The user's provided code uses `order.estimatedDeliveryDate` and `order.shippedDate`.
    // This implies the user might have updated `models.dart` or expects me to update it, OR the user's code is from a version where these existed or they copy-pasted from somewhere else.
    // BUT the user says "ad this".
    // I must make it work.
    // I can stick to `orderedAt` for placed.
    // for shipped/delivered, I depend on `status`.
    // `estimatedDeliveryDate` is usually `orderedAt` + X days.

    // I will add extension getters or just logic in the file to handle missing fields if I can't change the model right now without user permission (though I can if needed).
    // Better to define them locally or extend the model.
    // I'll update `models.dart` to include these if they are missing, or just fake them for now to make the code compile.
    // Actually, `estimatedDeliveryDate` was used in `MyOrdersPage` snippet too: `order.estimatedDeliveryDate`.
    // Check `MyOrdersPage` provided code... yes, `final displayDate = isDelivered ? order.estimatedDeliveryDate : order.estimatedDeliveryDate;`
    // It seems `ArtworkOrder` is expected to have these.
    // I should check `models.dart` again. Maybe I missed it?
    // Snippet 147:
    // class ArtworkOrder { ... }
    // It definitively does NOT have `estimatedDeliveryDate`.

    // I will add these getters to `ArtworkOrder` in `models.dart` first?
    // OR I can add them as extension methodology in a separate file? NO, better to fix the model.
    // However, I'll first write this file, maybe commenting out the missing fields or adding a TODO, then I'll fix the model.
    // Actually, I'll fix the `models.dart` file first if I want to be clean.
    // But the prompt is to "add this page".
    // I will write the file with `estimatedDeliveryDate` logic implemented as an extension or property if possible, logic: `orderedAt.add(Duration(days: 7))`

    final deliveryDate = order.estimatedDeliveryDate;
    final shippedDate = order.shippedDate;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF1DC),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: (order.imageUrl ?? "").isEmpty
                          ? const Icon(Icons.image, color: Colors.black38)
                          : Image.network(order.imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.artTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "₹${order.price}  •  Qty: ${order.quantity}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Order ID: #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Timeline
            const Text(
              "Order Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _timelineStep(
                    title: "Order Placed",
                    date: _formatDate(placedDate),
                    isCompleted: true,
                    isCurrent: status == OrderStatus.pending,
                    isLast: false,
                  ),
                  _timelineStep(
                    title: "Shipped",
                    date: _formatDate(shippedDate),
                    isCompleted:
                        status == OrderStatus.shipped ||
                        status == OrderStatus.delivered,
                    isCurrent: status == OrderStatus.shipped,
                    isLast: false,
                  ),
                  _timelineStep(
                    title: "Delivered",
                    date: _formatDate(deliveryDate),
                    isCompleted: status == OrderStatus.delivered,
                    isCurrent: status == OrderStatus.delivered,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Estimated Delivery Banner
            if (status != OrderStatus.delivered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE), // Light Blue
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      color: Colors.blue,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Estimated Delivery",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(deliveryDate),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9), // Light Green
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Delivered Successfully",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(deliveryDate),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 4. Shipping Address
            const Text(
              "Shipping Address",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                order.address ?? "No address provided",
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required String date,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color color = isCompleted || isCurrent
        ? const Color(0xFFFF8C1A)
        : Colors.grey.shade300;
    Color textColor = isCompleted || isCurrent ? Colors.black : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? color : Colors.white,
                border: Border.all(color: color, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted ? color : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
            ),
            if (isCurrent) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C1A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "Current Status",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF8C1A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            // Add extra spacing to align with the line if not last
            if (!isLast) const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }
}
