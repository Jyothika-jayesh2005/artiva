import 'package:flutter/material.dart';
import 'package:artiva/data/user_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;

  // Admin credentials (UI-only)
  final String adminEmail = 'admin@artiva.com';
  final String adminPassword = 'admin123';

  static const Color primary = Color(0xFFE16417);
  static const Color secondary = Color(0xFF80431F);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ✅ FULL GRADIENT BACKGROUND
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primary, secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            // ✅ CENTER CONTENT VERTICALLY
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
                      hint: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
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
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ✅ BUTTON THAT MATCHES THEME
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "LOGIN",
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
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                                context, '/register');
                          },
                          child: const Text(
                            'Register',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              
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

  // ================= LOGIN LOGIC =================
  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _snack('Please enter email and password');
      return;
    }

    // ADMIN LOGIN
    if (email == adminEmail && password == adminPassword) {
      Navigator.pushReplacementNamed(context, '/admin');
      return;
    }

    // CUSTOMER LOGIN
    final user = UserData.users.firstWhere(
      (u) => (u["email"] ?? "").toString().toLowerCase() == email.toLowerCase(),
      orElse: () => {},
    );

    if (user.isEmpty) {
      _snack('No account found. Please register.');
      return;
    }

    if (user["password"] != password) {
      _snack('Incorrect password');
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ================= INPUT FIELD =================
  Widget _buildInputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.25), // ✅ NO WHITE
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
