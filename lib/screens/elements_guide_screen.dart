import 'package:flutter/material.dart';
import '../widgets/themed_scaffold.dart';
import '../elemental_system.dart'; // Import your elemental system

class ElementsGuideScreen extends StatelessWidget {
  const ElementsGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Elements Guide'),
        toolbarHeight: 30,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: CardType.values.map((attackerType) {
          return _buildElementInfo(context, attackerType);
        }).toList(),
      ),
    );
  }

  Widget _buildElementInfo(BuildContext context, CardType attackerType) {
    List<Widget> strengths = [];
    List<Widget> weaknesses = [];
    List<Widget> neutral = [];

    for (var defenderType in CardType.values) {
      if (attackerType == defenderType) continue; // Skip self-comparison for this display

      double multiplier = ElementalSystem.getTypeEffectivenessMultiplier(attackerType, defenderType);
      if (multiplier > 1.0) {
        strengths.add(Text(defenderType.toString().split('.').last, style: TextStyle(color: Colors.green.shade700)));
      } else if (multiplier < 1.0 && multiplier > 0) { // Ensure it's a weakness, not immunity (if you add 0x)
        weaknesses.add(Text(defenderType.toString().split('.').last, style: TextStyle(color: Colors.red.shade700)));
      } else {
        // Could also explicitly list neutral interactions if desired
        // For now, we'll just show strengths and weaknesses
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attackerType.toString().split('.').last,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _getElementColor(attackerType)),
            ),
            const SizedBox(height: 8),
            if (strengths.isNotEmpty) ...[
              Text("Strong Against (x1.5):", style: Theme.of(context).textTheme.titleMedium),
              Wrap(spacing: 8.0, runSpacing: 4.0, children: strengths),
              const SizedBox(height: 8),
            ],
            if (weaknesses.isNotEmpty) ...[
              Text("Weak Against (x0.75):", style: Theme.of(context).textTheme.titleMedium),
              Wrap(spacing: 8.0, runSpacing: 4.0, children: weaknesses),
              const SizedBox(height: 8),
            ],
            if (strengths.isEmpty && weaknesses.isEmpty && attackerType != CardType.NEUTRAL)
              Text("Neutral against all other types.", style: Theme.of(context).textTheme.bodyMedium),
            if (attackerType == CardType.NEUTRAL)
              Text("Neutral: Deals normal damage to all types and receives normal damage from all types.", style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  // Helper to get a color for the element type for display purposes
  Color _getElementColor(CardType type) {
    switch (type) {
      case CardType.FIRE:
        return Colors.red.shade700;
      case CardType.WATER:
        return Colors.blue.shade700;
      case CardType.GRASS:
        return Colors.green.shade700;
      case CardType.ELECTRIC:
        return Colors.yellow.shade800;
      case CardType.GROUND:
        return Colors.brown.shade600;
      case CardType.LIGHT:
        return Colors.yellow.shade300;
      case CardType.DARK:
        return Colors.deepPurple.shade700;
      case CardType.NEUTRAL:
        return Colors.grey.shade700;
      default:
        return Colors.black;
    }
  }
}