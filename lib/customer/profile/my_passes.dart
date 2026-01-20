import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import '../../data/pass_data.dart';
import 'pass_detail_page.dart';

class MyPassesPage extends StatelessWidget {
  const MyPassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomerScaffold(
      currentIndex: -1,
      title: "My Passes",
      body: PassData.myPasses.isEmpty
          ? const Center(child: Text("No passes booked yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: PassData.myPasses.length,
              itemBuilder: (context, index) {
                final pass = PassData.myPasses[index];

                final title = (pass["title"] ?? "-").toString();
                final venue = (pass["venue"] ?? "-").toString();
                final seats = (pass["seats"] ?? 0).toString();

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PassDetailPage(pass: pass),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE16417).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.confirmation_number_outlined,
                            color: Color(0xFFE16417),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                venue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Seats: $seats",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
