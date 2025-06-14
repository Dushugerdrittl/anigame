import '../card_model.dart'; // For CardRarity and Card (template)

class RarityStatsUtil {
  static Map<String, int> calculateStatsForRarity({
    required int baseHp,
    required int baseAttack,
    required int baseDefense,
    required int baseSpeed,
    required CardRarity rarity,
  }) {
    double multiplier = 1.0;

    switch (rarity) {
      case CardRarity.COMMON:
        multiplier = 1.0; // Base
        break;
      case CardRarity.UNCOMMON:
        multiplier = 1.15; // +15%
        break;
      case CardRarity.RARE:
        multiplier = 1.25; // +25%
        break;
      case CardRarity.SUPER_RARE:
        multiplier = 1.45; // +45%
        break;
      case CardRarity.ULTRA_RARE:
        multiplier = 1.65; // +65%
        break;
    }

    return {
      'hp': (baseHp * multiplier).round(),
      'attack': (baseAttack * multiplier).round(),
      'defense': (baseDefense * multiplier).round(),
      'speed': (baseSpeed * multiplier).round(),
    };
  }
}
