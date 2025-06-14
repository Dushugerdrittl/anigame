import 'card_model.dart';
// For CardType
import 'dart:math'; // For Random

// Reverted to a more comprehensive list of TalentTypes
enum TalentType {
  // Active Skills from card_definitions and previous context
  REGENERATION,     // Active: Heals target (value: 0.1 for 10% max HP)
  REJUVENATION,     // Active: Heals all allies, increases healing effects
  PRECISION,        // Active/Passive: Increases CRIT chance and CRIT DMG
  BLAZE,            // Active: Inflicts Burn, reduces healing
  TIME_BOMB,        // Active: Deals damage after a delay

  // Passive Skills from card_definitions and previous context
  BERSERKER,        // Passive: ATK/DEF buff when low HP
  EXECUTIONER,      // Passive: ATK buff when enemy low HP
  OVERLOAD,         // Passive: Initial ATK buff, then ATK decrease per turn
  PROTECTOR,        // Passive: Heal and DEF buff when low HP
  
  BLOOD_SURGE,      // Passive: ATK buff (could be flat or % based on original design)
  YIN_YANG,         // Passive/Active: Alternating ATK/DEF buffs (OLD_YIN_YANG behavior)
  
  // Other potential TalentTypes from a more complex system
  AMPLIFIER,
  BALANCING_STRIKE,
  BREAKER_ATK,      // Active: Permanently decrease enemy ATK
  BREAKER_DEF,      // Active: Permanently decrease enemy DEF
  DEXTERITY_DRIVE,
  DOUBLE_EDGED_STRIKE,
  ELEMENTAL_STRIKE,
  ENDURANCE,
  EVASION,
  FREEZE,
  LUCKY_COIN,
  MANA_REAVER,      // Active: Absorb enemy mana, deal damage based on mana absorbed
  OFFENSIVE_STANCE,
  PARALYSIS,
  PAIN_FOR_POWER,
  POISON,
  RESTRICTED_INSTINCT,
  TIME_ATTACK,
  TRICK_ROOM_ATK,   // Active: Steal/buff ATK based on difference.
  TRICK_ROOM_DEF,   // Active: Steal/buff DEF based on difference.
  ULTIMATE_COMBO,   // Active: Damage scales with Fighting Counters. Empowered effect at team threshold.
  VENGEANCE,        // Active: Deals True damage based on 11% of opponent's highest stat (ATK/DEF/SPD).
  BLOODTHIRSTER, // Potentially different from BLOODTHIRST
  CELESTIAL_INFLUENCE,
  DIVINE_BLESSING,
  DOMINANCE,
  GRIEVOUS_LIMITER,
  LIFE_SAP,
  RECOIL,
  REVERSION,
  SOUL_STEALER,
  TEMPORAL_REWIND,
  TRANSFORMATION,
  UNDERDOG,
}

class Talent {
  final String name;
  final String description;
  final TalentType type;
  final double value; // Primary value for the talent
  final double? secondaryValue; // Optional: For talents with a second numeric effect
  final int manaCost; // 0 for passive talents

  const Talent({
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.secondaryValue,
    this.manaCost = 0, // Default to passive
  });
}

const int MAX_BURN_STACKS = 5; // Max stacks for Blaze's burn
// const int INITIAL_BURN_DEBUFF_HEALTH = 40; // This was for the old Blaze mechanic
const double BURN_RESIST_CHANCE = 0.40; // 40% chance for opponent to resist burn damage each turn
const int BURN_BASE_DURATION_TURNS = 3; // Burn lasts for 3 turns, resist check each turn
final Random _random = Random(); // For resist chance
const double MAX_EVASION_CHANCE_CAP = 0.75; // Max 75% evasion
const int FROZEN_DURATION_TURNS = 2; // Duration of the SPD debuff part of Freeze
const int OFFENSIVE_STANCE_DURATION_TURNS = 3;
const int PAIN_FOR_POWER_DURATION_TURNS = 3;
const int POISON_DURATION_TURNS = 3; // Example duration for poison
const double POISON_RESIST_CHANCE = 0.40; // 40% chance for enemy to resist poison tick
const int PRECISION_DURATION_TURNS = 3;
const int RESTRICTED_INSTINCT_DURATION_TURNS = 3;
const int ULTIMATE_COMBO_EMPOWERED_THRESHOLD = 3; // Team fighting counter threshold for empowered effect
const int TIME_BOMB_DURATION_TURNS = 1; // As per description "after 1 turn"
const int TRICK_ROOM_EFFECT_DURATION_TURNS = 3; // Example duration for Trick Room stat effects
const double TRICK_ROOM_ATK_DAMAGE_SCALING_FACTOR_K = 0.001; // Scaling factor for TR ATK damage
const int ULTIMATE_COMBO_COUNTER_INCREMENT = 1;   // How much the caster's counter increases by


class TalentSystem {
  // Applies talents that modify base stats at the start of a battle or upon acquisition
  // Also handles initial effects like Bloodthirst heal and YinYang's first state.
  static void applyPermanentTalentEffects(Card card, Function(String) logCallback) {
    if (card.talent == null) return;

    final talent = card.talent!;
    // Store original stats before any modifications for talents like YinYang or Overload
    card.originalAttack = card.attack;
    card.originalDefense = card.defense;
    card.originalSpeed = card.speed; // Ensure originalSpeed is captured
    card.originalMaxHp = card.maxHp; // Capture originalMaxHp

    switch (talent.type) {
      case TalentType.BLOOD_SURGE: 
        // New lifesteal version handled by checkAndApplyBloodSurgeLifesteal.
        break;
      case TalentType.YIN_YANG:
        card.isYangBuffActive = false; // Start with Yin Buff (DEF increase)
        int defenseBoost = (card.originalDefense * talent.value).round(); // talent.value will be 0.70
        card.defense = card.originalDefense + defenseBoost;
        logCallback("${card.name}'s ${talent.name} (Yin Buff Active - Initial): Defense increased by $defenseBoost to ${card.defense}. Attack is ${card.originalAttack}.");
        break;
      case TalentType.OVERLOAD:
        if (talent.manaCost == 0) {
          double buffPercent = 0;
          if (card.rarity == CardRarity.SUPER_RARE) {
            buffPercent = talent.value; 
          } else if (card.rarity == CardRarity.ULTRA_RARE) {
            buffPercent = talent.secondaryValue ?? talent.value; 
          }
          if (buffPercent == 0 && (card.rarity == CardRarity.RARE || card.rarity == CardRarity.UNCOMMON || card.rarity == CardRarity.COMMON)) buffPercent = 0.70; 

          int attackBoost = (card.originalAttack * buffPercent).round();
          card.attack = card.originalAttack + attackBoost;
          logCallback("${card.name}'s ${talent.name} increases ATK by ${(buffPercent * 100).toStringAsFixed(0)}% to ${card.attack}. (Will decrease each turn)");
        }
        break;
      case TalentType.BLOODTHIRSTER:
        if (talent.manaCost == 0 && talent.secondaryValue != null) {
          card.currentHealingEffectivenessBonus += talent.secondaryValue!;
          logCallback("${card.name}'s ${talent.name} passively increases healing effectiveness by ${(talent.secondaryValue! * 100).toStringAsFixed(0)}%. Current Bonus: ${(card.currentHealingEffectivenessBonus * 100).toStringAsFixed(0)}%");
        }
        break;
      case TalentType.CELESTIAL_INFLUENCE:
        if (talent.manaCost == 0) {
          card.manaRegenBonus = talent.value; 
          logCallback("${card.name}'s ${talent.name} passively increases Mana Regen by ${(talent.value * 100).toStringAsFixed(0)}%.");
        }
        break;
      case TalentType.DIVINE_BLESSING:
        if (talent.manaCost == 0) {
          double buffPercent = 0;
          if (card.rarity == CardRarity.SUPER_RARE) {
            buffPercent = talent.value; 
          } else if (card.rarity == CardRarity.ULTRA_RARE) {
            buffPercent = talent.secondaryValue ?? talent.value; 
          }

          if (buffPercent > 0) {
            card.isDivineBlessingActive = true;
            card.divineBlessingTurnsRemaining = 5;
            int atkBoost = (card.originalAttack * buffPercent).round();
            int defBoost = (card.originalDefense * buffPercent).round();
            card.attack += atkBoost;
            card.defense += defBoost;
            logCallback("${card.name}'s Divine Blessing activates! ATK/DEF +${(buffPercent * 100).toStringAsFixed(0)}% for 5 turns. (ATK: ${card.attack}, DEF: ${card.defense})");
          }
        }
        break;
      case TalentType.RECOIL:
        if (talent.manaCost == 0) {
          card.recoilSourceMaxHpForSelf = card.maxHp; 
          logCallback("${card.name}'s Recoil talent is active. Will take self-damage each turn.");
        }
        break;
      case TalentType.TRANSFORMATION:
        if (talent.manaCost == 0) {
          int spdDecrease = (card.originalSpeed * (talent.secondaryValue ?? 0.25)).round();
          card.speed = (card.speed - spdDecrease).clamp(1, card.originalSpeed * 3); 
          int hpIncrease = (card.maxHp * talent.value).round(); 
          card.maxHp += hpIncrease;
          card.currentHp = card.maxHp; 
          int atkIncrease = (card.originalAttack * talent.value).round();
          card.attack += atkIncrease;
          logCallback("${card.name}'s ${talent.name} activates! SPD: ${card.speed} (-${(talent.secondaryValue ?? 0.25) * 100}%), MaxHP: ${card.maxHp} (+${talent.value * 100}%), ATK: ${card.attack} (+${talent.value * 100}%).");
        }
        break;
      default:
        logCallback("${talent.name} has no immediate permanent stat effect at battle start or is conditional.");
        break;
    }
  }
// Add this method to your TalentSystem class
static bool activateTimeAttack(Card cardWithTalent, Card opponentCard, int currentBattleRound, Function(String) logCallback) {
  if (cardWithTalent.talent?.type != TalentType.TIME_ATTACK || cardWithTalent.currentHp <= 0) {
    return false;
  }
  if (cardWithTalent.isSilenced) {
    logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
    return false;
  }
  final talent = cardWithTalent.talent!;
  if (cardWithTalent.currentMana < talent.manaCost) {
    logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
    return false;
  }
  cardWithTalent.currentMana -= talent.manaCost;

  int baseStatSum = cardWithTalent.originalAttack + cardWithTalent.originalDefense + cardWithTalent.originalMaxHp;
  double baseDamagePercent = talent.value; // 0.05
  int baseDamageComponent = (baseStatSum * baseDamagePercent).round();

  double turnMultiplierIncrease = talent.secondaryValue ?? 0.40; // 0.40
  double turnBasedMultiplier = 1.0 + (max(0, currentBattleRound - 1) * turnMultiplierIncrease);

  int totalDamage = (baseDamageComponent * turnBasedMultiplier).round();
  if (totalDamage < 1) totalDamage = 1;

  opponentCard.takeDamage(totalDamage);

  logCallback("${cardWithTalent.name} uses ${talent.name} (Round $currentBattleRound, Multiplier: ${turnBasedMultiplier.toStringAsFixed(2)})! Deals $totalDamage (${cardWithTalent.type.toString().split('.').last}) damage to ${opponentCard.name}. ${opponentCard.name} HP: ${opponentCard.currentHp}. Mana cost: ${talent.manaCost}.");
  return true;
}

