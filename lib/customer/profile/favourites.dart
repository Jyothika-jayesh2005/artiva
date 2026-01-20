import 'package:flutter/material.dart';
import 'package:artiva/widgets/customer_scaffold.dart';
import 'package:artiva/widgets/artwork_card.dart';
import 'package:artiva/data/artwork_data.dart';
import 'package:artiva/customer/artwork_detail.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = ArtworkData.favouriteArtworks();

    return CustomerScaffold(
      currentIndex: -1,
      title: "Favourites",
      body: favs.isEmpty
          ? const Center(
              child: Text(
                "No favourites yet",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : Padding(
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
            ),
    );
  }
}
