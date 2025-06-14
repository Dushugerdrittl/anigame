import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';
import '../card_model.dart' as app_card;
import '../widgets/star_display_widget.dart'; // Import StarDisplayWidget

class EventCardsShopScreen extends StatelessWidget {
  const EventCardsShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final List<app_card.Card> eventCards = gameState.diamondShopEventCards; // This will be empty for now

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20.0, // Smaller icon
          padding: const EdgeInsets.all(5.0), // Reduced padding
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),        
        title: const Text('Event Cards'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
         actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Chip(
                avatar: Icon(Icons.diamond_outlined, color: Colors.blue.shade300),
                label: Text('${gameState.playerDiamonds}', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold, fontSize: 16)),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
          ],
                  toolbarHeight: 30, // Set the AppBar height to 30
      ),
      body: eventCards.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "No special event cards available at the moment. Check back soon!",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: eventCards.length,
              itemBuilder: (context, index) {
                final card = eventCards[index];
                // TODO: Define diamond prices for event cards. This could be in CardDefinitions or a separate data structure.
                // For now, let's use a placeholder price.
                final int diamondPrice = 100 + (card.rarity.index * 150); // Example dynamic price

                // TODO: Check if the player already owns this specific event card (if they are unique)
                // or if there's a purchase limit. For now, we assume they can be bought if affordable.

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: SizedBox(
                      width: 60,
                      height: 84,
                      child: Image.asset(
                        'assets/${card.imageUrl}',
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, st) => const Icon(Icons.image_not_supported_outlined, size: 40),
                      ),
                    ),
                    title: Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StarDisplayWidget(ascensionLevel: card.ascensionLevel, rarity: card.rarity, starSize: 14),
                        Text("Rarity: ${card.rarity.toString().split('.').last.replaceAll('_', ' ')}", style: TextStyle(color: _getRarityColor(card.rarity, context))),
                        Text("Type: ${card.type.toString().split('.').last}"),
                        if (card.talent != null) Text("Talent: ${card.talent!.name}", style: const TextStyle(fontStyle: FontStyle.italic)),
                        // Add more stats if needed
                      ],
                    ),
                    trailing: ElevatedButton.icon(
                      icon: Icon(Icons.diamond_outlined, color: Theme.of(context).colorScheme.onPrimary),
                      label: Text("$diamondPrice", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                      onPressed: gameState.playerDiamonds >= diamondPrice
                          ? () {
                              // TODO: Implement purchase logic in GameState for event cards
                              // bool success = gameState.buyEventCard(card, diamondPrice);
                              // For now, just a placeholder:
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Purchase logic for ${card.name} with Diamonds - Coming Soon!"), backgroundColor: Colors.purple),
                              );
                            }
                          : null, // Disable if not enough diamonds
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getRarityColor(app_card.CardRarity rarity, BuildContext context) {
    switch (rarity) {
      case app_card.CardRarity.COMMON: return Colors.grey.shade600;
      case app_card.CardRarity.UNCOMMON: return Colors.green.shade600;
      case app_card.CardRarity.RARE: return Colors.blue.shade600;
      case app_card.CardRarity.SUPER_RARE: return Colors.purple.shade600;
      case app_card.CardRarity.ULTRA_RARE: return Colors.orange.shade700;
    }
  }
}