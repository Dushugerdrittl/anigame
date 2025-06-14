import 'dart:math';
import '../card_model.dart'; // For CardRarity

class LevelingCostUtil {
  static const int BASE_GOLD_COST = 150;
  static const int BASE_SHARD_COST = 50;
  static const double COST_INCREASE_FACTOR_PER_LEVEL = 1.015; // 1.5% increase

  static int calculateGoldCost(int currentCardLevel) {
    if (currentCardLevel <= 0) return BASE_GOLD_COST; // Should not happen for level 1+
    // Cost to go from currentCardLevel to currentCardLevel + 1
    return (BASE_GOLD_COST * pow(COST_INCREASE_FACTOR_PER_LEVEL, currentCardLevel - 1)).round();
  }

  static int calculateShardCost(int currentCardLevel) {
    if (currentCardLevel <= 0) return BASE_SHARD_COST;
    // Cost to go from currentCardLevel to currentCardLevel + 1
    return (BASE_SHARD_COST * pow(COST_INCREASE_FACTOR_PER_LEVEL, currentCardLevel - 1)).round();
  }


// Example usage:
// To level up from Lvl 1 to Lvl 2 (currentLevel = 1):
// Gold: calculateGoldCost(1) = (150 * 1.015^0) = 150
// Shards: calculateShardCost(1) = (50 * 1.015^0) = 50
// To level up from Lvl 2 to Lvl 3 (currentLevel = 2):
// Gold: calculateGoldCost(2) = (150 * 1.015^1) = 152 (rounded)
// Shards: calculateShardCost(2) = (50 * 1.015^1) = 51 (rounded)

  // Helper to get stat boosts for a single level up, used by Reversion's stat recalculation
  static Map<String, int> getStatBoostsForLevelUp(CardRarity rarity) {
    int hpBoost = 0, atkBoost = 0, defBoost = 0, spdBoost = 0;
    switch (rarity) {
      case CardRarity.COMMON:
        hpBoost = 5; atkBoost = 1; defBoost = 1; spdBoost = 1; break;
      case CardRarity.UNCOMMON:
        hpBoost = 7; atkBoost = 2; defBoost = 1; spdBoost = 1; break;
      case CardRarity.RARE:
        hpBoost = 10; atkBoost = 2; defBoost = 2; spdBoost = 2; break;
      case CardRarity.SUPER_RARE:
        hpBoost = 12; atkBoost = 3; defBoost = 2; spdBoost = 2; break;
      case CardRarity.ULTRA_RARE:
        hpBoost = 15; atkBoost = 3; defBoost = 3; spdBoost = 3; break;
    }
    return {'hp': hpBoost, 'attack': atkBoost, 'defense': defBoost, 'speed': spdBoost};
  }
}