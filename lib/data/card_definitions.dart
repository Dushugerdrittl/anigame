import 'dart:math';

import '../card_model.dart';
import '../elemental_system.dart';
import '../talent_system.dart';

class CardDefinitions {
  static final List<Card> availableCards = [
    Card(
      id: "naruto_uzumaki",
      originalTemplateId: "naruto_uzumaki", // Template ID is its own ID
      name: "Naruto",
      imageUrl: "cards/naruto/naruto.jpg",
      maxHp: 95, attack: 23, defense: 9, speed: 14, type: CardType.FIRE,
      talent: Talent(
    name: "Berserker", // Or a more thematic name like "Nine-Tails Chakra"
        description: "While your health is low 45％ Max HP, increase the ATK/DEF of all allied familiars by 30%.",
        type: TalentType.BERSERKER,
        value: 0.3,
        manaCost: 0
      ),
    ),
    Card(
      id: "hinata_hyuga",
      originalTemplateId: "hinata_hyuga",
      name: "Hinata Hyuga",
      imageUrl: "cards/naruto/hinata.jpg",
      maxHp: 90, attack: 20, defense: 10, speed: 14, type: CardType.DARK,
      talent: Talent(
        name: TalentType.REGENERATION.toString().split('.').last,
        description: "Heals self for a small amount each turn.",
        type: TalentType.REGENERATION,
        value: 0.25,
        secondaryValue: -0.15,
        manaCost: 30
      ),
    ),
    Card(
      id: "sakura_haruno",
      originalTemplateId: "sakura_haruno",
      name: "Sakura",
      imageUrl: "cards/naruto/sakura.jpg",
      maxHp: 105, attack: 19, defense: 13, speed: 11, type: CardType.WATER,
      talent: Talent(
        name: TalentType.REJUVENATION.toString().split('.').last,
        description: "Restores HP of all allied familiars by 12%, as well as increasing healing effects on allied familiars by 10%, up to a maximum of 50% heal increase.",
        type: TalentType.REJUVENATION,
        value: 0.12,
        manaCost: 30
      ),
    ),
    Card(
      id: "kakashi_hatake",
      originalTemplateId: "kakashi_hatake",
      name: "Kakashi",
      imageUrl: "cards/naruto/kakashi.jpg",
      maxHp: 120, attack: 17, defense: 16, speed: 9, type: CardType.GRASS,
      talent: Talent(
        name: TalentType.PRECISION.toString().split('.').last,
        description: "Increase the CRIT of ally familiars by 16%, and increase CRIT DMG by 20%.",
        type: TalentType.PRECISION,
        value: 0.16,
        manaCost: 20
      ),
    ),
    Card(
      id: "itachi_uchiha",
      originalTemplateId: "itachi_uchiha",
      name: "Itachi",
      imageUrl: "cards/naruto/itachi.jpg",
      maxHp: 140, attack: 15, defense: 20, speed: 7, type: CardType.GROUND,
      talent: Talent(
        name: TalentType.BLAZE.toString().split('.').last,
        description: "Inflict a stack of Burn to enemy familiars, dealing 10% True damage per turn, as well as reducing all healing effects on them by 75%.",
        type: TalentType.BLAZE,
        value: 0.10,
        manaCost: 25
      ),
    ),
     Card(
      id: "tsunade",
      originalTemplateId: "tsunade",
      name: "Tsunade",
      imageUrl: "cards/naruto/tsunade.jpg",
      maxHp: 85, attack: 21, defense: 8, speed: 18, type: CardType.ELECTRIC,
      talent: Talent(
        name: TalentType.PROTECTOR.toString().split('.').last,
        description: "When your health drops below 25%, restore the HP of all allied familiars by 20% and raise their DEF by 35%.",
        type: TalentType.PROTECTOR,
        value: 0.20,
        manaCost: 0
      ),
    ),
    Card(
      id: "sasuke_uchiha",
      originalTemplateId: "sasuke_uchiha",
      name: "Sasuke",
      imageUrl: "cards/naruto/sasuke.jpg",
      maxHp: 90, attack: 24, defense: 7, speed: 16, type: CardType.DARK,
      talent: Talent(
        name: TalentType.EXECUTIONER.toString().split('.').last,
        description: "When the enemy's health is below 27% increase your ATK by 50%.",
        type: TalentType.EXECUTIONER,
        value: 0.50,
        manaCost: 0
      ),
    ),
    Card(
      id: "madara_uchiha",
      originalTemplateId: "madara_uchiha",
      name: "Madara",
      imageUrl: "cards/naruto/madara.jpg",
      maxHp: 130, attack: 16, defense: 22, speed: 6, type: CardType.LIGHT,
      talent: Talent(
        name: TalentType.OVERLOAD.toString().split('.').last,
        description: "When the battle starts, increase the ATK by 55% of all allied familiars. Your ATK decreases by 8% every turn after that.",
        type: TalentType.OVERLOAD,
        value: 0.55,
        manaCost: 0
      ),
    ),
    Card(
      id: "obito_uchiha",
      originalTemplateId: "obito_uchiha",
      name: "Obito",
      imageUrl: "cards/naruto/obito.jpg",
      maxHp: 80, attack: 22, defense: 10, speed: 13, type: CardType.FIRE,
      talent: Talent(
        name: TalentType.TIME_BOMB.toString().split('.').last,
        description: "Inflict a stack of Time Bomb to enemy familiars, dealing 30% of your ATK as True damage after 1 turn.",
        type: TalentType.TIME_BOMB,
        value: 0.30,
        manaCost: 35
      ),
    ),
    // --- One Piece Series ---
    Card(
      id: "monkey_d_luffy",
      originalTemplateId: "monkey_d_luffy",
      name: "Monkey D. Luffy",
      imageUrl: "cards/one_piece/luffy.jpg",
      maxHp: 110, attack: 25, defense: 12, speed: 15, type: CardType.NEUTRAL,
      talent: Talent(
        name: TalentType.ENDURANCE.toString().split('.').last,
        description: "Increases Defense significantly but slightly lowers Speed. Chance to evade attacks.",
        type: TalentType.ENDURANCE,
        value: 0.25,
        secondaryValue: -0.10,
        manaCost: 0
      ),
    ),
    Card(
      id: "roronoa_zoro",
      originalTemplateId: "roronoa_zoro",
      name: "Roronoa Zoro",
      imageUrl: "cards/one_piece/zoro.jpg",
      maxHp: 100, attack: 28, defense: 10, speed: 13, type: CardType.GROUND,
      talent: Talent(
        name: TalentType.BLOODTHIRSTER.toString().split('.').last, // Changed to BLOODTHIRSTER
        description: "Heals for a percentage of damage dealt.", // Updated description
        type: TalentType.BLOODTHIRSTER,
        value: 0.20, // Example: 20% lifesteal
        manaCost: 0
      ),
    ),
    Card(
      id: "nami",
      originalTemplateId: "nami",
      name: "Nami",
      imageUrl: "cards/one_piece/nami.jpg",
      maxHp: 85, attack: 18, defense: 8, speed: 16, type: CardType.ELECTRIC,
      talent: Talent(
        name: TalentType.PARALYSIS.toString().split('.').last,
        description: "Uses the Clima-Tact for weather attacks with a chance to Paralyze opponents.",
        type: TalentType.PARALYSIS,
        value: 0.15,
        manaCost: 25
      ),
    ),
    Card(
      id: "sanji",
      originalTemplateId: "sanji",
      name: "Sanji",
      imageUrl: "cards/one_piece/sanji.jpg",
      maxHp: 95, attack: 26, defense: 9, speed: 17, type: CardType.FIRE,
      talent: Talent(
        name: TalentType.OFFENSIVE_STANCE.toString().split('.').last,
        description: "Greatly increases Attack for one turn, inflicting Burn. Costs HP to activate.",
        type: TalentType.OFFENSIVE_STANCE,
        value: 0.50,
        secondaryValue: 0.05,
        manaCost: 15
      ),
    ),
    Card(
      id: "nico_robin",
      originalTemplateId: "nico_robin",
      name: "Nico Robin",
      imageUrl: "cards/one_piece/nico_robin.jpg",
      maxHp: 90, attack: 20, defense: 10, speed: 14, type: CardType.DARK,
      talent: Talent(
        name: TalentType.REVERSION.toString().split('.').last,
        description: "Chance to nullify an opponent's next talent activation or reduce their stats temporarily.",
        type: TalentType.REVERSION,
        value: 0.25,
        secondaryValue: -0.15,
        manaCost: 30
      ),
    ),
    Card(
      id: "boa_hancock",
      originalTemplateId: "boa_hancock",
      name: "Boa Hancock",
      imageUrl: "cards/one_piece/boa_hancock.jpg",
      maxHp: 100, attack: 26, defense: 11, speed: 16, type: CardType.LIGHT,
      talent: Talent(
        name: TalentType.PARALYSIS.toString().split('.').last,
        description: "High chance to Paralyze male opponents. Lower chance against female opponents.",
        type: TalentType.PARALYSIS,
        value: 0.75,
        secondaryValue: 0.25,
        manaCost: 35
      ),
    ),
    // --- Teen Titans ---
    Card(
      id: "robin_dick_grayson", // Example ID
      originalTemplateId: "robin_dick_grayson",
      name: "Robin (Dick Grayson)",
      imageUrl: "cards/teen_titans/robin.jpg", // Ensure you have this image path
      maxHp: 90, attack: 22, defense: 12, speed: 18, type: CardType.NEUTRAL,
      talent: Talent(
        name: TalentType.PRECISION.toString().split('.').last,
        description: "Leader of the Titans, skilled in acrobatics and combat. Increases team critical hit chance.",
        type: TalentType.PRECISION,
        value: 0.15, // 15% crit chance increase
        manaCost: 20
      ),
    ),
    Card(
      id: "starfire_koriandr",
      originalTemplateId: "starfire_koriandr",
      name: "Starfire",
      imageUrl: "cards/teen_titans/starfire.jpg", // Ensure you have this image path
      maxHp: 110, attack: 25, defense: 10, speed: 16, type: CardType.LIGHT, // Light or Fire could fit
      talent: Talent(
        name: TalentType.BLAZE.toString().split('.').last, // Or a new "Starbolt" talent
        description: "Alien princess with powerful energy blasts. Can inflict Burn.",
        type: TalentType.BLAZE,
        value: 0.12, // 12% burn damage
        manaCost: 30
      ),
    ),
    Card(
      id: "raven_rachel_roth",
      originalTemplateId: "raven_rachel_roth",
      name: "Raven",
      imageUrl: "cards/teen_titans/raven.jpg", // Ensure you have this image path
      maxHp: 85, attack: 18, defense: 15, speed: 12, type: CardType.DARK,
      talent: Talent(
        name: TalentType.REVERSION.toString().split('.').last, // Or a new "Soul Self" talent
        description: "Empath with dark magical abilities. Can weaken opponents or heal allies.",
        type: TalentType.REVERSION, // Example: reduce enemy stats
        value: 0.10, // 10% stat reduction
        manaCost: 25
      ),
    ),
    Card(
      id: "beast_boy_garfield_logan",
      originalTemplateId: "beast_boy_garfield_logan",
      name: "Beast Boy",
      imageUrl: "cards/teen_titans/beastboy.jpg", // Ensure you have this image path
      maxHp: 100, attack: 20, defense: 14, speed: 15, type: CardType.GRASS, // Grass for nature/animal forms
      talent: Talent(
        name: TalentType.TRANSFORMATION.toString().split('.').last, // Or a new "AnimalMimicry" talent
        description: "Can transform into various animals, gaining different stat boosts or abilities.",
        type: TalentType.TRANSFORMATION, // Example: could cycle through different stat profiles
        value: 0.15, // Placeholder
        manaCost: 30
      ),
    ),
    Card(
      id: "cyborg_victor_stone",
      originalTemplateId: "cyborg_victor_stone",
      name: "Cyborg",
      imageUrl: "cards/teen_titans/cyborg.jpg", // Ensure you have this image path
      maxHp: 120, attack: 24, defense: 18, speed: 10, type: CardType.NEUTRAL, // Neutral or Electric
      talent: Talent(
        name: TalentType.OVERLOAD.toString().split('.').last, // Or a new "SonicCannon" talent
        description: "Half-human, half-machine with super strength and advanced weaponry.",
        type: TalentType.OVERLOAD, // Example: high initial attack
        value: 0.40,
        secondaryValue: 0.10, // Decay
        manaCost: 0
      ),
    ),
    Card(
      id: "deathstroke_slade_wilson",
      originalTemplateId: "deathstroke_slade_wilson",
      name: "Deathstroke (Slade)",
      imageUrl: "cards/teen_titans/deathstroke.jpg", // Ensure you have this image path
      maxHp: 105, attack: 26, defense: 16, speed: 17, type: CardType.DARK, // Dark or Neutral
      talent: Talent(
        name: TalentType.EXECUTIONER.toString().split('.').last,
        description: "Master tactician and assassin with enhanced physical abilities. Deals more damage to low HP targets.",
        type: TalentType.EXECUTIONER,
        value: 0.60, // 60% damage increase
        manaCost: 0
      ),
    ),
    // --- Powerpuff Girls (as playable cards) ---
    Card(
      id: "powerpuff_girls_buttercup_playable", // Unique ID for playable version
      originalTemplateId: "powerpuff_girls_buttercup_playable",
      name: "Buttercup",
      imageUrl: "cards/event_cards/powerpuff_girls/buttercup.jpg",
      maxHp: 100, attack: 24, defense: 11, speed: 15, type: CardType.GRASS, // Adjusted base stats
      talent: Talent(
        name: "LIFE SAP",
        description: "Saps life from enemies, healing self for a percentage of damage dealt.",
        type: TalentType.LIFE_SAP,
        value: 0.25,
        manaCost: 0, // Assuming passive for base card, or adjust if it's an active skill
      ),
    ),
    Card(
      id: "powerpuff_girls_blossom_playable", // Unique ID for playable version
      originalTemplateId: "powerpuff_girls_blossom_playable",
      name: "Blossom",
      imageUrl: "cards/event_cards/powerpuff_girls/blossom.jpg",
      maxHp: 95, attack: 22, defense: 13, speed: 14, type: CardType.FIRE, // Adjusted base stats
      talent: Talent(
        name: "TRICK ROOM",
        description: "If the enemy familiars' ATK is higher than yours, your allies gain ATK equal to 108% of the difference between the two ATK's, and simultaneously reduce their ATK by the same amount.",
        type: TalentType.TRICK_ROOM_ATK,
        value: 0.10, // This value might need context for TRICK_ROOM_ATK
        manaCost: 0, // Assuming passive for base card, or adjust
      ),
    ),
    Card(
      id: "powerpuff_girls_bubbles_playable", // Unique ID for playable version
      originalTemplateId: "powerpuff_girls_bubbles_playable",
      name: "Bubbles",
      imageUrl: "cards/event_cards/powerpuff_girls/bubbles.jpg",
      maxHp: 90, attack: 20, defense: 12, speed: 16, type: CardType.WATER, // Adjusted base stats
      talent: Talent(
       name: "TRICK ROOM", // Assuming same talent as Blossom for this example, adjust if different
        description: "If the enemy familiars' ATK is higher than yours, your allies gain ATK equal to 108% of the difference between the two ATK's, and simultaneously reduce their ATK by the same amount.",
        type: TalentType.TRICK_ROOM_ATK,
        value: 0.15, // This value might need context for TRICK_ROOM_ATK
        secondaryValue: 0.20, // This value might need context for TRICK_ROOM_ATK
        manaCost: 0, // Assuming passive for base card, or adjust
      ),
    ),
    

  ];

