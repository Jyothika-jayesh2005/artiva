import 'package:flutter/material.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBack; // ✅ NEW

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBack = false, // default: no back arrow
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // ================= ADMIN HEADER =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF7B2CBF), Color(0xFF5A189A)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT: BACK + TITLE
                  Row(
                    children: [
                      if (showBack)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),

                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // RIGHT: ACTIONS (logout etc.)
                  if (actions != null)
                    IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: Row(children: actions!),
                    ),
                ],
              ),
            ),

            // ================= BODY =================
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
