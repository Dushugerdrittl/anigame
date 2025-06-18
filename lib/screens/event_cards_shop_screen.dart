import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';
import '../card_model.dart' as app_card;
import '../widgets/themed_scaffold.dart';
import '../widgets/framed_card_image_widget.dart';
import '../widgets/star_display_widget.dart';

class EventCardsShopScreen extends StatelessWidget {
  const EventCardsShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final theme = Theme.of(context);
    final Color neonAccentColor =
        Colors.cyanAccent.shade400; // Specific accent for diamond shop
    final Color primaryTextColor = Colors.white.withOpacity(0.9);

    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: primaryTextColor.withOpacity(0.8),
            size: 16.0,
          ),
          padding: const EdgeInsets.all(5.0),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'BUTTERFLY EVENT SHOP', // Thematic title
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
                Icons.diamond_outlined,
                color: Colors.lightBlueAccent.shade200,
                size: 16,
              ),
              label: Text(
                '${gameState.playerDiamonds}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  shadows: [Shadow(blurRadius: 1, color: Colors.black38)],
                ),
              ), // Closing parenthesis for Text's TextStyle
              backgroundColor: Colors.black.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              labelPadding: const EdgeInsets.only(left: 2, right: 3),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
        toolbarHeight: 40,
      ),
      body: _buildEventCardList(
        context,
        gameState,
        neonAccentColor,
        primaryTextColor,
      ),
    );
  }

  Widget _buildEventCardList(
    BuildContext context,
    GameState gameState,
    Color neonAccentColor,
    Color primaryTextColor,
  ) {
    final theme = Theme.of(context);
    final List<app_card.Card> eventCards = gameState.diamondShopEventCards;

    if (eventCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No special event cards available at the moment. Check back soon!",
            style: TextStyle(
              fontSize: 16,
              color: primaryTextColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Sort cards, e.g., by price or name
    // Note: gameState.eventCardPrices is currently a TODO in GameState.
    // This sorting might not be effective until prices are properly defined.
    List<app_card.Card> sortedShopCards = List.from(eventCards)
      ..sort(
        (a, b) =>
            (a.diamondPrice ?? 99999) // Use card.diamondPrice if available
                .compareTo(b.diamondPrice ?? 99999),
      );

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: sortedShopCards.length,
      itemBuilder: (context, index) {
        final card = sortedShopCards[index];
        final price =
            card.diamondPrice ??
            (100 + (card.rarity.index * 150)); // Fallback price
        final bool canAfford = gameState.playerDiamonds >= price;
        // Basic ownership check: assumes event cards might be unique instances based on template ID
        final bool isOwned = gameState.userOwnedCards.any(
          (ownedCard) => ownedCard.originalTemplateId == card.id,
        );
        final cardRarityColor = app_card.getRarityColor(card.rarity);

        return InkWell(
          onTap: canAfford && !isOwned
              ? () {
                  bool success = gameState.buyEventCardWithDiamonds(
                    card,
                    price,
                  );
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Successfully purchased ${card.name}!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Failed to purchase ${card.name}. Not enough diamonds or card unavailable.",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
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
                        rarity: card.rarity,
                        ascensionLevel: card.ascensionLevel,
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
                      if (card.talent != null)
                        Text(
                          "Talent: ${card.talent!.name}",
                          style: TextStyle(
                            color: primaryTextColor.withOpacity(0.8),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.diamond_outlined,
                          color: Colors.lightBlueAccent.shade200,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$price",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlueAccent.shade100,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: canAfford && !isOwned
                          ? () {
                              bool success = gameState.buyEventCardWithDiamonds(
                                card,
                                price,
                              );
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Successfully purchased ${card.name}!",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Failed to purchase ${card.name}. Not enough diamonds or card unavailable.",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonAccentColor.withOpacity(
                          isOwned || !canAfford ? 0.3 : 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(
                        isOwned ? "OWNED" : "BUY",
                        style: TextStyle(
                          color: primaryTextColor.withOpacity(
                            isOwned || !canAfford ? 0.5 : 1.0,
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
}
