import 'elemental_system.dart'; // For CardType
import 'talent_system.dart'; // For Talent
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'data/card_definitions.dart'; // To look up templates during deserialization
import 'package:flutter/material.dart'; // For Color
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

enum CardRarity { COMMON, UNCOMMON, RARE, SUPER_RARE, ULTRA_RARE }

enum ShardType {
  // Elemental Shards (can map from CardType)
  GRASS_SHARD,
  FIRE_SHARD,
  WATER_SHARD,
  GROUND_SHARD,
  ELECTRIC_SHARD,
  NEUTRAL_SHARD,
  LIGHT_SHARD,
  DARK_SHARD,
  // Progression Shards - These have been removed as per request
  // RARE_SHARD, EPIC_SHARD, LEGENDARY_SHARD, SOUL_SHARD
}

// Centralized Rarity Colors
const Color kRareColor = Colors.blue; // Or Colors.blue.shade600
const Color kSuperRareColor = Colors.amber; // Or Colors.amber.shade700
const Color kUltraRareColor = Colors.red; // Or Colors.red.shade700
const Color kCommonColor = Colors.grey;
const Color kUncommonColor = Colors.green;

// Helper function to get rarity color
Color getRarityColor(CardRarity rarity) {
  switch (rarity) {
    case CardRarity.COMMON:
      return kCommonColor;
    case CardRarity.UNCOMMON:
      return kUncommonColor;
    case CardRarity.RARE:
      return kRareColor;
    case CardRarity.SUPER_RARE:
      return kSuperRareColor;
    case CardRarity.ULTRA_RARE:
      return kUltraRareColor;
    default:
      return Colors.grey;
  }
}