  // Activates Time Bomb
  static bool activateTimeBomb(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.TIME_BOMB || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;

    opponentCard.isTimeBombActive = true;
    opponentCard.timeBombTurnsRemaining = TIME_BOMB_DURATION_TURNS;
    // Calculate damage now based on current caster's ATK
    opponentCard.timeBombDamage = (cardWithTalent.attack * talent.value).round();
    if (opponentCard.timeBombDamage < 1 && talent.value > 0) opponentCard.timeBombDamage = 1;

    logCallback("${cardWithTalent.name} plants a ${talent.name} on ${opponentCard.name}! It will explode in ${opponentCard.timeBombTurnsRemaining} turn(s) for ${opponentCard.timeBombDamage} True damage. Mana cost: ${talent.manaCost}.");
    return true;
  }


  // Activates Regeneration Buff
  static bool activateRegenerationBuff(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.REGENERATION || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    double baseHealPercent = talent.value; 
    double rarityMultiplier = 1.0;
    switch (cardWithTalent.rarity) {
      case CardRarity.COMMON: rarityMultiplier = 1.0; break;
      case CardRarity.UNCOMMON: rarityMultiplier = 1.2; break;
      case CardRarity.RARE: rarityMultiplier = 1.4; break;
      case CardRarity.SUPER_RARE: rarityMultiplier = 1.6; break;
      case CardRarity.ULTRA_RARE: rarityMultiplier = 1.8; break;
    }
    int healPerTurn = (cardWithTalent.maxHp * baseHealPercent * rarityMultiplier).round();
    if (healPerTurn < 1 && baseHealPercent > 0) healPerTurn = 1;
    cardWithTalent.isRegenerationBuffActive = true;
    cardWithTalent.regenerationTurnsRemaining = talent.secondaryValue?.toInt() ?? 3;
    cardWithTalent.regenerationHealPerTurn = healPerTurn;
    logCallback(
        "${cardWithTalent.name} uses ${talent.name}! Will heal for ${cardWithTalent.regenerationHealPerTurn} HP per turn for "
        "${cardWithTalent.regenerationTurnsRemaining} turns. Mana cost: ${talent.manaCost}."
    );
    return true;
  }

