import 'package:flutter/material.dart';
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold

class ShopLandingScreen extends StatelessWidget {
  const ShopLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold( // Use ThemedScaffold
      appBar: AppBar(
        title: const Text('Shops'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20.0, // Smaller icon
          padding: const EdgeInsets.all(5.0), // Reduced padding
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        toolbarHeight: 30, // Set the AppBar height to 30
        // The AppBar background color will be handled by the global theme
        // If you need a specific color for this AppBar, you can set it here.
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildShopNavigationTile(
            context: context,
            icon: Icons.attach_money_outlined,
            title: 'Gold Shop',
            routeName: '/gold_shop', // Make sure this route exists in main.dart if not already
          ),
          const SizedBox(height: 10),
          _buildShopNavigationTile(
            context: context,
            icon: Icons.diamond_outlined,
            title: 'Event Cards Shop (Diamonds)',
            routeName: '/event_cards_shop',
          ),
          // Add more shop links here if needed
        ],
      ),
    );
  }

  Widget _buildShopNavigationTile({required BuildContext context, required IconData icon, required String title, required String routeName}) {
    return ListTile(
      leading: Icon(icon, size: 30),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}