class Card {
  final String id; // Unique identifier
  final String
  originalTemplateId; // The ID of the base card template from CardDefinitions
  final String name;
  final String imageUrl; // For display (we'll use placeholders for now)
  int maxHp;
  int currentHp;
  int attack;
  int defense;
  int speed;
  CardType type;
  Talent? talent; // Changed from List<Talent> to single Talent?
  CardRarity rarity;
  int level;
  int evolutionLevel; // 0, 1, 2, 3
  int ascensionLevel; // 0 to 25
  int currentMana;
  int xp;
  int xpToNextLevel; // XP needed for the next level
  int maxMana;
  // Fields for stateful talents
  bool isYangBuffActive; // For YinYang talent
  bool isBloodSurgeAttackBuffActive; // For Blood Surge talent
  double currentLifestealBonus; // For Blood Surge lifesteal effect
  double
  manaRegenBonus; // Percentage bonus to mana regeneration (e.g., 0.45 for +45%)
  double
  currentHealingEffectivenessBonus; // Cumulative bonus to healing received (e.g., 0.15 for +15%)
  bool isBloodSurgeLifestealActive; // Tracks if Blood Surge lifesteal is active
  bool isDivineBlessingActive; // Tracks if Divine Blessing buff is active
  bool isDominanceBuffActive; // Tracks if Dominance ATK buff is active
  bool isExecutionerBuffActive; // Tracks if Executioner ATK buff is active
  bool
  isUnderGrievousLimiterDebuff; // True if this card is debuffed by an enemy's Grievous Limiter
  bool isProtectorDefBuffActive; // True if Protector's DEF buff is active
  bool
  hasProtectorActivatedThisBattle; // True if Protector has triggered this battle
  int
  recoilSourceMaxHpForSelf; // If this card has Recoil, stores its MaxHP for self-damage calc. 0 if no Recoil.
  bool
  isTakingRecoilDamageFromOpponent; // True if opponent has Recoil affecting this card.
  int
  recoilDamageSourceMaxHpFromOpponent; // MaxHP of the opponent who applied Recoil. 0 if not affected.
  bool
  hasReversionActivatedThisBattle; // True if Reversion talent has triggered this battle
  bool
  isReversionAllyBuffActive; // True if this card received the DEF/SPD buff from an ally's Reversion
  bool isTemporalRewindActive; // True if Temporal Rewind buff is active
  int
  temporalRewindTurnsRemaining; // Turns remaining for Temporal Rewind effect
  bool isAmplifierBuffActive; // True if Amplifier ATK/DEF buff is active
  int amplifierTurnsRemaining; // Turns remaining for Amplifier buff
  bool isUnderdogBuffActive; // Tracks if Underdog ATK/DEF buff is active
  int temporalRewindInitialHpAtBuff; // HP when Temporal Rewind was applied
  // No need to store debuff amount here, recovery is based on originalAttack
  bool isUnderBurnDebuff; // True if afflicted by Blaze's burn
  int burnStacks; // Number of burn stacks from Blaze
  int burnCasterAttack; // ATK of the caster of the burn
  int burnDurationTurns; // Turns remaining for the burn debuff
  double burnDamagePerStackPercent; // Damage % per stack from Blaze talent
  double burnHealingReductionPercent; // Healing reduction % from Blaze talent
  int divineBlessingTurnsRemaining; // Turns remaining for Divine Blessing
  bool isEnduranceBuffActive; // True if Endurance buff is active
  int enduranceTurnsRemaining; // Turns remaining for Endurance buff
  double enduranceDamageReductionPercent; // Damage reduction % from Endurance
  double currentEvasionChance; // Current chance to evade attacks
  int evasionBuffTurnsRemaining; // Turns remaining for evasion buff
  int evasionStacks; // Number of evasion stacks
  bool isFrozen; // True if the card is Frozen
  int frozenTurnsRemaining; // Turns remaining for Frozen status (SPD debuff)
  double frozenSpeedReductionPercent; // The SPD reduction % from Freeze
  bool isOffensiveStanceActive; // True if Offensive Stance is active
  bool isStunned; // True if the card is stunned and will miss its next turn
  bool isPoisoned; // True if the card is poisoned
  int poisonTurnsRemaining; // Turns remaining for poison
  int poisonFlatDamage; // Flat damage component of poison
  double
  poisonPercentDamage; // Percent damage component of poison (based on caster's ATK)
  bool isSilenced; // True if the card is Silenced and cannot use active skills
  int silenceTurnsRemaining; // Turns remaining for Silence
  int poisonCasterAttack; // ATK of the card that applied the poison
  bool isPainForPowerBuffActive; // True if Pain For Power buff is active
  bool isPrecisionBuffActive; // True if Precision buff is active
  int precisionTurnsRemaining; // Turns remaining for Precision buff
  double precisionCritChanceBonus; // Bonus to crit chance from Precision
  double precisionCritDamageBonus; // Bonus to crit damage from Precision
  bool isRegenerationBuffActive; // True if Regeneration buff is active
  int regenerationTurnsRemaining; // Turns remaining for Regeneration buff
  int regenerationHealPerTurn; // Amount to heal per turn from Regeneration buff
  int painForPowerTurnsRemaining; // Turns remaining for Pain For Power buff
  bool isTimeBombActive; // True if afflicted by Time Bomb
  int timeBombTurnsRemaining; // Turns until Time Bomb explodes
  int timeBombDamage; // Damage the Time Bomb will deal
  // bool isUnderTrickRoomEffect; // Replaced by specific flags
  // int trickRoomOriginalSpeed; // Replaced by specific stat tracking
  int trickRoomEffectTurnsRemaining; // General duration for TR effects
  bool isTrickRoomAtkActive; // True if TR ATK steal/buff is active
  int trickRoomAtkBuffDebuffAmount; // Amount of ATK changed by TR
  bool isTrickRoomDefActive; // True if TR DEF steal/buff is active
  int trickRoomDefBuffDebuffAmount; // Amount of DEF changed by TR
  int fightingCounter; // For talents like Ultimate Combo
  int offensiveStanceTurnsRemaining; // Turns remaining for Offensive Stance
  int originalSpeed; // To store base speed
  int originalMaxHp; // To store base max HP for talents like Balancing Strike
  bool isBerserkerBuffActive; // For Berserker talent
  int
  originalAttack; // To store base attack before YinYang/BloodSurge modifications
  int originalDefense; // To store base defense before YinYang modifications
  final int? diamondPrice; // Optional: For cards purchasable with diamonds

  // Max level is now dynamic based on rarity
  int get maxCardLevel {
    switch (rarity) {
      case CardRarity.COMMON:
        return 30;
      case CardRarity.UNCOMMON:
        return 40;
      case CardRarity.RARE:
        return 50;
      case CardRarity.SUPER_RARE:
        return 60;
      case CardRarity.ULTRA_RARE:
        return 75;
    }
  }

  int get maxAscensionLevel {
    switch (rarity) {
      case CardRarity.SUPER_RARE:
        return 20; // Up to 5 Pink stars (4 tiers * 5 stars/tier)
      case CardRarity.ULTRA_RARE:
        return 25; // Up to 5 Red stars (5 tiers * 5 stars/tier)
      default:
        return 0; // Common, Uncommon, Rare cannot ascend
    }
  }

  // Helper to determine the current tier of ascension (0-4)
  // Tier 0 = White, 1 = Yellow, 2 = Blue, 3 = Pink, 4 = Red
  int get currentAscensionTier {
    if (ascensionLevel == 0) {
      return 0; // No stars, default to white for display if needed
    }
    return ((ascensionLevel - 1) / 5).floor();
  }

