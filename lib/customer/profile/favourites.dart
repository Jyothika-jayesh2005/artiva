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
    if (user == null) return const Stream.empty();

    // 1️⃣ Listen to the favourites subcollection
    return FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("favourites")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .asyncMap((snap) async {
          final List<Map<String, dynamic>> results = [];

          for (var d in snap.docs) {
            final favData = d.data();
            final artId = (favData["artworkId"] ?? d.id).toString();

            // 2️⃣ Fetch the full artwork doc for each favourite
            final artDoc = await FirebaseFirestore.instance
                .collection("artworks")
                .doc(artId)
                .get();

            if (artDoc.exists) {
              final artData = artDoc.data()!;
              
              // 3️⃣ Normalize image fields
              final imageAny = (artData["imageUrl"] ??
                      artData["image"] ??
                      artData["imagePath"] ??
                      "")
                  .toString();

              results.add({
                ...artData,
                "id": artId,
                "imageUrl": imageAny.startsWith("http") ? imageAny : "",
                "imagePath": imageAny.startsWith("http") ? "" : imageAny,
                "favCreatedAt": favData["createdAt"], // Keep the fav timestamp
              });
            }
          }
          return results;
        });
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

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
            return Center(child: Text("Error: ${snap.error}"));
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
