import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import '../game_state.dart';
import '../card_model.dart' as app_card;
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold
import '../widgets/star_display_widget.dart'; // Import StarDisplayWidget

class CardDetailScreen extends StatelessWidget {
  final app_card.Card card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>(); // Watch for currency updates
    // Find the latest instance of the card from userOwnedCards to reflect any upgrades
    // TODO: Consider if this lookup is still the best approach or if the card instance passed to the screen should be the source of truth, updated via callbacks or state management.
    final app_card.Card currentCardInstance = gameState.userOwnedCards.firstWhere(
      (ownedCard) => ownedCard.id == card.id,
      orElse: () {
        // This case should ideally not be reached if card IDs are managed correctly.
        // Fallback to the initially passed card.
        return card; 
      },
    );
    
    // Get new costs from GameState
    final goldCost = gameState.getGoldCostForLevelUp(currentCardInstance);
    final shardCost = gameState.getShardCostForLevelUp(currentCardInstance);
    final requiredShardType = gameState.getRequiredShardTypeForLevelUp(currentCardInstance);

    return ThemedScaffold( // Use ThemedScaffold
      appBar: AppBar(
        title: Text(currentCardInstance.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Chip(
              avatar: Icon(Icons.monetization_on_outlined, color: Theme.of(context).colorScheme.onSecondaryContainer),
              label: Text('${gameState.playerCurrency}', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Use a larger card display here (similar to BattleScreen's _buildCardDisplay)
            _buildDetailedCardView(context, currentCardInstance),
            const SizedBox(height: 20),
            if (currentCardInstance.level < currentCardInstance.maxCardLevel && goldCost != -1 && shardCost != -1 && requiredShardType != null) ...[
              Text(
                "Level Up Cost:",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                "$goldCost Gold",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                "& $shardCost ${requiredShardType.toString().split('.').last.replaceAll('_', ' ')}s (or Souls)",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                "You have: ${gameState.playerShards[requiredShardType] ?? 0} ${requiredShardType.toString().split('.').last.replaceAll('_', ' ')}s / ${gameState.playerSouls} Souls",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.upgrade_outlined),
                label: const Text("Level Up (Currency)"),
                onPressed: gameState.playerCurrency >= goldCost && 
                           ((gameState.playerShards[requiredShardType] ?? 0) >= shardCost || gameState.playerSouls >= (shardCost - (gameState.playerShards[requiredShardType] ?? 0)))
                    ? () {
                        bool success = gameState.upgradeCard(currentCardInstance); // No cost parameter
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${currentCardInstance.name} upgraded to Lvl ${currentCardInstance.level}!"), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to upgrade. Check resources or if max level reached."), backgroundColor: Colors.red),
                          );
                        }
                      }
                    : null, // Disable if not enough resources or max level
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ] else ...[
              Text("Max Level Reached!", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green)),
            ],
            const SizedBox(height: 16),
            // Evolve Button
            if (gameState.canEvolve(currentCardInstance)) // Assuming canEvolve exists in GameState
              ElevatedButton.icon(
                icon: const Icon(Icons.trending_up_outlined), // Or a more specific evolution icon
                label: const Text("Evolve Card"),
                onPressed: () {
                  _showEvolutionDialog(context, gameState, currentCardInstance);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.teal, // Example color
                  foregroundColor: Colors.white,
                ),
              ),
            if (gameState.canEvolve(currentCardInstance)) // Add spacing if Evolve button was shown
              const SizedBox(height: 16),
            // Ascension Button
            if (gameState.canAscend(currentCardInstance))
              ElevatedButton.icon(
                icon: const Icon(Icons.star_outlined),
                label: const Text("Ascend Card"),
                onPressed: () {
                  _showSacrificeSelectionDialog(context, gameState, currentCardInstance);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Theme.of(context).colorScheme.onTertiary,
                ),
              )
            else ...[ // Use collection else
              if (currentCardInstance.rarity == app_card.CardRarity.SUPER_RARE || currentCardInstance.rarity == app_card.CardRarity.ULTRA_RARE)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _getAscensionDisabledReason(currentCardInstance, gameState),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orange.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
            const SizedBox(height: 20),
            // You can add more details here, like talent description, evolution info etc.
          ],
        ),
      ),
    );
  }

  String _getAscensionDisabledReason(app_card.Card card, GameState gameState) {
    if (card.ascensionLevel >= card.maxAscensionLevel) {
      return "Max Ascension Reached!";
    }
    // These checks mirror parts of GameState.canAscend to provide UI feedback
    if (card.evolutionLevel < 3) {
      return "Requires Evo 3 to ascend.";
    }
    bool hasSacrificeEvo0Card = gameState.userOwnedCards.any((ownedCard) =>
        ownedCard.id != card.id &&
        ownedCard.originalTemplateId == card.originalTemplateId &&
        ownedCard.rarity == card.rarity &&
        ownedCard.evolutionLevel == 0);
    if (!hasSacrificeEvo0Card) {
      return "No suitable Evo 0 duplicate available for sacrifice.";
    }

    final app_card.ShardType? elementalShardType = gameState.getElementalShardTypeFromCardType(card.type); // Prefixed with app_card.
    final int elementalShardCost = 30 + (card.ascensionLevel * 15);
    if (elementalShardType != null) {
      int elementalShardsOwned = gameState.playerShards[elementalShardType] ?? 0;
      if (elementalShardsOwned < elementalShardCost) {
        int deficit = elementalShardCost - elementalShardsOwned;
        if (gameState.playerSouls < deficit) {
          return "Not enough ${elementalShardType.toString().split('.').last.replaceAll('_', ' ')}s or Souls.";
        }
      }
    } // If elementalShardType is null, GameState.canAscend should handle it.
    // The LEGENDARY_SHARD check was removed here as the shard type itself is gone.
    // If there's a new cost for high-tier UR ascension (e.g. gold, or more elemental shards),
    // that logic would be in GameState.canAscend(), and this UI helper would reflect that
    // if GameState.canAscend() returns false for that reason.
    // For now, if GameState.canAscend() is false and other conditions here are met,
    // it implies a condition handled within GameState.canAscend() itself.
    return "Ascension requirements not fully met. Check Evo level, duplicates, and shards."; // Generic fallback
  }

  // --- Ascension Dialog ---
  void _showSacrificeSelectionDialog(BuildContext context, GameState gameState, app_card.Card cardToAscend) {
    // Find suitable sacrifice cards (Evo 0 duplicates of the same rarity)
    final suitableSacrifices = gameState.userOwnedCards.where((c) =>
        c.id != cardToAscend.id &&
        c.rarity == cardToAscend.rarity &&
        c.evolutionLevel == 0).toList(); // Sacrifice must be Evo 0

    if (suitableSacrifices.isEmpty) { // Should be caught by canAscend, but good to double check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No suitable cards available for sacrifice."), backgroundColor: Colors.orange),
      );
      return;
    }

    // Calculate shard costs based on GameState logic
    final app_card.ShardType? elementalShardType = gameState.getElementalShardTypeFromCardType(cardToAscend.type); // Prefixed with app_card.
    final int elementalShardCost = 30 + (cardToAscend.ascensionLevel * 15);
    final int legendaryShardCost = (cardToAscend.rarity == app_card.CardRarity.ULTRA_RARE && cardToAscend.ascensionLevel >= 15)
        ? (5 + ((cardToAscend.ascensionLevel - 15) ~/ 2)) 
        : 0;
    // Legendary shard check removed as the shard type itself is removed.
    // The cost logic for high-tier UR ascension might need a new resource if not elemental shards.
    // For now, we only check elemental shards. If legendaryShardCost > 0, GameState.canAscend would handle if a new resource is needed.
    bool canAffordResources = false;
    if (elementalShardType != null) {
      int elementalShardsOwned = gameState.playerShards[elementalShardType] ?? 0;
      canAffordResources = elementalShardsOwned >= elementalShardCost || 
                           gameState.playerSouls >= (elementalShardCost - elementalShardsOwned);
    }


    app_card.Card? selectedSacrifice; // To hold the selected sacrifice card

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Wrap the entire AlertDialog in a StatefulBuilder
        return StatefulBuilder(
          builder: (BuildContext sbfDialogContext, StateSetter setDialogState) {
            return AlertDialog(
              title: Text("Select Sacrifice Card for ${cardToAscend.name}"),
              content: SizedBox( // Constrain the width of the AlertDialog's content
                width: MediaQuery.of(dialogContext).size.width * 0.8, // Or a fixed value like 300.0
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Important for Column in Dialog
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ascension Costs:", style: Theme.of(sbfDialogContext).textTheme.titleMedium),
                    if (elementalShardType != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("- $elementalShardCost ${elementalShardType.toString().split('.').last.replaceAll('_', ' ')} (or Souls)"),
                          Text("  (Have: ${gameState.playerShards[elementalShardType] ?? 0} Shards / ${gameState.playerSouls} Souls)", style: Theme.of(sbfDialogContext).textTheme.bodySmall),
                        ],
                      ),
                    // The legendaryShardCost Text is removed as legendaryShardCost is 0
                    const SizedBox(height: 10),
                    Text("Select 1 Evo 0 Duplicate to Sacrifice:", style: Theme.of(sbfDialogContext).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SizedBox( 
                          height: 200, 
                          width: double.infinity, // Make ListView take full width of parent SizedBox
                          child: ListView.builder(
                            shrinkWrap: true, // Still useful with fixed height parent
                            itemCount: suitableSacrifices.length,
                            itemBuilder: (listContext, index) { // Renamed context
                              final sacrifice = suitableSacrifices[index];
                              final bool isSelected = selectedSacrifice?.id == sacrifice.id;
                              return ListTile(
                                leading: Image.asset('assets/${sacrifice.imageUrl}', width: 40, height: 56, fit: BoxFit.contain),
                                title: Text(sacrifice.name),
                                subtitle: Text("Lvl: ${sacrifice.level}, Evo: ${sacrifice.evolutionLevel}, Rarity: ${sacrifice.rarity.toString().split('.').last}"),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                onTap: () {
                                  setDialogState(() { // Use setDialogState from the outer StatefulBuilder
                                    selectedSacrifice = isSelected ? null : sacrifice;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(sbfDialogContext).pop(),
                ),
                ElevatedButton(
                  // Enable only if a sacrifice is selected and shards are sufficient
                  onPressed: (selectedSacrifice != null && canAffordResources)
                      ? () {
                          bool success = gameState.ascendCard(cardToAscend, selectedSacrifice!.id);
                          Navigator.of(sbfDialogContext).pop(); // Close the dialog
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${cardToAscend.name} ascended!"), backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Ascension failed. Please check conditions or shard balance."), backgroundColor: Colors.red),
                            );
                          }
                        }
                      : null, // Disable if conditions not met
                  child: const Text('Ascend'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // --- Evolution Dialog ---
  void _showEvolutionDialog(BuildContext context, GameState gameState, app_card.Card cardToEvolve) {
    // Find the suitable sacrifice card (Max level, same evo level duplicate)
    final suitableSacrifice = gameState.userOwnedCards.firstWhereOrNull((c) =>
        c.id != cardToEvolve.id &&
        c.originalTemplateId == cardToEvolve.originalTemplateId &&
        c.rarity == cardToEvolve.rarity &&
        c.evolutionLevel == cardToEvolve.evolutionLevel &&
        c.level == c.maxCardLevel); // Sacrifice must be max level

    if (suitableSacrifice == null) { // Should be caught by canEvolve, but good to double check
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No suitable max level duplicate available for evolution."), backgroundColor: Colors.orange),
      );
      return;
    }

    // Calculate shard costs based on GameState logic
    final app_card.ShardType? requiredElementalShardType = gameState.getElementalShardTypeFromCardType(cardToEvolve.type);
    int elementalShardCostForEvolution = 0;
    if (cardToEvolve.evolutionLevel == 0) {
      elementalShardCostForEvolution = 50;
    } else if (cardToEvolve.evolutionLevel == 1) elementalShardCostForEvolution = 75;
    else if (cardToEvolve.evolutionLevel == 2) elementalShardCostForEvolution = 100;

    if (requiredElementalShardType == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot determine elemental shard type for ${cardToEvolve.name}."), backgroundColor: Colors.orange),
      );
      return;
    }
    bool canAffordResources = false;
    int elementalShardsOwned = gameState.playerShards[requiredElementalShardType] ?? 0;
    if (elementalShardsOwned >= elementalShardCostForEvolution) {
      canAffordResources = true;
    } else {
      canAffordResources = gameState.playerSouls >= (elementalShardCostForEvolution - elementalShardsOwned);
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // For evolution, the sacrifice is fixed, so the dialog's Ascend button state doesn't need to change based on selection.
        // No need for an outer StatefulBuilder here unless other parts of the dialog content needed to be stateful.
        return AlertDialog(
          title: Text("Evolve ${cardToEvolve.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Evolve to Evo ${cardToEvolve.evolutionLevel + 1}", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Text("Requires:", style: Theme.of(context).textTheme.titleMedium),
              Text("- 1x Max Level Evo ${cardToEvolve.evolutionLevel} Duplicate of ${cardToEvolve.name}"),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("- $elementalShardCostForEvolution ${requiredElementalShardType.toString().split('.').last.replaceAll('_', ' ')} (or Souls)"),
                  Text("  (Have: ${gameState.playerShards[requiredElementalShardType] ?? 0} Shards / ${gameState.playerSouls} Souls)", style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              Text("Sacrifice Card Found:", style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                leading: Image.asset('assets/${suitableSacrifice.imageUrl}', width: 40, height: 56, fit: BoxFit.contain),
                title: Text(suitableSacrifice.name),
                subtitle: Text("Lvl: ${suitableSacrifice.level}, Evo: ${suitableSacrifice.evolutionLevel}, Rarity: ${suitableSacrifice.rarity.toString().split('.').last}"),
                // No selection needed, it's the required sacrifice
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              // Enable only if shards are sufficient
              onPressed: canAffordResources
                  ? () {
                      // Pass the ID of the single required sacrifice card
                      bool success = gameState.evolveCard(cardToEvolve, suitableSacrifice.id);
                      Navigator.of(dialogContext).pop(); // Close the dialog
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${cardToEvolve.name} evolved!"), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ascension failed. Please check conditions or shard balance."), backgroundColor: Colors.red),
                        );
                      }
                    }
                  : null, // Disable if conditions not met
              child: const Text('Evolve'),
            ),
          ],
        );
      },
    );
  }

  // --- Enhance Dialog ---
  void _showEnhanceDialog(BuildContext context, GameState gameState, app_card.Card cardToEnhance) {
    final TextEditingController soulsController = TextEditingController();
    // TODO: Add UI for selecting fodder cards. For now, only souls.

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Enhance ${cardToEnhance.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Current Level: ${cardToEnhance.level}"),
              Text("XP: ${cardToEnhance.xp} / ${cardToEnhance.xpToNextLevel}"),
              const SizedBox(height: 16),
              Text("Available Souls: ${gameState.playerSouls}"),
              TextField(
                controller: soulsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Souls to use",
                  hintText: "Enter amount",
                ),
              ),
              // TODO: Add Fodder Card Selection UI here
              // For example, a button to open another dialog/screen to pick fodders.
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Enhance'),
              onPressed: () {
                int soulsToUse = int.tryParse(soulsController.text) ?? 0;
                // List<String> selectedFodderIds = []; // Get from fodder selection UI

                if (soulsToUse <= 0 /* && selectedFodderIds.isEmpty */) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter souls to use or select fodder."), backgroundColor: Colors.orange),
                  );
                  return;
                }

                bool success = gameState.enhanceCard(cardToEnhance, soulsToUse: soulsToUse /*, fodderCardIds: selectedFodderIds */);
                Navigator.of(dialogContext).pop(); // Close the dialog

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${cardToEnhance.name} enhanced!"), backgroundColor: Colors.green),
                  );
                } else {
                  // GameState.enhanceCard already logs specific reasons if it returns false (e.g., max level, no XP gained)
                  // We can show a generic message or rely on the log.
                }
              },
            ),
          ],
        );
      },
    );
  }

  // A more detailed card view for this screen
  Widget _buildDetailedCardView(BuildContext context, app_card.Card card) {
     return Card(
      elevation: 6.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StarDisplayWidget( // Add star display
              ascensionLevel: card.ascensionLevel,
              rarity: card.rarity,
              starSize: 20, // Larger stars for detail view
            ),
            const SizedBox(height: 8), // Spacing after stars
            Text(card.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text("Rarity: ${card.rarity.toString().split('.').last.replaceAll('_', ' ')}", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: _getRarityColor(card.rarity, context))),
            Text("Evolution: Evo ${card.evolutionLevel}", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.deepPurpleAccent)),
            Text("Lvl: ${card.level} / ${card.maxCardLevel}", style: Theme.of(context).textTheme.titleMedium),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0), // Keep padding around the container
              child: Container( // Wrap Image.asset for clipping and fixed size
                width: 150, // Current width
                height: 200, // Current height
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0), // Optional: if you want rounded corners for the image
                ),
                child: Image.asset(
                  'assets/${card.imageUrl}',
                  fit: BoxFit.cover, // Change to cover
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined, size: 100, color: Colors.grey),
                ),
              ),
            ),
            Text("Type: ${card.type.toString().split('.').last}", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (card.talent != null) ...[
              Text("Talent: ${card.talent!.name}", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
              Text(card.talent!.description, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              if (card.talent!.manaCost > 0)
                Text("Mana Cost: ${card.talent!.manaCost}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue)),
            ],
            const SizedBox(height: 16),
            _buildStatRow(context, "HP:", "${card.currentHp}/${card.maxHp}", Colors.green.shade700),
            _buildStatRow(context, "Attack:", "${card.attack}", Colors.red.shade700),
            _buildStatRow(context, "Defense:", "${card.defense}", Colors.blue.shade700),
            _buildStatRow(context, "Speed:", "${card.speed}", Colors.orange.shade700),
            if (card.maxMana > 0)
              _buildStatRow(context, "Max Mana:", "${card.maxMana}", Colors.purple.shade700),
            const SizedBox(height: 16),
            if (card.level < card.maxCardLevel) ...[
              Text("XP: ${card.xp} / ${card.xpToNextLevel}", style: Theme.of(context).textTheme.titleMedium),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
                child: LinearProgressIndicator(
                  value: card.xpToNextLevel > 0 ? card.xp / card.xpToNextLevel : 0,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
        ],
      ),
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
}
