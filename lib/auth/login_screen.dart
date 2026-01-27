import 'package:flutter/material.dart';
import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/backend/models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _loading = false;

  static const Color accent = Color(0xFFE16417);
  static const String adminEmail = "admin@artiva.com";

  // 🎬 Animations
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);

    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );

    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌤️ Welcome-style background
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

          // 🟠 Decorative blobs
          IgnorePointer(
            child: Stack(
              children: [
                _blob(top: -120, left: -120, size: 260, alpha: 0.15),
                _blob(top: 140, right: -160, size: 320, alpha: 0.12),
                _blob(bottom: -180, left: -140, size: 360, alpha: 0.10),
              ],
            ),
          ),

          // 📋 Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slideUp,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),

                              const Text(
                                'Artiva',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF5A2E1C),
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 40),

                              _input(
                                hint: 'Email',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) return 'Enter email';
                                  final emailRegex = RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              _input(
                                hint: 'Password',
                                icon: Icons.lock,
                                controller: _passwordController,
                                obscure: !_passwordVisible,
                                suffix: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.brown.shade400,
                                  ),
                                  onPressed: _loading
                                      ? null
                                      : () => setState(() =>
                                          _passwordVisible = !_passwordVisible),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Enter password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 30),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    _loading ? "PLEASE WAIT..." : "LOGIN",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ✅ Admin-aware footer (same logic)
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _emailController,
                                builder: (_, value, __) {
                                  final email =
                                      value.text.trim().toLowerCase();
                                  final isAdminTrying = email == adminEmail;

                                  if (isAdminTrying) {
                                    return const Text(
                                      "Admin account has no registration.",
                                      style: TextStyle(
                                        color: Color(0xFF7A5A4A),
                                      ),
                                    );
                                  }

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Don't have an account? ",
                                        style: TextStyle(
                                          color: Color(0xFF7A5A4A),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _loading
                                            ? null
                                            : () =>
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  '/register',
                                                ),
                                        child: const Text(
                                          'Register',
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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

  // 🔧 UI helpers
  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
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
          color: accent.withOpacity(alpha),
        ),
      ),
    );
  }

  Widget _input({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        errorStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // 🔐 BACKEND (UNCHANGED logic) + gate by form validation
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _loading = true);

    try {
      AppUser user = await authService.login(email, password);
      if (!mounted) return;

      if (email.toLowerCase() == adminEmail) {
        await authService.ensureAdminRole(adminEmail);
        user = authService.currentUser ?? user;
      }

      Navigator.pushReplacementNamed(
        context,
        user.role == Role.admin ? '/admin' : '/home',
      );
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