  // Helper to determine how many stars (1-5) are filled in the current tier
  int get starsInCurrentTier {
    if (ascensionLevel == 0) return 0;
    return (ascensionLevel - 1) % 5 + 1;
  }

  // Helper to get the color for the current tier of stars
  Color get currentStarColor {
    switch (currentAscensionTier) {
      case 0: // White stars
        return Colors.grey.shade300; // Or Colors.white if background allows
      case 1: // Yellow stars
        return Colors.yellow.shade600;
      case 2: // Blue stars
        return Colors.blue.shade400;
      case 3: // Pink stars
        return Colors.pink.shade300;
      case 4: // Red stars (Ultra Rare only)
        return Colors.red.shade600;
      default:
        return Colors.grey; // Should not happen
    }
  }

  Card({
    required this.id,
    required this.originalTemplateId,
    required this.name,
    required this.imageUrl,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.speed,
    this.type = CardType.NEUTRAL, // Default to Neutral
    this.talent, // Default to null
    this.rarity = CardRarity.COMMON, // Default to Common
    this.level = 1,
    this.evolutionLevel = 0, // Default to Evo 0
    this.ascensionLevel = 0, // Default to 0 ascension
    this.xp = 0,
    // xpToNextLevel is now calculated in the constructor body
    this.currentMana = 0, // Initialize mana
    this.maxMana = 0, // Initialize maxMana
    this.isYangBuffActive = false, // Default state for YinYang
    this.isBloodSurgeAttackBuffActive = false, // Default state for Blood Surge
    this.manaRegenBonus = 0.0, // Default no mana regen bonus
    this.currentHealingEffectivenessBonus = 0.0, // Default no healing bonus
    this.currentLifestealBonus = 0.0, // Default no lifesteal bonus
    this.isBloodSurgeLifestealActive = false, // Default not active
    this.isDivineBlessingActive = false,
    this.isDominanceBuffActive = false,
    this.isExecutionerBuffActive = false,
    this.isProtectorDefBuffActive = false,
    this.hasProtectorActivatedThisBattle = false,
    this.recoilSourceMaxHpForSelf = 0,
    this.isTakingRecoilDamageFromOpponent = false,
    this.recoilDamageSourceMaxHpFromOpponent = 0,
    this.hasReversionActivatedThisBattle = false,
    this.isReversionAllyBuffActive = false,
    this.isTemporalRewindActive = false,
    this.temporalRewindTurnsRemaining = 0,
    this.isAmplifierBuffActive = false,
    this.amplifierTurnsRemaining = 0,
    this.isUnderdogBuffActive = false,
    this.isUnderBurnDebuff = false,
    this.burnStacks = 0, // Blaze
    this.burnCasterAttack = 0,
    this.burnDurationTurns = 0, // Blaze
    this.burnDamagePerStackPercent = 0.0,
    this.burnHealingReductionPercent = 0.0,
    this.temporalRewindInitialHpAtBuff = 0,
    this.isEnduranceBuffActive = false,
    this.enduranceTurnsRemaining = 0,
    this.enduranceDamageReductionPercent = 0.0,
    this.currentEvasionChance = 0.0,
    this.evasionBuffTurnsRemaining = 0,
    this.evasionStacks = 0,
    this.isFrozen = false,
    this.frozenTurnsRemaining = 0,
    this.frozenSpeedReductionPercent = 0.0,
    this.isOffensiveStanceActive = false,
    this.offensiveStanceTurnsRemaining = 0,
    this.isStunned = false,
    this.isPoisoned = false,
    this.poisonTurnsRemaining = 0,
    this.poisonFlatDamage = 0,
    this.poisonPercentDamage = 0.0,
    this.poisonCasterAttack = 0,
    this.isSilenced = false,
    this.silenceTurnsRemaining = 0,
    this.isPainForPowerBuffActive = false,
    this.isPrecisionBuffActive = false,
    this.precisionTurnsRemaining = 0,
    this.precisionCritChanceBonus = 0.0,
    this.precisionCritDamageBonus = 0.0,
    this.isRegenerationBuffActive = false,
    this.regenerationTurnsRemaining = 0,
    this.regenerationHealPerTurn = 0,
    this.isTimeBombActive = false,
    this.timeBombTurnsRemaining = 0,
    this.timeBombDamage = 0,
    // this.isUnderTrickRoomEffect = false, // Replaced
    // this.trickRoomOriginalSpeed = 0, // Replaced
    this.trickRoomEffectTurnsRemaining = 0,
    this.isTrickRoomAtkActive = false,
    this.trickRoomAtkBuffDebuffAmount = 0,
    this.isTrickRoomDefActive = false,
    this.trickRoomDefBuffDebuffAmount = 0,
    this.fightingCounter = 0,
    this.painForPowerTurnsRemaining = 0,
    this.isUnderGrievousLimiterDebuff = false,
    this.divineBlessingTurnsRemaining = 0,
    this.isBerserkerBuffActive = false, // Default state for Berserker
    this.originalSpeed = 0, // Will be set properly
    this.originalMaxHp = 0, // Will be set properly
    this.originalAttack =
        0, // Will be set properly in GameState or TalentSystem
    this.originalDefense =
        0, // Will be set properly in GameState or TalentSystem
    this.diamondPrice,
  }) : currentHp = maxHp,
       xpToNextLevel = 0 /* Initialize, will be set below */ {
    // Ensure level does not exceed max level, though this should be managed by upgrade logic later
    if (level > maxCardLevel) level = maxCardLevel;
    if (level < maxCardLevel) {
      xpToNextLevel = calculateXpToNextLevel(level);
    } else {
      xpToNextLevel = 0;
    }
    // Ascension level check is fine here
    if (ascensionLevel > maxAscensionLevel) ascensionLevel = maxAscensionLevel;
  }

