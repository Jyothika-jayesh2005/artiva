import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/backend/models.dart';
import 'package:artiva/backend/auction_service.dart';
import 'package:artiva/customer/profile/saved_address.dart';
import 'package:artiva/customer/auctions/payment_success_page.dart';

class AuctionPaymentPage extends StatefulWidget {
  final Auction auction;
  const AuctionPaymentPage({super.key, required this.auction});

  @override
  State<AuctionPaymentPage> createState() => _AuctionPaymentPageState();
}

class _AuctionPaymentPageState extends State<AuctionPaymentPage> {
  final AuctionService _auctionService = AuctionService();
  bool _isProcessing = false;
  Map<String, dynamic>? _selectedAddress; // ✅ Added state

  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SavedAddressPage(isSelectionMode: true),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() => _selectedAddress = result);
    }
  }

  Future<void> _handlePayment() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a delivery address first."),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      await _auctionService.markAsSold(
        widget.auction.id,
        shippingAddress: _selectedAddress, // ✅ Pass Address
      );

      if (mounted) {
        Navigator.pop(context); // Close any previous dialogs if needed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentSuccessPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Confirm Payment",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Complete your Rare Piece purchase",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ✅ Address Selection UI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Delivery Address",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedAddress != null)
                        TextButton(
                          onPressed: _selectAddress,
                          child: const Text("Change"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_selectedAddress == null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectAddress,
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text("Select Address"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAddress!["name"] ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_selectedAddress!["phone"] ?? ""),
                        const SizedBox(height: 4),
                        Text(
                          [
                                _selectedAddress!["address"],
                                _selectedAddress!["city"],
                                _selectedAddress!["pincode"],
                              ]
                              .where(
                                (e) => e != null && e.toString().isNotEmpty,
                              )
                              .join(", "),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // ✅ Payment Details (Hidden until address selected)
            if (_selectedAddress != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    Text(
                      widget.auction.artTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Amount to Pay: ₹${widget.auction.currentBid}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE16417),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Simulated QR Code
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        size: 150,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Scan any UPI app to pay",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE16417),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "I HAVE PAID",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "By clicking, you confirm you have completed the payment transaction.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  "Please select a delivery address to view payment details.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
