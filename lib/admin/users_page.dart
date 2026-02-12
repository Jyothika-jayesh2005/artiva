import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artiva/widgets/admin_scaffold.dart';

enum UserFilter { all, active, archived }

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: "Users",
      showBack: true,
      body: const UsersListBody(filter: UserFilter.all),
    );
  }
}

/// ===================================================
/// REUSABLE BODY FOR DASHBOARD (NO AdminScaffold)
/// ARCHIVE / UNARCHIVE (NO DELETE)
/// ===================================================
class UsersListBody extends StatelessWidget {
  final UserFilter filter;

  const UsersListBody({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user');

    if (filter == UserFilter.active) {
      query = query.where('archived', isEqualTo: false);
    } else if (filter == UserFilter.archived) {
      query = query.where('archived', isEqualTo: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final email = (data['email'] ?? '').toString().toLowerCase();
          return email != 'admin@artiva.com';
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, i) {
            final doc = users[i];
            final data = doc.data() as Map<String, dynamic>;

            final name = (data['name'] ?? 'Unknown').toString();
            final email = (data['email'] ?? '-').toString();
            final phone = (data['phone'] ?? '-').toString();
            final bool archived = (data['archived'] == true);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: const Color(0xFFFFF3E8), // 🔥 same light orange as filters
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: const Color(0xFFFF8C1A).withOpacity(0.25),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8C1A), // ← ADD THIS
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(archived: archived),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text("Email: $email\nPhone: $phone"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool archived;
  const _StatusChip({required this.archived});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: archived
            ? Colors.red.withOpacity(0.10)
            : Colors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: archived
              ? Colors.red.withOpacity(0.35)
              : Colors.green.withOpacity(0.35),
        ),
      ),
      child: Text(
        archived ? "Archived" : "Active",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: archived ? Colors.red : Colors.green,
        ),
      ),
    );
  }
}