  void takeDamage(int damageAmount) {
    currentHp -= damageAmount;
    if (currentHp < 0) {
      currentHp = 0;
    }
  }

  void reset() {
    currentHp = maxHp;
    // Reset temporary battle states if needed, mana is handled by _copyCard
    // isYangBuffActive = false; // This should be set at the start of battle by talent system
    // manaRegenBonus = 0.0; // Reset at battle start by talent system
    // currentHealingEffectivenessBonus = 0.0; // Reset at battle start by talent system
    // currentLifestealBonus = 0.0; // Reset at battle start by talent system
    // isBloodSurgeLifestealActive = false; // Reset at battle start
    // isUnderGrievousLimiterDebuff = false; // Reset at battle start
    // isProtectorDefBuffActive = false; // Reset at battle start
    // hasProtectorActivatedThisBattle = false; // Reset at battle start
    // recoilSourceMaxHpForSelf = 0; // Reset at battle start by talent system
    // isTakingRecoilDamageFromOpponent = false; // Reset at battle start by talent system
    // recoilDamageSourceMaxHpFromOpponent = 0; // Reset at battle start
    // hasReversionActivatedThisBattle = false; // Reset at battle start
    // isReversionAllyBuffActive = false; // Reset at battle start
    // isTemporalRewindActive = false; // Reset at battle start
    // temporalRewindTurnsRemaining = 0; // Reset at battle start
    // isAmplifierBuffActive = false; // Reset at battle start
    // amplifierTurnsRemaining = 0; // Reset at battle start
    // isUnderdogBuffActive = false; // Reset at battle start
    // isUnderBurnDebuff = false; // Reset at battle start
    // burnStacks = 0; // Reset at battle start (Blaze)
    // burnCasterAttack = 0; // Reset at battle start
    // burnDurationTurns = 0; // Reset at battle start (Blaze)
    // burnDamagePerStackPercent = 0.0; // Reset at battle start
    // isEnduranceBuffActive = false; // Reset at battle start
    // enduranceTurnsRemaining = 0; // Reset at battle start
    // enduranceDamageReductionPercent = 0.0; // Reset at battle start
    // currentEvasionChance = 0.0; // Reset at battle start
    // evasionBuffTurnsRemaining = 0; // Reset at battle start
    // evasionStacks = 0; // Reset at battle start
    // isFrozen = false; // Reset at battle start
    // frozenTurnsRemaining = 0; // Reset at battle start
    // frozenSpeedReductionPercent = 0.0; // Reset at battle start
    // isOffensiveStanceActive = false; // Reset at battle start
    // isStunned = false; // Reset at battle start
    // isPoisoned = false; // Reset at battle start
    // poisonTurnsRemaining = 0; // Reset at battle start
    // poisonFlatDamage = 0; // Reset at battle start
    // poisonPercentDamage = 0.0; // Reset at battle start
    // poisonCasterAttack = 0; // Reset at battle start
    // isSilenced = false; // Reset at battle start
    // silenceTurnsRemaining = 0; // Reset at battle start
    // isPrecisionBuffActive = false; // Reset at battle start
    // precisionTurnsRemaining = 0; // Reset at battle start
    // precisionCritChanceBonus = 0.0; // Reset at battle start
    // precisionCritDamageBonus = 0.0; // Reset at battle start
    // isRegenerationBuffActive = false; // Reset at battle start
    // regenerationTurnsRemaining = 0; // Reset at battle start
    // regenerationHealPerTurn = 0; // Reset at battle start
    // isPainForPowerBuffActive = false; // Reset at battle start
    // isTimeBombActive = false; // Reset at battle start
    // timeBombTurnsRemaining = 0; // Reset at battle start
    // timeBombDamage = 0; // Reset at battle start
    // isUnderTrickRoomEffect = false; // Replaced
    // trickRoomOriginalSpeed = 0; // Replaced
    // trickRoomEffectTurnsRemaining = 0; // Reset at battle start
    // isTrickRoomAtkActive = false; // Reset at battle start
    // trickRoomAtkBuffDebuffAmount = 0; // Reset at battle start
    // isTrickRoomDefActive = false; // Reset at battle start
    // trickRoomDefBuffDebuffAmount = 0; // Reset at battle start
    // fightingCounter = 0; // Reset at battle start
    // painForPowerTurnsRemaining = 0; // Reset at battle start
    // offensiveStanceTurnsRemaining = 0; // Reset at battle start
    // burnHealingReductionPercent = 0.0; // Reset at battle start
    // temporalRewindInitialHpAtBuff = 0; // Reset at battle start
    // isExecutionerBuffActive = false; // Reset at battle start
    // isDominanceBuffActive = false; // Reset at battle start
    // isDivineBlessingActive = false; // Reset at battle start by talent system
    // divineBlessingTurnsRemaining = 0; // Reset at battle start
    // isBloodSurgeAttackBuffActive = false;
    // isBerserkerBuffActive = false; // This should also be managed by the talent system checks
    // originalAttack and originalDefense are set at battle start by talent system
    // originalMaxHp is set at battle start
    // originalSpeed is set at battle start
  }

