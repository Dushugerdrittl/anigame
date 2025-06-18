import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/themed_scaffold.dart';
import '../game_state.dart';
import '../card_model.dart' as app_card;
import 'package:flutter/services.dart'; // For input formatters

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final theme = Theme.of(context);
    final Color neonAccentColor =
        theme.colorScheme.secondary; // Or choose a specific neon color
    final Color primaryTextColor = Colors.white.withOpacity(0.9);
    final Color secondaryTextColor = Colors.white.withOpacity(0.7);

    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: primaryTextColor.withOpacity(0.8),
            size: 16.0, // Further reduced size
          ), // Changed icon and reduced size
          padding: const EdgeInsets.all(5.0),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'OPERATIVE PROFILE', // More thematic title
          style: TextStyle(
            fontWeight: FontWeight.w600, // Slightly less bold
            color: primaryTextColor,
            letterSpacing: 1.2, // Further reduced letter spacing
            fontSize: 14, // Further reduced font size
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0, // Flat design
        toolbarHeight: 40, // Further reduced toolbar height
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            _buildUserHeader(
              context,
              gameState,
              neonAccentColor,
              primaryTextColor,
              secondaryTextColor,
            ),
            const SizedBox(height: 16), // Further Reduced
            // Stats Grid
            _buildStatsGrid(
              context,
              gameState,
              neonAccentColor,
              primaryTextColor,
              secondaryTextColor,
            ),
            const SizedBox(height: 24), // Spacing after stats grid
            // Featured Cards Display
            _buildFeaturedCardsDisplay(
              context,
              gameState,
              neonAccentColor,
              primaryTextColor,
              secondaryTextColor,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    GameState gameState,
    Color neonAccentColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          gameState.currentAuthUsername.isNotEmpty
              ? gameState.currentAuthUsername.toUpperCase()
              : "OPERATIVE",
          style: TextStyle(
            fontSize: 22, // Further Reduced
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
            letterSpacing: 1.5,
            shadows: [
              Shadow(blurRadius: 10.0, color: neonAccentColor.withOpacity(0.7)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "SERVER: Butterfly Version | UID: ${gameState.currentUserDisplayUid}",
          style: TextStyle(
            fontSize: 11,
            color: secondaryTextColor,
          ), // Further Reduced
        ),
        // Conditionally display user status if it's not empty
        if (gameState.userStatusMessage.isNotEmpty ||
            gameState.currentPlayerId ==
                gameState
                    .currentPlayerId) // Always show for own profile to allow editing
          _buildUserStatus(
            context,
            gameState,
            neonAccentColor,
            primaryTextColor,
            secondaryTextColor,
          ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    GameState gameState,
    Color neonAccentColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    // Calculate Base Level (Max Unlocked Floor)
    String maxUnlockedFloorDisplay = "Floor 1";
    if (gameState.unlockedFloorIds.isNotEmpty) {
      int highestFloorNumber = 0;
      for (var floorId in gameState.unlockedFloorIds) {
        final floorIndex = gameState.gameFloors.indexWhere(
          (f) => f.id == floorId,
        );
        if (floorIndex != -1 && (floorIndex + 1) > highestFloorNumber) {
          highestFloorNumber = floorIndex + 1;
        }
      }
      if (highestFloorNumber > 0) {
        maxUnlockedFloorDisplay = "Floor $highestFloorNumber";
      }
    }

    // Card Count (UR Cards)
    int urCardCount = gameState.userOwnedCards
        .where((card) => card.rarity == app_card.CardRarity.ULTRA_RARE)
        .length;

    // Card Power (Highest Level Card Stats)
    String highestLevelCardPowerDisplay = "N/A";
    if (gameState.userOwnedCards.isNotEmpty) {
      app_card.Card highestLevelCard = gameState.userOwnedCards.reduce(
        (currentMax, card) => card.level > currentMax.level ? card : currentMax,
      );
      int power =
          highestLevelCard.attack +
          highestLevelCard.defense +
          highestLevelCard.maxHp ~/ 10 +
          highestLevelCard.speed;
      highestLevelCardPowerDisplay = power.toString();
    }

    final stats = {
      "BASE LEVEL": maxUnlockedFloorDisplay,
      "UR CARD COUNT": urCardCount.toString(),
      "MAX CARD POWER": highestLevelCardPowerDisplay,
    };

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8, // Adjusted for 3 columns - items will be shorter
      mainAxisSpacing: 6, // Further Reduced
      crossAxisSpacing: 6, // Further Reduced
      children: stats.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.all(8), // Further Reduced internal padding
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: neonAccentColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: neonAccentColor.withOpacity(0.2), // Reduced shadow
                blurRadius: 5, // Further Reduced
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 9, // Slightly smaller for 3 columns
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.value,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 13, // Slightly smaller for 3 columns
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: neonAccentColor.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturedCardsDisplay(
    BuildContext context,
    GameState gameState,
    Color neonAccentColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final displayedCardsJson = gameState.displayedCardJsonStrings;
    List<app_card.Card> cardsToDisplay = [];
    for (String jsonString in displayedCardsJson) {
      app_card.Card? card = app_card.cardFromJson(jsonString);
      if (card != null) {
        cardsToDisplay.add(card);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SHOWCASE",
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 14, // Compact title
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                color: neonAccentColor.withOpacity(0.8),
                size: 20,
              ),
              tooltip: "Edit Showcase Cards",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                // TODO: Navigate to card selection screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Navigate to Edit Showcase Screen (TBD)"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: neonAccentColor.withOpacity(0.3)),
          ),
          child: Builder(
            // Use Builder to correctly scope the child
            builder: (context) {
              if (cardsToDisplay.isEmpty &&
                  gameState.displayedCardJsonStrings.every(
                    (json) => json.isEmpty,
                  )) {
                // Show 5 empty slots if no cards are showcased at all
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    5,
                    (index) => InkWell(
                      onTap: () async {
                        // Logic for adding a card to an empty slot
                        app_card.Card? selectedCardFromDialog =
                            await _showCardSelectionDialog(
                              context,
                              gameState,
                              neonAccentColor,
                            );
                        if (selectedCardFromDialog != null) {
                          List<String> currentCardInstanceIds = List.filled(
                            5,
                            "",
                            growable: false,
                          );
                          // Since it's empty, just place the new card at the tapped index
                          currentCardInstanceIds[index] =
                              selectedCardFromDialog.id;
                          await gameState.setDisplayedProfileCards(
                            currentCardInstanceIds
                                .where((id) => id.isNotEmpty)
                                .toList(),
                          );
                        }
                      },
                      child: _buildEmptySlot(
                        context,
                        secondaryTextColor,
                        neonAccentColor,
                      ),
                    ),
                  ),
                );
              } else {
                // Display cards or empty slots
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (index) {
                    app_card.Card? cardInSlot;
                    if (index < gameState.displayedCardJsonStrings.length) {
                      final cardJson =
                          gameState.displayedCardJsonStrings[index];
                      if (cardJson.isNotEmpty) {
                        // Ensure json is not empty before parsing
                        cardInSlot = app_card.cardFromJson(cardJson);
                      }
                    }

                    return InkWell(
                      onTap: () async {
                        app_card.Card? selectedCardFromDialog =
                            await _showCardSelectionDialog(
                              context,
                              gameState,
                              neonAccentColor,
                            );
                        if (selectedCardFromDialog != null) {
                          List<String> currentCardInstanceIds = List.filled(
                            5,
                            "",
                            growable: false,
                          );
                          for (
                            int i = 0;
                            i < gameState.displayedCardJsonStrings.length;
                            i++
                          ) {
                            if (i < 5 &&
                                gameState
                                    .displayedCardJsonStrings[i]
                                    .isNotEmpty) {
                              final existingCard = app_card.cardFromJson(
                                gameState.displayedCardJsonStrings[i],
                              );
                              if (existingCard != null) {
                                currentCardInstanceIds[i] = existingCard.id;
                              }
                            }
                          }
                          int alreadyAtIndex = currentCardInstanceIds.indexOf(
                            selectedCardFromDialog.id,
                          );
                          if (alreadyAtIndex != -1 && alreadyAtIndex != index) {
                            currentCardInstanceIds[alreadyAtIndex] = "";
                          }
                          currentCardInstanceIds[index] =
                              selectedCardFromDialog.id;
                          await gameState.setDisplayedProfileCards(
                            currentCardInstanceIds
                                .where((id) => id.isNotEmpty)
                                .toList(),
                          );
                        }
                      },
                      child: cardInSlot != null
                          ? _buildSmallCard(
                              context,
                              cardInSlot,
                              neonAccentColor,
                            )
                          : _buildEmptySlot(
                              context,
                              secondaryTextColor,
                              neonAccentColor,
                            ),
                    );
                  }),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCard(
    BuildContext context,
    app_card.Card card,
    Color neonAccentColor,
  ) {
    return Container(
      width: 55, // Very small width
      height: 75, // Very small height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: app_card.getRarityColor(card.rarity).withOpacity(0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: app_card.getRarityColor(card.rarity).withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.5),
        child: Image.asset(
          card.imageUrl.isNotEmpty
              ? card.imageUrl
              : "assets/Themes/background_one.jpg", // Fallback
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.broken_image_outlined,
              color: Colors.white.withOpacity(0.5),
              size: 24,
            );
          },
        ),
      ),
    );
  }

  // Helper method to show card selection dialog
  Future<app_card.Card?> _showCardSelectionDialog(
    BuildContext context,
    GameState gameState,
    Color neonAccentColor,
  ) async {
    final theme = Theme.of(context);
    return await showDialog<app_card.Card>(
      context: context,
      builder: (BuildContext dialogContext) {
        final availableCards =
            gameState.userOwnedCards; // All cards owned by the user

        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: neonAccentColor.withOpacity(0.7)),
          ),
          title: Text(
            'Select Card for Showcase',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: availableCards.isEmpty
                ? Center(
                    child: Text(
                      "No cards in inventory.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableCards.length,
                    itemBuilder: (BuildContext itemContext, int index) {
                      final card = availableCards[index];
                      bool isAlreadyShowcased = gameState
                          .displayedCardJsonStrings
                          .any((json) {
                            final showcasedCard = app_card.cardFromJson(json);
                            return showcasedCard?.id == card.id;
                          });

                      return Material(
                        // Wrap with Material for InkWell splash
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(dialogContext).pop(card);
                          },
                          splashColor: neonAccentColor.withOpacity(0.3),
                          highlightColor: neonAccentColor.withOpacity(0.2),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: app_card
                                          .getRarityColor(card.rarity)
                                          .withOpacity(0.9),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: Image.asset(
                                      card.imageUrl.isNotEmpty
                                          ? card.imageUrl
                                          : "assets/Themes/background_one.jpg",
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                              size: 20,
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Lvl ${card.level} - ${card.rarity.toString().split('.').last}',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAlreadyShowcased)
                                  Icon(
                                    Icons.check_circle,
                                    color: neonAccentColor.withOpacity(0.7),
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 10.0),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptySlot(
    BuildContext context,
    Color secondaryTextColor,
    Color neonAccentColor,
  ) {
    return Container(
      width: 55,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: neonAccentColor.withOpacity(0.4), width: 1),
      ),
      child: Icon(
        Icons.add_circle_outline_rounded,
        color: neonAccentColor.withOpacity(0.7),
        size: 24,
      ),
    );
  }
}

Widget _buildUserStatus(
  BuildContext context,
  GameState gameState,
  Color neonAccentColor,
  Color primaryTextColor,
  Color secondaryTextColor,
) {
  // Assuming this screen is always for the currently logged-in user for editing purposes.
  // If it can display other users' profiles, you'd need a flag to enable/disable onTap.
  return Padding(
    padding: const EdgeInsets.only(top: 4.0), // Add some space above the status
    child: InkWell(
      onTap: () {
        // Only allow editing if it's the current user's profile
        // This check might be redundant if this screen is always for the current user
        // but good for clarity if it could be used for others.
        _showEditStatusDialog(
          context,
          gameState,
          neonAccentColor,
          primaryTextColor,
          secondaryTextColor,
        );
      },
      child: Text(
        gameState.userStatusMessage.isNotEmpty
            ? gameState.userStatusMessage
            : "Tap to set status...",
        style: TextStyle(
          fontSize: 11,
          color: gameState.userStatusMessage.isNotEmpty
              ? secondaryTextColor.withOpacity(0.8)
              : neonAccentColor.withOpacity(
                  0.7,
                ), // Different color for placeholder
          fontStyle: gameState.userStatusMessage.isNotEmpty
              ? FontStyle.italic
              : FontStyle.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

Future<void> _showEditStatusDialog(
  BuildContext context,
  GameState gameState,
  Color neonAccentColor,
  Color primaryTextColor,
  Color secondaryTextColor,
) async {
  TextEditingController statusController = TextEditingController(
    text: gameState.userStatusMessage,
  );

  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.black87.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: neonAccentColor.withOpacity(0.5)),
        ),
        title: Text(
          'Edit Status',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: statusController,
          maxLength: 50,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")),
          ], // Allow only alphabets and space
          style: TextStyle(color: primaryTextColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: "What's on your mind?",
            hintStyle: TextStyle(
              color: secondaryTextColor.withOpacity(0.6),
              fontSize: 14,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: neonAccentColor.withOpacity(0.4)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: neonAccentColor, width: 1.5),
            ),
            counterStyle: TextStyle(
              color: secondaryTextColor.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: secondaryTextColor.withOpacity(0.8)),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text(
              'Save',
              style: TextStyle(
                color: neonAccentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              gameState.updateUserStatusMessage(statusController.text.trim());
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}