  // Activates Rejuvenation
  static bool activateRejuvenation(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.REJUVENATION || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int healAmount = (cardWithTalent.maxHp * talent.value).round(); 
    if (healAmount < 1 && talent.value > 0) healAmount = 1;
    cardWithTalent.heal(healAmount); 
    logCallback("${cardWithTalent.name} uses ${talent.name}, healing for $healAmount HP. Current HP: ${cardWithTalent.currentHp}.");
    double effectivenessIncrease = talent.secondaryValue ?? 0.25;
    cardWithTalent.currentHealingEffectivenessBonus = 
        (cardWithTalent.currentHealingEffectivenessBonus + effectivenessIncrease).clamp(0.0, 0.50); 
    logCallback("${cardWithTalent.name}'s healing effectiveness increased by ${(effectivenessIncrease * 100).toStringAsFixed(0)}%. Total bonus: ${(cardWithTalent.currentHealingEffectivenessBonus * 100).toStringAsFixed(0)}%. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Temporal Rewind buff
  static bool activateTemporalRewind(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.TEMPORAL_REWIND || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    cardWithTalent.isTemporalRewindActive = true;
    cardWithTalent.temporalRewindTurnsRemaining = talent.value.toInt(); 
    cardWithTalent.temporalRewindInitialHpAtBuff = cardWithTalent.currentHp;
    logCallback("${cardWithTalent.name} activates ${talent.name}! Effect will trigger in ${cardWithTalent.temporalRewindTurnsRemaining} turns. Initial HP marked: ${cardWithTalent.temporalRewindInitialHpAtBuff}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Amplifier buff
  static bool activateAmplifier(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.AMPLIFIER || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    if (cardWithTalent.isAmplifierBuffActive) { 
        logCallback("${cardWithTalent.name} refreshes ${talent.name}.");
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int atkBoost = (cardWithTalent.originalAttack * talent.value).round();
    int defBoost = (cardWithTalent.originalDefense * talent.value).round();
    cardWithTalent.attack = cardWithTalent.originalAttack + atkBoost; 
    cardWithTalent.defense = cardWithTalent.originalDefense + defBoost;
    cardWithTalent.isAmplifierBuffActive = true;
    cardWithTalent.amplifierTurnsRemaining = talent.secondaryValue?.toInt() ?? 3; 
    logCallback("${cardWithTalent.name} activates ${talent.name}! ATK/DEF +${(talent.value * 100).toStringAsFixed(0)}% for ${cardWithTalent.amplifierTurnsRemaining} turns. ATK: ${cardWithTalent.attack}, DEF: ${cardWithTalent.defense}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Poison
  static bool activatePoison(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.POISON || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    opponentCard.isPoisoned = true;
    opponentCard.poisonTurnsRemaining = POISON_DURATION_TURNS;
    opponentCard.poisonFlatDamage = talent.value.toInt(); 
    opponentCard.poisonPercentDamage = talent.secondaryValue ?? 0.05; 
    opponentCard.poisonCasterAttack = cardWithTalent.attack; 
    logCallback(
        "${cardWithTalent.name} uses ${talent.name} on ${opponentCard.name}! "
        "${opponentCard.name} is Poisoned for ${opponentCard.poisonTurnsRemaining} turns. "
        "Mana cost: ${talent.manaCost}."
    );
    return true;
  }

  // Activates Precision buff
  static bool activatePrecision(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.PRECISION || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    if (cardWithTalent.isPrecisionBuffActive) {
      logCallback("${cardWithTalent.name} refreshes ${talent.name}.");
    }
    cardWithTalent.isPrecisionBuffActive = true;
    cardWithTalent.precisionTurnsRemaining = PRECISION_DURATION_TURNS;
    cardWithTalent.precisionCritChanceBonus = talent.value; 
    cardWithTalent.precisionCritDamageBonus = talent.secondaryValue ?? 0.30; 
    logCallback(
        "${cardWithTalent.name} uses ${talent.name}! CRIT Chance +${(cardWithTalent.precisionCritChanceBonus * 100).toStringAsFixed(0)}%, "
        "CRIT DMG +${(cardWithTalent.precisionCritDamageBonus * 100).toStringAsFixed(0)}% "
        "for ${cardWithTalent.precisionTurnsRemaining} turns. Mana cost: ${talent.manaCost}."
    );
    return true;
  }

  // Activates Pain For Power
  static bool activatePainForPower(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.PAIN_FOR_POWER || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    int hpSacrifice = (cardWithTalent.currentHp * talent.value).round(); 
    if (cardWithTalent.currentHp <= hpSacrifice) { 
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough HP to sacrifice (Current: ${cardWithTalent.currentHp}, Sacrifice: $hpSacrifice).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    cardWithTalent.takeDamage(hpSacrifice); 
    logCallback("${cardWithTalent.name} sacrifices $hpSacrifice HP for ${talent.name}. Current HP: ${cardWithTalent.currentHp}.");
    if (cardWithTalent.isPainForPowerBuffActive) {
      _revertPainForPowerBuff(cardWithTalent, logCallback, false);
    }
    double buffPercent = talent.secondaryValue ?? 0.35;
    int atkBoost = (cardWithTalent.originalAttack * buffPercent).round();
    int spdBoost = (cardWithTalent.originalSpeed * buffPercent).round();
    cardWithTalent.attack = cardWithTalent.originalAttack + atkBoost;
    cardWithTalent.speed = cardWithTalent.originalSpeed + spdBoost;
    cardWithTalent.isPainForPowerBuffActive = true;
    cardWithTalent.painForPowerTurnsRemaining = PAIN_FOR_POWER_DURATION_TURNS;
    logCallback("${cardWithTalent.name}'s ${talent.name} activates! ATK +${(buffPercent * 100).toStringAsFixed(0)}% to ${cardWithTalent.attack}, SPD +${(buffPercent * 100).toStringAsFixed(0)}% to ${cardWithTalent.speed} for ${cardWithTalent.painForPowerTurnsRemaining} turns. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Balancing Strike
  static bool activateBalancingStrike(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.BALANCING_STRIKE || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    double cardHpPercent = cardWithTalent.maxHp > 0 ? cardWithTalent.currentHp / cardWithTalent.maxHp : 0;
    double enemyHpPercent = opponentCard.maxHp > 0 ? opponentCard.currentHp / opponentCard.maxHp : 0;
    int damageDealt;
    String damageSourceLog;
    if (cardHpPercent < enemyHpPercent) {
      damageDealt = (cardWithTalent.currentHp * talent.value).round(); 
      damageSourceLog = "15% of current HP";
    } else {
      damageDealt = (cardWithTalent.originalMaxHp * (talent.secondaryValue ?? 0.05)).round(); 
      damageSourceLog = "5% of original Max HP";
    }
    if (damageDealt < 1 && (talent.value > 0 || (talent.secondaryValue ?? 0) > 0)) damageDealt = 1; 
    opponentCard.takeDamage(damageDealt); 
    logCallback("${cardWithTalent.name} uses ${talent.name}! Deals $damageDealt True damage to ${opponentCard.name} (based on $damageSourceLog). ${opponentCard.name} HP: ${opponentCard.currentHp}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Blaze
  static bool activateBlaze(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.BLAZE || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!; 
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    opponentCard.isUnderBurnDebuff = true;
    opponentCard.burnCasterAttack = cardWithTalent.attack; 
    opponentCard.burnDamagePerStackPercent = talent.value; 
    opponentCard.burnHealingReductionPercent = talent.secondaryValue ?? 0.75; 
    if (opponentCard.burnStacks < MAX_BURN_STACKS) {
      opponentCard.burnStacks++;
    }
    opponentCard.burnDurationTurns = BURN_BASE_DURATION_TURNS; 
    logCallback("${cardWithTalent.name} uses ${talent.name} on ${opponentCard.name}! Burn stacks: ${opponentCard.burnStacks}/$MAX_BURN_STACKS. Duration: ${opponentCard.burnDurationTurns} turns. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Breaker (ATK) debuff on opponent
  static bool activateBreakerAtk(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.BREAKER_ATK || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int atkReduction = (opponentCard.attack * talent.value).round(); 
    opponentCard.attack = (opponentCard.attack - atkReduction).clamp(1, opponentCard.originalAttack * 3); 
    logCallback("${cardWithTalent.name} uses ${talent.name} on ${opponentCard.name}! Enemy ATK permanently reduced by $atkReduction to ${opponentCard.attack}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Breaker (DEF) debuff on opponent
  static bool activateBreakerDef(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.BREAKER_DEF || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int defReduction = (opponentCard.defense * talent.value).round(); 
    opponentCard.defense = (opponentCard.defense - defReduction).clamp(1, opponentCard.originalDefense * 3); 
    logCallback("${cardWithTalent.name} uses ${talent.name} on ${opponentCard.name}! Enemy DEF permanently reduced by $defReduction to ${opponentCard.defense}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Dexterity Drive
  static bool activateDexterityDrive(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.DEXTERITY_DRIVE || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int baseDamage = (cardWithTalent.speed * talent.value).round();
    int bonusDamage = 0;
    int speedDifference = cardWithTalent.speed - opponentCard.speed;
    if (speedDifference > 0) {
      bonusDamage = (speedDifference * (talent.secondaryValue ?? 0.01)).round();
    }
    int totalDamage = baseDamage + bonusDamage;
    if (totalDamage < 1) totalDamage = 1; 
    opponentCard.takeDamage(totalDamage); 
    logCallback("${cardWithTalent.name} uses ${talent.name}! Deals $totalDamage (${cardWithTalent.type.toString().split('.').last}) damage to ${opponentCard.name} (Base: $baseDamage, Bonus: $bonusDamage). ${opponentCard.name} HP: ${opponentCard.currentHp}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Double-edged Strike
  static bool activateDoubleEdgedStrike(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.DOUBLE_EDGED_STRIKE || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int highestStat = cardWithTalent.attack;
    String statSource = "ATK";
    if (cardWithTalent.defense > highestStat) {
      highestStat = cardWithTalent.defense;
      statSource = "DEF";
    }
    if (cardWithTalent.speed > highestStat) {
      highestStat = cardWithTalent.speed;
      statSource = "SPD";
    }
    int damageDealtToOpponent = (highestStat * talent.value).round();
    if (damageDealtToOpponent < 1) damageDealtToOpponent = 1;
    opponentCard.takeDamage(damageDealtToOpponent);
    logCallback("${cardWithTalent.name} uses ${talent.name}! Deals $damageDealtToOpponent (${cardWithTalent.type.toString().split('.').last}) damage to ${opponentCard.name} (based on $statSource: $highestStat). ${opponentCard.name} HP: ${opponentCard.currentHp}. Mana cost: ${talent.manaCost}.");
    int recoilDamage = (damageDealtToOpponent * (talent.secondaryValue ?? 0.25)).round();
    if (recoilDamage < 1 && (talent.secondaryValue ?? 0) > 0) recoilDamage = 1;
    cardWithTalent.takeDamage(recoilDamage);
    logCallback("${cardWithTalent.name} takes $recoilDamage recoil damage. ${cardWithTalent.name} HP: ${cardWithTalent.currentHp}.");
    return true;
  }

  // Activates Elemental Strike
  static bool activateElementalStrike(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.ELEMENTAL_STRIKE || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int highestStat = cardWithTalent.attack;
    String statSource = "ATK";
    if (cardWithTalent.defense > highestStat) {
      highestStat = cardWithTalent.defense;
      statSource = "DEF";
    }
    int damageDealt = (highestStat * talent.value).round();
    if (damageDealt < 1) damageDealt = 1;
    opponentCard.takeDamage(damageDealt); 
    logCallback("${cardWithTalent.name} uses ${talent.name}! Deals $damageDealt (${cardWithTalent.type.toString().split('.').last}) damage to ${opponentCard.name} (based on $statSource: $highestStat). ${opponentCard.name} HP: ${opponentCard.currentHp}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Endurance buff
  static bool activateEndurance(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.ENDURANCE || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    if (cardWithTalent.isEnduranceBuffActive) { 
        logCallback("${cardWithTalent.name} refreshes ${talent.name}.");
    }
    cardWithTalent.currentMana -= talent.manaCost;
    cardWithTalent.isEnduranceBuffActive = true;
    cardWithTalent.enduranceTurnsRemaining = talent.secondaryValue?.toInt() ?? 3;
    cardWithTalent.enduranceDamageReductionPercent = talent.value; 
    logCallback("${cardWithTalent.name} activates ${talent.name}! Will take ${(talent.value * 100).toStringAsFixed(0)}% less damage from normal attacks for ${cardWithTalent.enduranceTurnsRemaining} turns. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Evasion buff
  static bool activateEvasion(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.EVASION || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int maxStacks = talent.secondaryValue?.toInt() ?? 9;
    if (cardWithTalent.evasionStacks < maxStacks) {
      cardWithTalent.evasionStacks++;
    }
    cardWithTalent.currentEvasionChance = (cardWithTalent.evasionStacks * talent.value).clamp(0.0, MAX_EVASION_CHANCE_CAP);
    cardWithTalent.evasionBuffTurnsRemaining = maxStacks; 
    logCallback("${cardWithTalent.name} uses ${talent.name}! Evasion chance increased to ${(cardWithTalent.currentEvasionChance * 100).toStringAsFixed(0)}% (Stacks: ${cardWithTalent.evasionStacks}/$maxStacks). Buff lasts ${cardWithTalent.evasionBuffTurnsRemaining} turns. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Freeze debuff
  static bool activateFreeze(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.FREEZE || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int atkReduction = (opponentCard.attack * talent.value).round(); 
    opponentCard.attack = (opponentCard.attack - atkReduction).clamp(1, opponentCard.originalAttack * 3); 
    logCallback("${cardWithTalent.name} uses ${talent.name} on ${opponentCard.name}! Enemy ATK permanently reduced by $atkReduction to ${opponentCard.attack}.");
    if (!opponentCard.isFrozen) { 
      int spdReductionValue = (opponentCard.originalSpeed * (talent.secondaryValue ?? 0.50)).round();
      opponentCard.speed = (opponentCard.speed - spdReductionValue).clamp(1, opponentCard.originalSpeed * 3);
      opponentCard.frozenSpeedReductionPercent = talent.secondaryValue ?? 0.50;
      logCallback("${opponentCard.name}'s SPD reduced by ${(opponentCard.frozenSpeedReductionPercent * 100).toStringAsFixed(0)}% to ${opponentCard.speed}.");
    } else {
      logCallback("${opponentCard.name} is already Frozen, refreshing duration.");
    }
    opponentCard.isFrozen = true;
    opponentCard.frozenTurnsRemaining = FROZEN_DURATION_TURNS;
    logCallback("${opponentCard.name} is Frozen for ${opponentCard.frozenTurnsRemaining} turns. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Lucky Coin
  static bool activateLuckyCoin(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.LUCKY_COIN || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int diceSides = talent.value.toInt(); 
    int roll = _random.nextInt(diceSides) + 1; 
    int multiplier = talent.secondaryValue?.toInt() ?? 3;
    int statBoostAmount = roll * multiplier;
    int statToBoost = _random.nextInt(4); 
    String boostedStatName = "";
    switch (statToBoost) {
      case 0: 
        cardWithTalent.maxHp += statBoostAmount;
        cardWithTalent.currentHp += statBoostAmount; 
        boostedStatName = "Max HP";
        break;
      case 1: 
        cardWithTalent.attack += statBoostAmount;
        boostedStatName = "ATK";
        break;
      case 2: 
        cardWithTalent.defense += statBoostAmount;
        boostedStatName = "DEF";
        break;
      case 3: 
        cardWithTalent.speed += statBoostAmount;
        boostedStatName = "SPD";
        break;
    }
    logCallback("${cardWithTalent.name} uses ${talent.name}! Rolled a $roll. $boostedStatName increased by $statBoostAmount. Current $boostedStatName: ${statToBoost == 0 ? cardWithTalent.maxHp : (statToBoost == 1 ? cardWithTalent.attack : (statToBoost == 2 ? cardWithTalent.defense : cardWithTalent.speed))}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Mana Reaver
  static bool activateManaReaver(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.MANA_REAVER || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int manaToAbsorbMax = (opponentCard.currentMana * talent.value).round(); 
    int manaAbsorbed = manaToAbsorbMax.clamp(0, opponentCard.currentMana); 
    opponentCard.currentMana -= manaAbsorbed;
    if (opponentCard.currentMana < 0) opponentCard.currentMana = 0;
    cardWithTalent.currentMana += manaAbsorbed;
    if (cardWithTalent.currentMana > cardWithTalent.maxMana) {
      cardWithTalent.currentMana = cardWithTalent.maxMana;
    }
    int damageMultiplier = talent.secondaryValue?.toInt() ?? 10;
    int damageDealt = manaAbsorbed * damageMultiplier;
    if (damageDealt < 0) damageDealt = 0; 
    opponentCard.takeDamage(damageDealt); 
    logCallback("${cardWithTalent.name} uses ${talent.name}! Absorbed $manaAbsorbed mana from ${opponentCard.name} and dealt $damageDealt True damage. ${cardWithTalent.name} Mana: ${cardWithTalent.currentMana}, ${opponentCard.name} Mana: ${opponentCard.currentMana}, HP: ${opponentCard.currentHp}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Paralysis
  static bool activateParalysis(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.PARALYSIS || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    int defReduction = (opponentCard.defense * (talent.secondaryValue ?? 0.10)).round();
    opponentCard.defense = (opponentCard.defense - defReduction).clamp(1, opponentCard.originalDefense * 3); 
    logCallback("${cardWithTalent.name} uses ${talent.name} on ${opponentCard.name}! Enemy DEF permanently reduced by $defReduction to ${opponentCard.defense}.");
    if (_random.nextDouble() < talent.value) { 
      opponentCard.isStunned = true;
      logCallback("${opponentCard.name} is Stunned and will miss their next turn!");
    } else {
      logCallback("${opponentCard.name} resisted the Stun from ${talent.name}.");
    }
    logCallback("Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Offensive Stance
  static bool activateOffensiveStance(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.OFFENSIVE_STANCE || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    if (cardWithTalent.isOffensiveStanceActive) {
      _revertOffensiveStance(cardWithTalent, logCallback, false); 
    }
    int atkBoost = (cardWithTalent.originalAttack * talent.value).round(); 
    cardWithTalent.attack = cardWithTalent.originalAttack + atkBoost;
    int defDecrease = (cardWithTalent.originalDefense * (talent.secondaryValue ?? 0.10)).round(); 
    cardWithTalent.defense = (cardWithTalent.originalDefense - defDecrease).clamp(0, cardWithTalent.originalDefense * 3); 
    cardWithTalent.isOffensiveStanceActive = true;
    cardWithTalent.offensiveStanceTurnsRemaining = OFFENSIVE_STANCE_DURATION_TURNS;
    logCallback(
        "${cardWithTalent.name} uses ${talent.name}! ATK +${(talent.value * 100).toStringAsFixed(0)}% to ${cardWithTalent.attack}, "
        "DEF -${((talent.secondaryValue ?? 0.10) * 100).toStringAsFixed(0)}% to ${cardWithTalent.defense} "
        "for ${cardWithTalent.offensiveStanceTurnsRemaining} turns. Mana cost: ${talent.manaCost}."
    );
    return true;
  }

  // Activates Ultimate Combo
  static bool activateUltimateCombo(Card cardWithTalent, Card opponentCard, List<Card> alliedTeam, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.ULTIMATE_COMBO || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;

    int totalTeamFightingCounters = 0;
    for (var ally in alliedTeam) {
      totalTeamFightingCounters += ally.fightingCounter;
    }

    int damageDealt;

    if (totalTeamFightingCounters >= ULTIMATE_COMBO_EMPOWERED_THRESHOLD) {
      // Empowered Mode
      damageDealt = (opponentCard.maxHp * (talent.secondaryValue ?? 0.30)).round();
      opponentCard.takeDamage(damageDealt);
      logCallback("${cardWithTalent.name} unleashes an Empowered ${talent.name} (Team Counters: $totalTeamFightingCounters)! Deals $damageDealt True damage to ${opponentCard.name}.");
      cardWithTalent.fightingCounter = 0; // Reset caster's counters
      logCallback("${cardWithTalent.name}'s Fighting Counters reset to 0.");
    } else {
      // Normal Mode
      cardWithTalent.fightingCounter += ULTIMATE_COMBO_COUNTER_INCREMENT;
      damageDealt = (cardWithTalent.speed * cardWithTalent.fightingCounter * talent.value).round();
      if (damageDealt < 1 && cardWithTalent.fightingCounter > 0) damageDealt = 1;
      opponentCard.takeDamage(damageDealt);
      logCallback("${cardWithTalent.name} uses ${talent.name}! Deals $damageDealt True damage to ${opponentCard.name}. ${cardWithTalent.name}'s Fighting Counters: ${cardWithTalent.fightingCounter}.");
    }

    logCallback("${opponentCard.name} HP: ${opponentCard.currentHp}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Vengeance
  static bool activateVengeance(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.VENGEANCE || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;

    int opponentHighestStat = opponentCard.attack;
    String statSource = "ATK";
    if (opponentCard.defense > opponentHighestStat) {
      opponentHighestStat = opponentCard.defense;
      statSource = "DEF";
    }
    if (opponentCard.speed > opponentHighestStat) {
      opponentHighestStat = opponentCard.speed;
      statSource = "SPD";
    }

    int damageDealt = (opponentHighestStat * talent.value).round(); // talent.value should be 0.11
    if (damageDealt < 1) damageDealt = 1;
    opponentCard.takeDamage(damageDealt);
    logCallback("${cardWithTalent.name} uses ${talent.name}! Deals $damageDealt True damage to ${opponentCard.name} (based on opponent's $statSource: $opponentHighestStat). ${opponentCard.name} HP: ${opponentCard.currentHp}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Trick Room (ATK variant)
  static bool activateTrickRoomAtk(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.TRICK_ROOM_ATK || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }

    if (opponentCard.attack <= cardWithTalent.attack) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but ${opponentCard.name}'s ATK (${opponentCard.attack}) is not higher than theirs (${cardWithTalent.attack}).");
      // Optionally, still consume mana or return false earlier to prevent mana consumption. For now, let's say it fails but mana is spent.
      cardWithTalent.currentMana -= talent.manaCost;
      return true; // Skill "used" but had no effect due to condition
    }
    
    // Store stats *before* any TR modifications from this activation for damage calculation
    int opponentCurrentAttackBeforeDebuff = opponentCard.attack;
    int casterCurrentAttackBeforeBuff = cardWithTalent.attack;
    int casterOriginalAttack = cardWithTalent.originalAttack;

    cardWithTalent.currentMana -= talent.manaCost; // Consume mana

    // --- Calculate and Deal Damage First ---
    int atkDifferenceForDamage = opponentCurrentAttackBeforeDebuff - casterCurrentAttackBeforeBuff;
    double term1DamageCalc = atkDifferenceForDamage * 1.08;
    double damageFactor = (term1DamageCalc + casterOriginalAttack) * casterOriginalAttack;
    int damageDealt = (damageFactor * TRICK_ROOM_ATK_DAMAGE_SCALING_FACTOR_K).round();
    if (damageDealt < 1 && damageFactor > 0) damageDealt = 1;

    opponentCard.takeDamage(damageDealt);
    logCallback("${cardWithTalent.name}'s ${talent.name} deals $damageDealt True damage to ${opponentCard.name}. Opponent HP: ${opponentCard.currentHp}.");

    // Revert previous TR_ATK if active on caster
    if (cardWithTalent.isTrickRoomAtkActive) {
      cardWithTalent.attack -= cardWithTalent.trickRoomAtkBuffDebuffAmount;
      logCallback("${cardWithTalent.name}'s previous Trick Room ATK buff fades. ATK back to ${cardWithTalent.attack}.");
    }
    // Revert previous TR_ATK if active on opponent (applied by this caster or another TR_ATK user)
    if (opponentCard.isTrickRoomAtkActive) {
       opponentCard.attack += opponentCard.trickRoomAtkBuffDebuffAmount; // Add back what was debuffed
       logCallback("${opponentCard.name}'s previous Trick Room ATK debuff fades. ATK back to ${opponentCard.attack}.");
    }

    // Use the initially captured opponent attack for difference calculation if it changed due to damage (though it shouldn't for True Damage)
    // Or, more simply, use the current opponentCard.attack if the damage step doesn't alter its attack stat.
    // For stat steal, the difference is based on current states *after* damage but *before* this skill's stat manipulation.
    int atkDifferenceForStatSteal = opponentCard.attack - cardWithTalent.attack; // Opponent's ATK might be same as before if damage didn't kill/trigger other effects
                                                                                // Caster's ATK is also pre-buff for this calculation.
    
    double percentage = (cardWithTalent.rarity == CardRarity.ULTRA_RARE) ? (talent.secondaryValue ?? 1.05) : talent.value; // 0.90 or 1.05
    int statChangeAmount = (atkDifferenceForStatSteal * percentage).round();
    if (statChangeAmount <= 0) statChangeAmount = 1; // Ensure at least 1 stat point is changed

    cardWithTalent.attack += statChangeAmount;
    cardWithTalent.trickRoomAtkBuffDebuffAmount = statChangeAmount;
    cardWithTalent.isTrickRoomAtkActive = true;

    opponentCard.attack -= statChangeAmount;
    if (opponentCard.attack < 0) opponentCard.attack = 0; // Prevent negative ATK
    opponentCard.trickRoomAtkBuffDebuffAmount = statChangeAmount; // Store the amount debuffed
    opponentCard.isTrickRoomAtkActive = true; // Mark opponent as affected

    cardWithTalent.trickRoomEffectTurnsRemaining = TRICK_ROOM_EFFECT_DURATION_TURNS;
    opponentCard.trickRoomEffectTurnsRemaining = TRICK_ROOM_EFFECT_DURATION_TURNS; // Both affected for same duration

    logCallback("As part of ${talent.name}: ${cardWithTalent.name} ATK +$statChangeAmount to ${cardWithTalent.attack}. ${opponentCard.name} ATK -$statChangeAmount to ${opponentCard.attack}. Effect lasts $TRICK_ROOM_EFFECT_DURATION_TURNS turns. Mana cost: ${talent.manaCost}.");

    return true;
  }

  // Activates Trick Room (DEF variant)
  static bool activateTrickRoomDef(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.TRICK_ROOM_DEF || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) {
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }

    if (opponentCard.defense <= cardWithTalent.defense) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but ${opponentCard.name}'s DEF (${opponentCard.defense}) is not higher than theirs (${cardWithTalent.defense}).");
      cardWithTalent.currentMana -= talent.manaCost;
      return true; 
    }
    cardWithTalent.currentMana -= talent.manaCost;

    // Revert previous TR_DEF if active (similar to ATK version)
    if (cardWithTalent.isTrickRoomDefActive) cardWithTalent.defense -= cardWithTalent.trickRoomDefBuffDebuffAmount;
    if (opponentCard.isTrickRoomDefActive) opponentCard.defense += opponentCard.trickRoomDefBuffDebuffAmount;

    int defDifference = opponentCard.defense - cardWithTalent.defense;
    double percentage = (cardWithTalent.rarity == CardRarity.ULTRA_RARE) ? (talent.secondaryValue ?? 1.05) : talent.value;
    int statChangeAmount = (defDifference * percentage).round();
    if (statChangeAmount <= 0) statChangeAmount = 1;

    cardWithTalent.defense += statChangeAmount;
    cardWithTalent.trickRoomDefBuffDebuffAmount = statChangeAmount;
    cardWithTalent.isTrickRoomDefActive = true;

    opponentCard.defense -= statChangeAmount;
    if (opponentCard.defense < 0) opponentCard.defense = 0;
    opponentCard.trickRoomDefBuffDebuffAmount = statChangeAmount;
    opponentCard.isTrickRoomDefActive = true;

    cardWithTalent.trickRoomEffectTurnsRemaining = TRICK_ROOM_EFFECT_DURATION_TURNS;
    opponentCard.trickRoomEffectTurnsRemaining = TRICK_ROOM_EFFECT_DURATION_TURNS;

    logCallback("${cardWithTalent.name} uses ${talent.name}! ${cardWithTalent.name} DEF +$statChangeAmount to ${cardWithTalent.defense}. ${opponentCard.name} DEF -$statChangeAmount to ${opponentCard.defense}. Effect lasts $TRICK_ROOM_EFFECT_DURATION_TURNS turns. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Activates Restricted Instinct (Silence)
  static bool activateRestrictedInstinct(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.RESTRICTED_INSTINCT || cardWithTalent.currentHp <= 0) {
      return false;
    }
    if (cardWithTalent.isSilenced) { 
      logCallback("${cardWithTalent.name} is Silenced and cannot use ${cardWithTalent.talent!.name}!");
      return false;
    }
    final talent = cardWithTalent.talent!;
    if (cardWithTalent.currentMana < talent.manaCost) {
      logCallback("${cardWithTalent.name} tries to use ${talent.name}, but not enough mana (${cardWithTalent.currentMana}/${talent.manaCost}).");
      return false;
    }
    cardWithTalent.currentMana -= talent.manaCost;
    double enemyResistChance = talent.value; 
    if (_random.nextDouble() < enemyResistChance) {
      logCallback("${opponentCard.name} resisted ${talent.name}!");
    } else {
      opponentCard.isSilenced = true;
      opponentCard.silenceTurnsRemaining = talent.secondaryValue?.toInt() ?? RESTRICTED_INSTINCT_DURATION_TURNS;
      logCallback("${opponentCard.name} is Silenced by ${talent.name} for ${opponentCard.silenceTurnsRemaining} turns!");
    }
    logCallback("${cardWithTalent.name} used ${talent.name}. Mana cost: ${talent.manaCost}.");
    return true;
  }

  // Handles YinYang rotation at the start of a card's turn or round
  static void rotateYinYangBuff(Card card, Function(String) logCallback) {
    if (card.talent?.type != TalentType.YIN_YANG) return; 

    final talent = card.talent!;
    card.isYangBuffActive = !card.isYangBuffActive; 

    card.attack = card.originalAttack;
    card.defense = card.originalDefense;

    if (card.isYangBuffActive) { 
      int defenseBoost = (card.originalDefense * talent.value).round();
      card.defense = card.originalDefense + defenseBoost;
      logCallback("${card.name}'s ${talent.name} (Yang Active): Defense increased by $defenseBoost to ${card.defense}. Attack is ${card.attack}.");
    } else { 
      int attackBoost = (card.originalAttack * talent.value).round();
      card.attack = card.originalAttack + attackBoost;
      logCallback("${card.name}'s ${talent.name} (Yin Active): Attack increased by $attackBoost to ${card.attack}. Defense is ${card.defense}.");
    }
  }

  // Applies talents that trigger upon dealing damage (e.g., Lifesteal)
  static bool activateOnDealDamageTalents(Card attacker, int damageDealt, Function(String) logCallback) {
    if (attacker.talent == null || damageDealt <= 0) return false;

    final talent = attacker.talent!;
    double totalLifestealPercent = 0;

    switch (talent.type) {
      case TalentType.BLOODTHIRSTER: 
        if (talent.manaCost == 0) {
          totalLifestealPercent += talent.value;
        }
        break;
      default:
        break;
    }
    totalLifestealPercent += attacker.currentLifestealBonus;

    if (totalLifestealPercent > 0) {
      int healAmount = (damageDealt * totalLifestealPercent).round();
      if (healAmount < 1 && totalLifestealPercent > 0) healAmount = 1; 
      if (healAmount > 0) { 
        attacker.heal(healAmount);
        logCallback("${attacker.name} lifesteals $healAmount HP! (Total Lifesteal: ${(totalLifestealPercent * 100).toStringAsFixed(0)}%)");
          return true;
      }
    }
    return false;
  }

  // Applies talents that have effects at the end of each round (e.g., Overload decay)
  static void applyRoundEndTalentEffects(Card cardWithTalent, Card opponentCard, int currentRound, Function(String) logCallback) {
    if (cardWithTalent.talent == null || cardWithTalent.currentHp <= 0) return;

    final talent = cardWithTalent.talent!;
    switch (talent.type) {
      case TalentType.OVERLOAD:
        if (currentRound > 0) { 
          int attackDecrease = (cardWithTalent.originalAttack * 0.10).round();
          cardWithTalent.attack = (cardWithTalent.attack - attackDecrease).clamp(0, cardWithTalent.originalAttack * 2); 
          logCallback("${cardWithTalent.name}'s ${talent.name} causes ATK to decrease by $attackDecrease to ${cardWithTalent.attack}.");
        }
        break;
      case TalentType.GRIEVOUS_LIMITER: 
        if (cardWithTalent.isUnderGrievousLimiterDebuff) {
          int recoveryAmount = (cardWithTalent.originalAttack * 0.10).round(); 
          cardWithTalent.attack = (cardWithTalent.attack + recoveryAmount).clamp(0, cardWithTalent.originalAttack);
          logCallback("${cardWithTalent.name} recovers from Grievous Limiter, ATK +$recoveryAmount to ${cardWithTalent.attack}.");
          if (cardWithTalent.attack >= cardWithTalent.originalAttack) {
            cardWithTalent.isUnderGrievousLimiterDebuff = false;
            logCallback("${cardWithTalent.name} has fully recovered from Grievous Limiter. ATK restored to ${cardWithTalent.originalAttack}.");
          }
        }
        break;
      case TalentType.POISON: 
        if (cardWithTalent.isPoisoned) {
          if (cardWithTalent.poisonTurnsRemaining > 0) {
            logCallback("${cardWithTalent.name} is Poisoned (${cardWithTalent.poisonTurnsRemaining} turns left).");
            if (_random.nextDouble() < POISON_RESIST_CHANCE) {
              logCallback("${cardWithTalent.name} resisted Poison damage this turn!");
            } else {
              int damageFromPercent = (cardWithTalent.poisonCasterAttack * cardWithTalent.poisonPercentDamage).round();
              int totalPoisonDamage = cardWithTalent.poisonFlatDamage + damageFromPercent;
              if (totalPoisonDamage < 1) totalPoisonDamage = 1; 
              cardWithTalent.takeDamage(totalPoisonDamage);
              logCallback("${cardWithTalent.name} takes $totalPoisonDamage True damage from Poison.");
            }
            cardWithTalent.poisonTurnsRemaining--;
            if (cardWithTalent.poisonTurnsRemaining <= 0) {
              _clearPoisonStatus(cardWithTalent, logCallback);
            }
          } else { 
            _clearPoisonStatus(cardWithTalent, logCallback);
          }
        }
        break;
      case TalentType.DIVINE_BLESSING:
        if (cardWithTalent.isDivineBlessingActive) {
          cardWithTalent.divineBlessingTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Divine Blessing: ${cardWithTalent.divineBlessingTurnsRemaining} turns remaining.");
          if (cardWithTalent.divineBlessingTurnsRemaining <= 0) {
            cardWithTalent.isDivineBlessingActive = false;
            double buffPercent = 0;
            if (cardWithTalent.rarity == CardRarity.SUPER_RARE) {
              buffPercent = talent.value;
            } else if (cardWithTalent.rarity == CardRarity.ULTRA_RARE) {
              buffPercent = talent.secondaryValue ?? talent.value;
            }
            if (buffPercent > 0) {
              int atkRevert = (cardWithTalent.originalAttack * buffPercent).round();
              int defRevert = (cardWithTalent.originalDefense * buffPercent).round();
              cardWithTalent.attack = (cardWithTalent.attack - atkRevert).clamp(0, cardWithTalent.originalAttack * 3); 
              cardWithTalent.defense = (cardWithTalent.defense - defRevert).clamp(0, cardWithTalent.originalDefense * 3);
              logCallback("${cardWithTalent.name}'s Divine Blessing has worn off. Stats reverted. (ATK: ${cardWithTalent.attack}, DEF: ${cardWithTalent.defense})");
            }
          }
        }
        break;
      case TalentType.LIFE_SAP:
        if (talent.manaCost == 0 && opponentCard.currentHp > 0) { 
          double sapPercent = 0;
          if (cardWithTalent.rarity == CardRarity.SUPER_RARE) {
            sapPercent = talent.value; 
          } else if (cardWithTalent.rarity == CardRarity.ULTRA_RARE) sapPercent = talent.secondaryValue ?? talent.value; 
          if (sapPercent > 0) {
            int damageDealt = (opponentCard.maxHp * sapPercent).round();
            if (damageDealt < 1) damageDealt = 1; 
            opponentCard.takeDamage(damageDealt);
            cardWithTalent.heal(damageDealt); 
            logCallback("${cardWithTalent.name}'s Life Sap deals $damageDealt damage to ${opponentCard.name} and heals for $damageDealt HP. ${opponentCard.name} HP: ${opponentCard.currentHp}");
          }
        }
        break;
      case TalentType.RECOIL: 
        if (cardWithTalent.recoilSourceMaxHpForSelf > 0) {
          int selfDamage = (cardWithTalent.recoilSourceMaxHpForSelf * talent.value).round(); 
          if (selfDamage < 1 && talent.value > 0) selfDamage = 1;
          cardWithTalent.takeDamage(selfDamage);
          logCallback("${cardWithTalent.name} takes $selfDamage recoil damage (self). HP: ${cardWithTalent.currentHp}");
        }
        if (cardWithTalent.isTakingRecoilDamageFromOpponent && cardWithTalent.recoilDamageSourceMaxHpFromOpponent > 0) {
          int incomingDamage = (cardWithTalent.recoilDamageSourceMaxHpFromOpponent * talent.value).round(); 
          if (incomingDamage < 1 && talent.value > 0) incomingDamage = 1;
          cardWithTalent.takeDamage(incomingDamage);
          logCallback("${cardWithTalent.name} takes $incomingDamage recoil damage (from ${opponentCard.name}). HP: ${cardWithTalent.currentHp}");
        }
        break;
      case TalentType.SOUL_STEALER:
        if (talent.manaCost == 0 && opponentCard.currentHp > 0 && opponentCard.defense > 0) {
          double absorbPercent = 0;
          if (cardWithTalent.rarity == CardRarity.SUPER_RARE) {
            absorbPercent = talent.value; 
          } else if (cardWithTalent.rarity == CardRarity.ULTRA_RARE) {
            absorbPercent = talent.secondaryValue ?? talent.value; 
          }
          if (absorbPercent > 0) {
            int defStolen = (opponentCard.defense * absorbPercent).round();
            if (defStolen < 1 && opponentCard.defense > 0 && absorbPercent > 0) defStolen = 1; 
            opponentCard.defense = (opponentCard.defense - defStolen).clamp(0, opponentCard.originalDefense * 3); 
            cardWithTalent.attack += defStolen; 
            logCallback("${cardWithTalent.name}'s Soul Stealer absorbs $defStolen DEF from ${opponentCard.name} and converts it to ATK. ${cardWithTalent.name} ATK: ${cardWithTalent.attack}, ${opponentCard.name} DEF: ${opponentCard.defense}.");
          }
        }
        break;
      case TalentType.TEMPORAL_REWIND:
        if (cardWithTalent.isTemporalRewindActive) {
          cardWithTalent.temporalRewindTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Temporal Rewind: ${cardWithTalent.temporalRewindTurnsRemaining} turns remaining.");
          if (cardWithTalent.temporalRewindTurnsRemaining <= 0) {
            int hpDifference = cardWithTalent.temporalRewindInitialHpAtBuff - cardWithTalent.currentHp;
            int amountToRestoreAndDeal = (hpDifference / 2).round();
            if (amountToRestoreAndDeal > 0) { 
              cardWithTalent.heal(amountToRestoreAndDeal);
              opponentCard.takeDamage(amountToRestoreAndDeal);
              logCallback("${cardWithTalent.name}'s Temporal Rewind triggers! Restores $amountToRestoreAndDeal HP. Deals $amountToRestoreAndDeal damage to ${opponentCard.name}. ${cardWithTalent.name} HP: ${cardWithTalent.currentHp}, ${opponentCard.name} HP: ${opponentCard.currentHp}");
            } else {
              logCallback("${cardWithTalent.name}'s Temporal Rewind triggers, but no HP to restore/damage to deal (HP difference was not positive).");
            }
            cardWithTalent.isTemporalRewindActive = false;
            cardWithTalent.temporalRewindInitialHpAtBuff = 0;
          }
        }
        break;
      case TalentType.AMPLIFIER:
        if (cardWithTalent.isAmplifierBuffActive) {
          cardWithTalent.amplifierTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Amplifier: ${cardWithTalent.amplifierTurnsRemaining} turns remaining.");
          if (cardWithTalent.amplifierTurnsRemaining <= 0) {
            int atkRevert = (cardWithTalent.originalAttack * talent.value).round();
            int defRevert = (cardWithTalent.originalDefense * talent.value).round();
            cardWithTalent.attack = (cardWithTalent.attack - atkRevert).clamp(0, cardWithTalent.originalAttack * 3);
            cardWithTalent.defense = (cardWithTalent.defense - defRevert).clamp(0, cardWithTalent.originalDefense * 3);
            cardWithTalent.isAmplifierBuffActive = false;
            logCallback("${cardWithTalent.name}'s Amplifier has worn off. Stats reverted. ATK: ${cardWithTalent.attack}, DEF: ${cardWithTalent.defense}.");
          }
        }
        break;
      case TalentType.BLAZE: 
        if (cardWithTalent.isUnderBurnDebuff) {
          if (cardWithTalent.burnDurationTurns > 0) {
            if (_random.nextDouble() < BURN_RESIST_CHANCE) {
              logCallback("${cardWithTalent.name} resists Burn damage this turn!");
            } else {
              int damageDealt = (cardWithTalent.burnStacks * cardWithTalent.burnDamagePerStackPercent * cardWithTalent.burnCasterAttack).round();
              if (damageDealt < 1 && cardWithTalent.burnStacks > 0 && cardWithTalent.burnDamagePerStackPercent > 0) damageDealt = 1;
              cardWithTalent.takeDamage(damageDealt);
              logCallback("${cardWithTalent.name} takes $damageDealt True damage from Burn (Stacks: ${cardWithTalent.burnStacks}, Source ATK: ${cardWithTalent.burnCasterAttack}).");
            }
            cardWithTalent.burnDurationTurns--;
            if (cardWithTalent.burnDurationTurns <= 0) {
                cardWithTalent.isUnderBurnDebuff = false;
                cardWithTalent.burnStacks = 0; 
                cardWithTalent.burnCasterAttack = 0;
                cardWithTalent.burnDamagePerStackPercent = 0.0;
                cardWithTalent.burnHealingReductionPercent = 0.0;
                logCallback("${cardWithTalent.name}'s Burn has expired (duration ended).");
            }
          } 
        }
        break;
      case TalentType.ENDURANCE:
        if (cardWithTalent.isEnduranceBuffActive) {
          cardWithTalent.enduranceTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Endurance: ${cardWithTalent.enduranceTurnsRemaining} turns remaining.");
          if (cardWithTalent.enduranceTurnsRemaining <= 0) {
            cardWithTalent.isEnduranceBuffActive = false;
            cardWithTalent.enduranceDamageReductionPercent = 0.0;
            logCallback("${cardWithTalent.name}'s Endurance buff has worn off.");
          }
        }
        break;
      case TalentType.EVASION:
        if (cardWithTalent.evasionBuffTurnsRemaining > 0) {
          cardWithTalent.evasionBuffTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Evasion buff: ${cardWithTalent.evasionBuffTurnsRemaining} turns remaining.");
          if (cardWithTalent.evasionBuffTurnsRemaining <= 0) {
            cardWithTalent.currentEvasionChance = 0.0;
            cardWithTalent.evasionStacks = 0;
            logCallback("${cardWithTalent.name}'s Evasion buff has worn off.");
          }
        }
        break;
      case TalentType.FREEZE: 
        if (cardWithTalent.isFrozen) {
          cardWithTalent.frozenTurnsRemaining--;
          logCallback("${cardWithTalent.name} (Frozen): ${cardWithTalent.frozenTurnsRemaining} turns of SPD debuff remaining.");
          if (cardWithTalent.frozenTurnsRemaining <= 0) {
            int spdRestore = (cardWithTalent.originalSpeed * cardWithTalent.frozenSpeedReductionPercent).round();
            cardWithTalent.speed = (cardWithTalent.speed + spdRestore).clamp(1, cardWithTalent.originalSpeed * 3);
            cardWithTalent.isFrozen = false;
            cardWithTalent.frozenSpeedReductionPercent = 0.0;
            logCallback("${cardWithTalent.name} is no longer Frozen. SPD restored to ${cardWithTalent.speed}. (ATK reduction is permanent)");
          }
        }
        break;
      case TalentType.OFFENSIVE_STANCE:
        if (cardWithTalent.isOffensiveStanceActive) {
          cardWithTalent.offensiveStanceTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Offensive Stance: ${cardWithTalent.offensiveStanceTurnsRemaining} turns remaining.");
          if (cardWithTalent.offensiveStanceTurnsRemaining <= 0) {
            _revertOffensiveStance(cardWithTalent, logCallback, true);
          }
        }
        break;
      case TalentType.REGENERATION: 
        if (cardWithTalent.isRegenerationBuffActive) {
          if (cardWithTalent.currentHp > 0 && cardWithTalent.currentHp < cardWithTalent.maxHp) {
            cardWithTalent.heal(cardWithTalent.regenerationHealPerTurn);
            logCallback("${cardWithTalent.name} regenerates ${cardWithTalent.regenerationHealPerTurn} HP from Regeneration buff.");
          }
          cardWithTalent.regenerationTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Regeneration buff: ${cardWithTalent.regenerationTurnsRemaining} turns remaining.");
          if (cardWithTalent.regenerationTurnsRemaining <= 0) {
            _revertRegenerationBuff(cardWithTalent, logCallback);
          }
        }
        break;
      case TalentType.PRECISION:
        if (cardWithTalent.isPrecisionBuffActive) {
          cardWithTalent.precisionTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Precision: ${cardWithTalent.precisionTurnsRemaining} turns remaining.");
          if (cardWithTalent.precisionTurnsRemaining <= 0) {
            _revertPrecisionBuff(cardWithTalent, logCallback);
          }
        }
        break;
      case TalentType.PAIN_FOR_POWER:
        if (cardWithTalent.isPainForPowerBuffActive) {
          cardWithTalent.painForPowerTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Pain For Power: ${cardWithTalent.painForPowerTurnsRemaining} turns remaining.");
          if (cardWithTalent.painForPowerTurnsRemaining <= 0) {
            _revertPainForPowerBuff(cardWithTalent, logCallback, true);
          }
        }
        break;
      case TalentType.RESTRICTED_INSTINCT: 
        if (cardWithTalent.isSilenced) {
          cardWithTalent.silenceTurnsRemaining--;
          logCallback("${cardWithTalent.name} (Silenced): ${cardWithTalent.silenceTurnsRemaining} turns remaining.");
          if (cardWithTalent.silenceTurnsRemaining <= 0) {
            cardWithTalent.isSilenced = false;
            logCallback("${cardWithTalent.name} is no longer Silenced.");
          }
        }
        break;
      case TalentType.TIME_BOMB: // This is for the card *affected* by Time Bomb
        if (cardWithTalent.isTimeBombActive) {
          cardWithTalent.timeBombTurnsRemaining--;
          logCallback("${cardWithTalent.name}'s Time Bomb: ${cardWithTalent.timeBombTurnsRemaining} turn(s) remaining.");
          if (cardWithTalent.timeBombTurnsRemaining <= 0) {
            logCallback("${cardWithTalent.name}'s Time Bomb explodes for ${cardWithTalent.timeBombDamage} True damage!");
            cardWithTalent.takeDamage(cardWithTalent.timeBombDamage);
            cardWithTalent.isTimeBombActive = false;
            cardWithTalent.timeBombDamage = 0;
            logCallback("${cardWithTalent.name} HP: ${cardWithTalent.currentHp}.");
          }
        }
        break;
      case TalentType.TRICK_ROOM_ATK:
      case TalentType.TRICK_ROOM_DEF:
        if (cardWithTalent.isTrickRoomAtkActive || cardWithTalent.isTrickRoomDefActive) {
          cardWithTalent.trickRoomEffectTurnsRemaining--;
          logCallback("${cardWithTalent.name} (Trick Room Effect): ${cardWithTalent.trickRoomEffectTurnsRemaining} turns remaining.");
          if (cardWithTalent.trickRoomEffectTurnsRemaining <= 0) {
            if (cardWithTalent.isTrickRoomAtkActive) {
              cardWithTalent.attack -= cardWithTalent.trickRoomAtkBuffDebuffAmount;
              cardWithTalent.isTrickRoomAtkActive = false;
              cardWithTalent.trickRoomAtkBuffDebuffAmount = 0;
              logCallback("${cardWithTalent.name}'s Trick Room ATK effect fades. ATK reverted to ${cardWithTalent.attack}.");
            }
            if (cardWithTalent.isTrickRoomDefActive) {
              cardWithTalent.defense -= cardWithTalent.trickRoomDefBuffDebuffAmount;
              cardWithTalent.isTrickRoomDefActive = false;
              cardWithTalent.trickRoomDefBuffDebuffAmount = 0;
              logCallback("${cardWithTalent.name}'s Trick Room DEF effect fades. DEF reverted to ${cardWithTalent.defense}.");
            }
          }
        }
        break;

      default:
        break;
    }
  }

  // Helper to revert Regeneration buff effects
  static void _revertRegenerationBuff(Card cardAffected, Function(String) logCallback) {
    if (!cardAffected.isRegenerationBuffActive) return;
    cardAffected.isRegenerationBuffActive = false;
    cardAffected.regenerationHealPerTurn = 0;
    logCallback("${cardAffected.name}'s Regeneration buff has worn off.");
  }

  // Helper to revert Precision buff effects
  static void _revertPrecisionBuff(Card cardAffected, Function(String) logCallback) {
    if (!cardAffected.isPrecisionBuffActive) return;
    cardAffected.isPrecisionBuffActive = false;
    cardAffected.precisionCritChanceBonus = 0.0;
    cardAffected.precisionCritDamageBonus = 0.0;
    logCallback("${cardAffected.name}'s Precision buff has worn off. Crit bonuses removed.");
  }

  // Helper to revert Pain For Power buff effects
  static void _revertPainForPowerBuff(Card cardAffected, Function(String) logCallback, bool logExpiry) {
    if (!cardAffected.isPainForPowerBuffActive && !logExpiry) return;
    final Talent? talent = cardAffected.talent;
    if (talent != null && talent.type == TalentType.PAIN_FOR_POWER) {
      cardAffected.attack = cardAffected.originalAttack;
      cardAffected.speed = cardAffected.originalSpeed;
    }
    cardAffected.isPainForPowerBuffActive = false;
    if (logExpiry) {
      logCallback("${cardAffected.name}'s Pain For Power buff has worn off. Stats reverted. ATK: ${cardAffected.attack}, SPD: ${cardAffected.speed}.");
    }
  }

  // Helper to clear Poison status
  static void _clearPoisonStatus(Card cardAffected, Function(String) logCallback) {
    cardAffected.isPoisoned = false;
    cardAffected.poisonFlatDamage = 0;
    cardAffected.poisonPercentDamage = 0.0;
    cardAffected.poisonCasterAttack = 0;
    logCallback("${cardAffected.name} is no longer Poisoned.");
  }

  // Helper to revert Offensive Stance effects
  static void _revertOffensiveStance(Card cardAffected, Function(String) logCallback, bool logExpiry) {
    if (!cardAffected.isOffensiveStanceActive && !logExpiry) return; 
    final Talent? talent = cardAffected.talent; 
    if (talent != null && talent.type == TalentType.OFFENSIVE_STANCE) {
        cardAffected.attack = (cardAffected.originalAttack).clamp(0, cardAffected.originalAttack * 3); 
        cardAffected.defense = (cardAffected.originalDefense).clamp(0, cardAffected.originalDefense * 3); 
    }
    cardAffected.isOffensiveStanceActive = false;
    if (logExpiry) {
      logCallback("${cardAffected.name}'s Offensive Stance has worn off. Stats reverted. ATK: ${cardAffected.attack}, DEF: ${cardAffected.defense}.");
    }
  }

  // Checks and applies/removes Berserker buff
  static void checkAndApplyBerserker(Card card, Function(String) logCallback) {
    if (card.talent?.type != TalentType.BERSERKER || card.currentHp <= 0) {
      if (card.isBerserkerBuffActive) {
        int attackRevert = (card.originalAttack * card.talent!.value).round();
        int defenseRevert = (card.originalDefense * card.talent!.value).round();
        card.attack = (card.attack - attackRevert).clamp(0, card.originalAttack * 3); 
        card.defense = (card.defense - defenseRevert).clamp(0, card.originalDefense * 3);
        card.isBerserkerBuffActive = false;
        logCallback("${card.name}'s Berserker buff deactivated (KO or talent changed). Stats reverted.");
      }
      return;
    }
    final talent = card.talent!;
    bool hpConditionMet = card.currentHp <= (card.maxHp * 0.45);
    if (hpConditionMet && !card.isBerserkerBuffActive) {
      int attackBoost = (card.originalAttack * talent.value).round();
      int defenseBoost = (card.originalDefense * talent.value).round();
      card.attack += attackBoost;
      card.defense += defenseBoost;
      card.isBerserkerBuffActive = true;
      logCallback("${card.name}'s Berserker activates! ATK +$attackBoost, DEF +$defenseBoost. (HP: ${card.currentHp}/${card.maxHp})");
    } else if (!hpConditionMet && card.isBerserkerBuffActive) {
      int attackRevert = (card.originalAttack * talent.value).round();
      int defenseRevert = (card.originalDefense * talent.value).round();
      card.attack -= attackRevert;
      card.defense -= defenseRevert;
      card.isBerserkerBuffActive = false;
      logCallback("${card.name}'s Berserker deactivates. (HP: ${card.currentHp}/${card.maxHp})");
    }
  }

  // Checks and applies/removes Blood Surge lifesteal buff
  static void checkAndApplyBloodSurgeLifesteal(Card card, Function(String) logCallback) {
    if (card.talent?.type != TalentType.BLOOD_SURGE || card.currentHp <= 0) {
      if (card.isBloodSurgeLifestealActive) {
        card.currentLifestealBonus = 0.0;
        card.isBloodSurgeLifestealActive = false;
        logCallback("${card.name}'s Blood Surge lifesteal deactivated (KO or talent changed).");
      }
      return;
    }
    final talent = card.talent!; 
    bool hpConditionMet = card.currentHp <= (card.maxHp * 0.80); 
    if (hpConditionMet && !card.isBloodSurgeLifestealActive) {
      card.currentLifestealBonus = talent.value; 
      card.isBloodSurgeLifestealActive = true;
      logCallback("${card.name}'s Blood Surge activates! Lifesteal increased by ${(talent.value * 100).toStringAsFixed(0)}%. (HP: ${card.currentHp}/${card.maxHp})");
    } else if (!hpConditionMet && card.isBloodSurgeLifestealActive) {
      card.currentLifestealBonus = 0.0;
      card.isBloodSurgeLifestealActive = false;
      logCallback("${card.name}'s Blood Surge lifesteal deactivates. (HP: ${card.currentHp}/${card.maxHp})");
    }
  }

  // Checks and applies/removes Dominance buff
  static void checkAndApplyDominance(Card card, Card enemyCard, Function(String) logCallback) {
    if (card.talent?.type != TalentType.DOMINANCE || card.currentHp <= 0) {
      if (card.isDominanceBuffActive) {
        double buffPercent = 0;
        if (card.rarity == CardRarity.SUPER_RARE) {
          buffPercent = card.talent!.value;
        } else if (card.rarity == CardRarity.ULTRA_RARE) buffPercent = card.talent!.secondaryValue ?? card.talent!.value;
        if (buffPercent > 0) {
          int atkRevert = (card.originalAttack * buffPercent).round();
          card.attack = (card.attack - atkRevert).clamp(0, card.originalAttack * 3);
        }
        card.isDominanceBuffActive = false;
        logCallback("${card.name}'s Dominance buff deactivated (KO or talent changed). ATK reverted.");
      }
      return;
    }
    final talent = card.talent!;
    double cardHpPercent = card.maxHp > 0 ? card.currentHp / card.maxHp : 0;
    double enemyHpPercent = enemyCard.maxHp > 0 ? enemyCard.currentHp / enemyCard.maxHp : 0;
    bool conditionMet = cardHpPercent >= enemyHpPercent && enemyCard.currentHp > 0; 
    double buffPercent = 0;
    if (card.rarity == CardRarity.SUPER_RARE) {
      buffPercent = talent.value; 
    } else if (card.rarity == CardRarity.ULTRA_RARE) buffPercent = talent.secondaryValue ?? talent.value; 
    if (conditionMet && !card.isDominanceBuffActive && buffPercent > 0) {
      int atkBoost = (card.originalAttack * buffPercent).round();
      card.attack += atkBoost;
      card.isDominanceBuffActive = true;
      logCallback("${card.name}'s Dominance activates! (HP% ${ (cardHpPercent * 100).toStringAsFixed(0)} >= Enemy HP% ${(enemyHpPercent * 100).toStringAsFixed(0)}) ATK +${(buffPercent * 100).toStringAsFixed(0)}% to ${card.attack}.");
    } else if ((!conditionMet || buffPercent == 0) && card.isDominanceBuffActive) {
      int atkRevert = (card.originalAttack * buffPercent).round(); 
      card.attack = (card.attack - atkRevert).clamp(0, card.originalAttack * 3);
      card.isDominanceBuffActive = false;
      logCallback("${card.name}'s Dominance deactivates. (HP% ${(cardHpPercent*100).toStringAsFixed(0)} < Enemy HP% ${(enemyHpPercent*100).toStringAsFixed(0)} or enemy KO'd) ATK reverted to ${card.attack}.");
    }
  }

  // Checks and applies/removes Executioner buff
  static void checkAndApplyExecutioner(Card cardWithTalent, Card enemyCard, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.EXECUTIONER || cardWithTalent.currentHp <= 0) {
      if (cardWithTalent.isExecutionerBuffActive) {
        double buffPercent = 0;
        if (cardWithTalent.rarity == CardRarity.SUPER_RARE) {
          buffPercent = cardWithTalent.talent!.value;
        } else if (cardWithTalent.rarity == CardRarity.ULTRA_RARE) buffPercent = cardWithTalent.talent!.secondaryValue ?? cardWithTalent.talent!.value;
        if (buffPercent > 0) {
          int atkRevert = (cardWithTalent.originalAttack * buffPercent).round();
          cardWithTalent.attack = (cardWithTalent.attack - atkRevert).clamp(0, cardWithTalent.originalAttack * 3);
        }
        cardWithTalent.isExecutionerBuffActive = false;
        logCallback("${cardWithTalent.name}'s Executioner buff deactivated (KO or talent changed). ATK reverted.");
      }
      return;
    }
    final talent = cardWithTalent.talent!;
    bool enemyHpConditionMet = enemyCard.currentHp > 0 && enemyCard.currentHp <= (enemyCard.maxHp * 0.37);
    double buffPercent = 0;
    if (cardWithTalent.rarity == CardRarity.SUPER_RARE) {
      buffPercent = talent.value; 
    } else if (cardWithTalent.rarity == CardRarity.ULTRA_RARE) buffPercent = talent.secondaryValue ?? talent.value; 
    if (enemyHpConditionMet && !cardWithTalent.isExecutionerBuffActive && buffPercent > 0) {
      int atkBoost = (cardWithTalent.originalAttack * buffPercent).round();
      cardWithTalent.attack += atkBoost;
      cardWithTalent.isExecutionerBuffActive = true;
      logCallback("${cardWithTalent.name}'s Executioner activates! (Enemy HP <= 37%) ATK +${(buffPercent * 100).toStringAsFixed(0)}% to ${cardWithTalent.attack}.");
    } else if ((!enemyHpConditionMet || buffPercent == 0) && cardWithTalent.isExecutionerBuffActive) {
      int atkRevert = (cardWithTalent.originalAttack * buffPercent).round(); 
      cardWithTalent.attack = (cardWithTalent.attack - atkRevert).clamp(0, cardWithTalent.originalAttack * 3);
      cardWithTalent.isExecutionerBuffActive = false;
      logCallback("${cardWithTalent.name}'s Executioner deactivates. (Enemy HP > 37% or enemy KO'd) ATK reverted to ${cardWithTalent.attack}.");
    }
  }

  // Applies offensive start-of-battle talents from cardWithTalent to opponentCard
  static void applyOffensiveStartOfBattleTalents(Card cardWithTalent, Card opponentCard, Function(String) logCallback) {
    if (cardWithTalent.talent == null || cardWithTalent.currentHp <= 0 || opponentCard.currentHp <= 0) return;
    final talent = cardWithTalent.talent!;
    switch (talent.type) {
      case TalentType.GRIEVOUS_LIMITER:
        if (talent.manaCost == 0) { 
          int reductionAmount = (opponentCard.originalAttack * talent.value).round(); 
          opponentCard.attack = (opponentCard.attack - reductionAmount).clamp(0, opponentCard.originalAttack * 3);
          opponentCard.isUnderGrievousLimiterDebuff = true;
          logCallback("${cardWithTalent.name}'s Grievous Limiter debuffs ${opponentCard.name}'s ATK by $reductionAmount to ${opponentCard.attack}.");
        }
        break;
      case TalentType.RECOIL:
        if (talent.manaCost == 0) { 
          opponentCard.isTakingRecoilDamageFromOpponent = true;
          opponentCard.recoilDamageSourceMaxHpFromOpponent = cardWithTalent.maxHp; 
          logCallback("${opponentCard.name} will take recoil damage each turn due to ${cardWithTalent.name}'s Recoil talent (based on ${cardWithTalent.name}'s MaxHP: ${cardWithTalent.maxHp}).");
        }
        break;
      default:
        break;
    }
  }

  // Checks and activates Protector talent if conditions are met
  static void checkAndActivateProtector(Card card, Function(String) logCallback) {
    if (card.talent?.type != TalentType.PROTECTOR || card.hasProtectorActivatedThisBattle || card.currentHp <= 0) {
      return;
    }
    final talent = card.talent!;
    bool hpConditionMet = card.currentHp <= (card.maxHp * 0.25);
    if (hpConditionMet) {
      int healAmount = (card.maxHp * talent.value).round(); 
      card.heal(healAmount); 
      logCallback("${card.name}'s Protector activates! Heals for $healAmount HP. (HP: ${card.currentHp}/${card.maxHp})");
      int defBoost = (card.originalDefense * (talent.secondaryValue ?? 0.35)).round(); 
      card.defense += defBoost;
      card.isProtectorDefBuffActive = true; 
      logCallback("${card.name}'s Protector DEF increased by $defBoost to ${card.defense}.");
      card.hasProtectorActivatedThisBattle = true; 
    }
  }

  // Checks if Reversion talent condition is met and marks it as activated.
  static bool checkReversionCondition(Card cardWithTalent, Function(String) logCallback) {
    if (cardWithTalent.talent?.type != TalentType.REVERSION || 
        cardWithTalent.hasReversionActivatedThisBattle || 
        cardWithTalent.currentHp <= 0) {
      return false;
    }
    final talent = cardWithTalent.talent!; 
    if (cardWithTalent.currentHp <= (cardWithTalent.maxHp * talent.value)) {
      logCallback("${cardWithTalent.name}'s Reversion condition met! (HP <= ${(talent.value * 100).toStringAsFixed(0)}%)");
      return true; 
    }
    return false;
  }

  // Checks and applies/removes Underdog buff
  static void checkAndApplyUnderdog(Card card, Card enemyCard, Function(String) logCallback) {
    if (card.talent?.type != TalentType.UNDERDOG || card.currentHp <= 0) {
      if (card.isUnderdogBuffActive) {
        int statRevert = (card.originalAttack * card.talent!.value).round(); 
        card.attack = (card.attack - statRevert).clamp(0, card.originalAttack * 3);
        card.defense = (card.defense - statRevert).clamp(0, card.originalDefense * 3);
        card.isUnderdogBuffActive = false;
        logCallback("${card.name}'s Underdog buff deactivated (KO or talent changed). Stats reverted.");
      }
      return;
    }
    final talent = card.talent!; 
    double cardHpPercent = card.maxHp > 0 ? card.currentHp / card.maxHp : 0;
    double enemyHpPercent = enemyCard.maxHp > 0 ? enemyCard.currentHp / enemyCard.maxHp : 0;
    bool conditionMet = cardHpPercent < enemyHpPercent && enemyCard.currentHp > 0; 
    double buffPercent = talent.value;
    if (conditionMet && !card.isUnderdogBuffActive) {
      int atkBoost = (card.originalAttack * buffPercent).round();
      int defBoost = (card.originalDefense * buffPercent).round();
      card.attack += atkBoost;
      card.defense += defBoost;
      card.isUnderdogBuffActive = true;
      logCallback("${card.name}'s Underdog activates! (HP% ${(cardHpPercent * 100).toStringAsFixed(0)} < Enemy HP% ${(enemyHpPercent * 100).toStringAsFixed(0)}) ATK/DEF +${(buffPercent * 100).toStringAsFixed(0)}%. ATK: ${card.attack}, DEF: ${card.defense}.");
    } else if (!conditionMet && card.isUnderdogBuffActive) {
      int atkRevert = (card.originalAttack * buffPercent).round();
      int defRevert = (card.originalDefense * buffPercent).round();
      card.attack = (card.attack - atkRevert).clamp(0, card.originalAttack * 3);
      card.defense = (card.defense - defRevert).clamp(0, card.originalDefense * 3);
      card.isUnderdogBuffActive = false;
      logCallback("${card.name}'s Underdog deactivates. (HP% ${(cardHpPercent*100).toStringAsFixed(0)} >= Enemy HP% ${(enemyHpPercent*100).toStringAsFixed(0)} or enemy KO'd) Stats reverted. ATK: ${card.attack}, DEF: ${card.defense}.");
    }
  }
}
