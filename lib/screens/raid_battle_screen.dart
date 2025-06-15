import 'dart:async';
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

  const RaidBattleScreen({super.key, required this.raidId});

  @override
  State<RaidBattleScreen> createState() => _RaidBattleScreenState();
}

class _RaidBattleScreenState extends State<RaidBattleScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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

    if (raidEvent == null || raidEvent.status != RaidEventStatus.battleInProgress) {
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

    final app_card.Card boss = raidEvent.bossCard;

    return ThemedScaffold(
      appBar: AppBar(title: Text("Raid Battle: ${boss.name}")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FramedCardImageWidget(card: boss, width: 150, height: 210),
            const SizedBox(height: 20),
            Text("Fighting: ${boss.name}!", style: Theme.of(context).textTheme.headlineMedium),
            Text("Rarity: ${boss.rarity.name}", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text("Time Remaining: ${_formatDuration(raidEvent.battleTimeRemaining)}", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 30),
            const Text("Raid battle mechanics TBD.", style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
            // TODO: Add player team display, boss HP, attack buttons, etc.
          ],
        ),
      ),
    );
  }
}