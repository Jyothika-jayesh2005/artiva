import 'package:flutter/material.dart';
import 'package:artiva/backend/models.dart';

class OrderTrackingPage extends StatelessWidget {
  final Auction auction;

  const OrderTrackingPage({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "Track Order",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork Details Card
            _buildArtworkCard(),
            const SizedBox(height: 30),

            const Text(
              "Order Status",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Timeline
            _buildTimeline(),

            const SizedBox(height: 30),

            // Shipping Details
            const Text(
              "Shipping Details",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildAddressCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              auction.artImageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auction.artTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Winner: ${auction.highestBidderName}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${auction.currentBid}",
                  style: const TextStyle(
                    color: Color(0xFFFF8C1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final addr = auction.shippingAddress;
    if (addr == null) {
      return const Text("No shipping address provided.");
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            addr['name'] ?? "",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "${addr['address']}\n${addr['city']} - ${addr['pincode']}\nPhone: ${addr['phone']}",
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final status = auction.effectiveDeliveryStatus;

    // Determine active step index
    int activeStep = 0;
    if (status == OrderStatus.shipped) activeStep = 1;
    if (status == OrderStatus.delivered) activeStep = 2;

    final placedDate = auction.paymentDate ?? auction.createdAt;
    final shippedDate = auction.shippedDate;
    final deliveredDate = auction.estimatedDeliveryDate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _timelineStep(
            title: "Order Placed",
            date: placedDate,
            isActive: true,
            isCompleted: activeStep >= 0,
            isLast: false,
          ),
          _timelineStep(
            title: "Shipped",
            date: shippedDate,
            isActive: activeStep >= 1,
            isCompleted: activeStep >= 1,
            isLast: false,
          ),
          _timelineStep(
            title: "Delivered",
            date: deliveredDate,
            isActive: activeStep >= 2,
            isCompleted: activeStep >= 2,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required DateTime? date,
    required bool isActive,
    required bool isCompleted,
    required bool isLast,
  }) {
    final color = isActive ? const Color(0xFFFF8C1A) : Colors.grey[300]!;
    final textColor = isActive ? Colors.black87 : Colors.grey[500];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFFFF8C1A)
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFFFF8C1A)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? const Color(0xFFFF8C1A).withOpacity(0.3)
                        : Colors.grey[200],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (date != null)
                    Text(
                      _formatDate(date),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
    final m = months[dt.month - 1];
    // Simple time formatting using padLeft
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    final min = dt.minute.toString().padLeft(2, '0');

    return "${dt.day} $m ${dt.year}, $h:$min $ampm";
  }
}
