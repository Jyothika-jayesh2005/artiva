import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artiva/auth/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _loading = false;

  static const Color accent = Color(0xFFE16417);

  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);

    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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

          IgnorePointer(
            child: Stack(
              children: [
                _blob(top: -120, left: -120, size: 260, alpha: 0.15),
                _blob(top: 140, right: -160, size: 320, alpha: 0.12),
                _blob(bottom: -180, left: -140, size: 360, alpha: 0.10),
              ],
            ),
          ),

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
                              const SizedBox(height: 16),
                              const Text(
                                'Artiva',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF5A2E1C),
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Create your account',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF7A5A4A),
                                ),
                              ),
                              const SizedBox(height: 36),

                              _field(
                                hint: 'Full Name',
                                icon: Icons.person,
                                controller: _nameController,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter your name';
                                  }
                                  if (v.trim().length < 3) {
                                    return 'Name must be at least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _field(
                                hint: 'Email',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) return 'Enter your email';
                                  final emailRegex = RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _field(
                                hint: 'Phone (10 digits)',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                controller: _phoneController,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) {
                                    return 'Enter phone number';
                                  }
                                  if (value.length != 10) {
                                    return 'Phone number must be 10 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _field(
                                hint: 'Password',
                                icon: Icons.lock,
                                controller: _passwordController,
                                obscure: !_passwordVisible,
                                suffix: _eye(
                                  _passwordVisible,
                                  () => setState(() => _passwordVisible =
                                      !_passwordVisible),
                                ),
                                validator: (v) {
                                  final value = v ?? '';
                                  if (value.isEmpty) return 'Enter password';
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              _field(
                                hint: 'Confirm Password',
                                icon: Icons.lock_outline,
                                controller: _confirmPasswordController,
                                obscure: !_confirmPasswordVisible,
                                suffix: _eye(
                                  _confirmPasswordVisible,
                                  () => setState(() =>
                                      _confirmPasswordVisible =
                                          !_confirmPasswordVisible),
                                ),
                                validator: (v) {
                                  final value = v ?? '';
                                  if (value.isEmpty) {
                                    return 'Confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _loading
                                      ? null
                                      : () async => _handleRegister(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    _loading ? 'PLEASE WAIT...' : 'REGISTER',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                        color: Color(0xFF7A5A4A)),
                                  ),
                                  GestureDetector(
                                    onTap: _loading
                                        ? null
                                        : () => Navigator.pushReplacementNamed(
                                              context,
                                              '/login',
                                            ),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        color: accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
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

  Widget _eye(bool open, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        open ? Icons.visibility : Icons.visibility_off,
        color: Colors.brown.shade400,
      ),
      onPressed: _loading ? null : onTap,
    );
  }

  Widget _field({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      inputFormatters: formatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        errorStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ✅ Backend call unchanged, just gate it with Form validation
  Future<void> _handleRegister() async {
    // ✅ This is real form validation
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;

    setState(() => _loading = true);

    try {
      await authService.register(
        name: name,
        email: email,
        phone: phone,
        password: pass,
      );

      if (!mounted) return;
      _snack('Account created. Please login.');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
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
