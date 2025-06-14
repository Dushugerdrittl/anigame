import '../models/floor_model.dart';

class FloorDefinitions {
  static final List<Floor> floors = [
    const Floor(
      id: "floor_1",
      name: "Hidden Leaf Village", // Renamed
      description: "Begin your journey and face various challenges from the Hidden Leaf Village.", // Updated description
      numberOfLevels: 25, // Example: 20 levels for the first floor
      themedCardPoolIds: [ // Card IDs from CardDefinitions that fit this theme
        "naruto_uzumaki",
        "sakura_haruno",
        "kakashi_hatake",
        "itachi_uchiha",
        "tsunade",
        "sasuke_uchiha",
        "madara_uchiha",
        "obito_uchiha",
        // All Naruto series cards are now included
      ],
      baseRewardPerLevel: 25,
      rewardForFloorCompletion: 150,
    ),
    const Floor(
      id: "floor_2",
      name: "East Blue To Grand Line",
      description: "Test your might against Chunin-level opponents from the Sand Village.",
      numberOfLevels: 30, // Example
      themedCardPoolIds: [ // Card IDs from CardDefinitions that fit this theme
        "monkey_d_luffy",
        "roronoa_zoro",
        "nami",
        "sanji",
        "nico_robin",
        "boa_hancock",
        // All One Piece series cards are now included
      ],
      baseRewardPerLevel: 40,
      rewardForFloorCompletion: 300,
    ),
    const Floor(
      id: "floor_3",
      name: "Jump City: Teen Titans", // Renamed
      description: "Face off against the heroes and villains of Jump City.", // Updated description
      numberOfLevels: 25, // Example
      themedCardPoolIds: [ // Added Teen Titans card IDs
        "robin_dick_grayson",
        "starfire_koriandr",
        "raven_rachel_roth",
        "beast_boy_garfield_logan",
        "cyborg_victor_stone",
        "deathstroke_slade_wilson",
      ],
      baseRewardPerLevel: 60,
      rewardForFloorCompletion: 500,
    ),
    // Add more floors here in the future
  ];
}