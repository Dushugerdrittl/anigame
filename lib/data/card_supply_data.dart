// card_supply_data.dart
import '../card_model.dart'; // Import CardRarity

// Defines the total number of copies available for each card template ID in the entire game,
// broken down by rarity.
// The card ID here refers to the 'id' field of the Card objects in 'availableCards' from card_definitions.dart.
class CardSupplyData {
  static final Map<String, Map<CardRarity, int>> cardMaxSupply = {
    // Naruto Series
    "naruto_uzumaki": {
      CardRarity.COMMON: 3000,
      CardRarity.UNCOMMON: 2700,
      CardRarity.RARE: 2400,
      CardRarity.SUPER_RARE: 1700,
      CardRarity.ULTRA_RARE: 400,
    },
    "sakura_haruno": {
      CardRarity.COMMON: 3500,
      CardRarity.UNCOMMON: 3000,
      CardRarity.RARE: 2000,
      CardRarity.SUPER_RARE: 1000,
      CardRarity.ULTRA_RARE: 200,
    },
    "kakashi_hatake": {
      // Example: Kakashi might not have Common/Uncommon versions
      CardRarity.RARE: 2200,
      CardRarity.SUPER_RARE: 1500,
      CardRarity.ULTRA_RARE: 350,
    },
    "itachi_uchiha": {
      // Example: Itachi might only be Super Rare and Ultra Rare
      CardRarity.SUPER_RARE: 1000,
      CardRarity.ULTRA_RARE: 300,
    },
    "tsunade": {
      CardRarity.RARE: 1800,
      CardRarity.SUPER_RARE: 1200,
      CardRarity.ULTRA_RARE: 250,
    },
    "sasuke_uchiha": {
      CardRarity.COMMON: 2800,
      CardRarity.UNCOMMON: 2500,
      CardRarity.RARE: 2000,
      CardRarity.SUPER_RARE: 1300,
      CardRarity.ULTRA_RARE: 300,
    },
    "madara_uchiha": {CardRarity.SUPER_RARE: 800, CardRarity.ULTRA_RARE: 200},
    "obito_uchiha": {
      CardRarity.RARE: 1500,
      CardRarity.SUPER_RARE: 900,
      CardRarity.ULTRA_RARE: 220,
    },

    // One Piece Series
    "monkey_d_luffy": {
      CardRarity.COMMON: 3000,
      CardRarity.UNCOMMON: 2700,
      CardRarity.RARE: 2400,
      CardRarity.SUPER_RARE: 1700,
      CardRarity.ULTRA_RARE: 400,
    },
    "roronoa_zoro": {
      CardRarity.COMMON: 2900,
      CardRarity.UNCOMMON: 2600,
      CardRarity.RARE: 2300,
      CardRarity.SUPER_RARE: 1600,
      CardRarity.ULTRA_RARE: 380,
    },
    "nami": {
      CardRarity.COMMON: 3200,
      CardRarity.UNCOMMON: 2900,
      CardRarity.RARE: 1800,
      CardRarity.SUPER_RARE: 800,
      CardRarity.ULTRA_RARE: 150,
    },
    "sanji": {
      CardRarity.COMMON: 2850,
      CardRarity.UNCOMMON: 2550,
      CardRarity.RARE: 2050,
      CardRarity.SUPER_RARE: 1350,
      CardRarity.ULTRA_RARE: 320,
    },
    "nico_robin": {
      CardRarity.UNCOMMON: 2400,
      CardRarity.RARE: 1900,
      CardRarity.SUPER_RARE: 1100,
      CardRarity.ULTRA_RARE: 280,
    },
    "boa_hancock": {
      CardRarity.RARE: 1600,
      CardRarity.SUPER_RARE: 1000,
      CardRarity.ULTRA_RARE: 330,
    },
    // --- Teen Titans Supply ---
    "robin_dick_grayson": {
      CardRarity.COMMON: 1000,
      CardRarity.UNCOMMON: 500,
      CardRarity.RARE: 200,
      CardRarity.SUPER_RARE: 100,
      CardRarity.ULTRA_RARE: 50,
    },
    "starfire_koriandr": {
      CardRarity.RARE: 200,
      CardRarity.SUPER_RARE: 100,
      CardRarity.ULTRA_RARE: 50,
    },
    "raven_rachel_roth": {
      CardRarity.RARE: 180,
      CardRarity.SUPER_RARE: 90,
      CardRarity.ULTRA_RARE: 40,
    },
    "beast_boy_garfield_logan": {
      CardRarity.UNCOMMON: 400,
      CardRarity.RARE: 150,
      CardRarity.SUPER_RARE: 70,
    },
    "cyborg_victor_stone": {
      CardRarity.RARE: 190,
      CardRarity.SUPER_RARE: 95,
      CardRarity.ULTRA_RARE: 45,
    },
    "deathstroke_slade_wilson": {
      CardRarity.SUPER_RARE: 80,
      CardRarity.ULTRA_RARE: 35,
    },
    // Supply for Event Powerpuff Girls (Raid Bosses / Event Shop specific)
    "powerpuff_girls_buttercup_playable": {CardRarity.SUPER_RARE: 100},
    "powerpuff_girls_blossom_playable": {CardRarity.SUPER_RARE: 100},
    "powerpuff_girls_bubbles_playable": {CardRarity.SUPER_RARE: 100},
    // Supply for new playable Powerpuff Girls
    "buttercup_player": {
      CardRarity.COMMON: 10000, // High supply for common
      CardRarity.UNCOMMON: 5000,
      CardRarity.RARE: 2500,
      CardRarity.SUPER_RARE: 1000,
      CardRarity.ULTRA_RARE: 500,
    },
    "blossom_player": {
      CardRarity.COMMON: 10000,
      CardRarity.UNCOMMON: 5000,
      CardRarity.RARE: 2500,
      CardRarity.SUPER_RARE: 1000,
      CardRarity.ULTRA_RARE: 500,
    },
    "bubbles_player": {
      CardRarity.COMMON: 10000,
      CardRarity.UNCOMMON: 5000,
      CardRarity.RARE: 2500,
      CardRarity.SUPER_RARE: 1000,
      CardRarity.ULTRA_RARE: 500,
    },
    // Add more card templates and their supply limits here
  };
}
