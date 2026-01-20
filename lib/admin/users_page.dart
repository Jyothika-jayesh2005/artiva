import 'package:flutter/material.dart';
import 'package:artiva/widgets/admin_scaffold.dart';
import 'package:artiva/data/user_data.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final users = UserData.users;

    return AdminScaffold(
      title: "Users",
      showBack: true,
      body: users.isEmpty
          ? const Center(
              child: Text(
                "No registered users yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];

                final name = (u["name"] ?? "Unknown").toString();
                final email = (u["email"] ?? "-").toString();
                final phone = (u["phone"] ?? "-").toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "?",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "Email: $email\nPhone: $phone",
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