  void heal(int amount) {
    // Apply healing effectiveness bonus, capped at +50%
    double actualHealAmount = amount.toDouble();
    if (isUnderBurnDebuff) {
      actualHealAmount *= (1.0 - burnHealingReductionPercent);
    }

    double effectiveHealingMultiplier =
        1.0 + currentHealingEffectivenessBonus.clamp(0.0, 0.50);
    int effectiveHealAmount = (actualHealAmount * effectiveHealingMultiplier)
        .round();
    currentHp += effectiveHealAmount;
    if (currentHp > maxHp) {
      currentHp = maxHp;
    }
  }

  // Helper to calculate XP needed for the next level
  static int calculateXpToNextLevel(int currentLevel) {
    return (currentLevel * 100) +
        50; // Example formula: 150 for L1->L2, 250 for L2->L3
  }

  Card copyWith({
    String? id,
    String? originalTemplateId,
    String? name,
    String? imageUrl,
    int? maxHp,
    int? currentHp,
    int? attack,
    int? defense,
    int? speed,
    CardType? type,
    Talent? talent,
    bool clearTalent = false, // Special flag to nullify talent
    CardRarity? rarity,
    int? level,
    int? evolutionLevel,
    int? ascensionLevel,
    int? xp,
    int? currentMana,
    int? maxMana,
    bool? isYangBuffActive,
    bool? isBloodSurgeAttackBuffActive,
    double? manaRegenBonus,
    double? currentHealingEffectivenessBonus,
    double? currentLifestealBonus,
    bool? isBloodSurgeLifestealActive,
    bool? isDivineBlessingActive,
    bool? isDominanceBuffActive,
    bool? isExecutionerBuffActive,
    bool? isProtectorDefBuffActive,
    bool? hasProtectorActivatedThisBattle,
    int? recoilSourceMaxHpForSelf,
    bool? isTakingRecoilDamageFromOpponent,
    int? recoilDamageSourceMaxHpFromOpponent,
    bool? hasReversionActivatedThisBattle,
    bool? isReversionAllyBuffActive,
    bool? isTemporalRewindActive,
    int? temporalRewindTurnsRemaining,
    bool? isAmplifierBuffActive,
    int? amplifierTurnsRemaining,
    bool? isUnderdogBuffActive,
    bool? isUnderBurnDebuff,
    int? burnStacks,
    int? burnCasterAttack,
    int? burnDurationTurns,
    double? burnDamagePerStackPercent,
    double? burnHealingReductionPercent,
    int? temporalRewindInitialHpAtBuff,
    bool? isEnduranceBuffActive,
    int? enduranceTurnsRemaining,
    double? enduranceDamageReductionPercent,
    double? currentEvasionChance,
    int? evasionBuffTurnsRemaining,
    int? evasionStacks,
    bool? isFrozen,
    int? frozenTurnsRemaining,
    double? frozenSpeedReductionPercent,
    bool? isOffensiveStanceActive,
    int? offensiveStanceTurnsRemaining,
    bool? isStunned,
    bool? isPoisoned,
    int? poisonTurnsRemaining,
    int? poisonFlatDamage,
    double? poisonPercentDamage,
    int? poisonCasterAttack,
    bool? isSilenced,
    int? silenceTurnsRemaining,
    bool? isPainForPowerBuffActive,
    bool? isPrecisionBuffActive,
    int? precisionTurnsRemaining,
    double? precisionCritChanceBonus,
    double? precisionCritDamageBonus,
    bool? isRegenerationBuffActive,
    int? regenerationTurnsRemaining,
    int? regenerationHealPerTurn,
    bool? isTimeBombActive,
    int? timeBombTurnsRemaining,
    int? timeBombDamage,
    int? trickRoomEffectTurnsRemaining,
    bool? isTrickRoomAtkActive,
    int? trickRoomAtkBuffDebuffAmount,
    bool? isTrickRoomDefActive,
    int? trickRoomDefBuffDebuffAmount,
    int? fightingCounter,
    int? painForPowerTurnsRemaining,
    bool? isUnderGrievousLimiterDebuff,
    int? divineBlessingTurnsRemaining,
    bool? isBerserkerBuffActive,
    int? originalAttack,
    int? originalDefense,
    int? originalSpeed,
    int? originalMaxHp,
    int? diamondPrice,
  }) {
    return Card(
      id: id ?? this.id,
      originalTemplateId: originalTemplateId ?? this.originalTemplateId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      maxHp: maxHp ?? this.maxHp,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      speed: speed ?? this.speed,
      type: type ?? this.type,
      talent: clearTalent ? null : (talent ?? this.talent),
      rarity: rarity ?? this.rarity,
      level: level ?? this.level,
      evolutionLevel: evolutionLevel ?? this.evolutionLevel,
      ascensionLevel: ascensionLevel ?? this.ascensionLevel,
      xp: xp ?? this.xp,
      currentMana: currentMana ?? this.currentMana,
      maxMana: maxMana ?? this.maxMana,
      isYangBuffActive: isYangBuffActive ?? this.isYangBuffActive,
      isBloodSurgeAttackBuffActive:
          isBloodSurgeAttackBuffActive ?? this.isBloodSurgeAttackBuffActive,
      manaRegenBonus: manaRegenBonus ?? this.manaRegenBonus,
      currentHealingEffectivenessBonus:
          currentHealingEffectivenessBonus ??
          this.currentHealingEffectivenessBonus,
      currentLifestealBonus:
          currentLifestealBonus ?? this.currentLifestealBonus,
      isBloodSurgeLifestealActive:
          isBloodSurgeLifestealActive ?? this.isBloodSurgeLifestealActive,
      isDivineBlessingActive:
          isDivineBlessingActive ?? this.isDivineBlessingActive,
      isDominanceBuffActive:
          isDominanceBuffActive ?? this.isDominanceBuffActive,
      isExecutionerBuffActive:
          isExecutionerBuffActive ?? this.isExecutionerBuffActive,
      isProtectorDefBuffActive:
          isProtectorDefBuffActive ?? this.isProtectorDefBuffActive,
      hasProtectorActivatedThisBattle:
          hasProtectorActivatedThisBattle ??
          this.hasProtectorActivatedThisBattle,
      recoilSourceMaxHpForSelf:
          recoilSourceMaxHpForSelf ?? this.recoilSourceMaxHpForSelf,
      isTakingRecoilDamageFromOpponent:
          isTakingRecoilDamageFromOpponent ??
          this.isTakingRecoilDamageFromOpponent,
      recoilDamageSourceMaxHpFromOpponent:
          recoilDamageSourceMaxHpFromOpponent ??
          this.recoilDamageSourceMaxHpFromOpponent,
      hasReversionActivatedThisBattle:
          hasReversionActivatedThisBattle ??
          this.hasReversionActivatedThisBattle,
      isReversionAllyBuffActive:
          isReversionAllyBuffActive ?? this.isReversionAllyBuffActive,
      isTemporalRewindActive:
          isTemporalRewindActive ?? this.isTemporalRewindActive,
      temporalRewindTurnsRemaining:
          temporalRewindTurnsRemaining ?? this.temporalRewindTurnsRemaining,
      isAmplifierBuffActive:
          isAmplifierBuffActive ?? this.isAmplifierBuffActive,
      amplifierTurnsRemaining:
          amplifierTurnsRemaining ?? this.amplifierTurnsRemaining,
      isUnderdogBuffActive: isUnderdogBuffActive ?? this.isUnderdogBuffActive,
      isUnderBurnDebuff: isUnderBurnDebuff ?? this.isUnderBurnDebuff,
      burnStacks: burnStacks ?? this.burnStacks,
      burnCasterAttack: burnCasterAttack ?? this.burnCasterAttack,
      burnDurationTurns: burnDurationTurns ?? this.burnDurationTurns,
      burnDamagePerStackPercent:
          burnDamagePerStackPercent ?? this.burnDamagePerStackPercent,
      burnHealingReductionPercent:
          burnHealingReductionPercent ?? this.burnHealingReductionPercent,
      temporalRewindInitialHpAtBuff:
          temporalRewindInitialHpAtBuff ?? this.temporalRewindInitialHpAtBuff,
      isEnduranceBuffActive:
          isEnduranceBuffActive ?? this.isEnduranceBuffActive,
      enduranceTurnsRemaining:
          enduranceTurnsRemaining ?? this.enduranceTurnsRemaining,
      enduranceDamageReductionPercent:
          enduranceDamageReductionPercent ??
          this.enduranceDamageReductionPercent,
      currentEvasionChance: currentEvasionChance ?? this.currentEvasionChance,
      evasionBuffTurnsRemaining:
          evasionBuffTurnsRemaining ?? this.evasionBuffTurnsRemaining,
      evasionStacks: evasionStacks ?? this.evasionStacks,
      isFrozen: isFrozen ?? this.isFrozen,
      frozenTurnsRemaining: frozenTurnsRemaining ?? this.frozenTurnsRemaining,
      frozenSpeedReductionPercent:
          frozenSpeedReductionPercent ?? this.frozenSpeedReductionPercent,
      isOffensiveStanceActive:
          isOffensiveStanceActive ?? this.isOffensiveStanceActive,
      offensiveStanceTurnsRemaining:
          offensiveStanceTurnsRemaining ?? this.offensiveStanceTurnsRemaining,
      isStunned: isStunned ?? this.isStunned,
      isPoisoned: isPoisoned ?? this.isPoisoned,
      poisonTurnsRemaining: poisonTurnsRemaining ?? this.poisonTurnsRemaining,
      poisonFlatDamage: poisonFlatDamage ?? this.poisonFlatDamage,
      poisonPercentDamage: poisonPercentDamage ?? this.poisonPercentDamage,
      poisonCasterAttack: poisonCasterAttack ?? this.poisonCasterAttack,
      isSilenced: isSilenced ?? this.isSilenced,
      silenceTurnsRemaining:
          silenceTurnsRemaining ?? this.silenceTurnsRemaining,
      isPainForPowerBuffActive:
          isPainForPowerBuffActive ?? this.isPainForPowerBuffActive,
      isPrecisionBuffActive:
          isPrecisionBuffActive ?? this.isPrecisionBuffActive,
      precisionTurnsRemaining:
          precisionTurnsRemaining ?? this.precisionTurnsRemaining,
      precisionCritChanceBonus:
          precisionCritChanceBonus ?? this.precisionCritChanceBonus,
      precisionCritDamageBonus:
          precisionCritDamageBonus ?? this.precisionCritDamageBonus,
      isRegenerationBuffActive:
          isRegenerationBuffActive ?? this.isRegenerationBuffActive,
      regenerationTurnsRemaining:
          regenerationTurnsRemaining ?? this.regenerationTurnsRemaining,
      regenerationHealPerTurn:
          regenerationHealPerTurn ?? this.regenerationHealPerTurn,
      isTimeBombActive: isTimeBombActive ?? this.isTimeBombActive,
      timeBombTurnsRemaining:
          timeBombTurnsRemaining ?? this.timeBombTurnsRemaining,
      timeBombDamage: timeBombDamage ?? this.timeBombDamage,
      trickRoomEffectTurnsRemaining:
          trickRoomEffectTurnsRemaining ?? this.trickRoomEffectTurnsRemaining,
      isTrickRoomAtkActive: isTrickRoomAtkActive ?? this.isTrickRoomAtkActive,
      trickRoomAtkBuffDebuffAmount:
          trickRoomAtkBuffDebuffAmount ?? this.trickRoomAtkBuffDebuffAmount,
      isTrickRoomDefActive: isTrickRoomDefActive ?? this.isTrickRoomDefActive,
      trickRoomDefBuffDebuffAmount:
          trickRoomDefBuffDebuffAmount ?? this.trickRoomDefBuffDebuffAmount,
      fightingCounter: fightingCounter ?? this.fightingCounter,
      painForPowerTurnsRemaining:
          painForPowerTurnsRemaining ?? this.painForPowerTurnsRemaining,
      isUnderGrievousLimiterDebuff:
          isUnderGrievousLimiterDebuff ?? this.isUnderGrievousLimiterDebuff,
      divineBlessingTurnsRemaining:
          divineBlessingTurnsRemaining ?? this.divineBlessingTurnsRemaining,
      isBerserkerBuffActive:
          isBerserkerBuffActive ?? this.isBerserkerBuffActive,
      originalAttack: originalAttack ?? this.originalAttack,
      originalDefense: originalDefense ?? this.originalDefense,
      originalSpeed: originalSpeed ?? this.originalSpeed,
      originalMaxHp: originalMaxHp ?? this.originalMaxHp,
      diamondPrice: diamondPrice ?? this.diamondPrice,
    );
  }
}

