import 'package:flutter/material.dart';
import '../talent_system.dart'; // To access TalentType and Talent
import '../data/card_definitions.dart'; // To get example talent descriptions

class TalentsListGuideScreen extends StatelessWidget {
  const TalentsListGuideScreen({super.key});

  // Helper to find an example talent for a given type
  Talent? _findExampleTalentForType(TalentType type) {
    for (var card in CardDefinitions.availableCards) {
      if (card.talent?.type == type) {
        return card.talent;
      }
    }
    return null; // Should not happen if all TalentTypes are used
  }

  @override
  Widget build(BuildContext context) {
    final talentTypes = TalentType.values; // Get all defined talent types

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talents Guide'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Understanding Talents",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Talents are special abilities unique to each card, providing various advantages in battle. They can be passive (always active or trigger automatically under certain conditions) or active (require mana to use).",
            ),
            const SizedBox(height: 16),
            Text(
              "Available Talents:",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: talentTypes.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final talentType = talentTypes[index];
                final exampleTalent = _findExampleTalentForType(talentType);
                final talentName = talentType.toString().split('.').last;

                String activationInfo = "Passive";
                if (exampleTalent != null && exampleTalent.manaCost > 0) {
                  activationInfo = "Active (Cost: ${exampleTalent.manaCost} Mana)";
                } else if (exampleTalent == null) {
                  // Attempt to infer from common active talent types if no example found
                  // This is a fallback, ideally all types would have an example
                  if ([TalentType.REGENERATION, TalentType.REJUVENATION, TalentType.PRECISION, TalentType.BLAZE, TalentType.TIME_BOMB].contains(talentType)) {
                     activationInfo = "Active (Mana Cost Varies)";
                  }
                }

                return ListTile(
                  title: Text(talentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activationInfo, style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.secondary)),
                      const SizedBox(height: 4),
                      Text(exampleTalent?.description ?? "General effects related to $talentName."),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}