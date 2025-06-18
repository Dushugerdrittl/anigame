import 'package:flutter/material.dart';
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold

class ShopLandingScreen extends StatelessWidget {
  const ShopLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      // Use ThemedScaffold
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white.withOpacity(0.8),
            size: 16.0,
          ),
          padding: const EdgeInsets.all(5.0), // Reduced padding
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'MERCHANT QUARTER', // Thematic title
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 1.2,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 40,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: <Widget>[
          _buildGameStyleShopButton(
            context: context,
            icon: Icons.attach_money_outlined,
            title: 'Gold Shop',
            subtitle: 'Acquire cards and resources with Gold.',
            accentColor: Colors.amber.shade700,
            routeName:
                '/gold_shop', // Make sure this route exists in main.dart if not already
          ),
          const SizedBox(height: 12),
          _buildGameStyleShopButton(
            context: context,
            icon: Icons.diamond_outlined,
            title: 'Event Cards Shop (Diamonds)',
            subtitle: 'Obtain exclusive event cards using Diamonds.',
            accentColor: Colors.lightBlueAccent.shade200,
            routeName: '/event_cards_shop',
          ),
          const SizedBox(height: 12),
          _buildGameStyleShopButton(
            context: context,
            icon: Icons.gavel_rounded, // Gavel icon for auction
            title: 'Auction House',
            subtitle: 'Trade cards and items with other operatives.',
            accentColor: Colors.greenAccent.shade400,
            routeName: '/auction_house', // Define this route in main.dart
          ),
          // Add more shop links here if needed
          // Example:
          // const SizedBox(height: 12),
          // _buildGameStyleShopButton(
          //   context: context,
          //   icon: Icons.shield_moon_outlined,
          //   title: 'Shard Exchange',
          //   subtitle: 'Trade and acquire elemental shards.',
          //   accentColor: Colors.purpleAccent,
          //   routeName: '/shard_exchange', // Define this route
          // ),
        ],
      ),
    );
  }

  Widget _buildGameStyleShopButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String routeName,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final effectiveAccentColor = accentColor ?? theme.colorScheme.secondary;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, routeName),
      borderRadius: BorderRadius.circular(12.0),
      splashColor: effectiveAccentColor.withOpacity(0.2),
      highlightColor: effectiveAccentColor.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: effectiveAccentColor.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveAccentColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: effectiveAccentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.navigate_next_rounded,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
