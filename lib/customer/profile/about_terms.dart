import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

class AboutTermsPage extends StatelessWidget {
  const AboutTermsPage({super.key});

  static const Color accent = Color(0xFFE16417);
  static const Color cardBg = Color(0xFFFFF4EC); // ✅ light orange

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Terms & Conditions",
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HeaderCard(),
          SizedBox(height: 12),

          _Section(
            title: "1. About Artiva",
            body:
                "Artiva is a platform for purchasing artworks and booking exhibitions. "
                "By using this app, you agree to comply with these terms.",
          ),

          _Section(
            title: "2. Order Cancellation & Refunds",
            body:
                "Orders can be cancelled before they are shipped. Once cancelled, refunds are processed within 7 days. "
                "Returns are not accepted after delivery unless the item is damaged.",
          ),

          _Section(
            title: "3. Artwork Representation",
            body:
                "Artwork images are shown as accurately as possible. Minor differences in color or appearance "
                "due to lighting or screen variations are not considered defects.",
          ),

          _Section(
            title: "4. Payments",
            body:
                "Payments are processed through secure third-party providers. Artiva does not store card details. "
                "If an amount is debited but an order fails, contact support with payment proof.",
          ),

          _Section(
            title: "5. User Conduct & Account Action",
            body:
                "Abusive behavior, harassment, scams, or misuse of the platform is strictly prohibited. "
                "Admins may suspend or archive accounts that violate platform rules.",
          ),

          _Section(
            title: "6. Changes to Terms",
            body:
                "Artiva may update these terms when required. Continued use of the app means acceptance of the latest version.",
          ),

          SizedBox(height: 18),
          _FooterNote(),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  static const Color accent = Color(0xFFE16417);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color(0xFFFF8C1A)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Artiva Terms & Conditions",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Simple. Transparent. Binding.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  static const Color accent = Color(0xFFE16417);
  static const Color cardBg = Color(0xFFFFF4EC);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg, // ✅ light orange background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2A2A2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.2,
              height: 1.5,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFFE6D6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        "Using Artiva means you accept these terms without exception.",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6A2F12),
        ),
      ),
    );
  }
}
