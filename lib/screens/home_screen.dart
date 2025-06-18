import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../card_model.dart'; // For ShardType
import '../game_state.dart';
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold
import '../utils/shard_display_utils.dart'; // Import the new shard display utilities
// Import the new guide widget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // mounted check is now valid here

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    // If user is not logged in, redirect to login screen
    // This check should ideally be at a higher level in your app's widget tree (e.g., in main.dart or a wrapper widget)
    if (!gameState.isUserLoggedIn) {
      // Use WidgetsBinding to schedule navigation after the current build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
      return const ThemedScaffold(
        body: Center(child: CircularProgressIndicator()),
      ); // Show loading while redirecting
    }

    return ThemedScaffold(
      // Use ThemedScaffold
      appBar: AppBar(
        title: const Text(
          'AniGame Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // Ensure title is visible
            shadows: [
              Shadow(
                blurRadius: 2,
                color: Colors.black54,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow for a flatter look
        toolbarHeight: 30, // Further reduced height
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: _buildCurrencyChip(
              icon: Icons.monetization_on_outlined,
              iconColor: Colors.amber.shade700,
              value: gameState.playerCurrency.toString(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildCurrencyChip(
              icon: Icons.diamond_outlined,
              iconColor: Colors.lightBlueAccent.shade200,
              value: gameState.playerDiamonds.toString(),
            ),
          ),
        ],
      ),
      body: Column(
        // The Container with background is removed
        children: [
          _buildPlayerResources(context, gameState), // Shard display
          Expanded(
            // Make the ListView take remaining space
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              children: <Widget>[
                _buildSectionHeader(context, "Engage"),
                _buildGameMenuButton(
                  context: context,
                  icon: Icons.stairs_outlined,
                  label: 'Floor Battles',
                  accentColor: Colors.orangeAccent,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/floor_selection'),
                ),
                _buildGameMenuButton(
                  context: context,
                  icon: Icons.event_available_outlined,
                  label: 'Events',
                  accentColor: Colors.deepPurpleAccent,
                  onPressed: () => Navigator.pushNamed(context, '/events'),
                ),
                const SizedBox(height: 16),

                _buildSectionHeader(context, "Manage & Acquire"),
                _buildGameMenuButton(
                  context: context,
                  icon: Icons.inventory_2_outlined,
                  label: 'My Cards (Inventory)',
                  accentColor: Colors.blueAccent,
                  onPressed: () => Navigator.pushNamed(context, '/inventory'),
                ),
                _buildGameMenuButton(
                  context: context,
                  icon: Icons.storefront_outlined,
                  label: 'Shop',
                  accentColor: Colors.tealAccent,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/shop_landing'),
                ),
                const SizedBox(height: 16),

                _buildSectionHeader(context, "Learn & Explore"),
                _buildGameMenuButton(
                  context: context,
                  icon: Icons.menu_book_outlined,
                  label: 'Cards Information',
                  accentColor: Colors.brown.shade400,
                  onPressed: () => Navigator.pushNamed(context, '/card_pedia'),
                ),
                _buildGameMenuButton(
                  context: context,
                  icon: Icons.lightbulb_outline,
                  label: 'Talent Guide',
                  accentColor: Colors.yellow.shade700,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/talent_guide'),
                ),
                _buildGameMenuButton(
                  context: context,
                  icon: Icons.shield_outlined, // Changed icon
                  label: 'Raid Battles Guide',
                  accentColor: const Color.fromARGB(255, 249, 12, 138),
                  onPressed: () => Navigator.pushNamed(context, '/raid_guide'),
                ),
                _buildGameMenuButton(
                  context: context,
                  icon: Icons.shield_outlined, // Changed icon
                  label: 'Elements Guide',
                  accentColor: Colors.cyanAccent,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/elements_guide'),
                ),
                const SizedBox(height: 16),

                _buildSectionHeader(context, "Profile"),
                _buildGameMenuButton(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'User Profile',
                  accentColor: Colors.pinkAccent,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/user_profile'),
                ),
                const SizedBox(height: 16), // Add some padding at the bottom
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13, // Slightly smaller for a more subtle header
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.secondary.withOpacity(0.8),
          letterSpacing: 1.8, // Increased letter spacing
        ),
      ),
    );
  }

  Widget _buildGameMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final effectiveAccentColor = accentColor ?? theme.colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5.0,
      ), // Spacing between buttons
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.0),
        splashColor: effectiveAccentColor.withOpacity(0.2),
        highlightColor: effectiveAccentColor.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ), // Adjusted padding
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(
              0.5,
            ), // Darker, semi-transparent
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: effectiveAccentColor.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveAccentColor.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 26,
                color: effectiveAccentColor,
              ), // Slightly smaller icon
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16, // Slightly smaller text
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(
                Icons.navigate_next_rounded,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyChip({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Chip(
      avatar: Icon(icon, color: iconColor, size: 16),
      label: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          shadows: [Shadow(blurRadius: 1, color: Colors.black38)],
        ),
      ),
      backgroundColor: Colors.black.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      labelPadding: const EdgeInsets.only(left: 2, right: 3),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          avatar: Icon(
            Icons.local_fire_department_outlined,
            color: Colors.orange.shade800,
            size: 16, // Reduced icon size
          ),
          label: Text(
            '${gameState.playerSouls}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ), // Reduced font size
          ),
          backgroundColor: Colors.white.withOpacity(
            0.7, // Slightly more transparent
          ), // Semi-transparent chip
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(
            horizontal: 6.0,
            vertical: 0,
          ), // Adjust padding
          materialTapTargetSize:
              MaterialTapTargetSize.shrinkWrap, // Reduce tap target size
          labelPadding: const EdgeInsets.symmetric(
            horizontal: 2.0,
          ), // Simplified padding
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
            avatar: Icon(
              getShardIcon(shardType),
              color: getShardColor(shardType),
              size: 16, // Reduced icon size
            ), // Use utility functions
            label: Text(
              '$count',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ), // Reduced font size
            ),
            backgroundColor: Colors.white.withOpacity(
              0.7, // Slightly more transparent
            ), // Semi-transparent chip
            elevation: 1, // Reduced elevation
            shadowColor: Colors.black.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(
              horizontal: 6.0,
              vertical: 0,
            ), // Adjust padding
            materialTapTargetSize:
                MaterialTapTargetSize.shrinkWrap, // Reduce tap target size
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 2.0,
            ), // Simplified padding
          ),
        ),
      );
      // }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8.0,
        8.0, // Reduced top padding
        8.0,
        8.0,
      ), // Adjusted padding
      child: Container(
        // Optional: Add a semi-transparent background to the resource bar for readability
        padding: const EdgeInsets.symmetric(
          horizontal: 6.0,
          vertical: 4.0,
        ), // Reduced container padding
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Wrap(
          spacing: 4.0, // Further reduced spacing
          runSpacing: 4.0, // Further reduced spacing

          alignment: WrapAlignment.center,
          children: resourceChips,
        ),
      ),
    ); // Removed extra parenthesis
  }
}
