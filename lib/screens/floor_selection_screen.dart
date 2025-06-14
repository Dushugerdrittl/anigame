import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'level_selection_screen.dart'; // Import the new screen
import '../game_state.dart';
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold

class FloorSelectionScreen extends StatelessWidget {
  const FloorSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return ThemedScaffold( // Use ThemedScaffold
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
        title: const Text('Select Floor'),
        toolbarHeight: 30, // Set the AppBar height to 30
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: gameState.gameFloors.length,
        itemBuilder: (context, index) {
          final floor = gameState.gameFloors[index];
          final bool isUnlocked = gameState.unlockedFloorIds.contains(floor.id);
          final bool isCompleted = gameState.completedFloorIds.contains(floor.id);

          return Card(
            elevation: isUnlocked ? 4.0 : 1.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color: isUnlocked ? (isCompleted ? Colors.green.shade100 : Colors.white) : Colors.grey.shade300,
            child: ListTile(
              leading: Icon(
                isUnlocked ? (isCompleted ? Icons.check_circle : Icons.lock_open_outlined) : Icons.lock_outline,
                color: isUnlocked ? (isCompleted ? Colors.green : Theme.of(context).colorScheme.primary) : Colors.grey.shade700,
                size: 30,
              ),
              title: Text(
                floor.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.black : Colors.grey.shade700,
                ),
              ),
              subtitle: Text(
                "${floor.description}\nCompletion Reward: ${floor.rewardForFloorCompletion} Currency",
                style: TextStyle(color: isUnlocked ? Colors.black87 : Colors.grey.shade600),
              ),
              trailing: isUnlocked && !isCompleted
                  ? ElevatedButton(
                      child: const Text('Battle'),
                      onPressed: () { // Navigate to Level Selection
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LevelSelectionScreen(floor: floor)),
                        );
                      },
                    )
                  : (isCompleted ? const Chip(label: Text("Completed"), backgroundColor: Colors.green) : null),
              onTap: isUnlocked && !isCompleted
                  ? () { // Navigate to Level Selection
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LevelSelectionScreen(floor: floor)),
                      );
                    }
                  : null, // Cannot tap locked or completed floors to start battle
            ),
          );
        },
      ),
    );
  }
}