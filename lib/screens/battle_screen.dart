import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';
import '../card_model.dart' as app_card;
import '../widgets/star_display_widget.dart'; // Import StarDisplayWidget

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch GameState for updates
    final gameState = context.watch<GameState>();

    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation if battle is in progress and not over
        if (gameState.isGameStarted && !gameState.isGameOver) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cannot leave while the battle is in progress!"),
              duration: Duration(seconds: 2),
            ),
          );
          return false; // Prevent pop
        }
        return true; // Allow pop if battle is over or not started
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Battle Arena'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          automaticallyImplyLeading: !gameState.isGameStarted || gameState.isGameOver, // Hide back button during active battle
        ),
        body: gameState.isGameStarted && !gameState.isGameOver && gameState.playerCard != null && gameState.enemyCard != null
            ? Column(
                children: [
                  // Player Card Display
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildCardDisplay(context, gameState.playerCard!, true, gameState),
                    ),
                  ),
                  // Battle Log
                  Container(
                    height: 120, // Fixed height for the battle log
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListView.builder(
                      reverse: true, // To show latest logs at the bottom and scroll up
                      itemCount: gameState.battleLog.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            gameState.battleLog[index],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  // Enemy Card Display
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildCardDisplay(context, gameState.enemyCard!, false, gameState),
                    ),
                  ),
                ],
              )
            : Center( // Fallback UI
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (gameState.isGameOver && gameState.winnerMessage != null) ...[
                      Text(
                        gameState.winnerMessage!,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // --- Post-battle navigation options ---                       
                      if (gameState.currentBattlingFloorId != null && gameState.currentBattlingLevelNumber != null) ...[
                        // It was a floor battle
                        if (gameState.playerCard?.currentHp != null && gameState.playerCard!.currentHp > 0) ...[
                          // Player won a floor battle
                          Builder(builder: (context) {
                            final currentFloor = gameState.gameFloors.firstWhere((f) => f.id == gameState.currentBattlingFloorId);
                            final currentLevelNumber = gameState.currentBattlingLevelNumber!;
                            final bool isLastLevelOfFloor = currentLevelNumber >= currentFloor.numberOfLevels;
                            final int currentFloorIndex = gameState.gameFloors.indexWhere((f) => f.id == currentFloor.id);
                            final bool hasNextFloor = currentFloorIndex < gameState.gameFloors.length - 1;
                            final String? nextFloorId = hasNextFloor ? gameState.gameFloors[currentFloorIndex + 1].id : null;

                            if (!isLastLevelOfFloor) {
                              return ElevatedButton(
                                onPressed: () {
                                  final nextLevel = currentLevelNumber + 1;
                                  gameState.setupBattleForFloorLevel(currentFloor.id, nextLevel);
                                  // No navigation needed, BattleScreen will rebuild with new battle state
                                },
                                child: Text('Start Next Level (${currentLevelNumber + 1})'),
                              );
                            } else if (hasNextFloor && nextFloorId != null && gameState.unlockedFloorIds.contains(nextFloorId)) {
                              return ElevatedButton(
                                onPressed: () {
                                  gameState.clearBattleState();
                                  Navigator.popUntil(context, ModalRoute.withName('/floor_selection'));
                                },
                                child: Text('Proceed to Next Floor (${gameState.gameFloors[currentFloorIndex+1].name})'),
                              );
                            }
                            return const SizedBox.shrink(); // Fallback if no specific next action
                          }),
                          const SizedBox(height: 10),
                        ] else ...[
                          // Player lost a floor battle
                          ElevatedButton(
                            onPressed: () {
                              // Retry the same level
                              gameState.setupBattleForFloorLevel(gameState.currentBattlingFloorId!, gameState.currentBattlingLevelNumber!);
                            },
                            child: const Text('Retry Level'),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              "Read the guide to win battles with element and talent advantages!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            ),
                          ),
                           ElevatedButton(
                            onPressed: () {
                                Navigator.pushNamed(context, '/talent_guide');
                            },
                            child: const Text('Open Guide'),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ], // End of floor battle specific options
                       ElevatedButton(
                         onPressed: () {
                           gameState.clearBattleState();
                            Navigator.popUntil(context, ModalRoute.withName('/floor_selection'));
                         },
                         child: const Text('Return to Floor Selection'),
                       )
                    ] else if (!gameState.isGameStarted && gameState.playerCard == null) ...[
                       Text(
                        "No battle started. Please select a card and an opponent.",
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, ModalRoute.withName('/')); // Go back to home
                        },
                        child: const Text('Go to Home'),
                      )
                    ]
                    else ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text("Loading battle..."),
                    ]
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCardDisplay(BuildContext context, app_card.Card card, bool isPlayer, GameState gameState) {
    final Color hpColor = isPlayer ? Colors.green.shade700 : Colors.red.shade700;
    final Color manaColor = Colors.blue.shade700;

    return Card(
      elevation: 6.0,
      clipBehavior: Clip.antiAlias, // Ensures content respects card's shape
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView( // Added SingleChildScrollView
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceAround, // Less effective with SingleChildScrollView
            crossAxisAlignment: CrossAxisAlignment.center, // Ensure items are centered
            children: [
              Text(
                "${isPlayer ? 'Player' : 'Enemy'}: ${card.name}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              StarDisplayWidget( // Add star display
                ascensionLevel: card.ascensionLevel,
                rarity: card.rarity,
                starSize: 14,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Evo: ${card.evolutionLevel}", style: TextStyle(fontSize: 11, color: Colors.deepPurpleAccent.shade200, fontWeight: FontWeight.w600)),
                  const Text(" • ", style: TextStyle(fontSize: 11)),
                  Text("Lvl: ${card.level}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 100, // Slightly larger image
                height: 140,
                child: ClipRRect( // Rounded corners for the image
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    'assets/${card.imageUrl}',
                    fit: BoxFit.cover, // Cover might look better for card art
                    errorBuilder: (ctx, err, st) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            // HP Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: hpColor, size: 18),
                  const SizedBox(width: 4),
                  Text("${card.currentHp}/${card.maxHp}", style: TextStyle(color: hpColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            SizedBox(
              height: 10, // Slightly thicker bar
              child: LinearProgressIndicator(
                value: card.maxHp > 0 ? card.currentHp / card.maxHp : 0,
                backgroundColor: hpColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                borderRadius: BorderRadius.circular(5),
              ),
              ),
              if (card.maxMana > 0)
              Padding( // Added Padding for consistency
                padding: const EdgeInsets.only(top: 6.0, bottom: 2.0), // Add some top margin
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flash_on, color: manaColor, size: 18),
                    const SizedBox(width: 4),
                    Text("${card.currentMana}/${card.maxMana}", style: TextStyle(color: manaColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                ),
            if (card.maxMana > 0)
              SizedBox(
                height: 10, // Slightly thicker bar
                child: LinearProgressIndicator(
                  value: card.maxMana > 0 ? card.currentMana / card.maxMana : 0,
                  backgroundColor: manaColor.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(manaColor),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 6),
              Text("ATK: ${card.attack} | DEF: ${card.defense} | SPD: ${card.speed}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text("Type: ${card.type.toString().split('.').last}", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              if (card.talent != null)
                Tooltip(
                  message: card.talent!.description,
                  child: Text("Talent: ${card.talent!.name}", style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.tertiary, fontWeight: FontWeight.w600), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
