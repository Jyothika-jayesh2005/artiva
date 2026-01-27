import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/customer/profile/my_orders.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String orderId;

  const PaymentSuccessPage({super.key, required this.orderId});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with TickerProviderStateMixin {
  late final AnimationController _popC;
  late final AnimationController _ringC;
  late final AnimationController _pulseC;

  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _popGlow;

  @override
  void initState() {
    super.initState();

    // Main pop-in animation
    _popC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(parent: _popC, curve: Curves.elasticOut),
    );

    _fade = CurvedAnimation(parent: _popC, curve: Curves.easeOut);

    _popGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _popC, curve: Curves.easeOutCubic),
    );

    // Rotating ring (unique)
    _ringC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Soft pulsing glow
    _pulseC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _popC.forward();
  }

  @override
  void dispose() {
    _popC.dispose();
    _ringC.dispose();
    _pulseC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A); // richer than default green

    return CustomerScaffold(
      currentIndex: -1,
      title: "Payment Successful",
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated success badge (unique)
                AnimatedBuilder(
                  animation: Listenable.merge([_scale, _ringC, _pulseC, _popGlow]),
                  builder: (_, __) {
                    final ringAngle = _ringC.value * 2 * math.pi;
                    final pulse = 0.70 + (_pulseC.value * 0.30); // 0.70..1.0
                    final glowStrength = _popGlow.value;

                    return Transform.scale(
                      scale: _scale.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing glow background
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: green.withOpacity(0.18 * pulse * glowStrength),
                                  blurRadius: 36 * pulse,
                                  spreadRadius: 6 * pulse,
                                ),
                                BoxShadow(
                                  color: green.withOpacity(0.10 * pulse * glowStrength),
                                  blurRadius: 64 * pulse,
                                  spreadRadius: 10 * pulse,
                                ),
                              ],
                            ),
                          ),

                          // Rotating ring
                          Transform.rotate(
                            angle: ringAngle,
                            child: CustomPaint(
                              size: const Size(118, 118),
                              painter: _RingPainter(
                                color: green.withOpacity(0.55),
                              ),
                            ),
                          ),

                          // Main circle + check
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  green.withOpacity(0.95),
                                  green.withOpacity(0.80),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 58,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                const Text(
                  "Payment completed!",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  "Order ID: ${widget.orderId}",
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text("View Orders"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A simple ring with a "gap" so rotation looks animated and not static.
class _RingPainter extends CustomPainter {
  final Color color;

  _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Draw arc with a gap (like a loading ring)
    const startAngle = -math.pi / 2; // top
    const sweepAngle = math.pi * 1.55; // not full circle (gap)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
