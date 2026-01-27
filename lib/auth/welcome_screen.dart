import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _loginPressed = false;
  bool _registerPressed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );

    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // ✅ Responsive button width (no more hard-coded 240)
    final double btnWidth = (w * 0.72).clamp(220.0, 280.0);

    return Scaffold(
      body: Stack(
        children: [
          // ✅ Background gradient
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

          // ✅ Background blobs MUST NOT block taps
          IgnorePointer(
            ignoring: true,
            child: Stack(
              children: [
                Positioned(
                  top: -120,
                  left: -120,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE16417).withValues(alpha: 35),
                    ),
                  ),
                ),

                // ✅ FIX: move the right blob further out so it won't crowd buttons
                Positioned(
                  top: 90,
                  right: -190,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE16417).withValues(alpha: 28),
                    ),
                  ),
                ),

                Positioned(
                  bottom: -160,
                  left: -120,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE16417).withValues(alpha: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Artiva',
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5A2E1C),
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Explore Art. Experience Exhibitions.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7A5A4A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 46),

                        // ✅ LOGIN
                        _AnimatedPressButton(
                          width: btnWidth,
                          pressed: _loginPressed,
                          label: "LOGIN",
                          filled: true,
                          onTapDown: () => setState(() => _loginPressed = true),
                          onTapUp: () => setState(() => _loginPressed = false),
                          onTapCancel: () =>
                              setState(() => _loginPressed = false),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                        ),
                        const SizedBox(height: 16),

                        // ✅ REGISTER
                        _AnimatedPressButton(
                          width: btnWidth,
                          pressed: _registerPressed,
                          label: "REGISTER",
                          filled: false,
                          onTapDown: () =>
                              setState(() => _registerPressed = true),
                          onTapUp: () =>
                              setState(() => _registerPressed = false),
                          onTapCancel: () =>
                              setState(() => _registerPressed = false),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedPressButton extends StatelessWidget {
  final double width;
  final bool pressed;
  final String label;
  final bool filled;
  final VoidCallback onPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const _AnimatedPressButton({
    required this.width,
    required this.pressed,
    required this.label,
    required this.filled,
    required this.onPressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 30.0;

    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      onTap: onPressed,
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: width,
            height: 52,
            child: filled
                ? Material(
                    color: const Color(0xFFE16417),
                    child: InkWell(
                      onTap: onPressed,
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPressed,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color:
                                const Color(0xFFE16417).withValues(alpha: 160),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFFE16417),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
