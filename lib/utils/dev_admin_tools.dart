import 'package:anigame/utils/leveling_cost_util.dart';
import 'package:anigame/utils/rarity_stats_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../card_model.dart';
import '../data/card_definitions.dart';
import '../game_state.dart'; // To access _copyCard and notifyListeners
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class DevAdminTools {
  // Note: For _copyCard, we'll need to make it accessible or replicate its logic.
  // For simplicity, if GameState is passed, we can call its internal _copyCard.
  // Alternatively, _copyCard logic could be made a static utility if it doesn't depend heavily on GameState instance fields.

  static void _logDevMessage(String message) {
    // ignore: avoid_print
    print("DEV_ADMIN_TOOL: $message");
  }

  /// Adds currency to a specified user. For developer use.
  static Future<void> addCurrencyToUser(
    GameState gameState,
    String username, {
    int? gold,
    int? diamonds,
    int? souls,
    int? allShardsAmount,
  }) async {
    _logDevMessage("Attempting to add currency/shards to user '$username'.");

    // --- Firestore Update ---
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String? userDocId;
    Map<String, dynamic> firestoreUpdates =
        {}; // Collect all Firestore updates here

    // --- User Lookup (common for all updates) ---
    try {
      QuerySnapshot userQuery = await firestore
          .collection('users')
          .where(
            'username',
            isEqualTo: username,
          ) // Assumes 'username' field stores display names
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        _logDevMessage("Firestore: User document found for '$username'.");
        userDocId = userQuery.docs.first.id;
      } else {
        _logDevMessage(
          "Firestore: User '$username' not found by username query. Firestore updates will be skipped.",
        );
      }
    } catch (e) {
      _logDevMessage(
        "Firestore: Error looking up user '$username': $e. Firestore updates will be skipped.",
      );
    }

    // --- Currency Firestore Updates ---
    if (userDocId != null) {
      if (gold != null) {
        firestoreUpdates['playerCurrency'] = FieldValue.increment(gold);
      }
      if (diamonds != null) {
        firestoreUpdates['playerDiamonds'] = FieldValue.increment(diamonds);
      }
      if (souls != null) {
        firestoreUpdates['playerSouls'] = FieldValue.increment(souls);
      }
    }

    // --- Shard Firestore Updates ---
    if (userDocId != null && allShardsAmount != null) {
      _logDevMessage(
        "Preparing to add $allShardsAmount to each elemental shard for user '$username' in Firestore.",
      );
      for (ShardType type in ShardType.values) {
        // Path for map field update: playerShards.INDEX
        // This assumes ShardType enum is available and its index corresponds to keys in Firestore.
        firestoreUpdates['playerShards.${type.index.toString()}'] =
            FieldValue.increment(allShardsAmount);
      }
    }

    // --- Execute Firestore Updates ---
    if (userDocId != null && firestoreUpdates.isNotEmpty) {
      try {
        DocumentReference userDocRef = firestore
            .collection('users')
            .doc(userDocId);
        await userDocRef.update(firestoreUpdates);
        _logDevMessage(
          "Firestore: Successfully applied updates for user '$username' (Doc ID: $userDocId).",
        );
        if (gold != null) {
          _logDevMessage("Firestore: Incremented gold by $gold.");
        }
        if (diamonds != null) {
          _logDevMessage("Firestore: Incremented diamonds by $diamonds.");
        }
        if (souls != null) {
          _logDevMessage("Firestore: Incremented souls by $souls.");
        }
        if (allShardsAmount != null) {
          _logDevMessage(
            "Firestore: Incremented all elemental shards by $allShardsAmount.",
          );
        }
      } catch (e) {
        _logDevMessage(
          "Firestore: Error applying updates for user '$username': $e",
        );
      }
    } else if (userDocId != null && firestoreUpdates.isEmpty) {
      _logDevMessage(
        "Firestore: No currency/shard updates requested for user '$username'.",
      );
    }

    // --- SharedPreferences Update (can remain as a local/secondary effect) ---
    final prefs = await SharedPreferences.getInstance();
    if (gold != null) {
      int currentGold =
          prefs.getInt('${username}_playerCurrency') ??
          0; // This key uses the passed 'username'
      await prefs.setInt('${username}_playerCurrency', currentGold + gold);
      _logDevMessage(
        "SharedPreferences: Added $gold gold to $username. New local total: ${currentGold + gold}",
      );
    }
    if (diamonds != null) {
      int currentDiamonds = prefs.getInt('${username}_playerDiamonds') ?? 0;
      await prefs.setInt(
        '${username}_playerDiamonds',
        currentDiamonds + diamonds,
      );
      _logDevMessage(
        "SharedPreferences: Added $diamonds diamonds to $username. New local total: ${currentDiamonds + diamonds}",
      );
    }
    if (souls != null) {
      int currentSouls = prefs.getInt('${username}_playerSouls') ?? 0;
      await prefs.setInt('${username}_playerSouls', currentSouls + souls);
      _logDevMessage(
        "SharedPreferences: Added $souls souls to $username. New local total: ${currentSouls + souls}",
      );
    }

    if (allShardsAmount != null) {
      // SharedPreferences update for shards is complex due to map storage in GameState.
      // GameState.loadGameState() will overwrite SharedPreferences with Firestore data for the current user.
      // So, for simplicity, we'll just log the intent for SharedPreferences for shards.
      _logDevMessage(
        "SharedPreferences: Intent to add $allShardsAmount to each elemental shard for $username. Actual update relies on Firestore and GameState.loadGameState().",
      );
      // To properly update SharedPreferences to match GameState's shard map structure:
      // 1. Define a key like '${username}_playerShardsMap'.
      // 2. Load the existing JSON string for this key.
      // 3. Decode to Map<String, dynamic>.
      // 4. Increment values for each ShardType.index.toString().
      // 5. Encode back to JSON and save.
    }

    // --- Reload GameState if current user ---
    if (userDocId != null &&
        userDocId == gameState.currentPlayerId &&
        gameState.isUserLoggedIn) {
      _logDevMessage(
        "Current user '$username' modified. Reloading their game state from Firestore.",
      );
      await gameState.loadGameState();
    }
  }

  /// Adds a specific card to a user's inventory. For developer use.
  static Future<void> addCardToUser(
    GameState gameState,
    String username,
    String cardTemplateId,
    CardRarity rarity,
    int level,
  ) async {
    // final prefs = await SharedPreferences.getInstance(); // SharedPreferences update is secondary to Firestore
    final template = CardDefinitions.availableCards.firstWhereOrNull(
      (c) => c.id == cardTemplateId,
    );
    if (template == null) {
      _logDevMessage(
        "Card template '$cardTemplateId' not found for user '$username'.",
      );
      return;
    }

    // We need a way to create a card instance. GameState has _copyCard.
    // Replicating a simplified _copyCard logic here for clarity and to set level correctly.
    // Ideally, GameState._copyCard or a utility would be used.
    // This simplified version focuses on getting a card with correct rarity and base stats for level 1.
    // Then we'll "level it up" to the target level.

    final baseStats = RarityStatsUtil.calculateStatsForRarity(
      baseHp: template.maxHp,
      baseAttack: template.attack,
      baseDefense: template.defense,
      baseSpeed: template.speed,
      rarity: rarity,
    );

    Card newCard = Card(
      id: "${template.id}_${rarity.toString().split('.').last}_dev_${DateTime.now().millisecondsSinceEpoch}",
      originalTemplateId: template.id,
      name: template.name,
      imageUrl: template.imageUrl,
      maxHp: baseStats['hp']!,
      attack: baseStats['attack']!,
      defense: baseStats['defense']!,
      speed: baseStats['speed']!,
      type: template.type,
      talent: template.talent,
      rarity: rarity,
      level: 1, // Start at level 1
      xp: 0,
      xpToNextLevel: Card.calculateXpToNextLevel(1),
      // ... other fields initialized as in GameState._copyCard
      originalAttack: baseStats['attack']!,
      originalDefense: baseStats['defense']!,
      originalSpeed: baseStats['speed']!,
      originalMaxHp: baseStats['hp']!,
    );

    // Apply level-up stat boosts iteratively if target level > 1
    for (int i = 1; i < level; i++) {
      if (newCard.level >= newCard.maxCardLevel) break;
      newCard.level++;
      // Replicate GameState._applyLevelUpStatBoosts logic
      final boosts = LevelingCostUtil.getStatBoostsForLevelUp(
        newCard.rarity,
      ); // Assuming this utility exists and is accessible
      newCard.maxHp += boosts['hp']!;
      newCard.attack += boosts['attack']!;
      newCard.defense += boosts['defense']!;
      newCard.speed += boosts['speed']!;
    }
    newCard.currentHp = newCard.maxHp; // Ensure HP is full

    // --- Firestore Update ---
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      QuerySnapshot userQuery = await firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        String userDocId = userQuery.docs.first.id;
        DocumentReference userDocRef = firestore
            .collection('users')
            .doc(userDocId);
        String newCardJson = cardToJson(
          newCard,
        ); // Assumes cardToJson exists and returns String
        await userDocRef.update({
          'userOwnedCards': FieldValue.arrayUnion([newCardJson]),
        });
        _logDevMessage(
          "Firestore: Added ${newCard.name} (Lvl ${newCard.level}, ${rarity.name}) to $username's inventory (Doc ID: $userDocId).",
        );
      } else {
        _logDevMessage(
          "Firestore: User '$username' not found. Card not added to Firestore.",
        );
      }
    } catch (e) {
      _logDevMessage("Firestore: Error adding card to user '$username': $e");
    }

    // --- Reload GameState if current user ---
    if (username == gameState.currentAuthUsername && gameState.isUserLoggedIn) {
      // Compare with GameState's auth username
      _logDevMessage(
        "Current user '$username' inventory modified. Reloading their game state from Firestore.",
      );
      await gameState.loadGameState();
    }
  }
}
