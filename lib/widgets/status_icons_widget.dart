import 'package:flutter/material.dart';
import '../card_model.dart' as app_card;

class StatusIconsWidget extends StatelessWidget {
  final app_card.Card card;

  const StatusIconsWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    List<Widget> statusWidgets = [];

    // Positive Buffs
    if (card.isPrecisionBuffActive) {
      statusWidgets.add(_buildStatusIcon(Icons.center_focus_strong, Colors.cyan, "Precision: ${card.precisionTurnsRemaining}t"));
    }
    if (card.isRegenerationBuffActive) {
      statusWidgets.add(_buildStatusIcon(Icons.healing, Colors.lightGreen, "Regen: ${card.regenerationTurnsRemaining}t"));
    }
    if (card.isAmplifierBuffActive) {
      statusWidgets.add(_buildStatusIcon(Icons.trending_up, Colors.orange, "Amplify: ${card.amplifierTurnsRemaining}t"));
    }
    if (card.isEnduranceBuffActive) {
      statusWidgets.add(_buildStatusIcon(Icons.shield, Colors.brown, "Endure: ${card.enduranceTurnsRemaining}t"));
    }
     if (card.isOffensiveStanceActive) {
      statusWidgets.add(_buildStatusIcon(Icons.gpp_good, Colors.red.shade300, "Offense: ${card.offensiveStanceTurnsRemaining}t"));
    }
    if (card.isPainForPowerBuffActive) {
      statusWidgets.add(_buildStatusIcon(Icons.whatshot_outlined, Colors.deepOrange, "P4P: ${card.painForPowerTurnsRemaining}t"));
    }
    // Add more positive buffs here...

    // Negative Debuffs
    if (card.isPoisoned) {
      statusWidgets.add(_buildStatusIcon(Icons.coronavirus, Colors.purple, "Poison: ${card.poisonTurnsRemaining}t"));
    }
    if (card.isUnderBurnDebuff) {
      statusWidgets.add(_buildStatusIcon(Icons.local_fire_department, Colors.red, "Burn: ${card.burnDurationTurns}t (${card.burnStacks}s)"));
    }
    if (card.isStunned) {
      statusWidgets.add(_buildStatusIcon(Icons.star, Colors.yellow.shade700, "Stunned"));
    }
    if (card.isSilenced) {
      statusWidgets.add(_buildStatusIcon(Icons.mic_off, Colors.grey, "Silence: ${card.silenceTurnsRemaining}t"));
    }
    if (card.isFrozen) {
      statusWidgets.add(_buildStatusIcon(Icons.ac_unit, Colors.lightBlue, "Frozen: ${card.frozenTurnsRemaining}t"));
    }
    if (card.isTimeBombActive) {
      statusWidgets.add(_buildStatusIcon(Icons.timer, Colors.orange.shade800, "Bomb: ${card.timeBombTurnsRemaining}t"));
    }
    // Add more negative debuffs here...

    if (statusWidgets.isEmpty) {
      return const SizedBox.shrink(); // No statuses to show
    }

    return Wrap(
      spacing: 4.0,
      runSpacing: 2.0,
      alignment: WrapAlignment.center,
      children: statusWidgets,
    );
  }

  Widget _buildStatusIcon(IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 16), // Smaller icons
    );
  }
}