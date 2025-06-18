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

  /// Helper function to find a user's Firestore document ID by their username.
  static Future<String?> _findUserDocId(String username) async {
    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.id;
      } else {
        _logDevMessage(
          "Firestore: User '$username' not found by username query.",
        );
        return null;
      }
    } catch (e) {
      _logDevMessage("Firestore: Error looking up user '$username': $e");
      return null;
    }
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

    String? userDocId = await _findUserDocId(username);

    if (userDocId != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userDocRef = firestore
          .collection('users')
          .doc(userDocId);
      Map<String, dynamic> firestoreUpdates = {};

      if (gold != null) {
        firestoreUpdates['playerCurrency'] = FieldValue.increment(gold);
      }
      if (diamonds != null) {
        firestoreUpdates['playerDiamonds'] = FieldValue.increment(diamonds);
      }
      if (souls != null) {
        firestoreUpdates['playerSouls'] = FieldValue.increment(souls);
      }

      if (allShardsAmount != null) {
        _logDevMessage(
          "Preparing to add $allShardsAmount to each elemental shard for user '$username' in Firestore.",
        );
        for (ShardType type in ShardType.values) {
          firestoreUpdates['playerShards.${type.index.toString()}'] =
              FieldValue.increment(allShardsAmount);
        }
      }

      if (firestoreUpdates.isNotEmpty) {
        try {
          await userDocRef.update(firestoreUpdates);
          _logDevMessage(
            "Firestore: Successfully applied updates for user '$username' (Doc ID: $userDocId). Gold: +$gold, Diamonds: +$diamonds, Souls: +$souls, AllShards: +$allShardsAmount",
          );
        } catch (e) {
          _logDevMessage(
            "Firestore: Error applying updates for user '$username': $e",
          );
        }
      } else {
        _logDevMessage(
          "Firestore: No currency/shard updates requested for user '$username'.",
        );
      }
    } else {
      _logDevMessage(
        "Skipping Firestore updates as user '$username' was not found.",
      );
    }

    // --- SharedPreferences Update (primarily for local testing or non-current users) ---
    final prefs = await SharedPreferences.getInstance();
    if (gold != null) {
      int currentGold =
          prefs.getInt('${username}_playerCurrency') ?? // Corrected key format
          0; // This key uses the passed 'username'
      await prefs.setInt(
        '${username}_playerCurrency',
        currentGold + gold,
      ); // Corrected key format
      _logDevMessage(
        "SharedPreferences: Added $gold gold to $username. New local total: ${currentGold + gold}",
      );
    }
    if (diamonds != null) {
      int currentDiamonds =
          prefs.getInt('${username}_playerDiamonds') ??
          0; // Corrected key format
      await prefs.setInt(
        '${username}_playerDiamonds', // Corrected key format
        currentDiamonds + diamonds,
      );
      _logDevMessage(
        "SharedPreferences: Added $diamonds diamonds to $username. New local total: ${currentDiamonds + diamonds}",
      );
    }
    if (souls != null) {
      int currentSouls =
          prefs.getInt('${username}_playerSouls') ?? 0; // Corrected key format
      await prefs.setInt(
        '${username}_playerSouls',
        currentSouls + souls,
      ); // Corrected key format
      _logDevMessage(
        "SharedPreferences: Added $souls souls to $username. New local total: ${currentSouls + souls}",
      );
    }

    if (allShardsAmount != null) {
      _logDevMessage(
        "SharedPreferences: Intent to add $allShardsAmount to each elemental shard for $username. Note: Firestore is the primary source of truth for shards; local SharedPreferences for shards are complex and typically overwritten on game load for the current user.",
      );
    }

    // --- Reload GameState if current user ---
    if (userDocId != null &&
        userDocId == gameState.currentPlayerId &&
        gameState.isUserLoggedIn) {
      // Enhanced logging for the reload condition
      _logDevMessage(
        "Reload Condition Met for '$username': \n  Firestore Doc ID for '$username': $userDocId \n  GameState.currentPlayerId: ${gameState.currentPlayerId} \n  Reloading game state...",
      );
      await gameState.loadGameState();
    } else if (userDocId != null) {
      _logDevMessage(
        "Reload Condition NOT Met for '$username': \n  Firestore Doc ID for '$username': $userDocId \n  GameState.currentPlayerId: ${gameState.currentPlayerId} \n  GameState.isUserLoggedIn: ${gameState.isUserLoggedIn}",
      );
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
    final template = CardDefinitions.availableCards.firstWhereOrNull(
      (c) => c.id == cardTemplateId,
    );
    if (template == null) {
      _logDevMessage(
        "Card template '$cardTemplateId' not found for user '$username'.",
      );
      return;
    }

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
    String? userDocId = await _findUserDocId(username);

    if (userDocId != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference userDocRef = firestore
          .collection('users')
          .doc(userDocId);
      String newCardJson = cardToJson(newCard);
      try {
        await userDocRef.update({
          'userOwnedCards': FieldValue.arrayUnion([newCardJson]),
        });
        _logDevMessage(
          "Firestore: Added ${newCard.name} (Lvl ${newCard.level}, ${rarity.name}) to $username's inventory (Doc ID: $userDocId).",
        );
      } catch (e) {
        // Added catch block to log specific Firestore error
        _logDevMessage(
          "Firestore: Error adding card to user '$username' (Doc ID: $userDocId): $e",
        );
      }
    } else {
      _logDevMessage(
        "Skipping Firestore card addition as user '$username' was not found.",
      );
    }

    // --- Reload GameState if current user ---
    if (userDocId != null &&
        userDocId == gameState.currentPlayerId &&
        gameState.isUserLoggedIn) {
      _logDevMessage(
        "Reload Condition Met for '$username' (Card Add): \n  Firestore Doc ID for '$username': $userDocId \n  GameState.currentPlayerId: ${gameState.currentPlayerId} \n  Reloading game state...",
      );
      await gameState.loadGameState();
    } else if (userDocId != null) {
      _logDevMessage(
        "Reload Condition NOT Met for '$username' (Card Add): \n  Firestore Doc ID for '$username': $userDocId \n  GameState.currentPlayerId: ${gameState.currentPlayerId} \n  GameState.isUserLoggedIn: ${gameState.isUserLoggedIn}",
      );
    }
  }
}
