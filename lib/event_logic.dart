import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert'; // For jsonEncode
import 'card_model.dart' as app_card;
import 'card_model.dart'
    show cardToJson, cardFromJson; // Import global card functions
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
  DateTime? battleEndsAt; // Time when the battle is scheduled to end
  final int
  maxParticipants; // Max players allowed in this specific raid instance

  List<String> playersInLobby; // List of player IDs or simplified User objects
  String? lobbyLeaderId;
  RaidEventStatus status;

  // Private constructor for deserialization
  RaidEvent._({
    required this.id,
    required this.bossCard,
    required this.rarity,
    required this.createdAt,
    required this.lobbyExpiresAt,
    this.battleStartedAt,
    this.battleEndsAt,
    required this.playersInLobby,
    this.lobbyLeaderId,
    required this.status,
    required this.maxParticipants,
  });

  // Primary constructor for creating new raids
  RaidEvent({required this.bossCard, int? maxParticipantsOverride})
    : // Initialize final fields first
      id = const Uuid().v4(), // Generate a unique ID
      maxParticipants =
          maxParticipantsOverride ??
          MAX_PLAYERS_IN_LOBBY, // Initialize maxParticipants
      rarity = bossCard.rarity, // Initialize final rarity
      createdAt = DateTime.now(), // Initialize final createdAt
      lobbyExpiresAt = DateTime.now().add(
        LOBBY_EXPIRY_DURATION,
      ), // Initialize lobbyExpiresAt
      playersInLobby = [],
      status = RaidEventStatus.lobbyOpen;

  // Getters for time remaining
  Duration get lobbyTimeRemaining {
    // Renamed from lobbyTimeRemaining
    if (status != RaidEventStatus.lobbyOpen) return Duration.zero;
    final remaining = lobbyExpiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration get battleTimeRemaining {
    if (status != RaidEventStatus.battleInProgress || battleEndsAt == null) {
      return Duration.zero;
    }
    final remaining = battleEndsAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Getters for raid properties based on rarity
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

  // Minimum players required to start the battle
  int get minPlayersNeededToWin {
    switch (rarity) {
      case app_card.CardRarity.COMMON:
      case app_card.CardRarity.UNCOMMON:
      case app_card.CardRarity.RARE:
        return 1; // Can be done solo
      case app_card.CardRarity.SUPER_RARE:
        return 2; // Example: Requires at least 2 players
      case app_card.CardRarity.ULTRA_RARE:
        return 3; // Example: Requires at least 3 players
    }
  }

  // Recommended players for Ultra Rare (example)
  // Recommended players for Ultra Rare might be higher, e.g., 4
  int get recommendedPlayersForUltraRare => 4;

  // Method to add a player to the lobby
  bool addPlayer(String playerId) {
    if (playersInLobby.length <
            maxParticipants && // Use instance maxParticipants
        status == RaidEventStatus.lobbyOpen &&
        !playersInLobby.contains(playerId)) {
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

  // Method to remove a player from the lobby
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

  // Method to start the battle
  bool startBattle(String starterId) {
    if (starterId == lobbyLeaderId &&
        status == RaidEventStatus.lobbyOpen &&
        playersInLobby.length >= minPlayersNeededToWin) {
      battleStartedAt = DateTime.now();
      battleEndsAt = battleStartedAt!.add(battleDuration);
      status = RaidEventStatus.battleInProgress;
      return true;
    }
    return false;
  }

  // Method to update the raid status based on time
  void updateStatus() {
    if (status == RaidEventStatus.lobbyOpen &&
        DateTime.now().isAfter(lobbyExpiresAt)) {
      status = RaidEventStatus.expiredUnstarted;
    } else if (status == RaidEventStatus.battleInProgress &&
        battleEndsAt != null &&
        DateTime.now().isAfter(battleEndsAt!)) {
      // If battle time runs out, it's a failure unless already completed.
      if (status != RaidEventStatus.completedSuccess) {
        status = RaidEventStatus.expiredInProgress; // Or completedFailure
      }
    }
  }

  // Method to mark the raid as completed (success or failure)
  // Methods for completing the raid (success/failure) would be called by your battle logic
  void completeRaid(bool success) {
    if (status == RaidEventStatus.battleInProgress) {
      status = success
          ? RaidEventStatus.completedSuccess
          : RaidEventStatus.completedFailure;
      // Battle end time might be set to now, or keep original battleEndsAt
    }
  }

  // --- Serialization/Deserialization for Firestore ---

  Map<String, dynamic> toJson() {
    return {
      'bossCard': cardToJson(bossCard), // Use global cardToJson
      'participants': playersInLobby,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(
        createdAt,
      ), // Convert DateTime to Timestamp
      'lobbyExpiresAt': Timestamp.fromDate(
        lobbyExpiresAt,
      ), // Convert DateTime to Timestamp
      'battleStartedAt': battleStartedAt != null
          ? Timestamp.fromDate(battleStartedAt!)
          : null, // Convert nullable DateTime
      'battleEndsAt': battleEndsAt != null
          ? Timestamp.fromDate(battleEndsAt!)
          : null, // Convert nullable DateTime
      'maxParticipants': maxParticipants, // Save maxParticipants
      'rarity': rarity.toString(),
      'creatorId': lobbyLeaderId,
    };
  }

  // Factory constructor to create a RaidEvent from Firestore data
  static RaidEvent? fromJson(Map<String, dynamic> data, String id) {
    // Changed to static method returning RaidEvent?
    app_card.Card? boss;
    String? bossCardJsonString;
    try {
      if (data['bossCard'] != null) {
        if (data['bossCard'] is String) {
          bossCardJsonString = data['bossCard'] as String;
          boss = cardFromJson(bossCardJsonString); // Use global cardFromJson
        } else if (data['bossCard'] is Map) {
          print(
            "Error: bossCard in Firestore for raid $id is a Map, expected String. Data: ${data['bossCard']}",
          );
          // Attempt to re-encode and parse if cardFromJson can handle the resulting string
          try {
            bossCardJsonString = jsonEncode(data['bossCard']);
            boss = cardFromJson(bossCardJsonString);
          } catch (e2) {
            print("Error attempting to re-encode and parse bossCard Map: $e2");
          }
        }
      }
    } catch (e) {
      print(
        "Error during cardFromJson for raid $id. Raw JSON: $bossCardJsonString. Error: $e",
      );
    }
    if (boss == null) {
      // If boss deserialization fails, we cannot create a valid RaidEvent.
      // ignore: avoid_print
      print(
        "Critical Error: Failed to deserialize bossCard for raid $id. Raw data: ${data['bossCard']}. Skipping this raid.",
      );
      return null; // Return null instead of throwing
    }

    // Deserialize DateTime fields from Timestamps
    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      // Handle missing or incorrect type for createdAt, e.g., default or throw error
      createdAt = DateTime.now(); // Or throw specific error
      // ignore: avoid_print
      print(
        "Warning: 'createdAt' field missing or not a Timestamp for raid $id. Using current time.",
      );
    }

    DateTime lobbyExpiresAt;
    if (data['lobbyExpiresAt'] is Timestamp) {
      lobbyExpiresAt = (data['lobbyExpiresAt'] as Timestamp).toDate();
    } else {
      // Handle missing or incorrect type for lobbyExpiresAt
      lobbyExpiresAt = DateTime.now().add(
        LOBBY_EXPIRY_DURATION,
      ); // Or throw specific error
      // ignore: avoid_print
      print(
        "Warning: 'lobbyExpiresAt' field missing or not a Timestamp for raid $id. Using default expiry.",
      );
    }

    DateTime? battleStartedAt = (data['battleStartedAt'] as Timestamp?)
        ?.toDate();
    DateTime? battleEndsAt = (data['battleEndsAt'] as Timestamp?)?.toDate();

    // Deserialize status string to enum
    RaidEventStatus status = RaidEventStatus.values.firstWhere(
      (e) => e.toString() == data['status'],
      orElse: () => RaidEventStatus.expiredUnstarted,
    );

    // Deserialize playersInLobby
    List<String> playersInLobby = List<String>.from(data['participants'] ?? []);

    // Deserialize creatorId
    String? lobbyLeaderId = data['creatorId'] as String?;

    // Deserialize rarity and maxParticipants
    app_card.CardRarity rarity = app_card.CardRarity.values.firstWhere(
      (r) => r.toString() == data['rarity'],
      orElse: () => app_card.CardRarity.COMMON, // Default on error
    );
    int maxParticipantsValue =
        data['maxParticipants'] ?? MAX_PLAYERS_IN_LOBBY; // Load maxParticipants

    // Use the private constructor to create the instance
    return RaidEvent._(
      id: id,
      bossCard: boss,
      rarity: rarity,
      createdAt: createdAt,
      lobbyExpiresAt: lobbyExpiresAt,
      battleStartedAt: battleStartedAt,
      battleEndsAt: battleEndsAt,
      playersInLobby: playersInLobby,
      lobbyLeaderId: lobbyLeaderId,
      status: status,
      maxParticipants: maxParticipantsValue,
    );
  }
}
