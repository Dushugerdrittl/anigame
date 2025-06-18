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
      maxHp: 95,
      attack: 23,
      defense: 9,
      speed: 14,
      type: CardType.FIRE,
      talent: Talent(
        name: "Berserker", // Or a more thematic name like "Nine-Tails Chakra"
        description:
            "While your health is low 45％ Max HP, increase the ATK/DEF of all allied familiars by 30%.",
        type: TalentType.BERSERKER,
        value: 0.3,
        manaCost: 0,
      ),
    ),
    Card(
      id: "hinata_hyuga",
      originalTemplateId: "hinata_hyuga",
      name: "Hinata Hyuga",
      imageUrl: "cards/naruto/hinata.jpg",
      maxHp: 90,
      attack: 20,
      defense: 10,
      speed: 14,
      type: CardType.DARK,
      talent: Talent(
        name: "Regeneration",
        description: "Heals self for a small amount each turn.",
        type: TalentType.REGENERATION,
        value: 0.25,
        secondaryValue: -0.15,
        manaCost: 30,
      ),
    ),
    Card(
      id: "sakura_haruno",
      originalTemplateId: "sakura_haruno",
      name: "Sakura",
      imageUrl: "cards/naruto/sakura.jpg",
      maxHp: 105,
      attack: 19,
      defense: 13,
      speed: 11,
      type: CardType.WATER,
      talent: Talent(
        name: "Rejuvenation",
        description:
            "Restores HP of all allied familiars by 12%, as well as increasing healing effects on allied familiars by 10%, up to a maximum of 50% heal increase.",
        type: TalentType.REJUVENATION,
        value: 0.12,
        manaCost: 30,
      ),
    ),
    Card(
      id: "kakashi_hatake",
      originalTemplateId: "kakashi_hatake",
      name: "Kakashi",
      imageUrl: "cards/naruto/kakashi.jpg",
      maxHp: 120,
      attack: 17,
      defense: 16,
      speed: 9,
      type: CardType.GRASS,
      talent: Talent(
        name: "Precision",
        description:
            "Increase the CRIT of ally familiars by 16%, and increase CRIT DMG by 20%.",
        type: TalentType.PRECISION,
        value: 0.16,
        manaCost: 20,
      ),
    ),
    Card(
      id: "itachi_uchiha",
      originalTemplateId: "itachi_uchiha",
      name: "Itachi",
      imageUrl: "cards/naruto/itachi.jpg",
      maxHp: 140,
      attack: 15,
      defense: 20,
      speed: 7,
      type: CardType.GROUND,
      talent: Talent(
        name: "Blaze",
        description:
            "Inflict a stack of Burn to enemy familiars, dealing 10% True damage per turn, as well as reducing all healing effects on them by 75%.",
        type: TalentType.BLAZE,
        value: 0.10,
        manaCost: 25,
      ),
    ),
    Card(
      id: "tsunade",
      originalTemplateId: "tsunade",
      name: "Tsunade",
      imageUrl: "cards/naruto/tsunade.jpg",
      maxHp: 85,
      attack: 21,
      defense: 8,
      speed: 18,
      type: CardType.ELECTRIC,
      talent: Talent(
        name: "Protector",
        description:
            "When your health drops below 25%, restore the HP of all allied familiars by 20% and raise their DEF by 35%.",
        type: TalentType.PROTECTOR,
        value: 0.20,
        manaCost: 0,
      ),
    ),
    Card(
      id: "sasuke_uchiha",
      originalTemplateId: "sasuke_uchiha",
      name: "Sasuke",
      imageUrl: "cards/naruto/sasuke.jpg",
      maxHp: 90,
      attack: 24,
      defense: 7,
      speed: 16,
      type: CardType.DARK,
      talent: Talent(
        name: "Executioner",
        description:
            "When the enemy's health is below 27% increase your ATK by 50%.",
        type: TalentType.EXECUTIONER,
        value: 0.50,
        manaCost: 0,
      ),
    ),
    Card(
      id: "madara_uchiha",
      originalTemplateId: "madara_uchiha",
      name: "Madara",
      imageUrl: "cards/naruto/madara.jpg",
      maxHp: 130,
      attack: 16,
      defense: 22,
      speed: 6,
      type: CardType.LIGHT,
      talent: Talent(
        name: "Overload",
        description:
            "When the battle starts, increase the ATK by 55% of all allied familiars. Your ATK decreases by 8% every turn after that.",
        type: TalentType.OVERLOAD,
        value: 0.55,
        manaCost: 0,
      ),
    ),
    Card(
      id: "obito_uchiha",
      originalTemplateId: "obito_uchiha",
      name: "Obito",
      imageUrl: "cards/naruto/obito.jpg",
      maxHp: 80,
      attack: 22,
      defense: 10,
      speed: 13,
      type: CardType.FIRE,
      talent: Talent(
        name: "Time Bomb",
        description:
            "Inflict a stack of Time Bomb to enemy familiars, dealing 30% of your ATK as True damage after 1 turn.",
        type: TalentType.TIME_BOMB,
        value: 0.30,
        manaCost: 35,
      ),
    ),
    // --- One Piece Series ---
    Card(
      id: "monkey_d_luffy",
      originalTemplateId: "monkey_d_luffy",
      name: "Monkey D. Luffy",
      imageUrl: "cards/one_piece/luffy.jpg",
      maxHp: 110,
      attack: 25,
      defense: 12,
      speed: 15,
      type: CardType.NEUTRAL,
      talent: Talent(
        name: "Endurance",
        description:
            "Increases Defense significantly but slightly lowers Speed. Chance to evade attacks.",
        type: TalentType.ENDURANCE,
        value: 0.25,
        secondaryValue: -0.10,
        manaCost: 0,
      ),
    ),
    Card(
      id: "roronoa_zoro",
      originalTemplateId: "roronoa_zoro",
      name: "Roronoa Zoro",
      imageUrl: "cards/one_piece/zoro.jpg",
      maxHp: 100,
      attack: 28,
      defense: 10,
      speed: 13,
      type: CardType.GROUND,
      talent: Talent(
        name: "Bloodthirster", // Changed to BLOODTHIRSTER
        description:
            "Heals for a percentage of damage dealt.", // Updated description
        type: TalentType.BLOODTHIRSTER,
        value: 0.20, // Example: 20% lifesteal
        manaCost: 0,
      ),
    ),
    Card(
      id: "nami",
      originalTemplateId: "nami",
      name: "Nami",
      imageUrl: "cards/one_piece/nami.jpg",
      maxHp: 85,
      attack: 18,
      defense: 8,
      speed: 16,
      type: CardType.ELECTRIC,
      talent: Talent(
        name: "Paralysis",
        description:
            "Uses the Clima-Tact for weather attacks with a chance to Paralyze opponents.",
        type: TalentType.PARALYSIS,
        value: 0.15,
        manaCost: 25,
      ),
    ),
    Card(
      id: "sanji",
      originalTemplateId: "sanji",
      name: "Sanji",
      imageUrl: "cards/one_piece/sanji.jpg",
      maxHp: 95,
      attack: 26,
      defense: 9,
      speed: 17,
      type: CardType.FIRE,
      talent: Talent(
        name: "Offensive Stance",
        description:
            "Greatly increases Attack for one turn, inflicting Burn. Costs HP to activate.",
        type: TalentType.OFFENSIVE_STANCE,
        value: 0.50,
        secondaryValue: 0.05,
        manaCost: 15,
      ),
    ),
    Card(
      id: "nico_robin",
      originalTemplateId: "nico_robin",
      name: "Nico Robin",
      imageUrl: "cards/one_piece/nico_robin.jpg",
      maxHp: 90,
      attack: 20,
      defense: 10,
      speed: 14,
      type: CardType.DARK,
      talent: Talent(
        name: "Reversion",
        description:
            "Chance to nullify an opponent's next talent activation or reduce their stats temporarily.",
        type: TalentType.REVERSION,
        value: 0.25,
        secondaryValue: -0.15,
        manaCost: 30,
      ),
    ),
    Card(
      id: "boa_hancock",
      originalTemplateId: "boa_hancock",
      name: "Boa Hancock",
      imageUrl: "cards/one_piece/boa_hancock.jpg",
      maxHp: 100,
      attack: 26,
      defense: 11,
      speed: 16,
      type: CardType.LIGHT,
      talent: Talent(
        name: "Paralysis",
        description:
            "High chance to Paralyze male opponents. Lower chance against female opponents.",
        type: TalentType.PARALYSIS,
        value: 0.75,
        secondaryValue: 0.25,
        manaCost: 35,
      ),
    ),
    // --- Teen Titans ---
    Card(
      id: "robin_dick_grayson", // Example ID
      originalTemplateId: "robin_dick_grayson",
      name: "Robin (Dick Grayson)",
      imageUrl:
          "cards/teen_titans/robin.jpg", // Ensure you have this image path
      maxHp: 90,
      attack: 22,
      defense: 12,
      speed: 18,
      type: CardType.NEUTRAL,
      talent: Talent(
        name: "Precision",
        // Talent description
        description:
            "Increase the CRIT of ally familiars by 16%, and increase CRIT DMG by 20%.", // Talent description
        type: TalentType.PRECISION,
        value: 0.15, // 15% crit chance increase
        manaCost: 20,
      ),
    ),
    Card(
      id: "starfire_koriandr",
      originalTemplateId: "starfire_koriandr",
      name: "Starfire",
      imageUrl:
          "cards/teen_titans/starfire.jpg", // Ensure you have this image path
      maxHp: 110,
      attack: 25,
      defense: 10,
      speed: 16,
      type: CardType.LIGHT, // Light or Fire could fit
      talent: Talent(
        name: "Blaze", // Or a new "Starbolt" talent
        // Talent description
        description:
            "Inflict a stack of Burn to enemy familiars, dealing 10% True damage per turn, as well as reducing all healing effects on them by 75%.", // Talent description
        type: TalentType.BLAZE,
        value: 0.12, // 12% burn damage
        manaCost: 30,
      ),
    ),
    Card(
      id: "raven_rachel_roth",
      originalTemplateId: "raven_rachel_roth",
      name: "Raven",
      imageUrl:
          "cards/teen_titans/raven.jpg", // Ensure you have this image path
      maxHp: 85,
      attack: 18,
      defense: 15,
      speed: 12,
      type: CardType.DARK,
      talent: Talent(
        name: "Reversion", // Or a new "Soul Self" talent
        // Talent description
        description:
            "Chance to nullify an opponent's next talent activation or reduce their stats temporarily.", // Talent description
        type: TalentType.REVERSION, // Example: reduce enemy stats
        value: 0.10, // 10% stat reduction
        manaCost: 25,
      ),
    ),
    Card(
      id: "beast_boy_garfield_logan",
      originalTemplateId: "beast_boy_garfield_logan",
      name: "Beast Boy",
      imageUrl:
          "cards/teen_titans/beastboy.jpg", // Ensure you have this image path
      maxHp: 100,
      attack: 20,
      defense: 14,
      speed: 15,
      type: CardType.GRASS, // Grass for nature/animal forms
      talent: Talent(
        name: "Transformation", // Or a new "AnimalMimicry" talent
        description: // Talent description - Assuming a generic description for Transformation
            "Transforms, gaining unique effects based on the new form.", // Talent description
        type: TalentType
            .TRANSFORMATION, // Example: could cycle through different stat profiles
        value: 0.15, // Placeholder
        manaCost: 30,
      ),
    ),
    Card(
      id: "cyborg_victor_stone",
      originalTemplateId: "cyborg_victor_stone",
      name: "Cyborg",
      imageUrl:
          "cards/teen_titans/cyborg.jpg", // Ensure you have this image path
      maxHp: 120,
      attack: 24,
      defense: 18,
      speed: 10,
      type: CardType.NEUTRAL, // Neutral or Electric
      talent: Talent(
        name: "Overload", // Or a new "SonicCannon" talent
        // Talent description
        description:
            "When the battle starts, increase the ATK by 55% of all allied familiars. Your ATK decreases by 8% every turn after that.", // Talent description
        type: TalentType.OVERLOAD, // Example: high initial attack
        value: 0.40,
        secondaryValue: 0.10, // Decay
        manaCost: 0,
      ),
    ),
    Card(
      id: "deathstroke_slade_wilson",
      originalTemplateId: "deathstroke_slade_wilson",
      name: "Deathstroke (Slade)",
      imageUrl:
          "cards/teen_titans/deathstroke.jpg", // Ensure you have this image path
      maxHp: 105,
      attack: 26,
      defense: 16,
      speed: 17,
      type: CardType.DARK, // Dark or Neutral
      talent: Talent(
        name: "Executioner",
        // Talent description
        description:
            "When the enemy's health is below 27% increase your ATK by 50%.", // Talent description
        type: TalentType.EXECUTIONER,
        value: 0.60, // 60% damage increase
        manaCost: 0,
      ),
    ),
    // Add Event Card templates here as well if they are used as base templates
    // for raid bosses or other dynamic instances.
  ];

  // --- Event Cards ---
  // These cards might only be available for a limited time or through special events.
  // They could have unique talents or slightly boosted stats for their rarity.
  static final List<Card> eventCards = [
    // Add more event cards here
    Card(
      id: "powerpuff_girls_buttercup_playable",
      originalTemplateId: "powerpuff_girls_buttercup_playable",
      name: "Buttercup (Event)",
      imageUrl: "cards/event_cards/powerpuff_girls/buttercup.jpg",
      maxHp: 2500, // Base HP x 2.5
      attack: 300, // Base Attack x 2.5
      defense: 200, // Base Defense x 2.5
      speed: 175, // Base Speed x 2.5
      type: CardType.GRASS,
      rarity: CardRarity.SUPER_RARE, // Rarity as it appears in the event shop
      talent: Talent(
        name: "LIFE SAP",
        description:
            "Saps life from enemies, healing self for a percentage of damage dealt.",
        type: TalentType.LIFE_SAP,
        value: 0.25,
        manaCost: 0,
      ),
      diamondPrice: 250,
    ),
    Card(
      id: "powerpuff_girls_blossom_playable",
      originalTemplateId: "powerpuff_girls_blossom_playable",
      name: "Blossom (Event)",
      imageUrl: "cards/event_cards/powerpuff_girls/blossom.jpg",
      maxHp: 2750, // Base HP x 2.5
      attack: 275, // Base Attack x 2.5
      defense: 225, // Base Defense x 2.5
      speed: 160, // Base Speed x ~2.46
      type: CardType.FIRE,
      rarity: CardRarity.SUPER_RARE,
      talent: Talent(
        name: "TRICK ROOM",
        description:
            "If the enemy familiars' ATK is higher than yours, your allies gain ATK equal to 108% of the difference between the two ATK's, and simultaneously reduce their ATK by the same amount.",
        type: TalentType.TRICK_ROOM_ATK,
        value: 0.10,
        manaCost: 0,
      ),
      diamondPrice: 250,
    ),
    Card(
      id: "powerpuff_girls_bubbles_playable",
      originalTemplateId: "powerpuff_girls_bubbles_playable",
      name: "Bubbles (Event)",
      imageUrl: "cards/event_cards/powerpuff_girls/bubbles.jpg",
      maxHp: 2375, // Base HP x 2.5
      attack: 250, // Base Attack x 2.5
      defense: 187, // Base Defense x ~2.5
      speed: 187, // Base Speed x ~2.5
      type: CardType.WATER,
      rarity: CardRarity.SUPER_RARE,
      talent: Talent(
        name: "TRICK ROOM",
        description:
            "If the enemy familiars' ATK is higher than yours, your allies gain ATK equal to 108% of the difference between the two ATK's, and simultaneously reduce their ATK by the same amount.",
        type: TalentType.TRICK_ROOM_ATK,
        value: 0.15,
        secondaryValue: 0.20,
        manaCost: 0,
      ),
      diamondPrice: 250,
    ),
  ];

  static Card getStarterCard(Random random) {
    List<CardType> elementalTypes = [
      CardType.FIRE,
      CardType.WATER,
      CardType.GRASS,
      CardType.ELECTRIC,
      CardType.GROUND,
      CardType.LIGHT,
      CardType.DARK,
    ];

    // Filter availableCards for cards with REGENERATION or BLOODTHIRSTER talent
    final List<Card> eligibleTemplates = availableCards.where((card) {
      return card.talent?.type == TalentType.REGENERATION ||
          card.talent?.type == TalentType.BLOODTHIRSTER;
    }).toList();

    if (eligibleTemplates.isEmpty) {
      throw Exception(
        "No available card templates with REGENERATION or BLOODTHIRSTER talents for starter card generation.",
      );
    }

    // Randomly select one template from the eligible list
    final Card chosenTemplate =
        eligibleTemplates[random.nextInt(eligibleTemplates.length)];

    String starterInstanceId =
        "starter_card_${DateTime.now().millisecondsSinceEpoch}";

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
      originalTemplateId:
          chosenTemplate.id, // Link to the chosen common template
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
      ascensionLevel: 0,
      talent: chosenTemplate.talent, // Get talent from the chosen template
    );
  }
}
