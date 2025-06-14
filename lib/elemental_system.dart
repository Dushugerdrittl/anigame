enum CardType {
  LIGHT,
  DARK,
  NEUTRAL,
  GROUND,
  WATER,
  ELECTRIC,
  GRASS,
  FIRE,
}

class ElementalSystem {
  static double getTypeEffectivenessMultiplier(CardType attackerType, CardType defenderType) {
    // Neutral has no specific strengths or weaknesses
    if (attackerType == CardType.NEUTRAL || defenderType == CardType.NEUTRAL) {
      return 1.0;
    }

    // Strengths (1.5x damage)
    if ((attackerType == CardType.LIGHT && defenderType == CardType.DARK) ||
        (attackerType == CardType.WATER && defenderType == CardType.GROUND) ||
        (attackerType == CardType.FIRE && defenderType == CardType.GRASS) ||
        (attackerType == CardType.GROUND && defenderType == CardType.ELECTRIC) ||
        (attackerType == CardType.ELECTRIC && defenderType == CardType.WATER) ||
        (attackerType == CardType.GRASS && defenderType == CardType.WATER) ||
        (attackerType == CardType.DARK && defenderType == CardType.LIGHT) 
        ) {
      return 1.5;
    }

    // Weaknesses (0.75x damage)
    if ((attackerType == CardType.LIGHT && defenderType == CardType.GRASS) || // Example weakness
        (attackerType == CardType.WATER && defenderType == CardType.GRASS) ||
        (attackerType == CardType.WATER && defenderType == CardType.ELECTRIC) ||
        (attackerType == CardType.FIRE && defenderType == CardType.WATER) ||
        (attackerType == CardType.FIRE && defenderType == CardType.GROUND) ||
        (attackerType == CardType.GROUND && defenderType == CardType.WATER) ||
        (attackerType == CardType.ELECTRIC && defenderType == CardType.GROUND) ||
        (attackerType == CardType.GRASS && defenderType == CardType.GROUND)
        ) {
      return 0.75;
    }

    return 1.0; // Default if no specific interaction
  }
}