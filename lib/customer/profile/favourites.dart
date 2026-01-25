import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:artiva/auth/auth_service.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/widgets/artwork_card.dart';
import 'package:artiva/customer/artwork_detail.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  Stream<List<Map<String, dynamic>>> _watchFavourites() {
    final user = authService.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection("users")
        .doc(user.email)
        .collection("favourites")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) {
        final data = d.data();

        // Ensure id exists (artwork id)
        final id = (data["artworkId"] ?? d.id).toString();

        // IMPORTANT:
        // ArtworkCard expects keys like: id, title, price, imagePath/image, category, etc.
        // We normalize common fields here.
        return {
          ...data,
          "id": id,
          "imagePath": (data["imagePath"] ?? data["image"] ?? "").toString(),
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    // Not logged in
    if (user == null) {
      return CustomerScaffold(
        currentIndex: -1,
        title: "Favourites",
        body: const Center(
          child: Text(
            "Please login to view favourites",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return CustomerScaffold(
      currentIndex: -1,
      title: "Favourites",
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _watchFavourites(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text("Error: ${snap.error}"),
            );
          }

          final favs = snap.data ?? [];

          if (favs.isEmpty) {
            return const Center(
              child: Text(
                "No favourites yet",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              itemCount: favs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 260,
              ),
              itemBuilder: (context, index) {
                final art = favs[index];

                // If ArtworkCard / Details needs strings, convert safely where needed
                return ArtworkCard(
                  artwork: art,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtworkDetailsPage(artwork: art),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
