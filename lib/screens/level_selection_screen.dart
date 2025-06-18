import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart';
import '../models/floor_model.dart'; // Import Floor model
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold
import '../widgets/framed_card_image_widget.dart'; // Import the new widget

class LevelSelectionScreen extends StatelessWidget {
  final Floor floor;

  const LevelSelectionScreen({super.key, required this.floor});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final int highestUnlockedLevel = gameState.getHighestUnlockedLevelForFloor(
      floor.id,
    );

    // Add visual debugging for the highest unlocked level
    print(
      "LevelSelectionScreen: Building for Floor ${floor.id}. Highest unlocked level according to GameState: $highestUnlockedLevel",
    );

    return ThemedScaffold(
      // Use ThemedScaffold
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20.0, // Smaller icon
          padding: const EdgeInsets.all(5.0), // Reduced padding
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('${floor.name} - Levels'),
        toolbarHeight: 30, // Set the AppBar height to 30
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow
      ),
      body: Column(
        // Use a Column to add the debug text above the list
        children: [
          // Display currently selected player card
          if (gameState.currentlySelectedPlayerCard != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Selected Card: ",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  FramedCardImageWidget(
                    card: gameState.currentlySelectedPlayerCard!,
                    width: 30, // Adjust size as needed
                    height: 42, // Adjust size as needed
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gameState.currentlySelectedPlayerCard!.name,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "No card selected for battle.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          Expanded(
            // Wrap the ListView.builder in Expanded
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: floor.numberOfLevels,
              itemBuilder: (context, index) {
                final levelNumber = index + 1;
                final bool isUnlocked = levelNumber <= highestUnlockedLevel;
                final bool isCompleted = gameState
                    .getCompletedLevelsForFloor(floor.id)
                    .contains(levelNumber);

                return Card(
                  elevation: isUnlocked ? 4.0 : 1.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: isUnlocked
                      ? (isCompleted ? Colors.green.shade100 : Colors.white)
                      : Colors.grey.shade300,
                  child: ListTile(
                    leading: Icon(
                      isUnlocked
                          ? (isCompleted
                                ? Icons.check_circle
                                : Icons.lock_open_outlined)
                          : Icons.lock_outline,
                      color: isUnlocked
                          ? (isCompleted
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary)
                          : Colors.grey.shade700,
                      size: 30,
                    ),
                    title: Text(
                      "Level $levelNumber",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.black : Colors.grey.shade700,
                      ),
                    ),
                    subtitle: Text(
                      isCompleted
                          ? "Completed"
                          : (isUnlocked ? "Ready to Battle" : "Locked"),
                      style: TextStyle(
                        color: isUnlocked
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    trailing: isCompleted
                        ? const Chip(
                            label: Text("Completed"),
                            backgroundColor: Colors.green,
                          )
                        : (isUnlocked
                              ? ElevatedButton(
                                  child: const Text('Battle'),
                                  onPressed: () {
                                    // Navigate to Inventory to select card for this battle
                                    Navigator.pushNamed(
                                      context,
                                      '/inventory',
                                      arguments: {
                                        'thenSetupFloorId': floor.id,
                                        'thenSetupLevelNumber': levelNumber,
                                      },
                                    );
                                  },
                                )
                              : null), // Button is null if not unlocked
                    onTap:
                        isUnlocked &&
                            !isCompleted // Allow tap only if unlocked and not completed
                        ? () {
                            // Navigate to Inventory to select card for this battle
                            Navigator.pushNamed(
                              context,
                              '/inventory',
                              arguments: {
                                'thenSetupFloorId': floor.id,
                                'thenSetupLevelNumber': levelNumber,
                              },
                            );
                          }
                        : null, // Tap is null if not unlocked or already completed
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
