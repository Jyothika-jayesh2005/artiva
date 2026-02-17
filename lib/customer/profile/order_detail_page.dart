import 'package:flutter/material.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

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

    // Fallback logic for dates
    final deliveryDate = order.estimatedDeliveryDate;
    final shippedDate = order.shippedDate;

    return CustomerScaffold(
      // 1. Consistent Header
      currentIndex: -1,
      title: "Order Details",
      // 2. Background Color
      body: Container(
        color: const Color(0xFFFFF1DC),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3. Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 100,
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
                              color: Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "₹${order.price}  •  Qty: ${order.quantity}",
                            style: const TextStyle(
                              color: Color(0xFFE16417),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Order #${order.id.length >= 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Status Title
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  "Order Timeline",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (status == OrderStatus.cancelled) ...[
                      _timelineStep(
                        title: "Order Placed",
                        date: _formatDate(placedDate),
                        isCompleted: true,
                        isCurrent: false,
                        isLast: false,
                      ),
                      _timelineStep(
                        title: "Cancelled",
                        date: order.updatedAt != null
                            ? _formatDate(order.updatedAt!)
                            : "Refund Processing",
                        isCompleted: true,
                        isCurrent:
                            !order.refunded, // Only current if NOT refunded
                        isLast: !order.refunded,
                        isCancelled: true,
                      ),
                      if (order.refunded)
                        _timelineStep(
                          title: "Refunded",
                          date: order.updatedAt != null
                              ? _formatDate(order.updatedAt!)
                              : "Refund Completed",
                          isCompleted: true,
                          isCurrent: true,
                          isLast: true,
                          isRefunded: true, // New flag
                        ),
                    ] else ...[
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
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Estimated / Delivered / Cancelled Banner
              if (status == OrderStatus.cancelled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: order.refunded
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: order.refunded
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        order.refunded
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: order.refunded ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),
                      Text(
                        order.refunded ? "Refunded" : "Order Cancelled",
                        style: TextStyle(
                          color: order.refunded ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.refunded
                            ? "Refund has been initiated."
                            : "Refund will be initiated within 7 days.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: order.refunded ? Colors.green : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else if (status != OrderStatus.delivered)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.blue,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Estimated Delivery",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(deliveryDate),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Delivered Successfully",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(deliveryDate),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // 6. Shipping Address
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  "Shipping To",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1DC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFE16417),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        order.address ?? "No address provided",
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
    bool isCancelled = false,
    bool isRefunded = false, // ✅ Added flag
  }) {
    Color color = isRefunded
        ? Colors.green
        : (isCancelled
              ? Colors.red
              : (isCompleted || isCurrent
                    ? const Color(0xFFE16417)
                    : Colors.grey.shade300));

    Color textColor = isCompleted || isCurrent
        ? const Color(0xFF1A1A1A)
        : Colors.grey;

    if (isRefunded)
      textColor = Colors.green;
    else if (isCancelled)
      textColor = Colors.red;

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
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted
                    ? color.withOpacity(0.5)
                    : Colors.grey.shade200,
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
            Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            if (isCurrent) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1DC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Current Status",
                  style: TextStyle(
                    fontSize: 11,
                    color: isRefunded
                        ? Colors.green
                        : (isCancelled ? Colors.red : const Color(0xFFE16417)),
                  ),
                ),
              ),
            ],
            // Add extra spacing to align with the line if not last
            if (!isLast) const SizedBox(height: 24),
          ],
        ),
      ],
    );
  }
}
