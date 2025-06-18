import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';
import '../card_model.dart' as app_card;
import '../data/card_definitions.dart';
import '../elemental_system.dart'; // Import CardType
import '../talent_system.dart'; // Import TalentType
import '../data/card_supply_data.dart';
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold
import '../widgets/framed_card_image_widget.dart'; // Import FramedCardImageWidget
import '../widgets/star_display_widget.dart';
import '../utils/shard_display_utils.dart'
    as shard_utils; // For shard icons and colors

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
    final theme = Theme.of(context);
    final Color neonAccentColor = theme.colorScheme.secondary;
    final Color primaryTextColor = Colors.white.withOpacity(0.9);

    return DefaultTabController(
      length: 4, // Rare, Super Rare, Ultra Rare, Shards
      child: ThemedScaffold(
        // Use ThemedScaffold
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: primaryTextColor.withOpacity(0.8),
              size: 16.0,
            ),
            padding: const EdgeInsets.all(5.0), // Reduced padding
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            'GOLD EMPORIUM', // Thematic title
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: primaryTextColor,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                avatar: Icon(
                  Icons.monetization_on_outlined,
                  color: Colors.amber.shade700,
                  size: 16,
                ),
                label: Text(
                  '${gameState.playerCurrency}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [Shadow(blurRadius: 1, color: Colors.black38)],
                  ),
                ),
                backgroundColor: Colors.black.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                labelPadding: const EdgeInsets.only(left: 2, right: 3),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
          toolbarHeight: 40, // Adjusted height
          bottom: TabBar(
            // Removed const
            indicatorColor: neonAccentColor,
            labelColor: neonAccentColor,
            unselectedLabelColor: primaryTextColor.withOpacity(0.7),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: [
              Tab(text: 'Rare'),
              Tab(text: 'Super Rare'),
              Tab(text: 'Ultra Rare'),
              Tab(text: 'Shards'),
            ],
          ),
        ),
        body: Column(
          // Added Column to hold search/filter and TabBarView
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
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
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                  hintStyle: TextStyle(
                    color: primaryTextColor.withOpacity(0.5),
                  ),
                  prefixIconColor: primaryTextColor.withOpacity(0.6),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TalentType?>(
                      isExpanded: true, // Add this
                      dropdownColor: Colors.grey[850],
                      decoration: InputDecoration(
                        labelText: 'Talent',
                        labelStyle: TextStyle(
                          color: primaryTextColor.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: neonAccentColor.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: neonAccentColor.withOpacity(0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      value: _selectedTalentFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Talents"),
                        ),
                        ...TalentType.values.map((talent) {
                          return DropdownMenuItem(
                            value: talent,
                            child: Text(
                              talent
                                  .toString()
                                  .split('.')
                                  .last
                                  .replaceAll('_', ' '),
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 13,
                              ),
                            ),
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
                      isExpanded: true, // Add this
                      dropdownColor: Colors.grey[850],
                      decoration: InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(
                          color: primaryTextColor.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: neonAccentColor.withOpacity(0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: neonAccentColor.withOpacity(0.3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      value: _selectedTypeFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Types"),
                        ),
                        ...CardType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.toString().split('.').last,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 13,
                              ),
                            ),
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
              // TabBarView needs to be in an Expanded widget
              child: TabBarView(
                children: [
                  _buildCardList(
                    context,
                    gameState,
                    gameState.goldShopRareCards,
                    "No Rare cards available matching criteria.",
                    neonAccentColor,
                    primaryTextColor,
                  ),
                  _buildCardList(
                    context,
                    gameState,
                    gameState.goldShopSuperRareCards,
                    "No Super Rare cards available matching criteria.",
                    neonAccentColor,
                    primaryTextColor,
                  ),
                  _buildCardList(
                    context,
                    gameState,
                    gameState.goldShopUltraRareCards,
                    "No Ultra Rare cards available matching criteria.",
                    neonAccentColor,
                    primaryTextColor,
                  ),
                  _buildShardList(
                    context,
                    gameState,
                    neonAccentColor,
                    primaryTextColor,
                  ), // Shards tab is not filtered
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(
    BuildContext context,
    GameState gameState,
    List<app_card.Card> allCardsForThisRarity,
    String emptyMessage,
    Color neonAccentColor,
    Color primaryTextColor,
  ) {
    List<app_card.Card> filteredCards = allCardsForThisRarity.where((card) {
      final nameMatches = card.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final talentMatches =
          _selectedTalentFilter == null ||
          card.talent?.type == _selectedTalentFilter;
      final typeMatches =
          _selectedTypeFilter == null || card.type == _selectedTypeFilter;
      return nameMatches && talentMatches && typeMatches;
    }).toList();

    if (filteredCards.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: primaryTextColor.withOpacity(0.7)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: filteredCards.length,
      itemBuilder: (context, index) {
        final card =
            filteredCards[index]; // Use the card from the filtered list
        String baseTemplateId = card.originalTemplateId;

        final templateIndex = CardDefinitions.availableCards.indexWhere(
          (def) => def.id == baseTemplateId,
        );
        if (templateIndex == -1) {
          return Center(
            child: Text(
              "Error: Definition not found for ${card.name}",
              style: TextStyle(color: Colors.red.shade300),
            ),
          );
        }
        final cardTemplate = CardDefinitions.availableCards[templateIndex];
        final price = gameState.getMarketPriceForCardTemplate(
          cardTemplate,
          card.rarity,
        );

        final maxSupplyForRarity =
            CardSupplyData.cardMaxSupply[baseTemplateId]?[card.rarity] ?? 0;
        final mintedCountForRarity =
            gameState.mintedCardCounts[baseTemplateId]?[card.rarity] ?? 0;
        final remainingSupply = maxSupplyForRarity - mintedCountForRarity;
        final bool isSoldOut = remainingSupply <= 0;

        final cardRarityColor = app_card.getRarityColor(card.rarity);

        return InkWell(
          onTap: gameState.playerCurrency >= price && !isSoldOut
              ? () {
                  bool success = gameState.buyCardFromMarket(
                    baseTemplateId,
                    card.rarity,
                    price,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "Purchased ${card.rarity.toString().split('.').last} ${card.name}!"
                            : "Failed to purchase ${card.name}. Not enough gold or supply exhausted.",
                      ),
                      backgroundColor: success
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: cardRarityColor.withOpacity(0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: cardRarityColor.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 90,
                  child: FramedCardImageWidget(
                    card: card,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          fontSize: 15,
                        ),
                      ),
                      StarDisplayWidget(
                        ascensionLevel: card.ascensionLevel,
                        rarity: card.rarity,
                        starSize: 13,
                      ),
                      Text(
                        "Rarity: ${card.rarity.toString().split('.').last.replaceAll('_', ' ')}",
                        style: TextStyle(color: cardRarityColor, fontSize: 12),
                      ),
                      Text(
                        "Type: ${card.type.toString().split('.').last}",
                        style: TextStyle(
                          color: primaryTextColor.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "Talent: ${card.talent?.name ?? 'None'}",
                        style: TextStyle(
                          color: primaryTextColor.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!isSoldOut)
                        Text(
                          "Available: $remainingSupply / $maxSupplyForRarity",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade200,
                          ),
                        ),
                      if (isSoldOut)
                        Text(
                          "Sold Out!",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$price G",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: gameState.playerCurrency >= price && !isSoldOut
                          ? () {
                              bool success = gameState.buyCardFromMarket(
                                baseTemplateId,
                                card.rarity,
                                price,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? "Purchased ${card.rarity.toString().split('.').last} ${card.name}!"
                                        : "Failed to purchase ${card.name}. Not enough gold or supply exhausted.",
                                  ),
                                  backgroundColor: success
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonAccentColor.withOpacity(
                          isSoldOut || gameState.playerCurrency < price
                              ? 0.3
                              : 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(
                        isSoldOut ? "SOLD OUT" : "BUY",
                        style: TextStyle(
                          color: primaryTextColor.withOpacity(
                            isSoldOut || gameState.playerCurrency < price
                                ? 0.5
                                : 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShardList(
    BuildContext context,
    GameState gameState,
    Color neonAccentColor,
    Color primaryTextColor,
  ) {
    final shardPrices = gameState.goldShopShardPrices;
    if (shardPrices.isEmpty) {
      return Center(
        child: Text(
          "No shards available for purchase.",
          style: TextStyle(color: primaryTextColor.withOpacity(0.7)),
        ),
      );
    }

    final List<MapEntry<app_card.ShardType, int>> sortedShards =
        shardPrices.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: sortedShards.length,
      itemBuilder: (context, index) {
        final shardEntry = sortedShards[index];
        final shardType = shardEntry.key;
        final pricePerShard = shardEntry.value;
        final shardName = shardType
            .toString()
            .split('.')
            .last
            .replaceAll('_', ' ');
        final shardIcon = shard_utils.getShardIcon(shardType);
        final shardColor = shard_utils.getShardColor(shardType);

        final int quantityToBuy = 10;
        final int totalPrice = pricePerShard * quantityToBuy;

        return InkWell(
          onTap: gameState.playerCurrency >= totalPrice
              ? () {
                  bool success = gameState.buyShardsFromGoldShop(
                    shardType,
                    quantityToBuy,
                    totalPrice,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? "Purchased $quantityToBuy $shardName!"
                            : "Failed to purchase $shardName. Not enough gold.",
                      ),
                      backgroundColor: success
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: shardColor.withOpacity(0.7),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(shardIcon, size: 30, color: shardColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shardName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "Price: $pricePerShard G / shard",
                        style: TextStyle(
                          color: primaryTextColor.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "Owned: ${gameState.playerShards[shardType] ?? 0}",
                        style: TextStyle(
                          color: primaryTextColor.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: gameState.playerCurrency >= totalPrice
                      ? () {
                          bool success = gameState.buyShardsFromGoldShop(
                            shardType,
                            quantityToBuy,
                            totalPrice,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? "Purchased $quantityToBuy $shardName!"
                                    : "Failed to purchase $shardName. Not enough gold.",
                              ),
                              backgroundColor: success
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: neonAccentColor.withOpacity(
                      gameState.playerCurrency < totalPrice ? 0.3 : 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: Text(
                    "BUY $quantityToBuy ($totalPrice G)",
                    style: TextStyle(
                      color: primaryTextColor.withOpacity(
                        gameState.playerCurrency < totalPrice ? 0.5 : 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
