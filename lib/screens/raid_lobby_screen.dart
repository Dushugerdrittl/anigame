import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import '../game_state.dart';
import '../event_logic.dart';
import '../card_model.dart' as app_card;
import '../widgets/themed_scaffold.dart';
import '../widgets/framed_card_image_widget.dart';

class RaidLobbyScreen extends StatefulWidget {
  final String raidId;

  const RaidLobbyScreen({super.key, required this.raidId});

  @override
  State<RaidLobbyScreen> createState() => _RaidLobbyScreenState();
}

class _RaidLobbyScreenState extends State<RaidLobbyScreen> {
  // Placeholder for the current player's ID. In a real app, this would come from auth/GameState.
  // For now, let's assume GameState will provide a way to get this.
  // We'll add a dummy one in GameState for testing.
  String _currentPlayerId = "player_123_test"; // Placeholder

  Timer? _timer;
  // Store selected cards for the team
  final List<app_card.Card?> _selectedTeamCards = List.filled(3, null);

  @override
  void initState() {
    super.initState();
    // Attempt to join the lobby when the screen is first loaded.
    // This is a simplified approach. A more robust system might have a separate "Join" button.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameState = Provider.of<GameState>(context, listen: false);
      _currentPlayerId = gameState.currentPlayerId; // Get actual player ID
      final raid = gameState.activeRaidEvents.firstWhereOrNull(
        (r) => r.id == widget.raidId,
      );
      if (raid != null &&
          raid.status == RaidEventStatus.lobbyOpen &&
          !raid.playersInLobby.contains(_currentPlayerId)) {
        gameState.joinRaidLobby(widget.raidId, _currentPlayerId);
      }

      // Pre-fill team with first available cards if slots are empty
      for (int i = 0; i < _selectedTeamCards.length; i++) {
        if (_selectedTeamCards[i] == null &&
            gameState.userOwnedCards.length > i) {
          _selectedTeamCards[i] = gameState.userOwnedCards[i];
        }
      }
    });

    // Timer to refresh the UI for countdowns
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "$hours:$minutes:$seconds";
    } else if (duration.inMinutes > 0) {
      return "$minutes:$seconds";
    } else {
      return "00:$seconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final RaidEvent? raidEvent = gameState.activeRaidEvents.firstWhereOrNull(
      (r) => r.id == widget.raidId,
    );

    if (raidEvent == null) {
      // Raid might have expired or been removed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(); // Go back if raid is no longer available
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Raid lobby is no longer available.")),
          );
        }
      });
      return ThemedScaffold(
        appBar: AppBar(title: const Text("Lobby Not Found")),
        body: const Center(
          child: Text("This raid lobby is no longer available."),
        ),
      );
    }

    final app_card.Card boss = raidEvent.bossCard;
    final bool isLeader = raidEvent.lobbyLeaderId == _currentPlayerId;
    // Player must have at least one card selected to start
    final bool hasSelectedAtLeastOneCard = _selectedTeamCards.any(
      (card) => card != null,
    );
    final bool canStart =
        isLeader &&
        raidEvent.playersInLobby.length >= raidEvent.minPlayersNeededToWin &&
        hasSelectedAtLeastOneCard;

    String timeRemainingString;
    if (raidEvent.status == RaidEventStatus.lobbyOpen) {
      timeRemainingString =
          "Lobby closes in: ${_formatDuration(raidEvent.lobbyTimeRemaining)}";
      if (raidEvent.lobbyTimeRemaining == Duration.zero) {
        timeRemainingString = "Lobby expired!";
        // Optionally pop here if GameState hasn't removed it yet
      }
    } else {
      timeRemainingString = "Status: ${raidEvent.status.name}";
    }

    return WillPopScope(
      onWillPop: () async {
        // Player leaves the lobby when they navigate back
        gameState.leaveRaidLobby(widget.raidId, _currentPlayerId);
        return true; // Allow back navigation
      },
      child: ThemedScaffold(
        appBar: AppBar(
          title: Text("Lobby: ${boss.name}"),
          backgroundColor: Colors.transparent, // Make AppBar transparent
          elevation: 0, // Remove shadow
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced overall padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Boss Info
              Center(
                child: Column(
                  children: [
                    FramedCardImageWidget(card: boss, width: 100, height: 140),
                    const SizedBox(height: 8),
                    Text(
                      boss.name,
                      style: Theme.of(context).textTheme.titleLarge, // Reduced
                    ),
                    Text(
                      "Rarity: ${boss.rarity.name}",
                      style: Theme.of(context).textTheme.titleSmall, // Reduced
                    ),
                    Text(
                      timeRemainingString,
                      style: TextStyle(
                        fontSize: 14, // Reduced
                        color:
                            raidEvent.lobbyTimeRemaining <
                                const Duration(minutes: 1)
                            ? Colors.redAccent
                            : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Player Team Selection Area
              Text(
                "Your Raid Team:",
                style: Theme.of(context).textTheme.titleMedium, // Reduced
              ),
              const SizedBox(height: 6), // Reduced
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(3, (index) {
                  final card = _selectedTeamCards[index];
                  return GestureDetector(
                    onTap: () => _showCardSelectionDialog(context, index),
                    child: Container(
                      width: 75, // Reduced
                      height: 125, // Reduced
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade600),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: card != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FramedCardImageWidget(
                                  card: card,
                                  width: 60, // Reduced
                                  height: 85, // Reduced
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    card.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall, // Reduced
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Icon(
                                Icons.add_circle_outline,
                                size: 24, // Reduced
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16), // Reduced
              // Player List
              Text(
                "Players (${raidEvent.playersInLobby.length}/$MAX_PLAYERS_IN_LOBBY):",
                style: Theme.of(context).textTheme.titleMedium, // Reduced
              ),
              const SizedBox(height: 6), // Reduced
              Expanded(
                child: ListView.builder(
                  itemCount: raidEvent.playersInLobby.length,
                  itemBuilder: (context, index) {
                    final playerId = raidEvent.playersInLobby[index];
                    final bool isThisPlayerLeader =
                        playerId == raidEvent.lobbyLeaderId;
                    return Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.8),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4.0,
                      ), // Added margin for spacing
                      child: ListTile(
                        dense: true, // Makes ListTile more compact
                        leading: Icon(
                          isThisPlayerLeader ? Icons.star : Icons.person,
                          size: 20, // Reduced
                        ),
                        title: Text(
                          playerId == _currentPlayerId
                              ? "$playerId (You)"
                              : playerId,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium, // Adjusted
                        ),
                        subtitle: isThisPlayerLeader
                            ? Text(
                                "Lobby Leader",
                                style: Theme.of(context).textTheme.labelSmall,
                              ) // Adjusted
                            : null,
                        trailing: (isLeader && playerId != _currentPlayerId)
                            ? IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                ),
                                iconSize: 20, // Reduced
                                tooltip: "Kick Player",
                                onPressed: () {
                                  gameState.kickPlayerFromRaidLobby(
                                    widget.raidId,
                                    _currentPlayerId,
                                    playerId,
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16), // Reduced
              // Actions
              if (raidEvent.status == RaidEventStatus.lobbyOpen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.exit_to_app),
                      label: Text(
                        "Leave",
                        style: Theme.of(context).textTheme.labelMedium,
                      ), // Adjusted text & style
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ), // Reduced padding
                      ),
                      onPressed: () {
                        gameState.leaveRaidLobby(
                          widget.raidId,
                          _currentPlayerId,
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                    if (isLeader)
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.play_arrow,
                          color: canStart ? Colors.white : Colors.grey.shade700,
                        ),
                        label: Text(
                          // Adjusted text & style
                          raidEvent.playersInLobby.length <
                                  raidEvent.minPlayersNeededToWin
                              ? "Need ${raidEvent.minPlayersNeededToWin - raidEvent.playersInLobby.length} more"
                              : "Start Raid",
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: canStart
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canStart
                              ? Colors.green
                              : Colors
                                    .grey
                                    .shade800, // Darker grey for disabled
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ), // Reduced padding
                        ),
                        onPressed: canStart
                            ? () async {
                                bool success = await gameState.startRaidBattle(
                                  widget.raidId,
                                  _currentPlayerId,
                                );
                                print(
                                  "Raid battle start attempt success: $success",
                                ); // Debug print
                                if (success && mounted) {
                                  // Prepare team from selected cards
                                  List<String> teamCardIds = _selectedTeamCards
                                      .where(
                                        (card) => card != null,
                                      ) // Filter out nulls
                                      .map((card) => card!.id)
                                      .toList();

                                  Navigator.popAndPushNamed(
                                    context,
                                    '/raid_battle',
                                    arguments: {
                                      'raidId': widget.raidId,
                                      'playerTeamCardIds': teamCardIds,
                                    },
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Failed to start raid. Conditions not met.",
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                  ],
                ),
              if (raidEvent.status != RaidEventStatus.lobbyOpen)
                Center(
                  child: Text(
                    "Lobby is ${raidEvent.status.name}",
                    style: Theme.of(context).textTheme.titleSmall, // Reduced
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardSelectionDialog(BuildContext context, int teamSlotIndex) {
    final gameState = Provider.of<GameState>(context, listen: false);
    // Filter out cards already selected in other slots
    final availableCardsForSlot = gameState.userOwnedCards.where((ownedCard) {
      return !_selectedTeamCards.any(
        (selectedCard) =>
            selectedCard != null &&
            selectedCard.id == ownedCard.id &&
            _selectedTeamCards.indexOf(selectedCard) != teamSlotIndex,
      );
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // Consider making this dialog more compact too if needed
          title: Text("Select Card for Slot ${teamSlotIndex + 1}"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount:
                  availableCardsForSlot.length +
                  1, // +1 for "Remove Card" option
              itemBuilder: (context, index) {
                if (index == availableCardsForSlot.length) {
                  // "Remove Card" option
                  return ListTile(
                    leading: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                    ),
                    title: const Text("Remove Card from Slot"),
                    onTap: () {
                      setState(() {
                        _selectedTeamCards[teamSlotIndex] = null;
                      });
                      Navigator.of(dialogContext).pop();
                    },
                  );
                }
                final card = availableCardsForSlot[index];
                return ListTile(
                  dense: true,
                  leading: FramedCardImageWidget(
                    card: card,
                    width: 35, // Reduced
                    height: 50, // Reduced
                  ),
                  title: Text(
                    card.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  ), // Adjusted
                  subtitle: Text("Lvl: ${card.level} - ${card.rarity.name}"),
                  onTap: () {
                    setState(() {
                      _selectedTeamCards[teamSlotIndex] = card;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
