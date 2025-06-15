import 'package:shared_preferences/shared_preferences.dart';
import '../card_model.dart';
import '../data/card_definitions.dart';
import '../game_state.dart'; // To access _copyCard and notifyListeners
import 'package:collection/collection.dart'; // For firstWhereOrNull

class DevAdminTools {
  // Note: For _copyCard, we'll need to make it accessible or replicate its logic.
  // For simplicity, if GameState is passed, we can call its internal _copyCard.
  // Alternatively, _copyCard logic could be made a static utility if it doesn't depend heavily on GameState instance fields.

  static void _logDevMessage(String message) {
    // ignore: avoid_print
    print("DEV_ADMIN_TOOL: $message");
  }

  /// Adds currency to a specified user. For developer use.
  static Future<void> addCurrencyToUser(GameState gameState, String username, {int? gold, int? diamonds, int? souls}) async {
    final prefs = await SharedPreferences.getInstance();
    _logDevMessage("Attempting to add currency to user '$username'.");

    if (gold != null) {
      int currentGold = prefs.getInt('${username}_playerCurrency') ?? 0;
      await prefs.setInt('${username}_playerCurrency', currentGold + gold);
      _logDevMessage("Added $gold gold to $username. New total: ${currentGold + gold}");
    }
    if (diamonds != null) {
      int currentDiamonds = prefs.getInt('${username}_playerDiamonds') ?? 0;
      await prefs.setInt('${username}_playerDiamonds', currentDiamonds + diamonds);
      _logDevMessage("Added $diamonds diamonds to $username. New total: ${currentDiamonds + diamonds}");
    }
    if (souls != null) {
      int currentSouls = prefs.getInt('${username}_playerSouls') ?? 0;
      await prefs.setInt('${username}_playerSouls', currentSouls + souls);
      _logDevMessage("Added $souls souls to $username. New total: ${currentSouls + souls}");
    }

    // If the modified user is the currently logged-in user, update GameState in memory
    if (username == gameState.currentPlayerId && gameState.isUserLoggedIn) {
      // Directly modify GameState's private fields and call notifyListeners
      // This requires GameState to expose methods to update these or for these dev tools to be friends (not typical in Dart)
      // A simpler way for now is to reload the game state for the current user if modified.
      _logDevMessage("Current user '$username' modified. Reloading their game state.");
      await gameState.loadGameState(); // This will pick up changes from SharedPreferences and notify listeners
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