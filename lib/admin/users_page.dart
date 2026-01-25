import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/widgets/admin_scaffold.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Users",
      showBack: true,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user') // ✅ only customers
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No registered users yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final doc = users[i];
              final data = doc.data() as Map<String, dynamic>;

              final name = (data['name'] ?? 'Unknown').toString();
              final email = (data['email'] ?? '-').toString();
              final phone = (data['phone'] ?? '-').toString();

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
                    child: Text("Email: $email\nPhone: $phone"),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _confirmDelete(context, doc.id, name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ===================================================
  // DELETE CONFIRMATION POPUP
  // ===================================================

  void _confirmDelete(BuildContext context, String userId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete User"),
        content: Text(
          "Are you sure you want to delete \"$name\"?\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .delete();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User deleted successfully")),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
