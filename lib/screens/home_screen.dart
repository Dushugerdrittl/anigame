import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../card_model.dart'; // For ShardType
import '../game_state.dart';
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return ThemedScaffold( // Use ThemedScaffold
      appBar: AppBar(
        title: const Text('AniGame Home'),
        // backgroundColor is now handled by AppBarTheme in main.dart
        toolbarHeight: 30, // You can adjust this value (default is usually 56.0)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0), // Reduced padding
            child: Chip(
              avatar: Icon(Icons.monetization_on_outlined, color: Theme.of(context).colorScheme.onSecondaryContainer),
              label: Text('${gameState.playerCurrency}', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Chip(
              avatar: Icon(Icons.diamond_outlined, color: Colors.blue.shade300), // Diamond icon
              label: Text('${gameState.playerDiamonds}', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          )
        ],
      ),
      body: Column( // The Container with background is removed
          children: [
            _buildPlayerResources(context, gameState), // Shard display
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView( // Added SingleChildScrollView for menu buttons
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildMenuButton(
                          context: context,
                          icon: Icons.inventory_2_outlined,
                          label: 'My Cards (Inventory)',
                          onPressed: () => Navigator.pushNamed(context, '/inventory'),
                        ),
                        const SizedBox(height: 15),
                        _buildMenuButton(
                          context: context,
                          icon: Icons.storefront_outlined,
                          label: 'Shop',
                          onPressed: () => Navigator.pushNamed(context, '/shop_landing'),
                        ),
                        const SizedBox(height: 15),
                        _buildMenuButton(
                          context: context,
                          icon: Icons.stairs_outlined,
                          label: 'Floor Battles',
                          onPressed: () => Navigator.pushNamed(context, '/floor_selection'),
                        ),
                        const SizedBox(height: 15),
                        _buildMenuButton(
                          context: context,
                          icon: Icons.event_available_outlined, // Example icon
                          label: 'Events',
                          onPressed: () => Navigator.pushNamed(context, '/events'),
                        ),
                        const SizedBox(height: 15),
                        _buildMenuButton(
                          context: context,
                          icon: Icons.menu_book_outlined,
                          label: 'Cards Information',
                          onPressed: () => Navigator.pushNamed(context, '/card_pedia'),
                        ),
                        const SizedBox(height: 15),
                        _buildMenuButton(
                          context: context,
                          icon: Icons.lightbulb_outline,
                          label: 'Talent Guide',
                          onPressed: () => Navigator.pushNamed(context, '/talent_guide'),
                        ),
                        const SizedBox(height: 15),
                        _buildMenuButton(
                          context: context,
                          icon: Icons.local_fire_department_outlined, // Example icon
                          label: 'Elements Guide',
                          onPressed: () => Navigator.pushNamed(context, '/elements_guide'),
                        ),
                        const SizedBox(height: 15),
                        _buildMenuButton(
                          context: context,
                          icon: Icons.person_outline,
                          label: 'User Profile',
                          onPressed: () => Navigator.pushNamed(context, '/user_profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildMenuButton({required BuildContext context, required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.85), // Semi-transparent
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildPlayerResources(BuildContext context, GameState gameState) {
    // Display all owned shards and souls
    List<Widget> resourceChips = [];

    // Add Souls Chip first
    resourceChips.add(
      Tooltip(
        message: "Souls",
        child: Chip(
          avatar: Icon(Icons.local_fire_department_outlined, color: Colors.orange.shade800, size: 18),
          label: Text('${gameState.playerSouls}', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white.withOpacity(0.8), // Semi-transparent chip
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0), // Adjust padding
          labelPadding: const EdgeInsets.only(left: 2.0, right: 4.0), // Adjust label padding
        ),
      ),
    );

    // Iterate over all ShardType enum values
    for (ShardType shardType in ShardType.values) {
      final count = gameState.playerShards[shardType] ?? 0;
      // Optionally, only display if count > 0
      // if (count > 0) {
        resourceChips.add(
          Tooltip(
            message: shardType.toString().split('.').last.replaceAll('_', ' '),
            child: Chip(
              avatar: Icon(_getShardIcon(shardType), color: _getShardColor(shardType), size: 18),
              label: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white.withOpacity(0.8), // Semi-transparent chip
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0), // Adjust padding
              labelPadding: const EdgeInsets.only(left: 2.0, right: 4.0), // Adjust label padding
            ),
          ),
        );
      // }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 8.0), // Adjusted padding
      child: Container( // Optional: Add a semi-transparent background to the resource bar for readability
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
      child: Wrap(
        spacing: 6.0, // Reduced spacing for more chips
        runSpacing: 6.0,
        alignment: WrapAlignment.center,
        children: resourceChips,
      ),
    )); // Removed extra parenthesis
  }
}

// Helper methods for shard display (can be moved to a common utility file if used elsewhere)
IconData _getShardIcon(ShardType shardType) {
  switch (shardType) {
    case ShardType.FIRE_SHARD: return Icons.whatshot;
    case ShardType.WATER_SHARD: return Icons.water_drop;
    case ShardType.GRASS_SHARD: return Icons.eco_outlined;
    case ShardType.GROUND_SHARD: return Icons.public_outlined;
    case ShardType.ELECTRIC_SHARD: return Icons.flash_on_outlined;
    case ShardType.NEUTRAL_SHARD: return Icons.radio_button_unchecked_outlined;
    case ShardType.LIGHT_SHARD: return Icons.lightbulb_outline;
    case ShardType.DARK_SHARD: return Icons.nightlight_round_outlined;
    // RARE_SHARD, EPIC_SHARD, LEGENDARY_SHARD, SOUL_SHARD cases removed
    default: return Icons.grain;
  }
}

Color _getShardColor(ShardType shardType) {
  switch (shardType) {
    case ShardType.FIRE_SHARD: return Colors.red.shade700;
    case ShardType.WATER_SHARD: return Colors.blue.shade700;
    case ShardType.GRASS_SHARD: return Colors.green.shade700;
    case ShardType.GROUND_SHARD: return Colors.brown.shade600;
    case ShardType.ELECTRIC_SHARD: return Colors.yellow.shade800;
    case ShardType.NEUTRAL_SHARD: return Colors.grey.shade700;
    case ShardType.LIGHT_SHARD: return Colors.yellow.shade300;
    case ShardType.DARK_SHARD: return Colors.deepPurple.shade700;
    // RARE_SHARD, EPIC_SHARD, LEGENDARY_SHARD, SOUL_SHARD cases removed
    default: return Colors.grey.shade600;
  }
}
