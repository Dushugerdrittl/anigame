import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';
import '../card_model.dart' as app_card;
import '../elemental_system.dart'; // Import CardType
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold
import 'card_detail_screen.dart'; // Import the new screen
// Import FramedCardImageWidget
import '../widgets/star_display_widget.dart'; // Import the StarDisplayWidget

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = "";
  app_card.CardRarity? _selectedRarityFilter;
  CardType? _selectedTypeFilter; // Use CardType directly
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool navigateToRandomBattleAfterSelection = arguments?['navigateToBattle'] ?? false; // For generic battle
    final String? thenSetupFloorId = arguments?['thenSetupFloorId'] as String?;
    final int? thenSetupLevelNumber = arguments?['thenSetupLevelNumber'] as int?;

    List<app_card.Card> filteredCards = gameState.userOwnedCards.where((card) {
      final nameMatches = card.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final rarityMatches = _selectedRarityFilter == null || card.rarity == _selectedRarityFilter;
      final typeMatches = _selectedTypeFilter == null || card.type == _selectedTypeFilter; // Use _selectedTypeFilter directly
      return nameMatches && rarityMatches && typeMatches;
    }).toList();

    return ThemedScaffold( // Use ThemedScaffold
      appBar: AppBar(
        title: const Text('My Card Inventory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20.0, // Slightly smaller icon (default is 24.0)
          padding: const EdgeInsets.all(5.0), // Reduced padding to fit (default is 8.0)
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        toolbarHeight: 30, // Adjust this value to make the AppBar smaller (default is ~56)
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cards by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<app_card.CardRarity?>(
                    decoration: InputDecoration(
                      labelText: 'Rarity',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedRarityFilter,
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Rarities")),
                      ...app_card.CardRarity.values.map((rarity) {
                        return DropdownMenuItem(
                          value: rarity,
                          child: Text(rarity.toString().split('.').last.replaceAll('_', ' ')),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRarityFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<CardType?>( // Use CardType directly
                     decoration: InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedTypeFilter,
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Types")),
                      ...CardType.values.map((type) { // Use CardType directly
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTypeFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredCards.isEmpty
                ? Center(child: Text(_searchQuery.isNotEmpty || _selectedRarityFilter != null || _selectedTypeFilter != null ? "No cards match your criteria." : "You have no cards!"))
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, // Changed to 4
                      childAspectRatio: 0.6, // Adjusted for a more portrait card
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filteredCards.length,
                    itemBuilder: (context, index) {
                      final card = filteredCards[index];
                      bool isSelected = gameState.currentlySelectedPlayerCard?.id == card.id &&
                                        gameState.currentlySelectedPlayerCard == card;
                      return InkWell(
                        onTap: () async { // Make async if performing multiple navigations
                          context.read<GameState>().selectCardForBattle(card);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${card.name} selected!")));

                          if (thenSetupFloorId != null && thenSetupLevelNumber != null) {
                            context.read<GameState>().setupBattleForFloorLevel(thenSetupFloorId, thenSetupLevelNumber);
                            Navigator.pop(context); // Pop inventory
                            Navigator.pushNamed(context, '/battle'); // Then push battle screen
                          } else if (navigateToRandomBattleAfterSelection) {
                            context.read<GameState>().setupNewRandomBattle(); // Setup a random battle
                            Navigator.pop(context, true); // Pop, indicating selection for battle is done
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CardDetailScreen(card: card),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(8), // Consistent with card shape
                        child: Card(
                          elevation: isSelected ? 6.0 : 2.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias, // Important for Stack and rounded corners
                          child: _buildCardDisplaySmall(context, card, isSelected),
                        ),
                      );
                    },
                  ),
          ),
          if (navigateToRandomBattleAfterSelection && thenSetupFloorId == null && gameState.userOwnedCards.isNotEmpty && gameState.currentlySelectedPlayerCard != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: gameState.currentlySelectedPlayerCard != null
                    ? () {
                        context.read<GameState>().setupNewRandomBattle();
                        Navigator.pop(context, true); // Pop with a result
                      } : null,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("Confirm Selection & Start Random Battle"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardDisplaySmall(BuildContext context, app_card.Card card, bool isSelected) {
    final Color rarityColor = _getRarityColor(card.rarity, context);
    return Stack(
      children: [
        // Card Image
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.0), // Match card's inner rounding
            child: Image.asset(
              'assets/${card.imageUrl}',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.image_not_supported_outlined, size: 30, color: Colors.grey),
              ),
            ),
          ),
        ),
        // Gradient overlay for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7.0),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        // Card Name and Level/Evo
        Positioned(
          bottom: 4,
          left: 4,
          right: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Text("Lvl ${card.level}", style: const TextStyle(fontSize: 9, color: Colors.white70, shadows: [Shadow(blurRadius: 1, color: Colors.black38)])),
                  const Text(" • ", style: TextStyle(fontSize: 9, color: Colors.white70)),
                  Text("Evo ${card.evolutionLevel}", style: const TextStyle(fontSize: 9, color: Colors.white70, shadows: [Shadow(blurRadius: 1, color: Colors.black38)])),
                ],
              ),
            ],
          ),
        ),
        // Rarity Banner (Top-Right)
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: rarityColor.withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(7.0),
                bottomLeft: Radius.circular(7.0),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 3, offset: const Offset(1,1))]
            ),
            child: Text(
              card.rarity.toString().split('.').last.substring(0,1), // R, S, U etc.
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        // Star Display (Top-Left or below name)
        Positioned(
          top: 4,
          left: 4,
          child: StarDisplayWidget(
            ascensionLevel: card.ascensionLevel,
            rarity: card.rarity,
            starSize: 8, // Very small stars
          ),
        ),
      ],
    );
  }

  Color _getRarityColor(app_card.CardRarity rarity, BuildContext context) {
    switch (rarity) {
      case app_card.CardRarity.COMMON: return app_card.kCommonColor;
      case app_card.CardRarity.UNCOMMON: return app_card.kUncommonColor;
      case app_card.CardRarity.RARE: return app_card.kRareColor;
      case app_card.CardRarity.SUPER_RARE: return app_card.kSuperRareColor;
      case app_card.CardRarity.ULTRA_RARE: return app_card.kUltraRareColor;
    }
  }

   @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
