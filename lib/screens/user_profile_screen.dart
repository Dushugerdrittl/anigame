import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/themed_scaffold.dart';
import '../game_state.dart';
import '../card_model.dart' as app_card; // Aliased import for ShardType and Card model
// To get total number of card templates

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20.0,
          padding: const EdgeInsets.all(5.0),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('User Profile'),
        toolbarHeight: 30,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "Player Resources"),
            _buildPlayerResources(context, gameState),
            const SizedBox(height: 20),
            _buildSectionTitle(context, "Game Progress"),
            _buildStatTile(context, "Ultra Rare Cards Owned:", "${gameState.userOwnedCards.where((card) => card.rarity == app_card.CardRarity.ULTRA_RARE).length}"),
            _buildStatTile(context, "Highest Floor Reached:", _getHighestFloorReached(gameState)),
            _buildStatTile(context, "Total Levels Completed:", _getTotalLevelsCompleted(gameState).toString()),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.warning_amber_outlined, color: Colors.white),
                label: const Text("Reset Game Progress", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: () => _confirmResetDialog(context, gameState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value) {
    return Card( // Use Flutter's Card widget directly
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: ListTile(
        title: Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
        trailing: Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  String _getHighestFloorReached(GameState gameState) {
    if (gameState.unlockedFloorIds.isEmpty) return "Floor 1 (Not Started)";
    int highestFloorNumber = 0;
    String highestFloorName = "N/A";

    for (var floorId in gameState.unlockedFloorIds) {
      final floor = gameState.gameFloors.firstWhere((f) => f.id == floorId, orElse: () => gameState.gameFloors.first);
      final floorNumber = gameState.gameFloors.indexOf(floor) + 1;
      if (floorNumber > highestFloorNumber) {
        highestFloorNumber = floorNumber;
        highestFloorName = floor.name;
      }
    }
    return "$highestFloorName (Floor $highestFloorNumber)";
  }

  int _getTotalLevelsCompleted(GameState gameState) {
    int total = 0; // Ensure total is explicitly int
    gameState.completedLevelsPerFloor.forEach((floorId, levels) {
      total += levels.length;
    });
    return total;
  }

  // Reusing the resource display from HomeScreen for consistency
  Widget _buildPlayerResources(BuildContext context, GameState gameState) {
    List<Widget> resourceChips = [];

    // Gold
    resourceChips.add(_buildResourceChip(context, Icons.monetization_on_outlined, Theme.of(context).colorScheme.secondaryContainer, gameState.playerCurrency.toString(), "Gold"));
    // Diamonds
    resourceChips.add(_buildResourceChip(context, Icons.diamond_outlined, Colors.blue.shade300, gameState.playerDiamonds.toString(), "Diamonds"));
    // Souls
    resourceChips.add(_buildResourceChip(context, Icons.local_fire_department_outlined, Colors.orange.shade800, gameState.playerSouls.toString(), "Souls"));

    // Shards
    for (app_card.ShardType shardType in app_card.ShardType.values) { // Use aliased ShardType
      final count = gameState.playerShards[shardType] ?? 0;
      if (count > 0) { // Optionally, only display if count > 0
        resourceChips.add(
          Tooltip(
            message: shardType.toString().split('.').last.replaceAll('_SHARD', '').replaceAll('_', ' '),
            child: Chip(
              avatar: Icon(_getShardIcon(shardType), color: _getShardColor(shardType), size: 16),
              label: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              labelPadding: const EdgeInsets.only(left: 2.0, right: 4.0),
            ),
          ),
        );
      }
    }

    return Card( // Use Flutter's Card widget directly
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: resourceChips,
        ),
      ),
    );
  }

  Widget _buildResourceChip(BuildContext context, IconData icon, Color iconColor, String value, String tooltipMessage) {
    return Tooltip(
      message: tooltipMessage,
      child: Chip(
        avatar: Icon(icon, color: iconColor, size: 18),
        label: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        labelPadding: const EdgeInsets.only(left: 4.0, right: 6.0),
      ),
    );
  }

  Future<void> _confirmResetDialog(BuildContext context, GameState gameState) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset Game Progress?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to reset all your game progress?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('RESET', style: TextStyle(color: Colors.red)),
              onPressed: () {
                gameState.resetToDefaultState(); // Call your reset logic
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Game progress has been reset."), backgroundColor: Colors.orange),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Helper methods for shard display (can be moved to a common utility file if used elsewhere)
// These are copied from home_screen.dart for now. Consider refactoring to a shared utility.
IconData _getShardIcon(app_card.ShardType shardType) { // Use aliased ShardType
  switch (shardType) {
    case app_card.ShardType.FIRE_SHARD: return Icons.whatshot;
    case app_card.ShardType.WATER_SHARD: return Icons.water_drop;
    case app_card.ShardType.GRASS_SHARD: return Icons.eco_outlined;
    case app_card.ShardType.GROUND_SHARD: return Icons.public_outlined;
    case app_card.ShardType.ELECTRIC_SHARD: return Icons.flash_on_outlined;
    case app_card.ShardType.NEUTRAL_SHARD: return Icons.radio_button_unchecked_outlined;
    case app_card.ShardType.LIGHT_SHARD: return Icons.lightbulb_outline;
    case app_card.ShardType.DARK_SHARD: return Icons.nightlight_round_outlined;
    default: return Icons.grain;
  }
}

Color _getShardColor(app_card.ShardType shardType) { // Use aliased ShardType
  switch (shardType) {
    case app_card.ShardType.FIRE_SHARD: return Colors.red.shade700;
    case app_card.ShardType.WATER_SHARD: return Colors.blue.shade700;
    case app_card.ShardType.GRASS_SHARD: return Colors.green.shade700;
    case app_card.ShardType.GROUND_SHARD: return Colors.brown.shade600;
    case app_card.ShardType.ELECTRIC_SHARD: return Colors.yellow.shade800;
    case app_card.ShardType.NEUTRAL_SHARD: return Colors.grey.shade700;
    case app_card.ShardType.LIGHT_SHARD: return Colors.yellow.shade300;
    case app_card.ShardType.DARK_SHARD: return Colors.deepPurple.shade700;
    default: return Colors.grey.shade600;
  }
}