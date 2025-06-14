import '../card_model.dart'; // For CardRarity

class EnemyDifficultyScaler {
  static Map<String, dynamic> getScaledEnemyAttributes({
    required int floorNumber, // 1-based
    required int levelNumber, // 1-based
    required int maxPossibleLevel, // e.g., 75 for UR
  }) {
    String floorDifficultyTier;
    if (floorNumber <= 10) {
      floorDifficultyTier = "easy";
    } else if (floorNumber <= 20) {
      floorDifficultyTier = "normal";
    } else {
      floorDifficultyTier = "hard";
    }

    String levelDifficultyTier;
    if (levelNumber <= 10) {
      levelDifficultyTier = "easy";
    } else if (levelNumber <= 20) {
      levelDifficultyTier = "normal";
    } else if (levelNumber <= 30) {
      levelDifficultyTier = "little_hard";
    } else {
      levelDifficultyTier = "hard";
    }

    CardRarity enemyRarity = CardRarity.COMMON;
    int enemyLevel = 1;
    int enemyEvo = 0;
    int enemyAsc = 0;

    // Base scaling on level number
    enemyLevel = 1 + (levelNumber ~/ 2).clamp(1, maxPossibleLevel);
    enemyEvo = (levelNumber ~/ 8).clamp(0, 3);

    // Adjust rarity based on level difficulty within the floor
    if (levelDifficultyTier == "normal") enemyRarity = CardRarity.UNCOMMON;
    if (levelDifficultyTier == "little_hard") enemyRarity = CardRarity.RARE;
    if (levelDifficultyTier == "hard") enemyRarity = CardRarity.SUPER_RARE;

    // Further boost based on overall floor difficulty
    if (floorDifficultyTier == "normal") {
      enemyLevel = (enemyLevel * 1.1).round().clamp(1, maxPossibleLevel);
      if (enemyRarity.index < CardRarity.SUPER_RARE.index) {
        enemyRarity = CardRarity.values[enemyRarity.index + 1];
      }
      if (enemyEvo < 3) enemyEvo = (enemyEvo + 1).clamp(0, 3);
    } else if (floorDifficultyTier == "hard") {
      enemyLevel = (enemyLevel * 1.25).round().clamp(1, maxPossibleLevel);
      if (enemyRarity.index < CardRarity.ULTRA_RARE.index) {
        enemyRarity = CardRarity.values[enemyRarity.index + 1];
      }
      enemyEvo = (enemyEvo + 1).clamp(0, 3);
      enemyAsc = (levelNumber ~/ 10).clamp(0, 5); // Max ascension 5 for enemies for now
    }
    
    // Final check to ensure level doesn't exceed max for the determined rarity
    // This requires knowing the max level for each rarity, which is in Card model.
    // For simplicity here, we'll assume maxPossibleLevel (e.g. 75) is a general cap.
    // A more precise cap would involve creating a temporary Card with enemyRarity.
    // For now, the clamp(1, maxPossibleLevel) should suffice for general scaling.

    return {
      'rarity': enemyRarity,
      'level': enemyLevel,
      'evolution': enemyEvo,
      'ascension': enemyAsc,
    };
  }
}
