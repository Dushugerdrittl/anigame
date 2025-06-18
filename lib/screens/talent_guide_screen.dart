import 'package:flutter/material.dart';
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold
import '../talent_system.dart'; // Import Talent and TalentType
import '../data/talent_definitions.dart'; // Import TalentDefinitions

class TalentGuideScreen extends StatelessWidget {
  const TalentGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For demonstration, let's get all talent types.
    // We will iterate through the keys of our defined talents map.
    final List<TalentType> definedTalentTypes = TalentDefinitions
        .allTalents
        .keys
        .toList();

    return ThemedScaffold(
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
        title: const Text('Talent Guide'),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow
        toolbarHeight: 30, // Set the AppBar height to 30
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: definedTalentTypes.length,
        itemBuilder: (context, index) {
          final talentType = definedTalentTypes[index];
          final Talent? talent = TalentDefinitions.allTalents[talentType];

          if (talent == null) {
            // Should not happen if definedTalentTypes comes from the map keys
            return const Card(
              child: ListTile(title: Text("Talent data not found")),
            );
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              title: Text(
                talent.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    talent.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (talent.manaCost > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Mana Cost: ${talent.manaCost}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