  // --- Event Cards ---
  // These cards might only be available for a limited time or through special events.
  // They could have unique talents or slightly boosted stats for their rarity.
  static final List<Card> eventCards = [
    Card(
      id: "powerpuff_girls_buttercup",
      originalTemplateId: "powerpuff_girls_buttercup", // Can be unique or based on an existing template
      name: "Buttercup", // Consistent casing
      imageUrl: "assets/cards/event_cards/powerpuff_girls/buttercup.jpg",
      maxHp: 1500, attack: 180, defense: 120, speed: 90, type: CardType.GRASS, // Example Raid Boss Stats
      talent: Talent(
        name: "LIFE SAP", // Example new Talent
        description: "Saps life from enemies, healing self for a percentage of damage dealt.",
        type: TalentType.LIFE_SAP, // Reusing Berserker for example
        value: 0.25, // 25% boost
        manaCost: 0,
      ),
      // Event cards often have a fixed, higher rarity
      diamondPrice: 2500, // Example diamond price
    ),
    Card(
      id: "powerpuff_girls_blossom",
      originalTemplateId: "powerpuff_girls_blossom",
      name: "Blossom",
      imageUrl: "assets/cards/event_cards/powerpuff_girls/blossom.jpg",
      maxHp: 1800, attack: 150, defense: 150, speed: 80, type: CardType.FIRE, // Example Raid Boss Stats
      talent: Talent(
        name: "TRICK ROOM", // Example new Talent
        description: "If the enemy familiars' ATK is higher than yours, your allies gain ATK equal to 108% of the difference between the two ATK's, and simultaneously reduce their ATK by the same amount.",
        type: TalentType.TRICK_ROOM_ATK, // Example, could be a new one
        value: 0.10, // 10% chance
        manaCost: 0,
      ),
      diamondPrice: 1500, // Example diamond price
    ),
    Card(
      id: "powerpuff_girls_bubbles",
      originalTemplateId: "powerpuff_girls_bubbles",
      name: "Bubbles",
      imageUrl: "assets/cards/event_cards/powerpuff_girls/bubbles.jpg",
      maxHp: 2000, attack: 200, defense: 100, speed: 110, type: CardType.WATER, // Example Raid Boss Stats
      talent: Talent(
       name: "TRICK ROOM", // Example new Talent
        description: "If the enemy familiars' ATK is higher than yours, your allies gain ATK equal to 108% of the difference between the two ATK's, and simultaneously reduce their ATK by the same amount.",
        type: TalentType.TRICK_ROOM_ATK, // Example, could be new
        value: 0.15, // 15% damage reduction
        secondaryValue: 0.20, // 20% counter-attack chance (if DOMINANCE was adapted)
        manaCost: 0,
      ),
      // Rarity for event cards is often fixed, e.g., always ULTRA_RARE for display purposes
      // The actual RaidEvent instance will use this card's stats and assign a raid rarity.
    ),
    
    // Add more event cards here
  ];

