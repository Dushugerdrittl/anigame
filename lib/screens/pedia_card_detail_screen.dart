import 'package:flutter/material.dart';
import '../card_model.dart' as app_card;
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold
import '../widgets/star_display_widget.dart';
import '../utils/rarity_stats_util.dart'; // Import the utility

class PediaCardDetailScreen extends StatelessWidget {
  final app_card.Card card;

  const PediaCardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
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
        title: Text(card.name),
        toolbarHeight: 30, // Set the AppBar height to 30
      ),
      body: SingleChildScrollView( // Make the body scrollable
        child: Padding( 
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0), // Adjusted padding
          child: Center( 
            child: _buildDetailedCardView(context, card), // This is the main content Card
          ),
        ),
      ),
    );
  }

  // A more detailed card view for this screen
  Widget _buildDetailedCardView(BuildContext context, app_card.Card card) {
    // Since this is Pedia, we show base stats of the template.
    // The 'card' object here is a template card from CardDefinitions.
    return Card(
      elevation: 8.0, // Slightly increased elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Consistent rounded corners
      ),
      clipBehavior: Clip.antiAlias, // Ensures gradient respects rounded corners
      // Add a subtle gradient background to the main card
      // decoration: BoxDecoration(
      //   gradient: LinearGradient(
      //     colors: [Theme.of(context).colorScheme.surface.withOpacity(0.95), Theme.of(context).colorScheme.surfaceContainerLowest.withOpacity(0.9)],
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //   ),
      // ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced internal padding of the main Card
        child: Column(
          children: [
            StarDisplayWidget( // Add star display
              ascensionLevel: card.ascensionLevel, // Template ascension is usually 0
              rarity: card.rarity,
              starSize: 18, // Adjusted star size
            ),
            const SizedBox(height: 8), // Spacing after stars
            Text(card.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text("Rarity: ${card.rarity.toString().split('.').last.replaceAll('_', ' ')}", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _getRarityColor(card.rarity, context))),
            Text("Max Lvl: ${card.maxCardLevel}", style: Theme.of(context).textTheme.titleSmall),
            // Text("Base Evo: ${card.evolutionLevel}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.deepPurpleAccent)),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0), 
              child: Container( // Wrap Image.asset for clipping and fixed size
                width: 200, // Further increased width
                height: 260, // Further increased height
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0), // Optional: if you want rounded corners for the image
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(2,2))],
                ),
                child: Image.asset(
                  'assets/${card.imageUrl}',
                  fit: BoxFit.cover, // Change to cover
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined, size: 100, color: Colors.grey),
                ),
              ),
            ),
            Text("Type: ${card.type.toString().split('.').last}", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            if (card.talent != null) ...[
              Text("Talent: ${card.talent!.name}", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  card.talent!.description, 
                  style: Theme.of(context).textTheme.bodySmall, 
                  textAlign: TextAlign.center,
                  maxLines: 2, // Limit description lines
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (card.talent!.manaCost > 0)
                Text("Mana Cost: ${card.talent!.manaCost}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue.shade700)),
            ],
            const SizedBox(height: 12),
            _buildSectionTitle(context, "Base Stats (as ${card.rarity.toString().split('.').last.replaceAll('_', ' ')})"),
            _buildStatRow(context, "HP:", "${card.maxHp}", Colors.green.shade700),
            _buildStatRow(context, "Attack:", "${card.attack}", Colors.red.shade700),
            _buildStatRow(context, "Defense:", "${card.defense}", Colors.blue.shade700),
            _buildStatRow(context, "Speed:", "${card.speed}", Colors.orange.shade700),
            
            const SizedBox(height: 12),
            // Calculate and display SR stats if the card is not already SR or UR
            if (card.rarity.index < app_card.CardRarity.SUPER_RARE.index) ...[
              _buildSectionTitle(context, "Base Stats (as Super Rare)", titleColor: _getRarityColor(app_card.CardRarity.SUPER_RARE, context)),
              _displayCalculatedRarityStats(context, card, app_card.CardRarity.SUPER_RARE, isEvolved: false),
              const SizedBox(height: 6),
              _buildSectionTitle(context, "Max Evo SR Stats (Evo 3)", titleColor: _getRarityColor(app_card.CardRarity.SUPER_RARE, context)),
              _displayCalculatedRarityStats(context, card, app_card.CardRarity.SUPER_RARE, isEvolved: true),
              const SizedBox(height: 12),
            ],

            // const SizedBox(height: 8), // Spacing handled by the block above if it renders
            // Calculate and display UR stats if the card is not already UR
            if (card.rarity.index < app_card.CardRarity.ULTRA_RARE.index) ...[
              _buildSectionTitle(context, "Base Stats (as Ultra Rare)", titleColor: _getRarityColor(app_card.CardRarity.ULTRA_RARE, context)),
              _displayCalculatedRarityStats(context, card, app_card.CardRarity.ULTRA_RARE, isEvolved: false),
              const SizedBox(height: 6),
              _buildSectionTitle(context, "Max Evo UR Stats (Evo 3)", titleColor: _getRarityColor(app_card.CardRarity.ULTRA_RARE, context)),
              _displayCalculatedRarityStats(context, card, app_card.CardRarity.ULTRA_RARE, isEvolved: true),
              const SizedBox(height: 12),
            ],

            // If the card itself is SR or UR, show its max evo stats
            if (card.rarity == app_card.CardRarity.SUPER_RARE || card.rarity == app_card.CardRarity.ULTRA_RARE) ...[
              // const SizedBox(height: 8), // Spacing handled by blocks above if they render
              _buildSectionTitle(context, "Max Evo Stats (Evo 3, as ${card.rarity.toString().split('.').last.replaceAll('_', ' ')})", titleColor: _getRarityColor(card.rarity, context)),
              _displayCalculatedRarityStats(context, card, card.rarity, isEvolved: true),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, {Color? titleColor}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _displayCalculatedRarityStats(BuildContext context, app_card.Card originalTemplateCard, app_card.CardRarity targetRarity, {required bool isEvolved}) {
    // First, get the base stats for the targetRarity from the original common template stats
    final rarityAdjustedStats = RarityStatsUtil.calculateStatsForRarity(
      baseHp: originalTemplateCard.maxHp, 
      baseAttack: originalTemplateCard.attack,
      baseDefense: originalTemplateCard.defense,
      baseSpeed: originalTemplateCard.speed,
      rarity: targetRarity,
    );

    int finalHp = rarityAdjustedStats['hp']!;
    int finalAttack = rarityAdjustedStats['attack']!;
    int finalDefense = rarityAdjustedStats['defense']!;
    int finalSpeed = rarityAdjustedStats['speed']!;

    if (isEvolved) {
      double evolutionMultiplier = 1.0 + (3 * 0.10); // Evo 3 = +30%
      finalHp = (finalHp * evolutionMultiplier).round();
      finalAttack = (finalAttack * evolutionMultiplier).round();
      finalDefense = (finalDefense * evolutionMultiplier).round();
      finalSpeed = (finalSpeed * evolutionMultiplier).round();
    }

    return Column(
      children: [
        _buildStatRow(context, "HP:", "$finalHp", Colors.green.shade700),
        _buildStatRow(context, "Attack:", "$finalAttack", Colors.red.shade700),
        _buildStatRow(context, "Defense:", "$finalDefense", Colors.blue.shade700),
        _buildStatRow(context, "Speed:", "$finalSpeed", Colors.orange.shade700),
      ],
    );
  }

  Color _getRarityColor(app_card.CardRarity rarity, BuildContext context) {
    switch (rarity) {
      case app_card.CardRarity.COMMON:
        return Colors.grey.shade600;
      case app_card.CardRarity.UNCOMMON:
        return Colors.green.shade600;
      case app_card.CardRarity.RARE:
        return Colors.blue.shade600;
      case app_card.CardRarity.SUPER_RARE:
        return Colors.purple.shade600;
      case app_card.CardRarity.ULTRA_RARE:
        return Colors.orange.shade700;
    }
  }

  Widget _buildStatRow(BuildContext context, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0), // Adjusted padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}