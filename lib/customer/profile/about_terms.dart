import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';

class AboutTermsPage extends StatelessWidget {
  const AboutTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "About / Terms",
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text("App details and terms go here"),
      ),
    );
  }
}