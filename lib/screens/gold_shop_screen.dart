import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';
import '../card_model.dart' as app_card;
import '../data/card_definitions.dart';
import '../elemental_system.dart'; // Import CardType
import '../talent_system.dart'; // Import TalentType
import '../data/card_supply_data.dart';
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold
import '../widgets/star_display_widget.dart';

class GoldShopScreen extends StatefulWidget {
  const GoldShopScreen({super.key});

  @override
  State<GoldShopScreen> createState() => _GoldShopScreenState();
}

class _GoldShopScreenState extends State<GoldShopScreen> {
  String _searchQuery = "";
  TalentType? _selectedTalentFilter;
  CardType? _selectedTypeFilter;
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

    return DefaultTabController(
      length: 4, // Rare, Super Rare, Ultra Rare, Shards
      child: ThemedScaffold( // Use ThemedScaffold
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
          title: const Text('Gold Shop'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Chip(
                avatar: Icon(Icons.attach_money_outlined, color: Colors.amber.shade700),
                label: Text('${gameState.playerCurrency}', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold, fontSize: 16)),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
          ],
          toolbarHeight: 30, // Set the AppBar height to 30
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rare'),
              Tab(text: 'Super Rare'),
              Tab(text: 'Ultra Rare'),
              Tab(text: 'Shards'),
            ],
          ),
        ),
        body: Column( // Added Column to hold search/filter and TabBarView
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
                    child: DropdownButtonFormField<TalentType?>(
                      decoration: InputDecoration(
                        labelText: 'Talent',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _selectedTalentFilter,
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Talents")),
                        ...TalentType.values.map((talent) {
                          return DropdownMenuItem(
                            value: talent,
                            child: Text(talent.toString().split('.').last.replaceAll('_', ' ')),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTalentFilter = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<CardType?>(
                       decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: _selectedTypeFilter,
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Types")),
                        ...CardType.values.map((type) {
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
            Expanded( // TabBarView needs to be in an Expanded widget
              child: TabBarView(
                children: [
                  _buildCardList(context, gameState, gameState.goldShopRareCards, "No Rare cards available matching criteria."),
                  _buildCardList(context, gameState, gameState.goldShopSuperRareCards, "No Super Rare cards available matching criteria."),
                  _buildCardList(context, gameState, gameState.goldShopUltraRareCards, "No Ultra Rare cards available matching criteria."),
                  _buildShardList(context, gameState), // Shards tab is not filtered
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(BuildContext context, GameState gameState, List<app_card.Card> allCardsForThisRarity, String emptyMessage) {
    
    List<app_card.Card> filteredCards = allCardsForThisRarity.where((card) {
      final nameMatches = card.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final talentMatches = _selectedTalentFilter == null || card.talent?.type == _selectedTalentFilter;
      final typeMatches = _selectedTypeFilter == null || card.type == _selectedTypeFilter;
      return nameMatches && talentMatches && typeMatches;
    }).toList();
    
    if (filteredCards.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: filteredCards.length,
      itemBuilder: (context, index) {
        final card = filteredCards[index]; // Use the card from the filtered list
        String baseTemplateId = card.originalTemplateId;
        
        final templateIndex = CardDefinitions.availableCards.indexWhere((def) => def.id == baseTemplateId);
        if (templateIndex == -1) {
          return Card(child: ListTile(title: Text("Error: Def not found for ${card.name} (ID: $baseTemplateId)")));
        }
        final cardTemplate = CardDefinitions.availableCards[templateIndex];
        final price = gameState.getMarketPriceForCardTemplate(cardTemplate, card.rarity);

        final maxSupplyForRarity = CardSupplyData.cardMaxSupply[baseTemplateId]?[card.rarity] ?? 0;
        final mintedCountForRarity = gameState.mintedCardCounts[baseTemplateId]?[card.rarity] ?? 0;
        final remainingSupply = maxSupplyForRarity - mintedCountForRarity;
        final bool isSoldOut = remainingSupply <= 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: ListTile(
            leading: SizedBox(
              width: 50,
              height: 70,
              child: Image.asset(
                'assets/${card.imageUrl}',
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => const Icon(Icons.image_not_supported_outlined),
              ),
            ),
            title: Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StarDisplayWidget(
                  ascensionLevel: card.ascensionLevel,
                  rarity: card.rarity,
                  starSize: 14,
                ),
                Text("Rarity: ${card.rarity.toString().split('.').last.replaceAll('_', ' ')}", style: TextStyle(color: _getRarityColor(card.rarity, context))),
                Text("Type: ${card.type.toString().split('.').last}"),
                Text("Talent: ${card.talent?.name ?? 'None'}"),
                if (!isSoldOut)
                  Text("Available: $remainingSupply / $maxSupplyForRarity", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                if (isSoldOut)
                  const Text("Sold Out!", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart_checkout_outlined),
              label: Text("$price"),
              onPressed: gameState.playerCurrency >= price && !isSoldOut
                  ? () {
                      bool success = gameState.buyCardFromMarket(baseTemplateId, card.rarity, price);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Successfully purchased ${card.rarity.toString().split('.').last} ${card.name}!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to purchase ${card.name}. Not enough currency or supply exhausted."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        );
      },
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

  Widget _buildShardList(BuildContext context, GameState gameState) {
    final shardPrices = gameState.goldShopShardPrices;
    if (shardPrices.isEmpty) {
      return const Center(child: Text("No shards available for purchase."));
    }

    final List<MapEntry<app_card.ShardType, int>> sortedShards = shardPrices.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // Sort by price or name if preferred

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedShards.length,
      itemBuilder: (context, index) {
        final shardEntry = sortedShards[index];
        final shardType = shardEntry.key;
        final pricePerShard = shardEntry.value;
        final shardName = shardType.toString().split('.').last.replaceAll('_', ' ');

        // Simple quantity selection (e.g., buy 1 or 10)
        // For more complex quantity, a text field or +/- buttons would be needed.
        final int quantityToBuy = 10; // Example: offer to buy in bundles of 10
        final int totalPrice = pricePerShard * quantityToBuy;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: ListTile(
            leading: Icon(_getShardIcon(shardType), size: 30, color: _getShardColor(shardType)),
            title: Text(shardName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Price: $pricePerShard gold / shard"),
                Text("Your Shards: ${gameState.playerShards[shardType] ?? 0}"),
              ],
            ),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: Text("Buy $quantityToBuy ($totalPrice G)"),
              onPressed: gameState.playerCurrency >= totalPrice
                  ? () {
                      bool success = gameState.buyShardsFromGoldShop(shardType, quantityToBuy, totalPrice);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Successfully purchased $quantityToBuy $shardName!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to purchase $shardName. Not enough gold."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getShardIcon(app_card.ShardType shardType) {
    // Basic icon mapping, can be expanded
    switch (shardType) {
      case app_card.ShardType.FIRE_SHARD: return Icons.whatshot;
      case app_card.ShardType.WATER_SHARD: return Icons.water_drop;
      case app_card.ShardType.GRASS_SHARD: return Icons.eco;
      // RARE_SHARD, EPIC_SHARD, LEGENDARY_SHARD cases removed
      default: return Icons.grain; // Generic shard icon
    }
  }

   Color _getShardColor(app_card.ShardType shardType) {
    // Basic color mapping
    switch (shardType) {
      case app_card.ShardType.FIRE_SHARD: return Colors.red.shade700;
      case app_card.ShardType.WATER_SHARD: return Colors.blue.shade700;
      case app_card.ShardType.GRASS_SHARD: return Colors.green.shade700;
      // RARE_SHARD, EPIC_SHARD, LEGENDARY_SHARD cases removed
      default: return Colors.grey.shade600;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
