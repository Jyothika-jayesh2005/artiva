import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/profile/my_orders.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String orderId;

  const PaymentSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Payment Successful",
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 84, color: Colors.green),
              const SizedBox(height: 12),
              const Text(
                "Payment completed!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text("Order ID: $orderId", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 18),
              SizedBox(
                width: 220,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyOrdersPage(fromPayment: true),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text("View Orders"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
