import 'package:flutter/material.dart';
import '../widgets/themed_scaffold.dart'; // Import ThemedScaffold

class RaidGuideScreen extends StatelessWidget {
  const RaidGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.primary,
    );
    final TextStyle? headingStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final TextStyle? bodyStyle = theme.textTheme.bodyMedium;
    final TextStyle? highlightStyle = bodyStyle?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.secondary,
    );

    return ThemedScaffold(
      appBar: AppBar(
        title: const Text("Raid Battle Guide"),
        toolbarHeight: 30,
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow for a flatter look
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text("Raid Battle Guide", style: titleStyle)),
                  const SizedBox(height: 16.0),
                  Text("Welcome to Raid Battles!", style: headingStyle),
                  const SizedBox(height: 8.0),
                  Text(
                    "Raid Battles are challenging encounters where you team up with other players (or go solo for lower rarity raids) to defeat a powerful boss card.",
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 12.0),

                  Text("Joining a Raid:", style: headingStyle),
                  const SizedBox(height: 4.0),
                  Text(
                    " • Go to the 'Events' screen to see active raid lobbies.\n"
                    " • Each lobby shows the boss, its rarity, and time remaining.\n"
                    " • Join a lobby before it expires or the battle starts. Max 6 players per lobby.",
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 12.0),

                  Text("The Battle:", style: headingStyle),
                  const SizedBox(height: 4.0),
                  Text(
                    " • Once the lobby leader starts the battle, or the lobby timer runs out with enough players, the fight begins!\n"
                    " • The battle is automated over 20 rounds.\n"
                    " • Your active card and the boss will automatically attack each other based on speed each round.\n"
                    " • You have 3 Special Attacks per attempt. Use them wisely by tapping the 'Special Attack' button!\n"
                    " • You can also use your active card's Talent if you have enough mana. This is separate from special attacks.",
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    " • Your goal is to contribute to depleting the boss's global HP pool with other players before the raid timer ends.",
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 12.0),

                  Text("Team & Strategy:", style: headingStyle),
                  const SizedBox(height: 4.0),
                  Text(
                    " • You select a team of up to 3 cards for your attempt.\n"
                    " • If your active card is defeated, the next card in your team (if available and healthy) will take over.\n"
                    " • If all your cards are defeated, your attempt ends, but the damage you dealt to the boss remains.",
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 12.0),

                  Text("Rewards:", style: headingStyle),
                  const SizedBox(height: 4.0),
                  Text(
                    " • If the raid boss is defeated globally, all participants who dealt damage receive rewards.\n"
                    " • Rewards include Gold, Diamonds, Elemental Shards, and a chance to get a copy of the defeated boss card (rarity based on luck and raid difficulty).",
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 4.0),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: " • Higher rarity raids offer ",
                          style: bodyStyle,
                        ),
                        TextSpan(text: "better rewards", style: highlightStyle),
                        TextSpan(
                          text: " but are much tougher!",
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // The "Got it!" button is removed as the AppBar's back button will handle navigation.
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
