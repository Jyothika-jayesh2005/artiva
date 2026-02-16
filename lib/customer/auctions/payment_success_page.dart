import 'package:flutter/material.dart';
import 'package:artiva/main.dart'; // For navigatorKey
import 'package:artiva/customer/auctions/my_wins.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // ✅ Slower animation
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green, // ✅ Full Green Background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Checkmark with Elastic Pop
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ✅ Text Fades In
              FadeTransition(
                opacity: _controller.drive(
                  CurveTween(
                    curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Payment Successful!",
                      style: TextStyle(
                        fontSize: 28, // Larger splash-like text
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Thank you for your purchase.\nYour order has been placed successfully.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // ✅ Buttons Slide Up & Fade In
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(
                          0.5,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                child: FadeTransition(
                  opacity: _controller.drive(
                    CurveTween(
                      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE16417), Color(0xFF80431F)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            navigatorKey.currentState?.popUntil(
                              (route) => route.isFirst,
                            );
                            navigatorKey.currentState?.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const MyWinsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "VIEW ORDER",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          navigatorKey.currentState?.popUntil(
                            (route) => route.isFirst,
                          );
                        },
                        child: const Text(
                          "Back to Home",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
