import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import '../game_state.dart';
import '../card_model.dart' as app_card;
import '../elemental_system.dart'; // Import CardType
import '../widgets/star_display_widget.dart';
import '../widgets/framed_card_image_widget.dart'; // Import the new widget
import '../widgets/status_icons_widget.dart'; // For status effect icons

// Define some common spacing and icon size constants for battle screen
const double kBattleSmallSpacing = 2.0;
const double kBattleMediumSpacing = 4.0;
const double kBattleLargeSpacing = 8.0;

const double kCardTitleFontSize = 13.0; // Adjusted for titleMedium equivalent
const double kCardLevelEvoFontSize = 8.0;
const double kCardTypeTalentFontSize = 9.0;
const double kCardStatIconSize = 14.0;
const double kCardStatBarIconSize = 16.0;
const double kCardStatBarFontSize = 10.0;

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  String _getBackgroundImage(BuildContext context, GameState gameState) {
    String defaultBg =
        "assets/Themes/battle_background_default.jpg"; // Ensure you have this asset

    if (gameState.currentBattlingFloorId != null &&
        gameState.gameFloors.isNotEmpty) {
      final floor = gameState.gameFloors.firstWhereOrNull(
        (f) => f.id == gameState.currentBattlingFloorId,
      );

      if (floor != null) {
        if (floor.backgroundImagePath != null &&
            floor.backgroundImagePath!.isNotEmpty) {
          // You might want to check if the asset actually exists here,
          // or rely on errorBuilder in Image.asset.
          return floor.backgroundImagePath!;
        } else {
          // Floor found, but it has no specific background image path defined.
          // print("Debug: Floor ${floor.name} has no specific background image. Falling back.");
        }
      } else {
        // currentBattlingFloorId was set, but no matching floor was found in gameFloors.
        print(
          "Warning: Could not find floor with ID ${gameState.currentBattlingFloorId}. Falling back.",
        );
      }
    }

    // Fallback to enemy type if no specific floor background matches
    if (gameState.enemyCard != null) {
      if (gameState.enemyCard!.type == CardType.FIRE) {
        return "assets/Themes/battle_background_fire.jpg";
      }
      if (gameState.enemyCard!.type == CardType.GRASS) {
        return "assets/Themes/battle_background_grass.jpg";
      }
      if (gameState.enemyCard!.type == CardType.WATER) {
        return "assets/Themes/battle_background_water.jpg";
      }
    }
    // Add more type-specific conditions here
    return defaultBg;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final String backgroundImageAsset = _getBackgroundImage(context, gameState);

    return WillPopScope(
      onWillPop: () async {
        if (gameState.isGameStarted && !gameState.isGameOver) {
          // Prevent back navigation during an active battle
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cannot leave an active battle!")),
          );
          return false;
        }
        // If game is over or not started, allow pop but clear state
        gameState.clearBattleState();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading:
              (!gameState.isGameStarted || gameState.isGameOver) &&
                  Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 18.0, // Smaller icon size
                  padding: EdgeInsets.zero, // Adjust padding as needed
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () {
                    gameState
                        .clearBattleState(); // Ensure state is cleared when manually going back
                    Navigator.of(context).pop();
                  },
                )
              : null, // No back button during active battle or if cannot pop
          title: const Text('Battle Arena'),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.errorContainer.withOpacity(0.0), // Fully transparent
          toolbarHeight: 30, // Set AppBar height to 30
          elevation: 0,
          automaticallyImplyLeading:
              false, // We are handling the leading widget manually
        ),
        extendBodyBehindAppBar:
            true, // Allows body to go behind appbar for full screen background
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                backgroundImageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print(
                    "Error loading background: $backgroundImageAsset. Error: $error",
                  );
                  return Image.asset(
                    "assets/Themes/battle_background_default.jpg", // Ensure you have this default
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            // Battle UI or Game Over UI
            SafeArea(
              // Ensures UI elements are not obscured by notches/system bars
              child:
                  (gameState.isGameStarted &&
                      !gameState.isGameOver &&
                      gameState.playerCard != null &&
                      gameState.enemyCard != null)
                  ? _buildBattleInterface(context, gameState)
                  : _buildGameOverInterface(context, gameState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleInterface(BuildContext context, GameState gameState) {
    return Column(
      children: [
        // Enemy Card Display (Top) - Takes up more space
        Expanded(
          flex: 4, // Adjusted flex for better balance
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kBattleLargeSpacing,
              kBattleLargeSpacing,
              kBattleLargeSpacing,
              kBattleMediumSpacing,
            ),
            child: _buildCardDisplay(
              context,
              gameState.enemyCard!,
              false,
              gameState,
            ),
          ),
        ),
        // Battle Log (Middle) - Smaller, more refined
        Container(
          height: MediaQuery.of(context).size.height * 0.15,
          margin: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: kBattleLargeSpacing,
          ),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.grey.shade700, width: 1.5),
          ),
          child: Scrollbar(
            // Added Scrollbar
            // thumbVisibility: true, // Removed to prevent error when not scrollable
            child: ListView.builder(
              reverse: true,
              itemCount: gameState.battleLog.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2.5,
                    horizontal: 4.0,
                  ),
                  child: Text(
                    gameState.battleLog[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.3,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Player Card Display (Bottom) - Takes up more space
        Expanded(
          flex: 4, // Adjusted flex
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kBattleLargeSpacing,
              kBattleMediumSpacing,
              kBattleLargeSpacing,
              kBattleLargeSpacing,
            ),
            child: _buildCardDisplay(
              context,
              gameState.playerCard!,
              true,
              gameState,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverInterface(BuildContext context, GameState gameState) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 3,
            ),
          ],
        ),
        child: SingleChildScrollView(
          // Added for smaller screens
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (gameState.isGameOver && gameState.winnerMessage != null) ...[
                Text(
                  gameState.winnerMessage!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color:
                        gameState.playerCard?.currentHp != null &&
                            gameState.playerCard!.currentHp > 0
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kBattleLargeSpacing * 3,
                ), // Larger spacing
                // --- Post-battle navigation options ---
                if (gameState.currentBattlingFloorId != null &&
                    gameState.currentBattlingLevelNumber != null) ...[
                  // It was a floor battle
                  if (gameState.playerCard?.currentHp != null &&
                      gameState.playerCard!.currentHp > 0) ...[
                    // Player won a floor battle
                    Builder(
                      builder: (context) {
                        final currentFloor = gameState.gameFloors
                            .firstWhereOrNull(
                              (f) => f.id == gameState.currentBattlingFloorId,
                            );
                        if (currentFloor == null) {
                          // This case should ideally not happen if currentBattlingFloorId is valid
                          print(
                            "Error: Current battling floor with ID '${gameState.currentBattlingFloorId}' not found in gameFloors list.",
                          );
                          return const Text(
                            "Error: Floor data missing. Cannot proceed.",
                          );
                        }
                        final int currentLevelNumber =
                            gameState.currentBattlingLevelNumber!;
                        final bool isLastLevelOfFloor =
                            currentLevelNumber >= currentFloor.numberOfLevels;
                        final int currentFloorIndex = gameState.gameFloors
                            .indexWhere((f) => f.id == currentFloor.id);
                        final bool hasNextFloor =
                            currentFloorIndex < gameState.gameFloors.length - 1;
                        final String? nextFloorId = hasNextFloor
                            ? gameState.gameFloors[currentFloorIndex + 1].id
                            : null;

                        if (!isLastLevelOfFloor) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              final nextLevel = currentLevelNumber + 1;
                              gameState.setupBattleForFloorLevel(
                                currentFloor.id,
                                nextLevel,
                              );
                            },
                            child: Text(
                              'Start Next Level (${currentLevelNumber + 1})',
                            ),
                          );
                        } else if (hasNextFloor &&
                            nextFloorId != null &&
                            gameState.unlockedFloorIds.contains(nextFloorId)) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              gameState.clearBattleState();
                              Navigator.popUntil(
                                context,
                                ModalRoute.withName('/floor_selection'),
                              );
                            },
                            child: Text(
                              'Proceed to Next Floor (${gameState.gameFloors[currentFloorIndex + 1].name})',
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: kBattleLargeSpacing * 1.5),
                  ] else ...[
                    // Player lost a floor battle
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        gameState.setupBattleForFloorLevel(
                          gameState.currentBattlingFloorId!,
                          gameState.currentBattlingLevelNumber!,
                        );
                      },
                      child: const Text('Retry Level'),
                    ),
                    const SizedBox(height: kBattleLargeSpacing * 1.5),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        "Read the guide to win battles with element and talent advantages!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/talent_guide');
                      },
                      child: const Text('Open Guide'),
                    ),
                    const SizedBox(height: kBattleLargeSpacing * 1.5),
                  ],
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    gameState.clearBattleState();
                    Navigator.popUntil(
                      context,
                      ModalRoute.withName('/floor_selection'),
                    );
                  },
                  child: const Text('Return to Floor Selection'),
                ),
              ] else if (!gameState.isGameStarted &&
                  gameState.playerCard == null) ...[
                Text(
                  "No battle started. Please select a card and an opponent.",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kBattleLargeSpacing * 2.5),
                ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      ModalRoute.withName('/'),
                    ); // Go back to home
                  },
                  child: const Text('Go to Home'),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                const SizedBox(height: kBattleLargeSpacing * 2),
                const Text("Loading battle..."),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDisplay(
    BuildContext context,
    app_card.Card card,
    bool isPlayer,
    GameState gameState,
  ) {
    final Color hpColor = Colors.red.shade400;
    final Color manaColor = Colors.blue.shade400;
    final bool isTurn =
        (isPlayer &&
            gameState.playerCard?.id ==
                gameState
                    .playerCard
                    ?.id) || // Simplified, needs actual turn logic
        (!isPlayer &&
            gameState.enemyCard?.id ==
                gameState.enemyCard?.id); // Placeholder for turn indication

    // Base container for card content
    Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0), // Consistent radius
        gradient: LinearGradient(
          colors: isPlayer
              ? [
                  Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.7),
                  Theme.of(context).colorScheme.surface.withOpacity(0.9),
                ]
              : [
                  Theme.of(context).colorScheme.errorContainer.withOpacity(0.7),
                  Theme.of(context).colorScheme.surface.withOpacity(0.9),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kBattleLargeSpacing,
          vertical: kBattleMediumSpacing + kBattleSmallSpacing,
        ), // Reduced padding
        child: Column(
          // Removed SingleChildScrollView
          mainAxisAlignment: MainAxisAlignment
              .spaceEvenly, // Distribute space, can help with overflow
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CardHeaderWidget(card: card, isPlayer: isPlayer),
            FramedCardImageWidget(
              // Use the new widget here
              card: card,
              width: 65,
              height: 85,
            ),
            const SizedBox(height: kBattleSmallSpacing),
            // HP Bar
            _buildStatBar(
              context,
              icon: Icons.favorite,
              iconColor: hpColor,
              currentValue: card.currentHp,
              maxValue: card.maxHp,
              barColor: hpColor,
            ),
            // Mana Bar (if applicable)
            if (card.maxMana > 0) ...[
              const SizedBox(height: kBattleSmallSpacing),
              _buildStatBar(
                context,
                icon: Icons.flash_on,
                iconColor: manaColor,
                currentValue: card.currentMana,
                maxValue: card.maxMana,
                barColor: manaColor,
              ),
            ],
            _CardStatsRowWidget(card: card),
            Text(
              "Type: ${card.type.toString().split('.').last}",
              style: TextStyle(
                fontSize: kCardLevelEvoFontSize,
                fontStyle: FontStyle.italic,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ), // Smaller font
            if (card.talent != null)
              Tooltip(
                message: card.talent!.description,
                preferBelow: false,
                child: Text(
                  "Talent: ${card.talent!.name}",
                  style: TextStyle(
                    fontSize: kCardTypeTalentFontSize,
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis, // Handle long talent names
                ),
              ),
            StatusIconsWidget(
              card: card,
              iconSize: 12, // This call is now valid
            ), // Made status icons smaller
          ],
        ),
      ),
    );

    return Card(
      elevation: isTurn ? 10.0 : 6.0, // Keep turn-based elevation
      margin: const EdgeInsets.symmetric(
        vertical: kBattleMediumSpacing + kBattleSmallSpacing,
        horizontal: kBattleMediumSpacing,
      ), // Apply margin here
      clipBehavior: Clip.antiAlias, // Important for rounded corners and border
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        // Revert to simpler turn-based border for the main card
        side: BorderSide(
          color: isPlayer
              ? (isTurn
                    ? Colors.blue.shade300
                    : Colors.blue.shade700.withOpacity(0.5))
              : (isTurn
                    ? Colors.red.shade300
                    : Colors.red.shade700.withOpacity(0.5)),
          width: isTurn ? 2.5 : 1.0,
        ),
      ),
      child: cardContent,
    );
  }

  Widget _buildStatBar(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required int currentValue,
    required int maxValue,
    required Color barColor,
  }) {
    double percentage = maxValue > 0 ? currentValue / maxValue : 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: kCardStatBarIconSize),
            const SizedBox(width: kBattleMediumSpacing),
            Text(
              "$currentValue/$maxValue",
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
                fontSize: kCardStatBarFontSize,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Container(
          height: 9, // Slightly thicker for better visual
          margin: const EdgeInsets.symmetric(
            horizontal: 24,
          ), // Increased margin for a sleeker look
          decoration: BoxDecoration(
            // Adding a subtle border to the bar background
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: barColor.withOpacity(0.4), width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: barColor.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 9,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardHeaderWidget extends StatelessWidget {
  final app_card.Card card;
  final bool isPlayer;

  const _CardHeaderWidget({required this.card, required this.isPlayer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "${isPlayer ? 'Player' : 'Enemy'}: ${card.name}",
          style: TextStyle(
            fontSize: kCardTitleFontSize,
            fontWeight: FontWeight.bold,
            color: isPlayer
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onErrorContainer,
            shadows: [
              Shadow(blurRadius: 1, color: Colors.black.withOpacity(0.3)),
            ],
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        StarDisplayWidget(
          ascensionLevel: card.ascensionLevel,
          rarity: card.rarity,
          starSize: 10,
        ),
        Text(
          "Lvl ${card.level} Evo ${card.evolutionLevel}",
          style: TextStyle(
            fontSize: kCardLevelEvoFontSize,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _CardStatsRowWidget extends StatelessWidget {
  final app_card.Card card;

  const _CardStatsRowWidget({required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.flash_on, // Standard icon for Attack
          color: Colors
              .orange
              .shade700, // Consider Theme.of(context).colorScheme.secondary or similar
          size: kCardStatIconSize,
        ),
        const SizedBox(
          width: kBattleSmallSpacing + 1,
        ), // Adjusted for visual balance
        Text(
          "ATK: ${card.attack}",
          style: TextStyle(
            color: Colors
                .orange
                .shade700, // Consider Theme.of(context).colorScheme.secondary
            fontWeight: FontWeight.bold,
            fontSize:
                kCardTypeTalentFontSize, // Consistent with talent/type font size
          ),
        ),
        const SizedBox(width: kBattleMediumSpacing + 1), // Spacer
        Icon(
          Icons.shield, // Standard icon for Defense
          color: Colors.brown.shade700, // Consider a theme color
          size: kCardStatIconSize,
        ),
        const SizedBox(width: kBattleSmallSpacing + 1),
        Text(
          "DEF: ${card.defense}",
          style: TextStyle(
            color: Colors.brown.shade700, // Consider a theme color
            fontWeight: FontWeight.bold,
            fontSize: kCardTypeTalentFontSize,
          ),
        ),
        const SizedBox(width: kBattleMediumSpacing + 1), // Spacer
        Icon(
          Icons.speed, // Standard icon for Speed
          color: Colors.green.shade600, // Consider a theme color
          size: kCardStatIconSize,
        ),
        const SizedBox(width: kBattleSmallSpacing + 1),
        Text(
          "SPD: ${card.speed}",
          style: TextStyle(
            color: Colors.green.shade600, // Consider a theme color
            fontWeight: FontWeight.bold,
            fontSize: kCardTypeTalentFontSize,
          ),
        ),
      ],
    );
  }
}