  static Card getStarterCard(Random random) {
    List<CardType> elementalTypes = [CardType.FIRE, CardType.WATER, CardType.GRASS, CardType.ELECTRIC, CardType.GROUND, CardType.LIGHT, CardType.DARK];
    
    // Filter availableCards for cards with REGENERATION or BLOODTHIRSTER talent
    final List<Card> eligibleTemplates = availableCards.where((card) {
      return card.talent?.type == TalentType.REGENERATION || card.talent?.type == TalentType.BLOODTHIRSTER;
    }).toList();

    if (eligibleTemplates.isEmpty) {
      throw Exception("No available card templates with REGENERATION or BLOODTHIRSTER talents for starter card generation.");
    }

    // Randomly select one template from the eligible list
    final Card chosenTemplate = eligibleTemplates[random.nextInt(eligibleTemplates.length)];

    String starterInstanceId = "starter_card_${DateTime.now().millisecondsSinceEpoch}";
    
    // Calculate Ultra Rare stats based on the chosen template's common stats
    // Replicating RarityStatsUtil logic here for simplicity as it's not directly available
    // In a larger system, you might pass RarityStatsUtil or have a shared utility.
    double ultraRareMultiplier = 1.65;
    int urMaxHp = (chosenTemplate.maxHp * ultraRareMultiplier).round();
    int urAttack = (chosenTemplate.attack * ultraRareMultiplier).round();
    int urDefense = (chosenTemplate.defense * ultraRareMultiplier).round();
    int urSpeed = (chosenTemplate.speed * ultraRareMultiplier).round();

    return Card(
      id: starterInstanceId, // Unique ID for this instance
      originalTemplateId: chosenTemplate.id, // Link to the chosen common template
      name: chosenTemplate.name, // Name from the template
      imageUrl: chosenTemplate.imageUrl, // Image from the template
      maxHp: urMaxHp, 
      attack: urAttack, 
      defense: urDefense, 
      speed: urSpeed, 
      type: chosenTemplate.type, // Element from the chosen template
      rarity: CardRarity.ULTRA_RARE, // Starter card is Ultra Rare
      level: 75, // Explicitly set to max level for Ultra Rare
      evolutionLevel: 3, // Starter card is already Evo 3
      ascensionLevel: 0, // Starts with 0 ascension
      xp: 0, // Max level, so XP is 0
      xpToNextLevel: 0, // Max level, so 0 XP to next
      talent: chosenTemplate.talent, // Get talent from the chosen template
    );
  }
}
