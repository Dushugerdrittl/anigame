import 'package:flutter/material.dart';
import '../card_model.dart' as app_card; // To access CardRarity and star logic

class StarDisplayWidget extends StatelessWidget {
  final int ascensionLevel;
  final app_card.CardRarity rarity;
  final double starSize;

  const StarDisplayWidget({
    super.key,
    required this.ascensionLevel,
    required this.rarity,
    this.starSize = 16.0, // Default star size
  });

  @override
  Widget build(BuildContext context) {
    // Create a temporary card instance just to use its star logic getters
    // This is a bit of a workaround; ideally, star logic could be static or in a utility.
    final tempCardForLogic = app_card.Card(
        id: 'temp', originalTemplateId: 'temp', name: '', imageUrl: '', // Dummy values
        maxHp: 1, attack: 1, defense: 1, speed: 1, // Dummy values
        rarity: rarity, ascensionLevel: ascensionLevel
    );

    if (tempCardForLogic.maxAscensionLevel == 0) {
      return const SizedBox.shrink(); // No stars for rarities that cannot ascend
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        bool isFilled = index < tempCardForLogic.starsInCurrentTier;
        return Icon(
          isFilled ? Icons.star : Icons.star_border,
          color: isFilled ? tempCardForLogic.currentStarColor : Colors.grey.shade400,
          size: starSize,
        );
      }),
    );
  }
}