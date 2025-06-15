import 'card_model.dart' as app_card;
import 'package:uuid/uuid.dart'; // For generating unique IDs. Add uuid to pubspec.yaml

const Duration LOBBY_EXPIRY_DURATION = Duration(minutes: 20);
const int MAX_PLAYERS_IN_LOBBY = 6;

enum RaidEventStatus {
  lobbyOpen,
  battleInProgress,
  completedSuccess,
  completedFailure, // e.g., time ran out, or players wiped
  expiredUnstarted, // Lobby timed out before battle started
  expiredInProgress, // Battle timed out
}

class RaidEvent {
  final String id;
  final app_card.Card bossCard;
  final app_card.CardRarity rarity;
  final DateTime createdAt;
  DateTime lobbyExpiresAt;
  DateTime? battleStartedAt;
  DateTime? battleEndsAt;

  List<String> playersInLobby; // List of player IDs or simplified User objects
  String? lobbyLeaderId;
  RaidEventStatus status;

  RaidEvent({required this.bossCard})
      : id = const Uuid().v4(), // Generate a unique ID
        rarity = bossCard.rarity,
        createdAt = DateTime.now(),
        lobbyExpiresAt = DateTime.now().add(LOBBY_EXPIRY_DURATION),
        playersInLobby = [],
        status = RaidEventStatus.lobbyOpen;

  Duration get lobbyTimeRemaining {
    if (status != RaidEventStatus.lobbyOpen) return Duration.zero;
    final remaining = lobbyExpiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration get battleTimeRemaining {
    if (status != RaidEventStatus.battleInProgress || battleEndsAt == null) return Duration.zero;
    final remaining = battleEndsAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration get battleDuration {
    switch (rarity) {
      case app_card.CardRarity.COMMON:
        return const Duration(hours: 1);
      case app_card.CardRarity.UNCOMMON:
        return const Duration(minutes: 90); // 1.5 hours
      case app_card.CardRarity.RARE:
        return const Duration(hours: 2);
      case app_card.CardRarity.SUPER_RARE:
        return const Duration(minutes: 150); // 2.5 hours
      case app_card.CardRarity.ULTRA_RARE:
        return const Duration(hours: 3);
    }
  }

  int get minPlayersNeededToWin {
    switch (rarity) {
      case app_card.CardRarity.COMMON:
      case app_card.CardRarity.UNCOMMON:
      case app_card.CardRarity.RARE:
        return 2;
      case app_card.CardRarity.SUPER_RARE:
        return 3;
      case app_card.CardRarity.ULTRA_RARE:
        return 3; // Minimum 3, but might need 4 for success. This is min to attempt/win.
    }
  }

  // Recommended players for Ultra Rare might be higher, e.g., 4
  int get recommendedPlayersForUltraRare => 4;

  bool addPlayer(String playerId) {
    if (playersInLobby.length < MAX_PLAYERS_IN_LOBBY && status == RaidEventStatus.lobbyOpen && !playersInLobby.contains(playerId)) {
      playersInLobby.add(playerId);
      if (playersInLobby.length == 1) {
        lobbyLeaderId = playerId; // First player becomes the leader
      }
      // Reset lobby expiry if someone joins an empty lobby? Or keep it fixed?
      // For now, keeping it fixed from creation.
      return true;
    }
    return false;
  }

  bool removePlayer(String playerId, {String? kickerId}) {
    if (kickerId != null && kickerId != lobbyLeaderId && playerId != kickerId) {
      return false; // Only leader can kick others, or players can leave themselves
    }
    if (playersInLobby.remove(playerId)) {
      if (playerId == lobbyLeaderId && playersInLobby.isNotEmpty) {
        lobbyLeaderId = playersInLobby.first; // Assign new leader
      } else if (playersInLobby.isEmpty) {
        lobbyLeaderId = null;
      }
      return true;
    }
    return false;
  }

  bool startBattle(String starterId) {
    if (starterId == lobbyLeaderId && status == RaidEventStatus.lobbyOpen && playersInLobby.length >= minPlayersNeededToWin) {
      battleStartedAt = DateTime.now();
      battleEndsAt = battleStartedAt!.add(battleDuration);
      status = RaidEventStatus.battleInProgress;
      return true;
    }
    return false;
  }

  void updateStatus() {
    if (status == RaidEventStatus.lobbyOpen && DateTime.now().isAfter(lobbyExpiresAt)) {
      status = RaidEventStatus.expiredUnstarted;
    } else if (status == RaidEventStatus.battleInProgress && battleEndsAt != null && DateTime.now().isAfter(battleEndsAt!)) {
      // If battle time runs out, it's a failure unless already completed.
      if (status != RaidEventStatus.completedSuccess) {
          status = RaidEventStatus.expiredInProgress; // Or completedFailure
      }
    }
  }

  // Methods for completing the raid (success/failure) would be called by your battle logic
  void completeRaid(bool success) {
    if (status == RaidEventStatus.battleInProgress) {
      status = success ? RaidEventStatus.completedSuccess : RaidEventStatus.completedFailure;
      // Battle end time might be set to now, or keep original battleEndsAt
    }
  }
}