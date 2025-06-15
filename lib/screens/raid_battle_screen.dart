import 'dart:async';
import 'dart:math'; // Import for Random
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../game_state.dart';
import '../event_logic.dart';
import '../card_model.dart' as app_card;
import '../widgets/themed_scaffold.dart';
import '../widgets/framed_card_image_widget.dart';

class RaidBattleScreen extends StatefulWidget {
  final String raidId;
  final List<String> playerTeamCardIds;

  const RaidBattleScreen({super.key, required this.raidId, required this.playerTeamCardIds});


  @override
  State<RaidBattleScreen> createState() => _RaidBattleScreenState();
}

class _RaidBattleScreenState extends State<RaidBattleScreen> {
  Timer? _timer;
  // Player's team for this battle instance. We'll start with one, then expand.
  final List<app_card.Card?> _playerTeamCards = List.filled(3, null, growable: false);
  int _activePlayerCardIndex = 0; // Index of the card in _playerTeamCards currently taking action
  
  // Boss's card for this battle instance (its HP is the global raid boss HP)
  app_card.Card? _bossBattleInstance; 

  final List<String> _battleLog = [];
  final Random _random = Random();
  bool _playerTeamWiped = false;

  @override
  void initState() {
    super.initState();
    final gameState = Provider.of<GameState>(context, listen: false);
    final raidEvent = gameState.activeRaidEvents.firstWhereOrNull((r) => r.id == widget.raidId);

    if (raidEvent != null && widget.playerTeamCardIds.isNotEmpty) {
      for (int i = 0; i < widget.playerTeamCardIds.length && i < 3; i++) {
        final cardId = widget.playerTeamCardIds[i];
        final cardFromInventory = gameState.userOwnedCards.firstWhereOrNull((c) => c.id == cardId);
        if (cardFromInventory != null) {
          _playerTeamCards[i] = gameState.copyCardForBattle(cardFromInventory);
        }
      }
      // Ensure at least one card is active if possible
      _activePlayerCardIndex = _playerTeamCards.indexWhere((card) => card != null && card.currentHp > 0);
      if (_activePlayerCardIndex == -1) _activePlayerCardIndex = 0; // Default to first slot if all are null/KO

      // The boss's health is tracked directly on raidEvent.bossCard
      _bossBattleInstance = raidEvent.bossCard; // We will directly modify raidEvent.bossCard.currentHp via GameState
      _logBattle("Battle started against ${raidEvent.bossCard.name}!");
    }

    // Timer to refresh UI for battle countdown
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

  void _logBattle(String message) {
    if (mounted) {
      setState(() {
        _battleLog.insert(0, message);
      });
    }
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
    final RaidEvent? raidEvent = gameState.activeRaidEvents.firstWhereOrNull((r) => r.id == widget.raidId);

    // If the raid event itself is completed (boss defeated globally), pop.
    if (raidEvent == null ||
        (raidEvent.status != RaidEventStatus.battleInProgress && raidEvent.status != RaidEventStatus.lobbyOpen) || // Allow viewing if lobby is open but battle not started by this player yet
        _playerTeamCards.every((card) => card == null)) { // If no player cards are set up
      // Raid ended or not in progress, pop back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Raid battle is no longer active.")),
          );
        }
      });
      return ThemedScaffold(
        appBar: AppBar(title: const Text("Battle Ended")),
        body: const Center(child: Text("This raid battle has concluded or is not available.")),
      );
    }

    // Use _bossBattleInstance for display, its HP is the global raid boss HP
    final app_card.Card currentBossState = raidEvent.bossCard;

    return ThemedScaffold(
      appBar: AppBar(title: Text("Raid Battle: ${currentBossState.name}")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Boss Area
              Text("Boss: ${currentBossState.name}", style: Theme.of(context).textTheme.headlineSmall),
              FramedCardImageWidget(card: currentBossState, width: 120, height: 180),
              Text("HP: ${currentBossState.currentHp} / ${currentBossState.maxHp}", style: const TextStyle(fontSize: 16)),
              Text("Time Remaining: ${_formatDuration(raidEvent.battleTimeRemaining)}", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              const Divider(),
              // Player Team Area
              Text("Your Team:", style: Theme.of(context).textTheme.headlineSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  final playerCard = _playerTeamCards[index];
                  if (playerCard == null) {
                    return const SizedBox(width: 100, child: Center(child: Text("Empty Slot")));
                  }
                  bool isActive = index == _activePlayerCardIndex && playerCard.currentHp > 0;
                  return GestureDetector(
                    onTap: playerCard.currentHp > 0 ? () => setState(() => _activePlayerCardIndex = index) : null,
                    child: Opacity(
                      opacity: playerCard.currentHp > 0 ? 1.0 : 0.5,
                      child: Column(
                        children: [
                          FramedCardImageWidget(card: playerCard, width: 80, height: 120, frameColorOverride: isActive ? Colors.greenAccent : null),
                          Text(playerCard.name, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                          Text("HP: ${playerCard.currentHp}/${playerCard.maxHp}", style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              if (!_playerTeamWiped) ...[
                if (_playerTeamCards.isNotEmpty &&
                    _activePlayerCardIndex >= 0 &&
                    _activePlayerCardIndex < _playerTeamCards.length &&
                    _playerTeamCards[_activePlayerCardIndex]?.currentHp != null &&
                    _playerTeamCards[_activePlayerCardIndex]!.currentHp > 0) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.flash_on),
                    label: const Text("Attack Boss"),
                    onPressed: (currentBossState.currentHp > 0 && (_playerTeamCards[_activePlayerCardIndex]?.currentHp ?? 0) > 0 && raidEvent.status == RaidEventStatus.battleInProgress)
                        ? _performPlayerAttack
                        : null,
                  ),
                ] else ...[
                  const Text("Select an active card or all cards KO'd for this attempt."),
                ]
              ] else ...[ // Player team is wiped
                Text("Your team has been defeated in this attempt!", style: TextStyle(color: Colors.red.shade300, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton.icon(icon: const Icon(Icons.arrow_back), label: const Text("Retreat"), onPressed: () => Navigator.of(context).pop()),
              ],
              const SizedBox(height: 20),
              // Battle Log
              Text("Battle Log:", style: Theme.of(context).textTheme.titleMedium),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: _battleLog.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                    child: Text(_battleLog[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performPlayerAttack() {
    final app_card.Card? attackingPlayerCard = _playerTeamCards[_activePlayerCardIndex];
    if (_playerTeamWiped || attackingPlayerCard == null || attackingPlayerCard.currentHp <= 0 || _bossBattleInstance == null || _bossBattleInstance!.currentHp <= 0) {
      _logBattle("Cannot attack: Attacking card is KO'd or boss is KO'd.");
      return;
    }

    final gameState = Provider.of<GameState>(context, listen: false);
    final raidEvent = gameState.activeRaidEvents.firstWhereOrNull((r) => r.id == widget.raidId);
    if (raidEvent == null || raidEvent.status != RaidEventStatus.battleInProgress) {
      _logBattle("Cannot attack: Raid is not in progress.");
      return;
    }
    if (attackingPlayerCard.isSilenced) {
        _logBattle("${attackingPlayerCard.name} is Silenced and cannot attack!");
        return;
    }

    // Simplified damage calculation for player's attack
    int damageDealt = (attackingPlayerCard.attack - (_bossBattleInstance!.defense * 0.5).round()).clamp(1, 99999); // Boss takes less from def
    _logBattle("${attackingPlayerCard.name} attacks ${_bossBattleInstance!.name} for $damageDealt damage!");

    gameState.dealDamageToRaidBoss(widget.raidId, gameState.currentPlayerId, damageDealt);

    if (raidEvent.bossCard.currentHp <= 0) {
      _logBattle("${raidEvent.bossCard.name} has been defeated!");
      // Victory handling / navigation will occur due to GameState update and RaidEvent status change
      // The screen will pop in the build method when raidEvent.status is no longer battleInProgress
      return;
    }

    // Boss retaliates (simplified)
    _performBossAttack();
  }

  void _performBossAttack() {
    if (_bossBattleInstance == null || _bossBattleInstance!.currentHp <= 0) return;

    // Find an active player card to target
    List<app_card.Card?> activePlayerCards = _playerTeamCards.where((card) => card != null && card.currentHp > 0).toList();
    if (activePlayerCards.isEmpty) {
      // This case should now be handled by _playerTeamWiped check before boss attack is even called, but good to keep.
      // Player's attempt ends. They might "retreat".
      return;
    }

    // Simple targeting: random active card
    final app_card.Card targetPlayerCard = activePlayerCards[_random.nextInt(activePlayerCards.length)]!;

    // Simplified damage calculation for boss's attack
    int damageTaken = (_bossBattleInstance!.attack - (targetPlayerCard.defense * 0.8).round()).clamp(1, 99999); // Player def is more effective
    _logBattle("${_bossBattleInstance!.name} attacks ${targetPlayerCard.name} for $damageTaken damage!");
    
    setState(() {
      targetPlayerCard.takeDamage(damageTaken);
    });

    if (targetPlayerCard.currentHp <= 0) {
      _logBattle("${targetPlayerCard.name} has been defeated!");
      if (_playerTeamCards.every((card) => card == null || card.currentHp <= 0)) {
        setState(() {
          _playerTeamWiped = true;
        });
        _logBattle("All your cards have been defeated in this attempt! You must retreat.");
        // UI will update to show retreat button
      }
    }
  }
}