import 'package:flutter/material.dart';

class ArtistInfoSheet extends StatelessWidget {
  final Map<String, dynamic> artwork;

  const ArtistInfoSheet({super.key, required this.artwork});

  @override
  Widget build(BuildContext context) {
    // Extract fields
    final String name = (artwork["artistName"] ?? "").toString();
    final String statement = (artwork["artistStatement"] ?? "").toString();

    // Behind the Artwork
    final String inspiration = (artwork["inspiration"] ?? "").toString();
    final String meaning = (artwork["meaning"] ?? "").toString();
    final String process = (artwork["process"] ?? "").toString();
    final String symbolism = (artwork["symbolism"] ?? "").toString();

    // From the Artist
    final String quote = (artwork["artistQuote"] ?? "").toString();
    final String howMade = (artwork["howMadeItNote"] ?? "").toString();
    final String feel = (artwork["viewerFeelNote"] ?? "").toString();

    final hasBehind =
        inspiration.isNotEmpty ||
        meaning.isNotEmpty ||
        process.isNotEmpty ||
        symbolism.isNotEmpty;

    final hasFromArtist =
        quote.isNotEmpty || howMade.isNotEmpty || feel.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                // Header
                Text(
                  "About the Artist",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (quote.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE16417).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE16417).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: Color(0xFFE16417),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quote,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D2D2D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                if (statement.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    "Artist Statement",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statement,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],

                if (hasBehind) ...[
                  const SizedBox(height: 32),
                  const Divider(thickness: 1, height: 1),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.palette_outlined,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Behind the Artwork",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (inspiration.isNotEmpty)
                    _section("Inspiration", inspiration),
                  if (meaning.isNotEmpty) _section("Meaning", meaning),
                  if (process.isNotEmpty) _section("Creative Process", process),
                  if (symbolism.isNotEmpty) _section("Symbolism", symbolism),
                ],

                if (hasFromArtist &&
                    (howMade.isNotEmpty || feel.isNotEmpty)) ...[
                  const SizedBox(height: 32),
                  const Divider(thickness: 1, height: 1),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.purple.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Insights",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (howMade.isNotEmpty) _section("How I Made It", howMade),
                  if (feel.isNotEmpty)
                    _section("What Viewers Should Feel", feel),
                ],
              ],
            ),
          ),

          // Close button bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE16417),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
