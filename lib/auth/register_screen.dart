import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artiva/data/user_data.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  static const Color primary = Color(0xFFE16417);
  static const Color secondary = Color(0xFF80431F);

  @override
  void dispose() {
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primary, secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    const Text(
                      'Artiva',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 40),

                    _buildInputField(
                      hint: 'Full Name',
                      icon: Icons.person,
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                    ),

                    const SizedBox(height: 18),

                    _buildInputField(
                      hint: 'Email',
                      icon: Icons.email,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 18),

                    _buildInputField(
                      hint: 'Phone Number',
                      icon: Icons.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _buildInputField(
                      hint: 'Password',
                      icon: Icons.lock,
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _passwordVisible = !_passwordVisible);
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    _buildInputField(
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                      controller: _confirmPasswordController,
                      obscureText: !_confirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() => _confirmPasswordVisible =
                              !_confirmPasswordVisible);
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ✅ same button style as login (white bg, orange text)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "CREATE ACCOUNT",
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= LOGIC =================

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        pass.isEmpty ||
        confirm.isEmpty) {
      _snack("Please fill all fields");
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      _snack("Enter a valid email address");
      return;
    }

    if (phone.length != 10) {
      _snack("Phone number must be 10 digits");
      return;
    }

    if (pass.length < 6) {
      _snack("Password must be at least 6 characters");
      return;
    }

    if (pass != confirm) {
      _snack("Passwords do not match");
      return;
    }

    final exists = UserData.users.any(
      (u) => (u["email"] ?? "").toString().toLowerCase() == email.toLowerCase(),
    );
    if (exists) {
      _snack("Email already registered. Please login.");
      return;
    }

    UserData.users.add({
      "name": name,
      "email": email,
      "phone": phone,
      "password": pass,
    });

    _snack("Account created. Please login.");

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ================= UI =================

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.25), // ✅ same as login
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
