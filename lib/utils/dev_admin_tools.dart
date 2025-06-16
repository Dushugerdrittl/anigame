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
  static Future<void> addCurrencyToUser(GameState gameState, String username, {int? gold, int? diamonds, int? souls, int? allShardsAmount}) async {
    _logDevMessage("Attempting to add currency/shards to user '$username'.");
    
    // --- Firestore Update ---
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String? userDocId;
    Map<String, dynamic> firestoreUpdates = {}; // Collect all Firestore updates here

    // --- User Lookup (common for all updates) ---
    try {
      QuerySnapshot userQuery = await firestore
          .collection('users')
          .where('username', isEqualTo: username) // Assumes 'username' field stores display names
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        _logDevMessage("Firestore: User document found for '$username'.");
        userDocId = userQuery.docs.first.id;
      } else {
        _logDevMessage("Firestore: User '$username' not found by username query. Firestore updates will be skipped.");
      }
    } catch (e) {
      _logDevMessage("Firestore: Error looking up user '$username': $e. Firestore updates will be skipped.");
    }

    // --- Currency Firestore Updates ---
    if (userDocId != null) {
        if (gold != null) firestoreUpdates['playerCurrency'] = FieldValue.increment(gold);
        if (diamonds != null) firestoreUpdates['playerDiamonds'] = FieldValue.increment(diamonds);
        if (souls != null) firestoreUpdates['playerSouls'] = FieldValue.increment(souls);
    }
    
    // --- Shard Firestore Updates ---
    if (userDocId != null && allShardsAmount != null) {
        _logDevMessage("Preparing to add $allShardsAmount to each elemental shard for user '$username' in Firestore.");
        for (ShardType type in ShardType.values) {
            // Path for map field update: playerShards.INDEX
            // This assumes ShardType enum is available and its index corresponds to keys in Firestore.
            firestoreUpdates['playerShards.${type.index}'] = FieldValue.increment(allShardsAmount);
        }
    }

    // --- Execute Firestore Updates ---
    if (userDocId != null && firestoreUpdates.isNotEmpty) {
        try {
            DocumentReference userDocRef = firestore.collection('users').doc(userDocId);
            await userDocRef.update(firestoreUpdates);
            _logDevMessage("Firestore: Successfully applied updates for user '$username' (Doc ID: $userDocId).");
            if (gold != null) _logDevMessage("Firestore: Incremented gold by $gold.");
            if (diamonds != null) _logDevMessage("Firestore: Incremented diamonds by $diamonds.");
            if (souls != null) _logDevMessage("Firestore: Incremented souls by $souls.");
            if (allShardsAmount != null) _logDevMessage("Firestore: Incremented all elemental shards by $allShardsAmount.");
        } catch (e) {
            _logDevMessage("Firestore: Error applying updates for user '$username': $e");
        }
    } else if (userDocId != null && firestoreUpdates.isEmpty) {
        _logDevMessage("Firestore: No currency/shard updates requested for user '$username'.");
    }

    // --- SharedPreferences Update (can remain as a local/secondary effect) ---
    final prefs = await SharedPreferences.getInstance();
    if (gold != null) {
      int currentGold = prefs.getInt('${username}_playerCurrency') ?? 0; // This key uses the passed 'username'
      await prefs.setInt('${username}_playerCurrency', currentGold + gold);
      _logDevMessage("SharedPreferences: Added $gold gold to $username. New local total: ${currentGold + gold}");
    }
    if (diamonds != null) {
      int currentDiamonds = prefs.getInt('${username}_playerDiamonds') ?? 0;
      await prefs.setInt('${username}_playerDiamonds', currentDiamonds + diamonds);
      _logDevMessage("SharedPreferences: Added $diamonds diamonds to $username. New local total: ${currentDiamonds + diamonds}");
    }
    if (souls != null) {
      int currentSouls = prefs.getInt('${username}_playerSouls') ?? 0;
      await prefs.setInt('${username}_playerSouls', currentSouls + souls);
      _logDevMessage("SharedPreferences: Added $souls souls to $username. New local total: ${currentSouls + souls}");
    }

    if (allShardsAmount != null) {
        // SharedPreferences update for shards is complex due to map storage in GameState.
        // GameState.loadGameState() will overwrite SharedPreferences with Firestore data for the current user.
        // So, for simplicity, we'll just log the intent for SharedPreferences for shards.
        _logDevMessage("SharedPreferences: Intent to add $allShardsAmount to each elemental shard for $username. Actual update relies on Firestore and GameState.loadGameState().");
        // To properly update SharedPreferences to match GameState's shard map structure:
        // 1. Define a key like '${username}_playerShardsMap'.
        // 2. Load the existing JSON string for this key.
        // 3. Decode to Map<String, dynamic>.
        // 4. Increment values for each ShardType.index.toString().
        // 5. Encode back to JSON and save.
    }

    // --- Reload GameState if current user ---
    if (userDocId != null && userDocId == gameState.currentPlayerId && gameState.isUserLoggedIn) {
      _logDevMessage("Current user '$username' modified. Reloading their game state from Firestore.");
      await gameState.loadGameState();
    }
  }

  /// Adds a specific card to a user's inventory. For developer use.
  static Future<void> addCardToUser(GameState gameState, String username, String cardTemplateId, CardRarity rarity, int level) async {
    final prefs = await SharedPreferences.getInstance();
    final template = CardDefinitions.availableCards.firstWhereOrNull((c) => c.id == cardTemplateId);
    if (template == null) {
      _logDevMessage("Card template '$cardTemplateId' not found for user '$username'.");
      return;
    }

    // We need a way to create a card instance. GameState has _copyCard.
    // If _copyCard is made public or static, it can be used here.
    // For now, assuming GameState instance is passed and it has a way to create card.
    // Let's assume GameState has a public method for this or we replicate logic.
    // Using the existing public `copyCardForBattle` as a stand-in for a generic "create instance"
    Card newCard = gameState.copyCardForBattle(template); // This creates a new instance
    newCard.rarity = rarity; // Override rarity
    newCard.level = level; // Override level
    // Recalculate stats based on new rarity/level if _copyCard doesn't do it or if it's a simple copy.
    // For now, _copyCard in GameState handles rarity stats, level stats are applied via upgrade.
    // This might need refinement if _copyCard doesn't fully set up for arbitrary level/rarity.

    List<String>? ownedCardsJson = prefs.getStringList('${username}_userOwnedCards');
    List<Card> userOwnedCardsList = ownedCardsJson?.map((json) => cardFromJson(json)).whereType<Card>().toList() ?? [];

    userOwnedCardsList.add(newCard);
    List<String> updatedOwnedCardsJson = userOwnedCardsList.map((card) => cardToJson(card)).whereType<String>().toList();
    await prefs.setStringList('${username}_userOwnedCards', updatedOwnedCardsJson);
    _logDevMessage("Added ${newCard.name} (Lvl $level, ${rarity.name}) to $username's inventory.");

    if (username == gameState.currentPlayerId && gameState.isUserLoggedIn) {
      _logDevMessage("Current user '$username' inventory modified. Reloading their game state.");
      await gameState.loadGameState();
    }
  }
}
