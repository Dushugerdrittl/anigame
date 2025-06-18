import 'package:anigame/game_state.dart';
import 'package:anigame/card_model.dart'; // For CardRarity
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'dev_admin_tools.dart';

class AdminActions {
  // You'll need a way to get the current GameState instance.
  // This could be passed in, or if this is part of a Flutter UI,
  // you might get it from Provider.
  final GameState gameState;

  AdminActions(this.gameState);

  void _logAdminAction(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print("ADMIN_ACTION: $message");
    }
  }

  Future<void> giveGoldToAstolf() async {
    String targetUsername = "astolf";
    int goldAmount = 1000000;
    int diamondAmount = 500000; // Specify the amount of diamonds to add
    _logAdminAction(
      "Attempting to give $goldAmount gold and $diamondAmount diamonds to '$targetUsername'. Current GameState user: '${gameState.currentAuthUsername}', ID: '${gameState.currentPlayerId}'",
    );
    await DevAdminTools.addCurrencyToUser(
      gameState,
      targetUsername,
      gold: goldAmount,
      diamonds: diamondAmount, // Add the diamonds parameter here
    );
    _logAdminAction(
      "DevAdminTools.addCurrencyToUser called for '$targetUsername'. Check DevAdminTools logs for Firestore/SharedPreferences updates.",
    );
  }

  Future<void> giveCardToUser(
    String username, // Add the username parameter back
    String cardTemplateId,
    CardRarity rarity,
    int level,
  ) async {
    print(
      "Executing admin action: Adding card $cardTemplateId ($rarity, Lvl $level) to $username",
    );
    _logAdminAction(
      "Attempting to give card $cardTemplateId ($rarity, Lvl $level) to '$username'. Current GameState user: '${gameState.currentAuthUsername}'",
    );
    await DevAdminTools.addCardToUser(
      gameState,
      username,
      cardTemplateId,
      rarity,
      level,
    );
    _logAdminAction(
      "DevAdminTools.addCardToUser called for '$username'. Check DevAdminTools logs.",
    );
  }

  // Add more methods here for other admin actions
  // e.g., addDiamonds, addSpecificShards, resetUserProgress (if you build such a tool)
}

// How you might use it (e.g., from a debug button in your UI):
//
// Assuming you have access to your GameState instance:
//
// GameState myGameState = Provider.of<GameState>(context, listen: false);
// AdminActions admin = AdminActions(myGameState);
//
// ElevatedButton(
//   onPressed: () async {
//     await admin.giveGoldToAstolf();
//     // Optionally show a snackbar or confirmation
//   },
//   child: Text("Give Gold to Astolf"),
// )
//
// ElevatedButton(
// onPressed: () async { // Example for giveCardToUser
// await admin.giveCardToUser("astolf", "sakura_haruno", CardRarity.RARE, 25);
// },
// child: Text("Give Sakura to Astolf"),
// )
