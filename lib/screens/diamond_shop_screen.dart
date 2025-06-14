import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';
// import '../card_model.dart' as app_card; // If displaying cards
import 'event_cards_shop_screen.dart'; // Import the new screen

class DiamondShopScreen extends StatelessWidget {
  const DiamondShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    // final List<app_card.Card> eventCards = gameState.diamondShopEventCards;
    // final List<String> cardSkins = gameState.diamondShopCardSkins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diamond Shop'),
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.event_available_outlined, size: 30),
            title: const Text("Event Cards"),
            subtitle: const Text("Limited time special cards!"),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EventCardsShopScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.style_outlined, size: 30),
            title: const Text("Card Skins"),
            subtitle: const Text("Customize your favorite cards!"),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () {
              // TODO: Navigate to Card Skins screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Card Skins - Coming Soon!"), backgroundColor: Colors.blueAccent),
              );
            },
          ),
        ],
      ),
    );
  }
}
