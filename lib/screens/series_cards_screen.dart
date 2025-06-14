import 'package:flutter/material.dart';
import '../card_model.dart' as app_card;
import 'pedia_card_detail_screen.dart'; // Import the PediaCardDetailScreen

class SeriesCardsScreen extends StatelessWidget {
  final String seriesName;
  final List<app_card.Card> cards;

  const SeriesCardsScreen({super.key, required this.seriesName, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(seriesName),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: cards.isEmpty
          ? const Center(child: Text("No cards found for this series."))
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // Display 5 cards per row
                childAspectRatio: 0.45, // Adjusted for more details
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return InkWell(
                  onTap: () {
                    // This is the correct way to navigate and instantiate PediaCardDetailScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PediaCardDetailScreen(card: card),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildPediaCardDisplay(context, card),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPediaCardDisplay(BuildContext context, app_card.Card card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            card.name,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Text("Lvl: ${card.level}", style: TextStyle(fontSize: 8, color: Theme.of(context).colorScheme.secondary)),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
            child: Image.asset(
              'assets/${card.imageUrl}',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, size: 18, color: Colors.grey),
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("HP: ${card.maxHp}", style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 1.0,
            runSpacing: 0.0,
            children: [
              Text("A:${card.attack}", style: const TextStyle(fontSize: 7)),
              const Text(" • ", style: TextStyle(fontSize: 7)),
              Text("D:${card.defense}", style: const TextStyle(fontSize: 7)),
              const Text(" • ", style: TextStyle(fontSize: 7)),
              Text("S:${card.speed}", style: const TextStyle(fontSize: 7)),
            ],
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(card.type.toString().split('.').last, style: const TextStyle(fontSize: 7, fontStyle: FontStyle.italic, color: Colors.black54))),
        if (card.talent != null) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.talent!.name,
              style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
              textAlign: TextAlign.center,
            ),
          ),
          if (card.talent!.manaCost > 0)
            FittedBox(fit: BoxFit.scaleDown, child: Text("Cost: ${card.talent!.manaCost}", style: TextStyle(fontSize: 6, color: Colors.blue.shade700))),
        ],
      ],
    );
  }
}
