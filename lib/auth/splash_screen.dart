import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;

  late final AnimationController _introC; // fade/slide/scale intro
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  late final AnimationController _loopC; // looping glow + blob drift
  late final Animation<double> _glow; // 0..1
  late final Animation<double> _drift; // 0..1

  static const Color accent = Color(0xFFE16417); // orange
  static const Color yellow = Color(0xFFFFC83D); // warm yellow

  @override
  void initState() {
    super.initState();

    _introC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _introC, curve: Curves.easeOut);

    _scale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _introC, curve: Curves.easeOutBack),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _introC, curve: Curves.easeOutCubic),
    );

    _loopC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _glow = CurvedAnimation(parent: _loopC, curve: Curves.easeInOut);
    _drift = CurvedAnimation(parent: _loopC, curve: Curves.easeInOutSine);

    _introC.forward();

    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _introC.dispose();
    _loopC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _loopC,
        builder: (context, _) {
          // drift amount (-1..1)
          final d = (_drift.value - 0.5) * 2;

          return Stack(
            children: [
              // 🌤️ Background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFF7EF),
                        Color(0xFFFFE6CC),
                        Color(0xFFFFF7EF),
                      ],
                    ),
                  ),
                ),
              ),

              // ✨ Yellow glow behind title (subtle)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.18 + (_glow.value * 0.12),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.05),
                          radius: 0.65,
                          colors: [
                            Color(0xFFFFC83D), // yellow
                            Color(0x00FFC83D), // transparent
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 🟠🟡 Floating blobs (orange + yellow)
              IgnorePointer(
                child: Stack(
                  children: [
                    _blob(
                      top: -120 + (d * 10),
                      left: -120 + (d * 8),
                      size: 260,
                      color: accent,
                      alpha: 0.16,
                    ),
                    _blob(
                      top: 140 + (d * 12),
                      right: -160 - (d * 8),
                      size: 320,
                      color: accent,
                      alpha: 0.14,
                    ),
                    _blob(
                      bottom: -180 - (d * 14),
                      left: -140 + (d * 10),
                      size: 360,
                      color: accent,
                      alpha: 0.12,
                    ),
                    // yellow accent blob
                    _blob(
                      top: 40 - (d * 10),
                      right: -110 + (d * 6),
                      size: 220,
                      color: yellow,
                      alpha: 0.10,
                    ),
                  ],
                ),
              ),

              // 🔥 Animated brand text (intro + glow pulse)
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Artiva',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              letterSpacing: 1.8,
                              shadows: [
                                // orange glow pulse
                                Shadow(
                                  blurRadius: 14 + (_glow.value * 10),
                                  color: accent.withOpacity(
                                    0.18 + (_glow.value * 0.10),
                                  ),
                                  offset: const Offset(0, 6),
                                ),
                                // yellow highlight glow (tiny)
                                Shadow(
                                  blurRadius: 10 + (_glow.value * 6),
                                  color: yellow.withOpacity(
                                    0.10 + (_glow.value * 0.08),
                                  ),
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Explore Art. Experience Exhibitions.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7A5A4A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ⏳ 3 bouncing dots (better than single dot)
              Positioned(
                bottom: 42,
                left: 0,
                right: 0,
                child: Center(
                  child: _BouncingDots(
                    t: _loopC.value,
                    orange: accent,
                    yellow: yellow,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
    required double alpha,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(alpha),
        ),
      ),
    );
  }
}

class _BouncingDots extends StatelessWidget {
  final double t; // 0..1
  final Color orange;
  final Color yellow;

  const _BouncingDots({
    required this.t,
    required this.orange,
    required this.yellow,
  });

  double _bounce(double phase) {
    // triangle wave -> smooth bounce
    final x = ((t + phase) % 1.0);
    final tri = x < 0.5 ? x * 2 : (1 - x) * 2; // 0..1..0
    return Curves.easeInOut.transform(tri);
  }

  @override
  Widget build(BuildContext context) {
    final b1 = _bounce(0.00);
    final b2 = _bounce(0.18);
    final b3 = _bounce(0.36);

    Widget dot(Color c, double b) {
      final y = -8 * b;
      final s = 0.75 + 0.25 * b;
      return Transform.translate(
        offset: Offset(0, y),
        child: Transform.scale(
          scale: s,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(orange.withOpacity(0.85), b1),
        const SizedBox(width: 8),
        dot(yellow.withOpacity(0.85), b2),
        const SizedBox(width: 8),
        dot(orange.withOpacity(0.85), b3),
      ],
    );
  }
}
