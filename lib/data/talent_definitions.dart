import '../talent_system.dart';

class TalentDefinitions {
  static final Map<TalentType, Talent> allTalents = {
    TalentType.BERSERKER: const Talent(
      name: "Berserker",
      description: "While your health is low (45% Max HP), increase the ATK/DEF of all allied familiars by 30%.",
      type: TalentType.BERSERKER,
      value: 0.3,
      manaCost: 0,
    ),
    TalentType.REGENERATION: const Talent(
      name: "Regeneration", // Active Buff
      description: "Heal for a small amount (scales with rarity) every turn for 3 turns.",
      type: TalentType.REGENERATION,
      value: 0.05, // Base 5% Max HP heal per turn
      secondaryValue: 3, // Duration in turns
      manaCost: 20, // Example mana cost
    ),
    TalentType.REJUVENATION: const Talent(
      name: "Rejuvenation", // Active
      description: "Restores 15% Max HP. Increases healing effects received by 25% (total bonus capped at 50%).",
      type: TalentType.REJUVENATION,
      value: 0.15, // Heal percentage
      secondaryValue: 0.25, // Healing effectiveness increase
      manaCost: 25, // Example mana cost
    ),
    TalentType.PRECISION: const Talent(
      name: "Precision", // Active
      description: "Increase CRIT Chance by 18% and CRIT DMG by 30% for 3 turns.",
      type: TalentType.PRECISION,
      value: 0.18, // CRIT chance increase
      secondaryValue: 0.30, // CRIT DMG increase
      // Duration (e.g., 3 turns) will be handled in TalentSystem logic
      manaCost: 20,
    ),
    TalentType.BLAZE: const Talent(
      name: "Blaze",
      description: "Inflict Burn (stacks). Deals 10% True DMG/turn (40% chance to resist/turn). Reduces healing by 75%.",
      type: TalentType.BLAZE,
      value: 0.10, // Burn damage
      secondaryValue: 0.75, // Healing reduction
      manaCost: 25,
    ),
    TalentType.PROTECTOR: const Talent(
      name: "Protector",
      description: "When your health drops below 25%, restore the HP of all allied familiars by 20% and raise their DEF by 35%.",
      type: TalentType.PROTECTOR,
      value: 0.20, // Heal value
      secondaryValue: 0.35, // DEF buff
      manaCost: 0,
    ),
    TalentType.EXECUTIONER: const Talent(
      name: "Executioner",
      description: "When the enemy's health is below 37%, increase your ATK by 50% (SR) or 60% (UR).",
      type: TalentType.EXECUTIONER,
      value: 0.50, // SR ATK buff
      secondaryValue: 0.60, // UR ATK buff
      manaCost: 0,
    ),
    TalentType.OVERLOAD: const Talent(
      name: "Overload",
      description: "When the battle starts, increase ATK by 80% (SR) or 90% (UR). Your ATK decreases by 10% of original ATK each turn after that.",
      type: TalentType.OVERLOAD,
      value: 0.80, // SR initial ATK buff
      secondaryValue: 0.90, // UR initial ATK buff (Decay is handled in logic as 10%)
      manaCost: 0,
    ),
    TalentType.TIME_BOMB: const Talent(
      name: "Time Bomb",
      description: "Inflict a stack of Time Bomb to enemy familiars, dealing 30% of your ATK as True damage after 1 turn.",
      type: TalentType.TIME_BOMB,
      value: 0.30,
      manaCost: 35,
    ),
    TalentType.ENDURANCE: const Talent(
      name: "Endurance",
      description: "Take 70% less damage from normal attacks for 3 turns.",
      type: TalentType.ENDURANCE,
      value: 0.70, // Damage reduction percentage
      secondaryValue: 3, // Duration in turns
      manaCost: 25, // Example mana cost
    ),
    TalentType.EVASION: const Talent(
      name: "Evasion",
      description: "Increase EVASION by 12% (stacks up to 9 times, lasts 9 turns).",
      type: TalentType.EVASION,
      value: 0.12, // 12% evasion increase per stack
      secondaryValue: 9, // Max turns / stacks
      manaCost: 15, // Example mana cost
    ),
    TalentType.BLOODTHIRSTER: const Talent(
      name: "Bloodthirster", // Passive
      description: "Restores HP equal to 18% of normal attack damage dealt. Increases all healing effects received by 15%.",
      type: TalentType.BLOODTHIRSTER, 
      value: 0.18, 
      secondaryValue: 0.15, 
      manaCost: 0,
    ),
    TalentType.PARALYSIS: const Talent( // Nami's talent
      name: "Paralysis",
      description: "40% chance to Stun enemy (miss next turn) & permanently decrease their DEF by 10%.",
      type: TalentType.PARALYSIS,
      value: 0.40, // Stun chance
      secondaryValue: 0.10, // Permanent DEF decrease
      manaCost: 25,
    ),
    TalentType.OFFENSIVE_STANCE: const Talent(
      name: "Offensive Stance", // Active
      description: "Increase ATK by 40% and decrease DEF by 10% for 3 turns.",
      type: TalentType.OFFENSIVE_STANCE,
      value: 0.40, // ATK increase percentage
      secondaryValue: 0.10, // DEF decrease percentage
      // Duration (e.g., 3 turns) will be handled in TalentSystem logic
      manaCost: 15,
    ),
    TalentType.REVERSION: const Talent(
      name: "Reversion",
      description: "Once HP drops below 30%, revert stats/HP of all familiars to base (for current rarity/level). Allies then gain +12% DEF/SPD.",
      type: TalentType.REVERSION,
      value: 0.30, // HP threshold for activation (30%)
      secondaryValue: 0.12, // DEF/SPD buff for allies (12%)
      manaCost: 0, // Passive trigger
    ),
    TalentType.TRANSFORMATION: const Talent(
      name: "Transformation",
      description: "Start battle with -25% SPD, but +45% base HP and ATK.",
      type: TalentType.TRANSFORMATION,
      value: 0.45, // HP/ATK increase percentage
      secondaryValue: 0.25, // SPD decrease percentage
      manaCost: 0, // Passive at battle start
    ),
    // Add other TalentTypes from your enum here with their full Talent objects
    TalentType.YIN_YANG: const Talent(
      name: "Yin Yang",
      description: "Passive: Alternates buffs. Starts with Yin (DEF +70%). Next round, Yang (ATK +70%, DEF normal), then back to Yin, etc.",
      type: TalentType.YIN_YANG,
      value: 0.70, // 70% buff to either ATK or DEF
      manaCost: 0,
    ),
    TalentType.BLOOD_SURGE: const Talent( // Repurposed for Lifesteal
      name: "Blood Surge",
      description: "When health is low (<= 80% Max HP), increase Lifesteal by 45%.",
      type: TalentType.BLOOD_SURGE,
      value: 0.45, // Represents 45% lifesteal bonus
      manaCost: 0, // Passive condition
    ),
    TalentType.CELESTIAL_INFLUENCE: const Talent(
      name: "Celestial Influence",
      description: "Start off the battle with 45% increased Mana Regen.",
      type: TalentType.CELESTIAL_INFLUENCE,
      value: 0.45, // 45% mana regen bonus
      manaCost: 0, // Passive
    ),
    TalentType.DIVINE_BLESSING: const Talent(
      name: "Divine Blessing",
      description: "Start battle with ATK/DEF increased by 55% (SR) or 65% (UR) for 5 turns.",
      type: TalentType.DIVINE_BLESSING,
      value: 0.55, // SR buff percentage
      secondaryValue: 0.65, // UR buff percentage
      manaCost: 0, // Passive activation at battle start
    ),
    TalentType.DOMINANCE: const Talent(
      name: "Dominance",
      description: "While your current HP % is >= enemy's current HP %, increase ATK by 37% (SR) or 47% (UR).",
      type: TalentType.DOMINANCE,
      value: 0.37, // SR ATK buff
      secondaryValue: 0.47, // UR ATK buff
      manaCost: 0, // Passive condition
    ),
    TalentType.GRIEVOUS_LIMITER: const Talent(
      name: "Grievous Limiter",
      description: "At battle start, decrease enemy ATK by 60%. Enemy recovers 10% of their original ATK each turn.",
      type: TalentType.GRIEVOUS_LIMITER,
      value: 0.60, // 60% initial ATK reduction on enemy
      secondaryValue: 0.10, // 10% of original ATK recovery per turn for enemy
      manaCost: 0, // Passive at battle start
    ),
    TalentType.LIFE_SAP: const Talent(
      name: "Life Sap",
      description: "Every round, deal (4% SR, 5% UR) of enemy's max HP as damage, and heal for that amount.",
      type: TalentType.LIFE_SAP,
      value: 0.04, // SR damage/heal percentage
      secondaryValue: 0.05, // UR damage/heal percentage
      manaCost: 0, // Passive round-end effect
    ),
    TalentType.RECOIL: const Talent(
      name: "Recoil",
      description: "Both you and your opponent take 3% of your Max HP as True damage per turn.",
      type: TalentType.RECOIL,
      value: 0.03, // 3% of talent-bearer's Max HP
      manaCost: 0, // Passive effect applied at start and triggers round-end
    ),
    TalentType.SOUL_STEALER: const Talent(
      name: "Soul Stealer",
      description: "Absorb (4% SR, 5% UR) of the enemy's current DEF as your ATK every turn.",
      type: TalentType.SOUL_STEALER,
      value: 0.04, // SR absorption rate
      secondaryValue: 0.05, // UR absorption rate
      manaCost: 0, // Passive round-end effect
    ),
    TalentType.TEMPORAL_REWIND: const Talent(
      name: "Temporal Rewind",
      description: "After 3 turns, restore HP equal to half the difference between HP at buff application and current HP, and deal that amount to the opponent.",
      type: TalentType.TEMPORAL_REWIND,
      value: 3, // Number of turns for the delay
      // secondaryValue: null, // Not explicitly used for a second numeric effect here
      manaCost: 25, // Example mana cost for an active skill
    ),
    TalentType.UNDERDOG: const Talent(
      name: "Underdog",
      description: "While your HP % is lower than the enemy's HP %, increase ATK/DEF by 15%.",
      type: TalentType.UNDERDOG,
      value: 0.15, // 15% ATK/DEF buff
      manaCost: 0, // Passive condition
    ),
    TalentType.AMPLIFIER: const Talent(
      name: "Amplifier",
      description: "Increase ATK/DEF by 25% for 3 turns.",
      type: TalentType.AMPLIFIER,
      value: 0.25, // 25% ATK/DEF buff
      secondaryValue: 3, // Duration in turns
      manaCost: 20, // Example mana cost
    ),
    TalentType.BALANCING_STRIKE: const Talent(
      name: "Balancing Strike",
      description: "If your HP % is lower than enemy's, deal 15% of your current HP as True damage. Else, deal 5% of your original Max HP as True damage.",
      type: TalentType.BALANCING_STRIKE,
      value: 0.15, // Higher damage percentage (current HP)
      secondaryValue: 0.05, // Lower damage percentage (original Max HP)
      manaCost: 15, // Example mana cost
    ),
    TalentType.BREAKER_ATK: const Talent(
      name: "Breaker (ATK)",
      description: "Permanently decrease enemy ATK by 20% of their current ATK.",
      type: TalentType.BREAKER_ATK,
      value: 0.20, // 20% ATK/DEF reduction
      manaCost: 20, // Example mana cost
    ),
    TalentType.BREAKER_DEF: const Talent(
      name: "Breaker (DEF)",
      description: "Permanently decrease enemy DEF by 20% of their current DEF.",
      type: TalentType.BREAKER_DEF,
      value: 0.20, // 20% ATK/DEF reduction
      manaCost: 20, // Example mana cost
    ),
    TalentType.DEXTERITY_DRIVE: const Talent(
      name: "Dexterity Drive",
      description: "Deal (Card Element) damage equal to 5% of your SPD, plus bonus damage based on SPD difference.",
      type: TalentType.DEXTERITY_DRIVE,
      value: 0.05, // 5% of SPD as base damage
      secondaryValue: 0.01, // e.g., 1% of SPD difference as bonus damage
      manaCost: 20, // Reverted mana cost
    ),
    TalentType.DOUBLE_EDGED_STRIKE: const Talent(
      name: "Double-edged Strike",
      description: "Deal (Card Element) damage equal to 15% of your highest stat (ATK/DEF/SPD), and take 1/4 of the damage dealt as recoil.",
      type: TalentType.DOUBLE_EDGED_STRIKE,
      value: 0.15, // 15% of highest stat as damage
      secondaryValue: 0.25, // 25% (1/4) recoil damage
      manaCost: 10, // Example mana cost
    ),
    TalentType.ELEMENTAL_STRIKE: const Talent(
      name: "Elemental Strike",
      description: "Deal (Card Element) damage equal to 10% of your highest stat (ATK or DEF).",
      type: TalentType.ELEMENTAL_STRIKE,
      value: 0.10, // 10% of highest stat (ATK/DEF) as damage
      // secondaryValue: null, // Not needed for this talent
      manaCost: 15, // Example mana cost
    ),
    TalentType.FREEZE: const Talent(
      name: "Freeze",
      description: "Inflict Frozen: -50% SPD for 2 turns, and permanently -10% ATK.",
      type: TalentType.FREEZE,
      value: 0.10, // 10% permanent ATK decrease
      secondaryValue: 0.50, // 50% temporary SPD decrease
      // Duration (e.g., 2 turns) will be handled in TalentSystem logic
      manaCost: 25, // Example mana cost
    ),
    TalentType.LUCKY_COIN: const Talent(
      name: "Lucky Coin",
      description: "Roll a D20. Gain (Roll x 3) to a random stat (HP/ATK/DEF/SPD).",
      type: TalentType.LUCKY_COIN,
      value: 20, // Sides of the die
      secondaryValue: 3, // Multiplier for the roll
      manaCost: 30, // Example mana cost
    ),
    TalentType.MANA_REAVER: const Talent(
      name: "Mana Reaver",
      description: "Absorb up to 20% Mana from enemy, deal True damage equal to (Mana absorbed x10).",
      type: TalentType.MANA_REAVER,
      value: 0.20, // 20% mana absorption
      secondaryValue: 10, // Damage multiplier for mana absorbed
      manaCost: 15, // Example mana cost
    ),
    TalentType.PAIN_FOR_POWER: const Talent(
      name: "Pain For Power",
      description: "Sacrifice 15% current HP to increase ATK/SPD by 35% for 3 turns.",
      type: TalentType.PAIN_FOR_POWER,
      value: 0.15, // HP sacrifice percentage (current HP)
      secondaryValue: 0.35, // ATK/SPD buff percentage
      manaCost: 10, // Example mana cost
    ),
    TalentType.POISON: const Talent(
      name: "Poison",
      description: "Inflict Poison: deals (5 + 5% Caster ATK) True DMG/turn. 40% chance to resist tick.",
      type: TalentType.POISON,
      value: 5, // Flat damage part
      secondaryValue: 0.05, // Percent damage part (of caster's ATK)
      manaCost: 20, // Example mana cost
    ),
    TalentType.RESTRICTED_INSTINCT: const Talent(
      name: "Restricted Instinct",
      description: "Inflict Silence on enemy for 3 turns (30% chance to resist). Silenced enemies cannot use abilities.",
      type: TalentType.RESTRICTED_INSTINCT,
      value: 0.30, // Enemy resist chance
      secondaryValue: 3, // Duration in turns
      manaCost: 20, // Example mana cost
    ),
    TalentType.TIME_ATTACK: const Talent(
      name: "Time Attack",
      description: "Deal (Card Element) damage equal to 5% of (Original ATK+DEF+MaxHP). Damage increases by 40% for every turn passed.",
      type: TalentType.TIME_ATTACK,
      value: 0.05, // 5% of sum of original stats
      secondaryValue: 0.40, // 40% damage increase per turn passed
      manaCost: 20, // Example mana cost
    ),
    TalentType.ULTIMATE_COMBO: const Talent(
      name: "Ultimate Combo",
      description: "Increases Fighting Counter. Deals SPD-based True damage. Empowered if team counters >= 3 (deals % opponent MaxHP, resets user's counters).",
      type: TalentType.ULTIMATE_COMBO,
      value: 0.03, // 3% of SPD per Fighting Counter (normal mode)
      secondaryValue: 0.30, // 30% of opponent's Max HP as True damage (empowered mode)
      manaCost: 25, // Example mana cost
    ),
    TalentType.VENGEANCE: const Talent(
      name: "Vengeance",
      description: "Deal True damage equal to 11% of the opponent's highest stat (ATK/DEF/SPD).",
      type: TalentType.VENGEANCE,
      value: 0.11, // 11% of opponent's highest stat
      // secondaryValue: null, // Not needed for this talent
      manaCost: 20, // Example mana cost
    ),
    TalentType.TRICK_ROOM_ATK: const Talent(
      name: "Trick Room (ATK)",
      description: "If enemy ATK > yours, gain ATK equal to (SR 90%, UR 105%) of difference, enemy loses same amount. Lasts 3 turns.",
      type: TalentType.TRICK_ROOM_ATK,
      value: 0.90, // SR percentage
      secondaryValue: 1.05, // UR percentage
      manaCost: 30, // Example mana cost
    ),
    TalentType.TRICK_ROOM_DEF: const Talent(
      name: "Trick Room (DEF)",
      description: "If enemy DEF > yours, gain DEF equal to (SR 90%, UR 105%) of difference, enemy loses same amount. Lasts 3 turns.",
      type: TalentType.TRICK_ROOM_DEF,
      value: 0.90, // SR percentage
      secondaryValue: 1.05, // UR percentage
      manaCost: 30, // Example mana cost
    ),

    // NOTE: Ensure TEMPORAL_REWIND is defined if it's a separate talent.
  };
}