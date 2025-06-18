import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart'; // To potentially access event card definitions or player data
import '../card_model.dart' as app_card; // For CardRarity
import '../talent_system.dart'; // For TalentType
// import '../data/card_definitions.dart'; // No longer needed as raids come from GameState
import '../event_logic.dart'; // Import RaidEvent and related constants
import '../widgets/themed_scaffold.dart'; // Assuming you want to use your themed scaffold
import '../widgets/framed_card_image_widget.dart'; // For displaying card images

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  app_card.CardRarity? _selectedRarityFilter;
  TalentType? _selectedTalentFilter;

  // Fetch RaidEvent instances from GameState
  List<RaidEvent> _getAvailableRaidEvents(GameState gameState) {
    // Fetch active raids, we'll typically want to show only open lobbies
    return gameState.activeRaidEvents
        .where((raid) => raid.status == RaidEventStatus.lobbyOpen)
        .toList();
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
    final List<RaidEvent> availableRaids = _getAvailableRaidEvents(gameState);

    final List<RaidEvent> filteredRaids = availableRaids.where((raidEvent) {
      final bossCard = raidEvent.bossCard;
      final rarityMatches =
          _selectedRarityFilter == null ||
          bossCard.rarity == _selectedRarityFilter;
      final talentMatches =
          _selectedTalentFilter == null ||
          bossCard.talent?.type == _selectedTalentFilter;
      return rarityMatches && talentMatches;
    }).toList();

    return ThemedScaffold(
      appBar: AppBar(
        title: const Text("Active Raid Lobbies"),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow
        // toolbarHeight: 30, // Consider if this specific height is necessary or use default
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter UI (Dropdowns) removed from here, will be in _showFilterDialog
          Expanded(
            child: filteredRaids.isEmpty
                ? Center(
                    child: Text(
                      gameState.activeRaidEvents.any(
                            (r) => r.status == RaidEventStatus.lobbyOpen,
                          )
                          ? "No raid lobbies match your filters."
                          : "No active raid lobbies currently.",
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredRaids.length,
                    itemBuilder: (context, index) {
                      try {
                        // Add try block to catch errors during item rendering
                        final raidEvent = filteredRaids[index];
                        final boss = raidEvent.bossCard;
                        String timeRemainingString;
                        if (raidEvent.status == RaidEventStatus.lobbyOpen) {
                          timeRemainingString =
                              "Lobby closes in: ${_formatDuration(raidEvent.lobbyTimeRemaining)}";
                        } else if (raidEvent.status ==
                            RaidEventStatus.battleInProgress) {
                          timeRemainingString =
                              "Battle ends in: ${_formatDuration(raidEvent.battleTimeRemaining)}";
                        } else {
                          timeRemainingString =
                              "Status: ${raidEvent.status.name}";
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.9),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                FramedCardImageWidget(
                                  card: boss,
                                  width: 70,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        boss.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Rarity: ${boss.rarity.name}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      Text(
                                        "Talent: ${boss.talent?.name ?? 'N/A'}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Players: ${raidEvent.playersInLobby.length}/${raidEvent.maxParticipants}", // Use raidEvent.maxParticipants
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      Text(
                                        "Min. to Start: ${raidEvent.minPlayersNeededToWin}",
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        timeRemainingString,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  child: const Text("View"), // Shorter text
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/raid_lobby',
                                      arguments: raidEvent.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      } catch (e, s) {
                        // If an error occurs rendering an item, display an error tile
                        // and print the error to the console.
                        // ignore: avoid_print
                        print(
                          'Error rendering raid event at index $index: $e\n$s',
                        );
                        return Card(
                          color: Colors.red.withOpacity(0.5),
                          child: ListTile(
                            title: Text(
                              'Error loading raid: ${filteredRaids.length > index ? filteredRaids[index].id : "ID Unknown"}',
                            ),
                            subtitle: Text(e.toString()),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    // Basic dialog for filters, can be expanded
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage the dialog's internal state for selections
        app_card.CardRarity? tempSelectedRarity = _selectedRarityFilter;
        TalentType? tempSelectedTalent = _selectedTalentFilter;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Filter Raids"),
              content: SingleChildScrollView(
                // In case of many options
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<app_card.CardRarity?>(
                      decoration: const InputDecoration(
                        labelText: 'Filter by Rarity',
                      ),
                      value: tempSelectedRarity,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Rarities"),
                        ),
                        ...app_card.CardRarity.values.map((rarity) {
                          return DropdownMenuItem(
                            value: rarity,
                            child: Text(rarity.name),
                          );
                        }),
                      ],
                      onChanged: (app_card.CardRarity? newValue) {
                        setDialogState(() {
                          tempSelectedRarity = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<TalentType?>(
                      decoration: const InputDecoration(
                        labelText: 'Filter by Talent',
                      ),
                      value: tempSelectedTalent,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("All Talents"),
                        ),
                        ...TalentType.values.map((talent) {
                          return DropdownMenuItem(
                            value: talent,
                            child: Text(talent.name),
                          );
                        }),
                      ],
                      onChanged: (TalentType? newValue) {
                        setDialogState(() {
                          tempSelectedTalent = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Clear Filters"),
                  onPressed: () {
                    setDialogState(() {
                      tempSelectedRarity = null;
                      tempSelectedTalent = null;
                    });
                  },
                ),
                TextButton(
                  child: const Text("Apply"),
                  onPressed: () {
                    setState(() {
                      // This setState is for the _EventScreenState
                      _selectedRarityFilter = tempSelectedRarity;
                      _selectedTalentFilter = tempSelectedTalent;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