// --- Serialization/Deserialization ---

String cardToJson(Card card) {
  return jsonEncode({
    'id': card.id, // Save the unique instance ID
    'originalTemplateId': card.originalTemplateId,
    // Name, imageUrl, type, talent, maxMana are derived from template on load
    'maxHp': card.maxHp, // Current maxHp after all modifications
    'attack': card.attack, // Current attack after all modifications
    'defense': card.defense, // Current defense after all modifications
    'speed': card.speed, // Current speed after all modifications
    'rarity': card.rarity.index,
    'level': card.level,
    'evolutionLevel': card.evolutionLevel,
    'ascensionLevel': card.ascensionLevel,
    'xp': card.xp,
    // xpToNextLevel is recalculated on load by Card constructor
    // currentHp is reset to maxHp on load (or could be saved if needed for specific scenarios)
    // currentMana is reset on load/battle start
    // isYangBuffActive, isBloodSurgeAttackBuffActive are battle states, not typically persisted this way
    // diamondPrice is part of the template, not saved per instance typically unless it changes
    // originalAttack, originalDefense, originalSpeed, originalMaxHp are battle states, not persisted here
  });
}

Card? cardFromJson(String jsonString) {
  try {
    Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final String? originalTemplateId = jsonMap['originalTemplateId'] as String?;

    if (originalTemplateId == null) {
      // If originalTemplateId is missing, we cannot reliably reconstruct the card.
      // This might happen for very old data or corrupted entries.
      print(
        "Error in cardFromJson: 'originalTemplateId' is missing. JSON: $jsonString",
      );
      // Optionally, try to use a fallback or default card if appropriate,
      // or simply return null. For now, let's be strict.
      return null;
    }

    // Combine all card definitions for lookup
    final List<Card> allCardDefinitions = [
      ...CardDefinitions.availableCards,
      ...CardDefinitions.eventCards,
    ];

    final Card? template = allCardDefinitions.firstWhereOrNull(
      (c) => c.id == originalTemplateId,
    );

    if (template == null) {
      print(
        "Warning in cardFromJson: Card template '$originalTemplateId' not found in any CardDefinitions list. Returning null. JSON: $jsonString",
      );
      return null;
    }

    return Card(
      id:
          jsonMap['id'] ??
          "${originalTemplateId}_instance_${DateTime.now().millisecondsSinceEpoch}", // Fallback ID if not saved
      originalTemplateId: originalTemplateId,
      name: template.name, // Always use name from template
      imageUrl: template
          .imageUrl, // ALWAYS use imageUrl from template (which now has 'assets/')
      maxHp:
          jsonMap['maxHp'] ??
          template.maxHp, // Fallback to template if not in JSON
      attack: jsonMap['attack'] ?? template.attack,
      defense: jsonMap['defense'] ?? template.defense,
      speed: jsonMap['speed'] ?? template.speed,
      type: template.type, // Always use type from template
      talent: template.talent, // Always use talent from template
      rarity: jsonMap['rarity'] != null
          ? CardRarity.values[jsonMap['rarity']]
          : template.rarity, // Fallback to template rarity
      level: jsonMap['level'] ?? 1,
      evolutionLevel: jsonMap['evolutionLevel'] ?? 0,
      ascensionLevel: jsonMap['ascensionLevel'] ?? 0,
      xp: jsonMap['xp'] ?? 0,
      // Other fields like xpToNextLevel, currentHp, currentMana, maxMana, originalAttack/Defense
      diamondPrice: template.diamondPrice, // Get from template
      // will be set by the Card constructor or later by GameState/TalentSystem.
    );
  } catch (e) {
    // Consider logging this error more formally in a real app
    print("Error in cardFromJson: $e. JSON string: $jsonString");
    return null; // Return null if deserialization fails
  }
}
