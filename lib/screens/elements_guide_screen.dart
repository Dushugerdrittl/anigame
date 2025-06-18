import 'package:flutter/material.dart';
import '../widgets/themed_scaffold.dart';
import '../elemental_system.dart'; // Import your elemental system

// Define some common spacing and icon size constants
const double kSmallSpacing = 3.0;
const double kMediumSpacing = 6.0;
const double kLargeSpacing = 10.0;
const double kChipIconSize = 14.0;
const double kSectionIconSize = 18.0;

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
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0,
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
      if (attackerType == defenderType) {
        continue; // Skip self-comparison for this display
      }

      double multiplier = ElementalSystem.getTypeEffectivenessMultiplier(
        attackerType,
        defenderType,
      );
      if (multiplier > 1.0) {
        strengths.add(
          Chip(
            label: Text(
              defenderType.toString().split('.').last, // Keep enum name
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
            ), // Smaller text
            backgroundColor: Colors.green.withOpacity(0.2),
            labelStyle: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
            avatar: Icon(
              Icons.arrow_upward,
              color: Colors.green.shade700,
              size: kChipIconSize,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 1,
            ), // Reduced padding
          ),
        );
      } else if (multiplier < 1.0 && multiplier > 0) {
        // Ensure it's a weakness, not immunity (if you add 0x)
        weaknesses.add(
          Chip(
            label: Text(
              defenderType.toString().split('.').last, // Keep enum name
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ), // Smaller text
            backgroundColor: Colors.red.withOpacity(0.2),
            labelStyle: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.bold,
            ),
            avatar: Icon(
              Icons.arrow_downward,
              color: Colors.red.shade700,
              size: kChipIconSize,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 1,
            ), // Reduced padding
          ),
        );
      } else {
        // Could also explicitly list neutral interactions if desired
        // For now, we'll just show strengths and weaknesses
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: kMediumSpacing),
      elevation: 2, // Slightly reduced elevation
      child: Padding(
        padding: const EdgeInsets.all(kLargeSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attackerType.toString().split('.').last,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                // Smaller title
                fontWeight: FontWeight.bold,
                color: _getElementColor(attackerType),
              ),
            ),
            const SizedBox(height: kMediumSpacing),
            if (strengths.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade700,
                    size: kSectionIconSize,
                  ),
                  const SizedBox(width: kMediumSpacing),
                  Text(
                    "Strong Against (x1.5):",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      // Smaller label
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kSmallSpacing),
              Wrap(
                spacing: kMediumSpacing,
                runSpacing: kSmallSpacing,
                children: strengths,
              ),
              const SizedBox(height: kMediumSpacing),
            ],
            if (weaknesses.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: Colors.red.shade700,
                    size: kSectionIconSize,
                  ),
                  const SizedBox(width: kMediumSpacing),
                  Text(
                    "Weak Against (x0.75):",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      // Smaller label
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kSmallSpacing),
              Wrap(
                spacing: kMediumSpacing,
                runSpacing: kSmallSpacing,
                children: weaknesses,
              ),
              const SizedBox(height: kMediumSpacing),
            ],
            if (strengths.isEmpty &&
                weaknesses.isEmpty &&
                attackerType != CardType.NEUTRAL)
              Text(
                "Neutral against all other types.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ), // Smaller text
              ),
            if (attackerType == CardType.NEUTRAL)
              Text(
                "Neutral: Deals normal damage to all types and receives normal damage from all types.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ), // Smaller text
              ),
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
