import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "Help & Support",
      body: const Center(child: Text("FAQ and contact info")),
    );
  }
}
