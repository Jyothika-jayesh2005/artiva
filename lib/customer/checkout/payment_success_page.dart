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

  // ✅ delayed reveal + burst moment
  late final AnimationController
  _revealC; // tick + full green overlay + shockwave
  late final AnimationController _burstC; // poppers/boxes burst

  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _popGlow;

  // reveal animations
  late final Animation<double> _tickScale;
  late final Animation<double> _tickFade;
  late final Animation<double> _shockWave;
  late final Animation<double> _greenWash; // ✅ full-page green popup

  @override
  void initState() {
    super.initState();

    _popC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(
      begin: 0.70,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _popC, curve: Curves.elasticOut));

    _fade = CurvedAnimation(parent: _popC, curve: Curves.easeOut);

    _popGlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _popC, curve: Curves.easeOutCubic));

    _ringC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);

    // ✅ Reveal: controls green popup + tick pop
    _revealC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _tickScale = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _revealC, curve: Curves.elasticOut));

    _tickFade = CurvedAnimation(parent: _revealC, curve: Curves.easeIn);

    _shockWave = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _revealC, curve: Curves.easeOutCubic));

    // ✅ Full-page green popup (fast at start, then settle)
    _greenWash = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _revealC, curve: Curves.easeOutExpo));

    _burstC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _popC.forward();

    // ✅ Delay the success “moment”
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _revealC.forward(from: 0);
      _burstC.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _popC.dispose();
    _ringC.dispose();
    _pulseC.dispose();
    _revealC.dispose();
    _burstC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);

    return CustomerScaffold(
      currentIndex: -1,
      title: "Payment Successful",
      body: AnimatedBuilder(
        animation: Listenable.merge([_fade, _revealC]),
        builder: (_, __) {
          final wash = _greenWash.value; // 0..1

          return Stack(
            children: [
              // ✅ Full-screen green popup overlay
              // starts transparent and becomes green, with a soft gradient look.
              IgnorePointer(
                child: Opacity(
                  opacity: (wash * 0.92).clamp(0.0, 0.92),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          green.withOpacity(0.65),
                          green.withOpacity(0.92),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _scale,
                            _ringC,
                            _pulseC,
                            _popGlow,
                            _revealC,
                            _burstC,
                          ]),
                          builder: (_, __) {
                            final ringAngle = _ringC.value * 2 * math.pi;
                            final pulse = 0.70 + (_pulseC.value * 0.30);
                            final glowStrength = _popGlow.value;

                            final wave = _shockWave.value;
                            final waveSize = 96 + (wave * 160);
                            final waveOpacity = (1.0 - wave).clamp(0.0, 1.0);

                            return Transform.scale(
                              scale: _scale.value,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  // ✅ poppers burst
                                  _PopBurst(
                                    progress: CurvedAnimation(
                                      parent: _burstC,
                                      curve: Curves.easeOutCubic,
                                    ).value,
                                    color: Colors
                                        .white, // ✅ white pops look better on green
                                  ),

                                  // ✅ shockwave ring
                                  if (wave > 0)
                                    Container(
                                      width: waveSize,
                                      height: waveSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(
                                            0.55 * waveOpacity,
                                          ),
                                          width: 6,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(
                                              0.18 * waveOpacity,
                                            ),
                                            blurRadius: 30,
                                            spreadRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),

                                  // pulsing glow
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(
                                            0.14 * pulse * glowStrength,
                                          ),
                                          blurRadius: 40 * pulse,
                                          spreadRadius: 10 * pulse,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // rotating ring
                                  Transform.rotate(
                                    angle: ringAngle,
                                    child: CustomPaint(
                                      size: const Size(118, 118),
                                      painter: _RingPainter(
                                        color: Colors.white.withOpacity(0.55),
                                      ),
                                    ),
                                  ),

                                  // main circle + tick pop
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.22),
                                          Colors.white.withOpacity(0.12),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.55),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 18,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: FadeTransition(
                                      opacity: _tickFade,
                                      child: ScaleTransition(
                                        scale: _tickScale,
                                        child: const Icon(
                                          Icons.check_rounded,
                                          size: 58,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        // ✅ Text becomes white when green wash appears
                        Text(
                          "Payment completed!",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _greenWash.value > 0.2
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Order ID: ${widget.orderId}",
                          style: TextStyle(
                            color: _greenWash.value > 0.2
                                ? Colors.white70
                                : Colors.grey,
                          ),
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
                                  builder: (_) =>
                                      const MyOrdersPage(fromPayment: true),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "View Orders",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ✅ Burst (poppers + boxes)
class _PopBurst extends StatelessWidget {
  final double progress; // 0..1
  final Color color;

  const _PopBurst({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return const SizedBox.shrink();

    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final dist = 42 + (progress * 56);

    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _box(
              angle: -20,
              dist: dist,
              size: 10,
              color: color.withOpacity(0.95),
            ),
            _box(
              angle: 35,
              dist: dist * 0.95,
              size: 8,
              color: color.withOpacity(0.85),
            ),
            _box(
              angle: 80,
              dist: dist * 0.88,
              size: 9,
              color: color.withOpacity(0.80),
            ),
            _box(
              angle: 145,
              dist: dist * 0.92,
              size: 7,
              color: color.withOpacity(0.78),
            ),
            _box(
              angle: 205,
              dist: dist * 0.96,
              size: 9,
              color: color.withOpacity(0.90),
            ),
            _box(
              angle: 255,
              dist: dist * 0.90,
              size: 8,
              color: color.withOpacity(0.82),
            ),
            _box(
              angle: 320,
              dist: dist * 0.94,
              size: 7,
              color: color.withOpacity(0.88),
            ),

            _dot(
              angle: 10,
              dist: dist * 1.06,
              r: 3.2,
              color: color.withOpacity(0.85),
            ),
            _dot(
              angle: 95,
              dist: dist * 1.00,
              r: 2.6,
              color: color.withOpacity(0.75),
            ),
            _dot(
              angle: 170,
              dist: dist * 1.08,
              r: 3.0,
              color: color.withOpacity(0.80),
            ),
            _dot(
              angle: 235,
              dist: dist * 1.02,
              r: 2.5,
              color: color.withOpacity(0.70),
            ),
            _dot(
              angle: 330,
              dist: dist * 1.05,
              r: 2.8,
              color: color.withOpacity(0.82),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box({
    required double angle,
    required double dist,
    required double size,
    required Color color,
  }) {
    final rad = angle * math.pi / 180;
    return Transform.translate(
      offset: Offset(math.cos(rad) * dist, math.sin(rad) * dist),
      child: Transform.rotate(
        angle: rad * 0.35,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot({
    required double angle,
    required double dist,
    required double r,
    required Color color,
  }) {
    final rad = angle * math.pi / 180;
    return Transform.translate(
      offset: Offset(math.cos(rad) * dist, math.sin(rad) * dist),
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Ring painter with a gap
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

    const startAngle = -math.pi / 2;
    const sweepAngle = math.pi * 1.55;
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
