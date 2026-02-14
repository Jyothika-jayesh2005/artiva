import 'package:flutter/material.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? floatingActionButton;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBack = false,
    this.floatingActionButton,
  });

  static const Color primary = Color(0xFFFF8C1A);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color text = Colors.black87;
  static const Color subText = Colors.black54;
  static const Color border = Color(0xFFEEEEEE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg, // Soft light background
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          // Gradient Header extending behind Status Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF9F1C), Color(0xFFFF7A18)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33FF8C1A),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                if (showBack)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.maybePop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 24,
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700, // Strong/Bold
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
