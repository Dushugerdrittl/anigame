import 'package:flutter/foundation.dart';
import 'card_model.dart';
import 'elemental_system.dart';
import 'talent_system.dart';
import 'dart:math'; // For Random
import 'dart:async'; // For Timer
import 'data/card_supply_data.dart'; // Import the new card supply data
import 'data/card_definitions.dart'; // Import the new card definitions
import 'models/floor_model.dart'; // Import Floor model
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'utils/rarity_stats_util.dart'; // Import the new utility
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'utils/leveling_cost_util.dart'; // Import leveling cost utility
import 'utils/enemy_difficulty_scaler.dart'; // Import the new difficulty scaler
import 'data/floor_definitions.dart'; // Import Floor definitions
import 'event_logic.dart'; // Import RaidEvent logic
// For generating unique player ID
// Import DevAdminTools
import 'package:firebase_auth/firebase_auth.dart'
    as fb_auth; // Import Firebase Auth

class GameState extends ChangeNotifier {
  Card?
  playerCard; // This will be a COPY of the selected card for the current battle
  Card? enemyCard;
  int currentRound = 0;
  final int maxRounds = 20;
  bool isGameStarted = false;
  bool isGameOver = false;
  String? winnerMessage;
  List<String> battleLog = [];
  final Random _random = Random();

  int _playerCurrency = 500; // Starting currency
  int _playerDiamonds = 10; // Starting diamonds
  int _playerSouls = 1000; // Starting souls for leveling
  static const int MANA_GAIN_PER_ROUND = 10; // Mana gained each round
  final List<Card> _userOwnedCards = [];
  List<Card> get userOwnedCards =>
      List.unmodifiable(_userOwnedCards); // Public getter for UI
  Card?
  _currentlySelectedPlayerCard; // The card instance from _userOwnedCards that the player has chosen
  Card? get currentlySelectedPlayerCard => _currentlySelectedPlayerCard;

  // Floor Battle State
  final List<Floor> _gameFloors = FloorDefinitions.floors;
  List<Floor> get gameFloors => List.unmodifiable(_gameFloors);
  final Set<String> _unlockedFloorIds = {
    FloorDefinitions.floors.first.id,
  }; // Unlock the first floor by default
  Set<String> get unlockedFloorIds => Set.unmodifiable(_unlockedFloorIds);
  final Set<String> _completedFloorIds = {};
  Set<String> get completedFloorIds => Set.unmodifiable(_completedFloorIds);
  // Initialize _highestUnlockedLevelPerFloor for the first floor
  final Map<String, int> _highestUnlockedLevelPerFloor =
      FloorDefinitions.floors.isNotEmpty
      ? {FloorDefinitions.floors.first.id: 1}
      : {}; // floorId -> highest level number unlocked
  final Map<String, Set<int>> _completedLevelsPerFloor =
      {}; // floorId -> Set of completed level numbers
  Map<String, Set<int>> get completedLevelsPerFloor => Map.unmodifiable(
    _completedLevelsPerFloor.map(
      (key, value) => MapEntry(key, Set.unmodifiable(value)),
    ),
  );

  String? _currentBattlingFloorId; // ID of the floor currently in battle
  String? get currentBattlingFloorId =>
      _currentBattlingFloorId; // Public getter
  int? _currentBattlingLevelNumber; // Number of the level currently in battle
  int? get currentBattlingLevelNumber =>
      _currentBattlingLevelNumber; // Public getter

  // Tracks the number of minted copies for each card template ID
  // Now tracks minted copies per template ID AND per rarity
  final Map<String, Map<CardRarity, int>> _mintedCardCounts = {};
  Map<String, Map<CardRarity, int>> get mintedCardCounts => Map.unmodifiable(
    _mintedCardCounts.map((key, value) {
      return MapEntry(
        key,
        Map<CardRarity, int>.unmodifiable(value),
      ); // Explicitly type the inner unmodifiable map
    }),
  );

  // Shard Inventory
  final Map<ShardType, int> _playerShards = {}; // Changed Key to ShardType
  Map<ShardType, int> get playerShards => Map.unmodifiable(_playerShards);

  // --- Raid Event State ---
  final List<RaidEvent> _activeRaidEvents = [];
  List<RaidEvent> get activeRaidEvents => List.unmodifiable(_activeRaidEvents);
  Timer? _raidEventStatusUpdaterTimer; // Updates status of existing raids
  Timer?
  _raidPopulationMaintenanceTimer; // Periodically ensures raid population meets criteria
  static const int MAX_ACTIVE_RAIDS =
      10; // Example limit for total active raids

  // _currentPlayerId will now be the Firebase User UID
  String _currentPlayerId = "";
  String get currentPlayerId => _currentPlayerId; // Public getter
  String _currentAuthUsername =
      ""; // To store the username used for login/registration
  String get currentAuthUsername => _currentAuthUsername; // Public getter
  String _userStatusMessage = ""; // To store the user's status message
  String get userStatusMessage => _userStatusMessage; // Public getter

  // _isUserLoggedIn will be determined by Firebase Auth state
  bool _isUserLoggedIn = false;
  bool get isUserLoggedIn => _isUserLoggedIn;

  List<String> _displayedCardJsonStrings =
      []; // JSON strings of cards to display on profile
  List<String> get displayedCardJsonStrings =>
      List.unmodifiable(_displayedCardJsonStrings);

  // --- Gold Shop Card Getters ---
  List<Card> _getShopCardsByRarity(CardRarity rarity) {
    return CardDefinitions.availableCards
        .where((card) {
          // Use definitions from CardDefinitions
          if (card.rarity != CardRarity.COMMON) {
            return false; // Only show base common templates in shop for now
          }
          // Check if the card template *can* be of the specified rarity
          final raritySupplies = CardSupplyData.cardMaxSupply[card.id];
          return raritySupplies?.containsKey(rarity) ?? false;
        })
        .expand((cardTemplate) {
          // Create a display card for this specific rarity
          return [_copyCard(cardTemplate, rarity, 1)]; // Show as Lvl 1 in shop
        })
        .toList();
  }

  List<Card> get goldShopRareCards => _getShopCardsByRarity(CardRarity.RARE);
  List<Card> get goldShopSuperRareCards =>
      _getShopCardsByRarity(CardRarity.SUPER_RARE);
  List<Card> get goldShopUltraRareCards =>
      _getShopCardsByRarity(CardRarity.ULTRA_RARE);

  // --- Shard Shop Data ---
  Map<ShardType, int> get goldShopShardPrices {
    // Define prices for various shards.
    // This could be more dynamic or loaded from a config file in a real game.
    return {
      ShardType.FIRE_SHARD: 10,
      ShardType.WATER_SHARD: 10,
      ShardType.GRASS_SHARD: 10,
      ShardType.GROUND_SHARD: 10,
      ShardType.ELECTRIC_SHARD: 10,
      ShardType.NEUTRAL_SHARD: 5, // Neutral might be cheaper
      ShardType.LIGHT_SHARD: 15,
      ShardType.DARK_SHARD: 15,
      // RARE_SHARD, EPIC_SHARD, LEGENDARY_SHARD removed
    };
  }

  // --- Diamond Shop Placeholders (Data needs to be defined) ---
  List<Card> get diamondShopEventCards {
    // TODO: Define data source for event cards
    // For now, let's assume event cards are displayed at their defined rarity and level 1
    // The _copyCard method will handle rarity stat scaling if their defined rarity is not COMMON
    return CardDefinitions.eventCards
        .map((template) => _copyCard(template, template.rarity, 1))
        .toList();
  }

  List<String> get diamondShopCardSkins {
    // Assuming skins are identified by a string for now
    // TODO: Define data source for card skins
    return ["Skin_Naruto_VariantA", "Skin_Luffy_PirateKing"];
  }

  GameState() {
    _listenToAuthStateChanges(); // New method to listen to Firebase Auth
    _startRaidSystemTimers();
    _maintainRaidPopulation(); // Initial population check
  }
  String get currentUserDisplayUid {
    if (!_isUserLoggedIn || _currentPlayerId.isEmpty) {
      return "N/A";
    }
    return _currentPlayerId.substring(0, min(9, _currentPlayerId.length));
  }

  void resetToDefaultState() {
    _playerCurrency = 500;
    _playerDiamonds = 10;
    _playerSouls = 1000;
    _userOwnedCards.clear();
    _mintedCardCounts.clear();
    _playerShards.clear();
    _unlockedFloorIds.clear();
    _completedFloorIds.clear();
    _activeRaidEvents.clear();
    _highestUnlockedLevelPerFloor.clear();
    _completedLevelsPerFloor.clear();
    _currentPlayerId = "";
    _isUserLoggedIn = false;
    _currentAuthUsername = "";
    _displayedCardJsonStrings.clear();

    _initializeUserInventory();
    _initializePlayerShards();
    if (gameFloors.isNotEmpty) {
      _unlockedFloorIds.add(gameFloors.first.id);
      _highestUnlockedLevelPerFloor[gameFloors.first.id] = 1;
    }

    _maintainRaidPopulation();

    _logMessage("Game progress has been reset to default.");
    notifyListeners();
    saveGameState();
  }

  void _listenToAuthStateChanges() {
    fb_auth.FirebaseAuth.instance.authStateChanges().listen((
      fb_auth.User? user,
    ) async {
      if (user == null) {
        _logMessage('User is currently signed out!');
        _isUserLoggedIn = false;
        _currentPlayerId = "";
        _currentAuthUsername = "";
        _activeRaidEvents.clear();
        _userOwnedCards.clear();
        _playerShards.clear();
        _playerCurrency = 0;
        _playerDiamonds = 0;
        _playerSouls = 0;
        _initializeUserInventory();
        _displayedCardJsonStrings.clear();
        _initializePlayerShards();
        _logMessage("User signed out. Local game state reset.");
      } else {
        _logMessage('User is signed in! UID: ${user.uid}');
        _isUserLoggedIn = true;
        _currentPlayerId = user.uid;
        await loadGameState();
        await _loadActiveRaidsFromFirestore();
      }
      notifyListeners();
    });
  }

  Future<void> _loadActiveRaidsFromFirestore() async {
    if (!_isUserLoggedIn) {
      _logMessage("User not logged in, skipping loading raids from Firestore.");
      _activeRaidEvents.clear();
      notifyListeners();
      return;
    }
    _logMessage("Loading active raids from Firestore...");
    try {
      QuerySnapshot raidSnapshot = await FirebaseFirestore.instance
          .collection('activeRaids')
          .get();
      _activeRaidEvents.clear();
      for (var doc in raidSnapshot.docs) {
        try {
          RaidEvent? raid = RaidEvent.fromJson(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          if (raid == null) {
            _logMessage(
              "Skipping raid ${doc.id} due to deserialization failure (boss card likely).",
            );
            continue;
          }
          raid.updateStatus();
          if (raid.status != RaidEventStatus.expiredUnstarted &&
              raid.status != RaidEventStatus.completedSuccess &&
              raid.status != RaidEventStatus.completedFailure &&
              raid.status != RaidEventStatus.expiredInProgress) {
            _activeRaidEvents.add(raid);
          } else {
            _logMessage(
              "Loaded raid ${raid.id} (${raid.bossCard.name}) is already ended (${raid.status}). Removing from Firestore.",
            );
            await FirebaseFirestore.instance
                .collection('activeRaids')
                .doc(raid.id)
                .delete();
          }
        } catch (e) {
          _logMessage(
            "Error deserializing raid ${doc.id} from Firestore: $e. Skipping.",
          );
        }
      }
      _logMessage(
        "Loaded ${_activeRaidEvents.length} active raids from Firestore.",
      );
    } catch (e) {
      _logMessage("Error loading active raids from Firestore: $e");
    }
    notifyListeners();
  }

  void _startRaidSystemTimers() {
    _raidEventStatusUpdaterTimer?.cancel();
    _raidPopulationMaintenanceTimer?.cancel();

    _raidEventStatusUpdaterTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) {
      updateRaidEventStatuses();
    });

    _raidPopulationMaintenanceTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        _maintainRaidPopulation();
      },
    );
  }

  Future<void> _maintainRaidPopulation() async {
    await updateRaidEventStatuses();

    if (CardDefinitions.eventCards.isEmpty) {
      _logMessage(
        "[Raid System] No event cards defined in CardDefinitions.eventCards. Cannot spawn any raids.",
      );
      return;
    }

    int currentUrRaids = _activeRaidEvents
        .where(
          (r) =>
              r.rarity == CardRarity.ULTRA_RARE &&
              r.status == RaidEventStatus.lobbyOpen,
        )
        .length;
    int urNeeded = 2 - currentUrRaids;
    for (
      int i = 0;
      i < urNeeded && _activeRaidEvents.length < MAX_ACTIVE_RAIDS;
      i++
    ) {
      await spawnNewRaidEvent(rarityOverride: CardRarity.ULTRA_RARE);
    }

    int currentSrRaids = _activeRaidEvents
        .where(
          (r) =>
              r.rarity == CardRarity.SUPER_RARE &&
              r.status == RaidEventStatus.lobbyOpen,
        )
        .length;
    int srNeeded = 2 - currentSrRaids;
    for (
      int i = 0;
      i < srNeeded && _activeRaidEvents.length < MAX_ACTIVE_RAIDS;
      i++
    ) {
      await spawnNewRaidEvent(rarityOverride: CardRarity.SUPER_RARE);
    }
    List<CardRarity> randomFillRarities = [
      CardRarity.COMMON,
      CardRarity.UNCOMMON,
      CardRarity.RARE,
    ];

    while (_activeRaidEvents.length < MAX_ACTIVE_RAIDS &&
        randomFillRarities.isNotEmpty) {
      CardRarity chosenRarity =
          randomFillRarities[_random.nextInt(randomFillRarities.length)];
      await spawnNewRaidEvent(rarityOverride: chosenRarity);
    }
    _logMessage(
      "[Raid System] Maintained raid population. Active lobbies: ${_activeRaidEvents.where((r) => r.status == RaidEventStatus.lobbyOpen).length}/${_activeRaidEvents.length} total raids.",
    );
    notifyListeners();
  }

  void _initializeUserInventory() {
    _userOwnedCards.clear();
    _userOwnedCards.add(CardDefinitions.getStarterCard(_random));

    if (CardDefinitions.availableCards.isNotEmpty) {
      Card? firstStarter = _mintCardInstanceByTemplateId(
        CardDefinitions.availableCards[0].id,
        CardRarity.COMMON,
        initialLevel: 1,
      );
      if (firstStarter != null) {
        _userOwnedCards.add(firstStarter);
      }
    }
    if (CardDefinitions.availableCards.length > 1 &&
        _userOwnedCards.length < 3) {
      final secondTemplate = CardDefinitions.availableCards[1];
      String secondStarterTemplateId = secondTemplate.id;
      bool isDifferentFromLast =
          _userOwnedCards.isEmpty ||
          !_userOwnedCards.last.originalTemplateId.startsWith(
            secondStarterTemplateId,
          );

      if (isDifferentFromLast) {
        Card? secondStarter = _mintCardInstanceByTemplateId(
          secondStarterTemplateId,
          CardRarity.COMMON,
          initialLevel: 1,
        );
        if (secondStarter != null) _userOwnedCards.add(secondStarter);
      } else if (CardDefinitions.availableCards.length > 2) {
        final thirdTemplate = CardDefinitions.availableCards[2];
        String thirdStarterTemplateId = thirdTemplate.id;
        Card? thirdStarter = _mintCardInstanceByTemplateId(
          thirdStarterTemplateId,
          CardRarity.COMMON,
          initialLevel: 1,
        );
        if (thirdStarter != null) _userOwnedCards.add(thirdStarter);
      }
    }
    _currentlySelectedPlayerCard = _userOwnedCards.isNotEmpty
        ? _userOwnedCards[0]
        : null;
    notifyListeners();
  }

  void _initializePlayerShards() {
    for (var shardType in ShardType.values) {
      _playerShards[shardType] = 0;
    }
  }

  ShardType? getElementalShardTypeFromCardType(CardType cardType) {
    try {
      return ShardType.values.firstWhere(
        (st) =>
            st.toString().split('.').last ==
            "${cardType.toString().split('.').last}_SHARD",
      );
    } catch (e) {
      return null;
    }
  }

  Card _copyCard(Card template, CardRarity rarity, int level) {
    final rarityAdjustedStats = RarityStatsUtil.calculateStatsForRarity(
      baseHp: template.maxHp,
      baseAttack: template.attack,
      baseDefense: template.defense,
      baseSpeed: template.speed,
      rarity: rarity,
    );

    return Card(
      id: "${template.id}_${rarity.toString().split('.').last}_copy_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}",
      originalTemplateId: template.id,
      name: template.name,
      imageUrl: template.imageUrl,
      maxHp: rarityAdjustedStats['hp']!,
      attack: rarityAdjustedStats['attack']!,
      defense: rarityAdjustedStats['defense']!,
      speed: rarityAdjustedStats['speed']!,
      type: template.type,
      talent: template.talent,
      rarity: rarity,
      level: level,
      evolutionLevel: 0,
      ascensionLevel: 0,
      xp: 0,
      currentMana: 0,
      maxMana: template.talent?.manaCost ?? 0,
      isYangBuffActive: false,
      isBloodSurgeAttackBuffActive: false,
      originalAttack: rarityAdjustedStats['attack']!,
      originalDefense: rarityAdjustedStats['defense']!,
      originalSpeed: rarityAdjustedStats['speed']!,
      originalMaxHp: rarityAdjustedStats['hp']!,
      diamondPrice: template.diamondPrice,
    );
  }

  Card copyCardForBattle(Card template) {
    return _copyCard(template, template.rarity, template.level);
  }

  Card? _mintCardInstanceByTemplateId(
    String templateId,
    CardRarity rarityToMint, {
    int initialLevel = 1,
  }) {
    final List<Card> allCardTemplates = [
      ...CardDefinitions.availableCards,
      ...CardDefinitions.eventCards,
    ];

    final Card? template = allCardTemplates.firstWhereOrNull(
      (c) => c.id == templateId,
    );

    if (template == null) {
      _logMessage("Error: Card template $templateId not found for minting.");
      return null;
    }

    final supplyForTemplate = CardSupplyData.cardMaxSupply[templateId];
    if (supplyForTemplate == null) {
      _logMessage(
        "Error: No supply data defined for card template $templateId.",
      );
      return null;
    }

    int maxSupply = supplyForTemplate[rarityToMint] ?? 0;
    int currentMinted =
        _mintedCardCounts.putIfAbsent(templateId, () => {})[rarityToMint] ?? 0;

    if (currentMinted < maxSupply) {
      _mintedCardCounts[templateId]![rarityToMint] = currentMinted + 1;
      Card newInstance = _copyCard(template, rarityToMint, initialLevel);
      _logMessage(
        "Minted ${rarityToMint.toString().split('.').last} ${template.name} (Lvl $initialLevel). Supply: ${currentMinted + 1}/$maxSupply",
      );
      return newInstance;
    } else {
      _logMessage(
        "Supply limit reached for ${rarityToMint.toString().split('.').last} ${template.name} (ID: $templateId). Cannot mint new copy.",
      );
      return null;
    }
  }

  void applyPermanentTalentEffects(Card card) {
    // Public
    TalentSystem.applyPermanentTalentEffects(card, _logMessage);
  }

  int get playerCurrency => _playerCurrency;
  int get playerDiamonds => _playerDiamonds;
  int get playerSouls => _playerSouls;

  void selectCardForBattle(Card cardFromInventory) {
    if (_userOwnedCards.contains(cardFromInventory)) {
      _currentlySelectedPlayerCard = cardFromInventory;
      notifyListeners();
    }
  }

  void setupBattleForFloorLevel(String floorId, int levelNumber) {
    _logMessage(
      "Attempting to setup battle for Floor: $floorId, Level: $levelNumber",
    );
    if (_currentlySelectedPlayerCard == null) {
      _logMessage("Error: No player card selected for battle.");
      isGameStarted = false;
      notifyListeners();
      return;
    }
    playerCard = _copyCard(
      _currentlySelectedPlayerCard!,
      _currentlySelectedPlayerCard!.rarity,
      _currentlySelectedPlayerCard!.level,
    );
    applyEvolutionAscensionBattleStats(playerCard!); // Public call
    resetCardBattleFlags(playerCard!); // Public call

    final floor = _gameFloors.firstWhere(
      (f) => f.id == floorId,
      orElse: () => throw Exception("Floor not found: $floorId"),
    );

    String enemyCardIdToBattle;
    if (floor.themedCardPoolIds.isNotEmpty) {
      enemyCardIdToBattle = floor
          .themedCardPoolIds[_random.nextInt(floor.themedCardPoolIds.length)];
    } else {
      _logMessage(
        "Warning: Floor ${floor.name} has no themed card pool. Using a random available card.",
      );
      if (CardDefinitions.availableCards.isEmpty) {
        throw Exception("No available cards for enemy fallback.");
      }
      enemyCardIdToBattle = CardDefinitions
          .availableCards[_random.nextInt(
            CardDefinitions.availableCards.length,
          )]
          .id;
    }

    final int enemyTemplateIndex = CardDefinitions.availableCards.indexWhere(
      (card) => card.id == enemyCardIdToBattle,
    );
    if (enemyTemplateIndex == -1) {
      throw Exception(
        "Enemy card ID $enemyCardIdToBattle for floor ${floor.name} not found in definitions.",
      );
    }
    final Card enemyTemplate =
        CardDefinitions.availableCards[enemyTemplateIndex];

    int floorNumber = _gameFloors.indexWhere((f) => f.id == floorId) + 1;

    final scaledAttributes = EnemyDifficultyScaler.getScaledEnemyAttributes(
      floorNumber: floorNumber,
      levelNumber: levelNumber,
      maxPossibleLevel: 75,
    );

    CardRarity enemyRarity = scaledAttributes['rarity'];
    int enemyLevel = scaledAttributes['level'];
    int enemyEvo = scaledAttributes['evolution'];
    int enemyAsc = scaledAttributes['ascension'];

    Card tempEnemyForLevelCap = Card(
      id: '',
      originalTemplateId: '',
      name: '',
      imageUrl: '',
      maxHp: 1,
      attack: 1,
      defense: 1,
      speed: 1,
      rarity: enemyRarity,
      level: 1,
    );
    enemyLevel = enemyLevel.clamp(1, tempEnemyForLevelCap.maxCardLevel);

    enemyCard = _copyCard(enemyTemplate, enemyRarity, enemyLevel);
    enemyCard!.evolutionLevel = enemyEvo;
    enemyCard!.ascensionLevel = enemyAsc;
    resetCardBattleFlags(enemyCard!); // Public call
    applyEvolutionAscensionBattleStats(enemyCard!); // Public call

    _currentBattlingFloorId = floorId;
    _currentBattlingLevelNumber = levelNumber;

    currentRound = 1;
    isGameStarted = true;
    isGameOver = false;
    winnerMessage = null;
    _logMessage(
      "GameState.isGameStarted set to: $isGameStarted for floor battle.",
    );
    battleLog.clear();
    _logMessage("Floor Battle Started: ${floor.name} - Level $levelNumber!");

    if (playerCard != null) {
      playerCard!.reset();
      applyPermanentTalentEffects(playerCard!); // Public call
    }
    if (enemyCard != null) {
      enemyCard!.reset();
      applyPermanentTalentEffects(enemyCard!); // Public call
    }

    if (playerCard != null && enemyCard != null) {
      TalentSystem.applyOffensiveStartOfBattleTalents(
        playerCard!,
        enemyCard!,
        _logMessage,
      );
    }
    if (enemyCard != null && playerCard != null) {
      TalentSystem.applyOffensiveStartOfBattleTalents(
        enemyCard!,
        playerCard!,
        _logMessage,
      );
    }

    _logMessage(
      "${playerCard?.name} (Lvl ${playerCard?.level}) HP: ${playerCard?.currentHp} vs ${enemyCard?.name} (Lvl ${enemyCard?.level}) HP: ${enemyCard?.currentHp}",
    );
    notifyListeners();
    _runGameLoop();
  }

  int getHighestUnlockedLevelForFloor(String floorId) {
    return _highestUnlockedLevelPerFloor[floorId] ?? 1;
  }

  Set<int> getCompletedLevelsForFloor(String floorId) {
    return _completedLevelsPerFloor[floorId] ?? {};
  }

  void setupNewRandomBattle() {
    if (_currentlySelectedPlayerCard == null) {
      _logMessage("Error: No player card selected for battle.");
      isGameStarted = false;
      notifyListeners();
      return;
    }
    playerCard = _copyCard(
      _currentlySelectedPlayerCard!,
      _currentlySelectedPlayerCard!.rarity,
      _currentlySelectedPlayerCard!.level,
    );
    resetCardBattleFlags(playerCard!); // Public call
    applyEvolutionAscensionBattleStats(playerCard!); // Public call

    _logMessage(
      "Player card for random battle: ${_currentlySelectedPlayerCard?.name}",
    );
    if (CardDefinitions.availableCards.isEmpty) {
      _logMessage("Error: No available cards for random enemy.");
      isGameStarted = false;
      notifyListeners();
      return;
    }
    Card enemyTemplate = CardDefinitions
        .availableCards[_random.nextInt(CardDefinitions.availableCards.length)];
    enemyCard = _copyCard(enemyTemplate, CardRarity.COMMON, 1);
    applyEvolutionAscensionBattleStats(enemyCard!); // Public call
    resetCardBattleFlags(enemyCard!); // Public call

    _currentBattlingFloorId = null;
    _currentBattlingLevelNumber = null;
    currentRound = 1;
    isGameStarted = true;
    isGameOver = false;
    winnerMessage = null;
    _logMessage("GameState.isGameStarted set to: $isGameStarted");
    battleLog.clear();
    _logMessage("Game started!");

    if (playerCard != null) {
      playerCard!.reset();
      applyPermanentTalentEffects(playerCard!); // Public call
    }
    if (enemyCard != null) {
      enemyCard!.reset();
      applyPermanentTalentEffects(enemyCard!); // Public call
    }
    if (playerCard != null && enemyCard != null) {
      TalentSystem.applyOffensiveStartOfBattleTalents(
        playerCard!,
        enemyCard!,
        _logMessage,
      );
    }
    if (enemyCard != null && playerCard != null) {
      TalentSystem.applyOffensiveStartOfBattleTalents(
        enemyCard!,
        playerCard!,
        _logMessage,
      );
    }

    _logMessage(
      "${playerCard?.name} (Lvl ${playerCard?.level}) HP: ${playerCard?.currentHp} Mana: ${playerCard?.currentMana}/${playerCard?.maxMana} | ${enemyCard?.name} (Lvl ${enemyCard?.level}) HP: ${enemyCard?.currentHp} Mana: ${enemyCard?.currentMana}/${enemyCard?.maxMana}",
    );
    notifyListeners();

    _runGameLoop();
  }

  void _logMessage(String message) {
    if (kDebugMode) print(message);
    battleLog.insert(0, message);
    if (battleLog.length > 100) {
      battleLog.removeLast();
    }
  }

  Future<void> _runGameLoop() async {
    if (!isGameStarted ||
        isGameOver ||
        playerCard == null ||
        enemyCard == null) {
      return;
    }

    _logMessage("--- Round $currentRound ---");
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));

    for (var card in [playerCard!, enemyCard!]) {
      if (card.maxMana > 0) {
        int manaGainedThisRound =
            (MANA_GAIN_PER_ROUND * (1.0 + card.manaRegenBonus)).round();
        card.currentMana += manaGainedThisRound;
        if (card.currentMana > card.maxMana) {
          card.currentMana = card.maxMana;
        }
        _logMessage(
          "${card.name} gained $manaGainedThisRound mana. Current: ${card.currentMana}/${card.maxMana}",
        );
      }
    }
    TalentSystem.rotateYinYangBuff(playerCard!, _logMessage);
    TalentSystem.rotateYinYangBuff(enemyCard!, _logMessage);
    TalentSystem.checkAndApplyBerserker(playerCard!, _logMessage);
    TalentSystem.checkAndApplyBerserker(enemyCard!, _logMessage);
    TalentSystem.checkAndApplyBloodSurgeLifesteal(playerCard!, _logMessage);
    TalentSystem.checkAndApplyBloodSurgeLifesteal(enemyCard!, _logMessage);
    TalentSystem.checkAndApplyDominance(playerCard!, enemyCard!, _logMessage);
    TalentSystem.checkAndApplyDominance(enemyCard!, playerCard!, _logMessage);
    TalentSystem.checkAndApplyExecutioner(playerCard!, enemyCard!, _logMessage);
    TalentSystem.checkAndApplyExecutioner(enemyCard!, playerCard!, _logMessage);
    TalentSystem.checkAndApplyUnderdog(playerCard!, enemyCard!, _logMessage);
    TalentSystem.checkAndApplyUnderdog(enemyCard!, playerCard!, _logMessage);

    notifyListeners();

    Card firstAttacker = (playerCard!.speed >= enemyCard!.speed)
        ? playerCard!
        : enemyCard!;
    Card secondAttacker = (firstAttacker == playerCard)
        ? enemyCard!
        : playerCard!;

    if (firstAttacker.isStunned) {
      _logMessage("${firstAttacker.name} is Stunned and misses their turn!");
      firstAttacker.isStunned = false;
    } else {
      _performAttack(firstAttacker, secondAttacker);
      notifyListeners();
      if (isGameOver) return;
      if (firstAttacker == playerCard) {
        TalentSystem.checkAndApplyBerserker(enemyCard!, _logMessage);
        TalentSystem.checkAndApplyBloodSurgeLifesteal(enemyCard!, _logMessage);
        TalentSystem.checkAndApplyDominance(
          playerCard!,
          enemyCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyDominance(
          enemyCard!,
          playerCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyExecutioner(
          playerCard!,
          enemyCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyUnderdog(
          playerCard!,
          enemyCard!,
          _logMessage,
        );
      } else {
        TalentSystem.checkAndApplyBerserker(playerCard!, _logMessage);
        TalentSystem.checkAndApplyBloodSurgeLifesteal(playerCard!, _logMessage);
        TalentSystem.checkAndApplyDominance(
          enemyCard!,
          playerCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyDominance(
          playerCard!,
          enemyCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyExecutioner(
          enemyCard!,
          playerCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyUnderdog(
          enemyCard!,
          playerCard!,
          _logMessage,
        );
      }
    }

    await Future.delayed(const Duration(milliseconds: 750));
    if (isGameOver) return;

    if (secondAttacker.isStunned) {
      _logMessage("${secondAttacker.name} is Stunned and misses their turn!");
      secondAttacker.isStunned = false;
    } else {
      _performAttack(secondAttacker, firstAttacker);
      notifyListeners();
      if (isGameOver) return;
      if (secondAttacker == playerCard) {
        TalentSystem.checkAndApplyBerserker(enemyCard!, _logMessage);
        TalentSystem.checkAndApplyBloodSurgeLifesteal(enemyCard!, _logMessage);
        TalentSystem.checkAndApplyDominance(
          playerCard!,
          enemyCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyDominance(
          enemyCard!,
          playerCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyExecutioner(
          playerCard!,
          enemyCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyUnderdog(
          playerCard!,
          enemyCard!,
          _logMessage,
        );
      } else {
        TalentSystem.checkAndApplyBerserker(playerCard!, _logMessage);
        TalentSystem.checkAndApplyBloodSurgeLifesteal(playerCard!, _logMessage);
        TalentSystem.checkAndApplyDominance(
          enemyCard!,
          playerCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyDominance(
          playerCard!,
          enemyCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyExecutioner(
          enemyCard!,
          playerCard!,
          _logMessage,
        );
        TalentSystem.checkAndApplyUnderdog(
          enemyCard!,
          playerCard!,
          _logMessage,
        );
      }
    }

    _applyRoundEndRegeneration(playerCard!);
    _applyRoundEndRegeneration(enemyCard!);

    TalentSystem.applyRoundEndTalentEffects(
      playerCard!,
      enemyCard!,
      currentRound,
      _logMessage,
    );
    TalentSystem.applyRoundEndTalentEffects(
      enemyCard!,
      playerCard!,
      currentRound,
      _logMessage,
    );

    notifyListeners();

    _logMessage(
      "${playerCard?.name} HP: ${playerCard?.currentHp} Mana: ${playerCard?.currentMana}/${playerCard?.maxMana} | ${enemyCard?.name} HP: ${enemyCard?.currentHp} Mana: ${enemyCard?.currentMana}/${enemyCard?.maxMana}",
    );
    notifyListeners();

    if (currentRound >= maxRounds) {
      _determineWinnerByHp();
      notifyListeners();
      return;
    } else {
      currentRound++;
    }

    await Future.delayed(const Duration(seconds: 1));
    if (!isGameOver) {
      _runGameLoop();
    }
  }

  void _applyRoundEndRegeneration(Card card) {
    // This logic is now primarily handled within TalentSystem.applyRoundEndTalentEffects
    // if the card has an active Regeneration buff.
  }

  double _getTypeEffectivenessMultiplier(
    CardType attackerType,
    CardType defenderType,
  ) {
    return ElementalSystem.getTypeEffectivenessMultiplier(
      attackerType,
      defenderType,
    );
  }

  void _performAttack(Card attacker, Card defender) {
    if (defender.currentEvasionChance > 0 &&
        _random.nextDouble() < defender.currentEvasionChance) {
      _logMessage("${defender.name} EVADED ${attacker.name}'s attack!");
      return;
    }

    double baseDamage = (attacker.attack - defender.defense).toDouble();
    if (baseDamage < 1.0) baseDamage = 1.0;

    double finalDamage = baseDamage;
    String attackLog =
        "${attacker.name} (Lvl ${attacker.level}) attacks ${defender.name} (Lvl ${defender.level})";

    double typeMultiplier = _getTypeEffectivenessMultiplier(
      attacker.type,
      defender.type,
    );
    if (typeMultiplier > 1.0) {
      attackLog += " (Super Effective!)";
    } else if (typeMultiplier < 1.0) {
      attackLog += " (Not Very Effective...)";
    }
    finalDamage *= typeMultiplier;

    double critChance = 0.05;
    double critDamageMultiplier = 1.5;

    if (attacker.isPrecisionBuffActive) {
      critChance += attacker.precisionCritChanceBonus;
      critDamageMultiplier += attacker.precisionCritDamageBonus;
    }
    critChance = critChance.clamp(0.0, 1.0);

    if (_random.nextDouble() < critChance) {
      finalDamage *= critDamageMultiplier;
      attackLog += " (CRITICAL HIT!)";
    }

    if (defender.isEnduranceBuffActive) {
      double reduction = finalDamage * defender.enduranceDamageReductionPercent;
      finalDamage -= reduction;
      attackLog += " (Endurance reduces damage by ${reduction.round()}!)";
    }

    int damageToDeal = finalDamage.round();
    if (damageToDeal < 1) damageToDeal = 1;

    defender.takeDamage(damageToDeal);
    TalentSystem.activateOnDealDamageTalents(
      attacker,
      damageToDeal,
      _logMessage,
    );

    if (defender.currentHp > 0) {
      TalentSystem.checkAndActivateProtector(defender, _logMessage);
      if (defender.talent?.type == TalentType.REVERSION &&
          !defender.hasReversionActivatedThisBattle) {
        bool reversionTriggered = TalentSystem.checkReversionCondition(
          defender,
          _logMessage,
        );
        if (reversionTriggered) {
          _executeReversionEffect(triggeredByCard: defender);
        }
      }
    }
    if (attacker.currentHp > 0 &&
        attacker.talent?.type == TalentType.REVERSION &&
        !attacker.hasReversionActivatedThisBattle) {
      bool reversionTriggered = TalentSystem.checkReversionCondition(
        attacker,
        _logMessage,
      );
      if (reversionTriggered) {
        _executeReversionEffect(triggeredByCard: attacker);
      }
    }

    _logMessage(
      "$attackLog for $damageToDeal damage. ${defender.name} HP: ${defender.currentHp}",
    );

    if (playerCard!.currentHp <= 0 || enemyCard!.currentHp <= 0) {
      _handleBattleEnd();
    }
  }

  void _executeReversionEffect({required Card triggeredByCard}) {
    _logMessage(
      "Reversion triggered by ${triggeredByCard.name}! Reverting stats for all familiars.",
    );
    triggeredByCard.hasReversionActivatedThisBattle = true;

    final List<Map<String, dynamic>> cardStatesToRevert = [
      {
        'card': playerCard!,
        'originalTemplateId': playerCard!.originalTemplateId,
        'rarity': playerCard!.rarity,
        'level': playerCard!.level,
        'isAlly':
            playerCard == triggeredByCard ||
            (playerCard!.id == triggeredByCard.id),
      },
      {
        'card': enemyCard!,
        'originalTemplateId': enemyCard!.originalTemplateId,
        'rarity': enemyCard!.rarity,
        'level': enemyCard!.level,
        'isAlly':
            enemyCard == triggeredByCard ||
            (enemyCard!.id == triggeredByCard.id),
      },
    ];

    for (var state in cardStatesToRevert) {
      Card cardToRevert = state['card'];
      String templateId = state['originalTemplateId'];
      CardRarity rarity = state['rarity'] as CardRarity;
      int level = state['level'] as int;
      bool isAllyToTrigger = state['isAlly'];

      Card? template = CardDefinitions.availableCards.firstWhereOrNull(
        (c) => c.id == templateId,
      );
      template ??= CardDefinitions.eventCards.firstWhereOrNull(
        (c) => c.id == templateId,
      );

      if (template == null) {
        _logMessage(
          "Error in _executeReversionEffect: Card template $templateId not found. Skipping stat reversion for ${cardToRevert.name}.",
        );
        continue;
      }

      final baseStats = RarityStatsUtil.calculateStatsForRarity(
        baseHp: template.maxHp,
        baseAttack: template.attack,
        baseDefense: template.defense,
        baseSpeed: template.speed,
        rarity: rarity,
      );
      int tempMaxHp = baseStats['hp']!;
      int tempAttack = baseStats['attack']!;
      int tempDefense = baseStats['defense']!;
      int tempSpeed = baseStats['speed']!;

      for (int i = 1; i < level; i++) {
        final boosts = LevelingCostUtil.getStatBoostsForLevelUp(rarity);
        tempMaxHp += boosts['hp']!;
        tempAttack += boosts['attack']!;
        tempDefense += boosts['defense']!;
        tempSpeed += boosts['speed']!;
      }

      cardToRevert.maxHp = tempMaxHp;
      cardToRevert.attack = tempAttack;
      cardToRevert.defense = tempDefense;
      cardToRevert.speed = tempSpeed;
      cardToRevert.currentHp = cardToRevert.maxHp;
      cardToRevert.originalAttack = cardToRevert.attack;
      cardToRevert.originalDefense = cardToRevert.defense;
      cardToRevert.originalSpeed = cardToRevert.speed;
      cardToRevert.originalMaxHp = cardToRevert.maxHp;

      resetCardBattleFlags(cardToRevert); // Public call
      _logMessage(
        "${cardToRevert.name} stats and HP reverted. HP: ${cardToRevert.currentHp}, ATK: ${cardToRevert.attack}, DEF: ${cardToRevert.defense}, SPD: ${cardToRevert.speed}",
      );

      if (isAllyToTrigger &&
          triggeredByCard.talent != null &&
          triggeredByCard.talent!.type == TalentType.REVERSION) {
        double buffPercent = triggeredByCard.talent!.secondaryValue ?? 0.12;
        cardToRevert.defense += (cardToRevert.originalDefense * buffPercent)
            .round();
        cardToRevert.speed += (cardToRevert.originalSpeed * buffPercent)
            .round();
        cardToRevert.isReversionAllyBuffActive = true;
        _logMessage(
          "${cardToRevert.name} (ally) received Reversion's +${(buffPercent * 100).toStringAsFixed(0)}% DEF/SPD buff. DEF: ${cardToRevert.defense}, SPD: ${cardToRevert.speed}",
        );
      }
    }

    if (playerCard != null && enemyCard != null) {
      TalentSystem.checkAndApplyBerserker(playerCard!, _logMessage);
      TalentSystem.checkAndApplyDominance(playerCard!, enemyCard!, _logMessage);
      TalentSystem.checkAndApplyExecutioner(
        playerCard!,
        enemyCard!,
        _logMessage,
      );
      TalentSystem.checkAndApplyUnderdog(playerCard!, enemyCard!, _logMessage);
      TalentSystem.checkAndApplyBloodSurgeLifesteal(playerCard!, _logMessage);

      TalentSystem.checkAndApplyBerserker(enemyCard!, _logMessage);
      TalentSystem.checkAndApplyDominance(enemyCard!, playerCard!, _logMessage);
      TalentSystem.checkAndApplyExecutioner(
        enemyCard!,
        playerCard!,
        _logMessage,
      );
      TalentSystem.checkAndApplyUnderdog(enemyCard!, playerCard!, _logMessage);
      TalentSystem.checkAndApplyBloodSurgeLifesteal(enemyCard!, _logMessage);
    }
    notifyListeners();
  }

  void resetCardBattleFlags(Card card) {
    // Public
    card.isYangBuffActive = false;
    card.isBloodSurgeAttackBuffActive = false;
    card.isBloodSurgeLifestealActive = false;
    card.isDivineBlessingActive = false;
    card.divineBlessingTurnsRemaining = 0;
    card.isDominanceBuffActive = false;
    card.isExecutionerBuffActive = false;
    card.isUnderGrievousLimiterDebuff = false;
    card.isProtectorDefBuffActive = false;
    card.isBerserkerBuffActive = false;
    card.isReversionAllyBuffActive = false;
    card.isUnderdogBuffActive = false;
    card.isAmplifierBuffActive = false;
    card.amplifierTurnsRemaining = 0;
    card.isTemporalRewindActive = false;
    card.temporalRewindTurnsRemaining = 0;
    card.temporalRewindInitialHpAtBuff = 0;
    card.isUnderBurnDebuff = false;
    card.burnStacks = 0;
    card.burnDurationTurns = 0;
    card.burnCasterAttack = 0;
    card.burnDamagePerStackPercent = 0.0;
    card.burnHealingReductionPercent = 0.0;
    card.isEnduranceBuffActive = false;
    card.enduranceTurnsRemaining = 0;
    card.enduranceDamageReductionPercent = 0.0;
    card.currentEvasionChance = 0.0;
    card.evasionBuffTurnsRemaining = 0;
    card.evasionStacks = 0;
    card.isPrecisionBuffActive = false;
    card.precisionTurnsRemaining = 0;
    card.precisionCritChanceBonus = 0.0;
    card.isRegenerationBuffActive = false;
    card.regenerationTurnsRemaining = 0;
    card.regenerationHealPerTurn = 0;
    card.isTimeBombActive = false;
    card.timeBombTurnsRemaining = 0;
    card.timeBombDamage = 0;
    card.trickRoomEffectTurnsRemaining = 0;
    card.isTrickRoomAtkActive = false;
    card.trickRoomAtkBuffDebuffAmount = 0;
    card.isTrickRoomDefActive = false;
    card.trickRoomDefBuffDebuffAmount = 0;
    card.fightingCounter = 0;
    card.isSilenced = false;
    card.silenceTurnsRemaining = 0;
    card.precisionCritDamageBonus = 0.0;
    card.isStunned = false;
  }

  void _handleBattleEnd() {
    isGameOver = true;
    if (playerCard == null || enemyCard == null) {
      winnerMessage = "Error: Battle cards not found at battle end.";
      _logMessage(winnerMessage!);
      notifyListeners();
      saveGameState();
      return;
    }

    bool playerWonBattle = false;
    if (playerCard!.currentHp > 0 && enemyCard!.currentHp <= 0) {
      playerWonBattle = true;
      winnerMessage = "${playerCard!.name} wins! (${enemyCard!.name} defeated)";
    } else if (enemyCard!.currentHp > 0 && playerCard!.currentHp <= 0) {
      playerWonBattle = false;
      winnerMessage = "${enemyCard!.name} wins! (${playerCard!.name} defeated)";
    } else if (playerCard!.currentHp <= 0 && enemyCard!.currentHp <= 0) {
      playerWonBattle = false;
      winnerMessage = "Mutual Knockout! Player is defeated.";
    } else {
      playerWonBattle = false;
      winnerMessage =
          "Battle ended: Ambiguous KO state (assuming player loss).";
    }
    _logMessage(winnerMessage!);

    if (playerWonBattle) {
      _logMessage(
        "[_handleBattleEnd] Player won by KO. Calling _completeLevel for floor: $_currentBattlingFloorId, level: $_currentBattlingLevelNumber",
      );
      if (_currentBattlingFloorId != null &&
          _currentBattlingLevelNumber != null) {
        _completeLevel(
          _currentBattlingFloorId!,
          _currentBattlingLevelNumber!,
          enemyCard?.type,
        );
      }
    } else {
      _logMessage(
        "[_handleBattleEnd] Player lost or draw by KO. _completeLevel will NOT be called.",
      );
    }
    notifyListeners();
    saveGameState();
  }

  void _determineWinnerByHp() {
    _logMessage(
      "[_determineWinnerByHp] Determining winner by HP. Player HP: ${playerCard?.currentHp}, Enemy HP: ${enemyCard?.currentHp}",
    );
    isGameOver = true;
    if (playerCard == null || enemyCard == null) {
      winnerMessage = "Error determining winner by HP.";
      _logMessage(winnerMessage!);
      notifyListeners();
      saveGameState();
      return;
    }

    bool playerWonBattle = false;
    if (playerCard!.currentHp > enemyCard!.currentHp) {
      playerWonBattle = true;
      winnerMessage =
          "${playerCard!.name} wins by HP! (${playerCard!.currentHp} vs ${enemyCard!.currentHp})";
    } else if (enemyCard!.currentHp > playerCard!.currentHp) {
      playerWonBattle = false;
      winnerMessage =
          "${enemyCard!.name} wins by HP! (${enemyCard!.currentHp} vs ${playerCard!.currentHp})";
    } else {
      playerWonBattle = false;
      winnerMessage = "It's a draw by HP! Player is defeated.";
    }
    _logMessage(winnerMessage!);

    if (playerWonBattle) {
      _logMessage(
        "[_determineWinnerByHp] Player won by HP. Calling _completeLevel for floor: $_currentBattlingFloorId, level: $_currentBattlingLevelNumber",
      );
      if (_currentBattlingFloorId != null &&
          _currentBattlingLevelNumber != null) {
        _completeLevel(
          _currentBattlingFloorId!,
          _currentBattlingLevelNumber!,
          enemyCard?.type,
        );
      }
    } else {
      _logMessage(
        "[_determineWinnerByHp] Player lost or draw by HP. _completeLevel will NOT be called.",
      );
    }
    notifyListeners();
    saveGameState();
  }

  void _completeLevel(
    String floorId,
    int levelNumber,
    CardType? defeatedEnemyType,
  ) {
    _logMessage(
      "[_completeLevel ENTRY] Called for floorId: $floorId, levelNumber: $levelNumber. Current highest for floor: ${_highestUnlockedLevelPerFloor[floorId]}",
    );
    final floor = _gameFloors.firstWhere((f) => f.id == floorId);

    const int goldReward = 25;
    _playerCurrency += goldReward;
    _logMessage(
      "Level $levelNumber on ${floor.name} completed! Gained $goldReward gold.",
    );

    if (defeatedEnemyType != null) {
      final ShardType? elementalShard = getElementalShardTypeFromCardType(
        defeatedEnemyType,
      );
      if (elementalShard != null) {
        addShards(elementalShard, 25);
      }
    }

    _completedLevelsPerFloor.putIfAbsent(floorId, () => {}).add(levelNumber);

    if (levelNumber < floor.numberOfLevels) {
      int nextLevelToUnlock = levelNumber + 1;
      if (nextLevelToUnlock > (_highestUnlockedLevelPerFloor[floorId] ?? 0)) {
        _highestUnlockedLevelPerFloor[floorId] = nextLevelToUnlock;
        _logMessage(
          "[_completeLevel] Unlocked next level. New highest for $floorId: $nextLevelToUnlock",
        );
      }
    } else {
      _completedFloorIds.add(floorId);
      _playerCurrency += floor.rewardForFloorCompletion;
      _logMessage(
        "Congratulations! ${floor.name} fully completed! Gained bonus ${floor.rewardForFloorCompletion} currency.",
      );

      int currentFloorIndex = _gameFloors.indexWhere((f) => f.id == floorId);
      if (currentFloorIndex != -1 &&
          currentFloorIndex < _gameFloors.length - 1) {
        String nextFloorId = _gameFloors[currentFloorIndex + 1].id;
        _unlockedFloorIds.add(nextFloorId);
        _highestUnlockedLevelPerFloor.putIfAbsent(nextFloorId, () => 1);
        _logMessage(
          "Unlocked new area: ${_gameFloors[currentFloorIndex + 1].name}!",
        );
      } else {
        _logMessage("All available floors completed!");
      }
    }
    notifyListeners();
    saveGameState();
  }

  bool buyCardFromMarket(String templateId, CardRarity rarity, int price) {
    if (_playerCurrency >= price) {
      Card? newCard = _mintCardInstanceByTemplateId(templateId, rarity);
      if (newCard != null) {
        _playerCurrency -= price;
        _userOwnedCards.add(newCard);
        _logMessage("Purchased ${newCard.name} for $price currency.");
        notifyListeners();
        saveGameState();
        return true;
      } else {
        _logMessage(
          "Could not purchase ${rarity.toString().split('.').last} card (ID: $templateId). No supply left or error.",
        );
        return false;
      }
    } else {
      _logMessage(
        "Not enough currency to buy card (ID: $templateId, Rarity: $rarity).",
      );
      notifyListeners();
      return false;
    }
  }

  bool buyEventCardWithDiamonds(Card cardTemplateToBuy, int diamondPrice) {
    if (_playerDiamonds >= diamondPrice) {
      Card? newCard = _mintCardInstanceByTemplateId(
        cardTemplateToBuy.originalTemplateId,
        cardTemplateToBuy.rarity,
        initialLevel: 1,
      );

      if (newCard != null) {
        _playerDiamonds -= diamondPrice;
        _userOwnedCards.add(newCard);
        _logMessage("Purchased ${newCard.name} for $diamondPrice diamonds.");
        notifyListeners();
        saveGameState();
        return true;
      } else {
        _logMessage(
          "Could not purchase event card ${cardTemplateToBuy.name}. Supply issue or error.",
        );
        return false;
      }
    } else {
      _logMessage(
        "Not enough diamonds to buy ${cardTemplateToBuy.name}. Required: $diamondPrice, Have: $_playerDiamonds",
      );
      return false;
    }
  }

  bool buyShardsFromGoldShop(ShardType shardType, int amount, int totalPrice) {
    if (_playerCurrency >= totalPrice) {
      if (amount <= 0) {
        _logMessage("Cannot purchase zero or negative amount of shards.");
        return false;
      }
      _playerCurrency -= totalPrice;
      addShards(shardType, amount);
      _logMessage(
        "Purchased $amount ${shardType.toString().split('.').last.replaceAll('_', ' ')} for $totalPrice gold.",
      );
      saveGameState();
      return true;
    } else {
      _logMessage(
        "Not enough gold to buy $amount ${shardType.toString().split('.').last.replaceAll('_', ' ')}. Required: $totalPrice, Have: $_playerCurrency",
      );
      notifyListeners();
      return false;
    }
  }

  int getGoldCostForLevelUp(Card card) {
    if (card.level >= card.maxCardLevel) return -1;
    return LevelingCostUtil.calculateGoldCost(card.level);
  }

  int getShardCostForLevelUp(Card card) {
    if (card.level >= card.maxCardLevel) return -1;
    return LevelingCostUtil.calculateShardCost(card.level);
  }

  ShardType? getRequiredShardTypeForLevelUp(Card card) {
    return getElementalShardTypeFromCardType(card.type);
  }

  bool upgradeCard(Card cardToUpgrade) {
    if (cardToUpgrade.level >= cardToUpgrade.maxCardLevel) {
      _logMessage("${cardToUpgrade.name} is already at max level.");
      return false;
    }

    int goldCost = getGoldCostForLevelUp(cardToUpgrade);
    int shardCost = getShardCostForLevelUp(cardToUpgrade);
    ShardType? requiredShardType = getRequiredShardTypeForLevelUp(
      cardToUpgrade,
    );

    if (requiredShardType == null) {
      _logMessage(
        "Cannot determine primary elemental shard type for ${cardToUpgrade.name} to level up with shards. Gold: $goldCost, Shard Cost: $shardCost.",
      );
      return false;
    }

    if (_playerCurrency >= goldCost) {
      _playerCurrency -= goldCost;

      int elementalShardsOwned = _playerShards[requiredShardType] ?? 0;
      int shardsToUseFromInventory = min(elementalShardsOwned, shardCost);
      bool paymentSuccess = true;

      if (shardsToUseFromInventory > 0) {
        useShards(requiredShardType, shardsToUseFromInventory);
      }

      int remainingShardCost = shardCost - shardsToUseFromInventory;
      if (remainingShardCost > 0) {
        if (!useSouls(remainingShardCost)) {
          _logMessage(
            "Not enough Souls to cover remaining shard cost for ${cardToUpgrade.name} level up. Refunding gold.",
          );
          _playerCurrency += goldCost;
          paymentSuccess = false;
        }
      }

      if (paymentSuccess) {
        int cardIndex = _userOwnedCards.indexWhere(
          (c) => c.id == cardToUpgrade.id,
        );
        if (cardIndex != -1) {
          _userOwnedCards[cardIndex].level++;
          _applyLevelUpStatBoosts(_userOwnedCards[cardIndex]);
          _userOwnedCards[cardIndex].xp = 0;
          if (_userOwnedCards[cardIndex].level <
              _userOwnedCards[cardIndex].maxCardLevel) {
            _userOwnedCards[cardIndex].xpToNextLevel =
                Card.calculateXpToNextLevel(_userOwnedCards[cardIndex].level);
          } else {
            _userOwnedCards[cardIndex].xpToNextLevel = 0;
          }
          _userOwnedCards[cardIndex].currentHp =
              _userOwnedCards[cardIndex].maxHp;
          _logMessage(
            "${_userOwnedCards[cardIndex].name} upgraded to Lvl ${_userOwnedCards[cardIndex].level}!",
          );
          notifyListeners();
          saveGameState();
          return true;
        }
      }
    }
    _logMessage(
      "Not enough resources for ${cardToUpgrade.name} upgrade. Gold: $goldCost, ${requiredShardType.toString().split(".").last.replaceAll("_SHARD", "") ?? "Unknown Shard"}: $shardCost (or Souls).",
    );
    return false;
  }

  void _applyLevelUpStatBoosts(Card card) {
    int hpBoost = 0;
    int atkBoost = 0;
    int defBoost = 0;
    int spdBoost = 0;

    switch (card.rarity) {
      case CardRarity.COMMON:
        hpBoost = 5;
        atkBoost = 1;
        defBoost = 1;
        spdBoost = 1;
        break;
      case CardRarity.UNCOMMON:
        hpBoost = 7;
        atkBoost = 2;
        defBoost = 1;
        spdBoost = 1;
        break;
      case CardRarity.RARE:
        hpBoost = 10;
        atkBoost = 2;
        defBoost = 2;
        spdBoost = 2;
        break;
      case CardRarity.SUPER_RARE:
        hpBoost = 12;
        atkBoost = 3;
        defBoost = 2;
        spdBoost = 2;
        break;
      case CardRarity.ULTRA_RARE:
        hpBoost = 15;
        atkBoost = 3;
        defBoost = 3;
        spdBoost = 3;
        break;
    }
    card.maxHp += hpBoost;
    card.attack += atkBoost;
    card.defense += defBoost;
    card.speed += spdBoost;
  }

  void applyEvolutionAscensionBattleStats(Card card) {
    // Public
    Card? commonBaseTemplate = CardDefinitions.availableCards.firstWhereOrNull(
      (c) => c.id == card.originalTemplateId,
    );
    commonBaseTemplate ??= CardDefinitions.eventCards.firstWhereOrNull(
      (c) => c.id == card.originalTemplateId,
    );
    if (commonBaseTemplate == null) {
      _logMessage(
        "Error in applyEvolutionAscensionBattleStats: Base template ${card.originalTemplateId} not found for ${card.name}. Stats may not be applied correctly.",
      );
    }

    int rarityAdjustedBaseHp;
    int rarityAdjustedBaseAttack;
    int rarityAdjustedBaseDefense;
    int rarityAdjustedBaseSpeed;

    final stats = RarityStatsUtil.calculateStatsForRarity(
      baseHp: commonBaseTemplate?.maxHp ?? card.maxHp,
      baseAttack: commonBaseTemplate?.attack ?? card.attack,
      baseDefense: commonBaseTemplate?.defense ?? card.defense,
      baseSpeed: commonBaseTemplate?.speed ?? card.speed,
      rarity: card.rarity,
    );
    rarityAdjustedBaseHp = stats['hp']!;
    rarityAdjustedBaseAttack = stats['attack']!;
    rarityAdjustedBaseDefense = stats['defense']!;
    rarityAdjustedBaseSpeed = stats['speed']!;

    double evolutionMultiplier = 1.0 + (card.evolutionLevel * 0.10);
    card.maxHp = (rarityAdjustedBaseHp * evolutionMultiplier).round();
    card.attack = (rarityAdjustedBaseAttack * evolutionMultiplier).round();
    card.defense = (rarityAdjustedBaseDefense * evolutionMultiplier).round();
    card.speed = (rarityAdjustedBaseSpeed * evolutionMultiplier).round();

    for (int i = 0; i < card.ascensionLevel; i++) {
      card.maxHp = (card.maxHp * 1.05).round();
      card.attack = (card.attack * 1.05).round();
      card.defense = (card.defense * 1.05).round();
      card.speed = (card.speed * 1.05).round();
    }
    card.currentHp = card.maxHp;
  }

  void clearBattleState() {
    _currentBattlingFloorId = null;
    _currentBattlingLevelNumber = null;
  }

  int getMarketPriceForCardTemplate(Card cardTemplate, CardRarity rarity) {
    int rarityMultiplier = CardRarity.values.indexOf(rarity) + 1;
    return (50 +
            (cardTemplate.attack +
                    cardTemplate.defense +
                    cardTemplate.maxHp ~/ 10 +
                    cardTemplate.speed) *
                2) *
        rarityMultiplier;
  }

  bool canEvolve(Card card) {
    if (card.evolutionLevel >= 3) {
      return false;
    }
    if (card.level < card.maxCardLevel) {
      return false;
    }

    bool hasSacrificeCard = _userOwnedCards.any(
      (ownedCard) =>
          ownedCard.id != card.id &&
          ownedCard.originalTemplateId == card.originalTemplateId &&
          ownedCard.rarity == card.rarity &&
          ownedCard.evolutionLevel == card.evolutionLevel &&
          ownedCard.level == ownedCard.maxCardLevel,
    );

    if (!hasSacrificeCard) {
      return false;
    }

    ShardType? requiredElementalShardType = getElementalShardTypeFromCardType(
      card.type,
    );
    if (requiredElementalShardType == null) {
      _logMessage(
        "Cannot determine elemental shard type for ${card.name} (Type: ${card.type}) to evolve.",
      );
      return false;
    }

    int elementalShardCostForEvolution = 0;
    if (card.evolutionLevel == 0) {
      elementalShardCostForEvolution = 50;
    } else if (card.evolutionLevel == 1)
      elementalShardCostForEvolution = 75;
    else if (card.evolutionLevel == 2)
      elementalShardCostForEvolution = 100;

    int elementalShardsOwned = _playerShards[requiredElementalShardType] ?? 0;
    if (elementalShardsOwned < elementalShardCostForEvolution) {
      int deficit = elementalShardCostForEvolution - elementalShardsOwned;
      if (_playerSouls < deficit) {
        _logMessage(
          "Not enough ${requiredElementalShardType.toString().split('.').last.replaceAll('_', ' ')} (Have: $elementalShardsOwned, Need: $elementalShardCostForEvolution) or Souls (Have: $_playerSouls, Need: $deficit) to evolve ${card.name}.",
        );
        return false;
      }
      _logMessage(
        "Will use $elementalShardsOwned ${requiredElementalShardType.toString().split('.').last.replaceAll('_', ' ')} and $deficit Souls for ${card.name} evolution.",
      );
    }

    return true;
  }

  bool evolveCard(Card cardToEvolve, String sacrificeCardId) {
    if (!canEvolve(cardToEvolve)) {
      _logMessage("Evolution conditions not met for ${cardToEvolve.name}.");
      return false;
    }

    final sacrificeCardIndex = _userOwnedCards.indexWhere(
      (c) => c.id == sacrificeCardId,
    );
    if (sacrificeCardIndex == -1) {
      _logMessage(
        "Sacrifice card (ID: $sacrificeCardId) for evolution not found.",
      );
      return false;
    }

    ShardType? requiredElementalShardType = getElementalShardTypeFromCardType(
      cardToEvolve.type,
    );
    if (requiredElementalShardType == null) {
      _logMessage(
        "Cannot determine elemental shard type for ${cardToEvolve.name} (Type: ${cardToEvolve.type}) to evolve.",
      );
      return false;
    }

    int elementalShardCostForEvolution = 0;
    if (cardToEvolve.evolutionLevel == 0) {
      elementalShardCostForEvolution = 50;
    } else if (cardToEvolve.evolutionLevel == 1)
      elementalShardCostForEvolution = 75;
    else if (cardToEvolve.evolutionLevel == 2)
      elementalShardCostForEvolution = 100;

    int elementalShardsOwned = _playerShards[requiredElementalShardType] ?? 0;
    int shardsToUseFromInventory = min(
      elementalShardsOwned,
      elementalShardCostForEvolution,
    );

    if (shardsToUseFromInventory > 0) {
      useShards(requiredElementalShardType, shardsToUseFromInventory);
    }

    int remainingShardCost =
        elementalShardCostForEvolution - shardsToUseFromInventory;
    if (remainingShardCost > 0) {
      if (!useSouls(remainingShardCost)) {
        _logMessage(
          "Evolution failed for ${cardToEvolve.name}: Insufficient souls for remaining cost. This should have been caught by canEvolve.",
        );
        return false;
      }
    }

    final sacrificeCard = _userOwnedCards[sacrificeCardIndex];
    _userOwnedCards.removeAt(sacrificeCardIndex);

    cardToEvolve.evolutionLevel++;
    _logMessage(
      "${cardToEvolve.name} evolved to Evo ${cardToEvolve.evolutionLevel} by sacrificing ${sacrificeCard.name}! Stats boosted. Level reset to 1.",
    );
    cardToEvolve.level = 1;

    final commonBaseTemplate = CardDefinitions.availableCards.firstWhereOrNull(
      (c) => c.id == cardToEvolve.originalTemplateId,
    );
    if (commonBaseTemplate == null) {
      _logMessage(
        "Error: Could not find base template ${cardToEvolve.originalTemplateId} for evolution stat calculation of ${cardToEvolve.name}.",
      );
      return false;
    }
    final rarityAdjustedStats = RarityStatsUtil.calculateStatsForRarity(
      baseHp: commonBaseTemplate.maxHp,
      baseAttack: commonBaseTemplate.attack,
      baseDefense: commonBaseTemplate.defense,
      baseSpeed: commonBaseTemplate.speed,
      rarity: cardToEvolve.rarity,
    );

    double evolutionStatMultiplier = 1.0 + (cardToEvolve.evolutionLevel * 0.10);

    cardToEvolve.maxHp = (rarityAdjustedStats['hp']! * evolutionStatMultiplier)
        .round();
    cardToEvolve.attack =
        (rarityAdjustedStats['attack']! * evolutionStatMultiplier).round();
    cardToEvolve.defense =
        (rarityAdjustedStats['defense']! * evolutionStatMultiplier).round();
    cardToEvolve.speed =
        (rarityAdjustedStats['speed']! * evolutionStatMultiplier).round();
    cardToEvolve.currentHp = cardToEvolve.maxHp;

    notifyListeners();
    saveGameState();
    return true;
  }

  bool canAscend(Card card) {
    _logMessage(
      "!!!!!!!!!! CAN ASCEND METHOD CALLED FOR: ${card.name} !!!!!!!!!!",
    );
    if (card.rarity != CardRarity.SUPER_RARE &&
        card.rarity != CardRarity.ULTRA_RARE) {
      _logMessage(
        "[canAscend Check] Failed: ${card.name} (Rarity: ${card.rarity}) is not Super Rare or Ultra Rare.",
      );
      return false;
    }
    if (card.evolutionLevel < 3) {
      _logMessage(
        "[canAscend Check] Failed: ${card.name} (Evo: ${card.evolutionLevel}) is not Evolution Level 3.",
      );
      return false;
    }
    if (card.level < card.maxCardLevel) {
      _logMessage(
        "[canAscend Check] Failed: ${card.name} (Evo ${card.evolutionLevel}, Lvl ${card.level}) must be at max level (${card.maxCardLevel}).",
      );
      return false;
    }

    if (card.ascensionLevel >= card.maxAscensionLevel) {
      _logMessage(
        "[canAscend Check] Failed: ${card.name} (Ascension: ${card.ascensionLevel}) is already at max ascension level (${card.maxAscensionLevel}).",
      );
      return false;
    }

    bool hasSacrificeEvo0Card = _userOwnedCards.any(
      (ownedCard) =>
          ownedCard.id != card.id &&
          ownedCard.originalTemplateId == card.originalTemplateId &&
          ownedCard.rarity == card.rarity &&
          ownedCard.evolutionLevel == 0,
    );

    if (!hasSacrificeEvo0Card) {
      _logMessage(
        "[canAscend Check] Failed: No suitable Evo 0 sacrifice card found for ${card.name} (Template: ${card.originalTemplateId}, Rarity: ${card.rarity}).",
      );
      return false;
    }

    ShardType? elementalShardType = getElementalShardTypeFromCardType(
      card.type,
    );
    if (elementalShardType == null) {
      _logMessage(
        "[canAscend Check] Failed: Cannot determine elemental shard type for ${card.name} (Type: ${card.type}) for ascension cost.",
      );
      return false;
    }

    int elementalShardCost = 30 + (card.ascensionLevel * 15);
    int elementalShardsOwned = _playerShards[elementalShardType] ?? 0;

    if (elementalShardsOwned < elementalShardCost) {
      int deficit = elementalShardCost - elementalShardsOwned;
      if (_playerSouls < deficit) {
        _logMessage(
          "[canAscend Check] Failed: Not enough ${elementalShardType.toString().split('.').last.replaceAll('_', ' ')} (Have: $elementalShardsOwned, Need: $elementalShardCost) or Souls (Have: $_playerSouls, Need: $deficit) to ascend ${card.name}.",
        );
        return false;
      }
      _logMessage(
        "[canAscend Check] Resource Info: Will use $elementalShardsOwned ${elementalShardType.toString().split('.').last.replaceAll('_', ' ')} and $deficit Souls for ${card.name} ascension.",
      );
    }

    _logMessage(
      "[canAscend Check] Passed: All conditions met for ${card.name}.",
    );
    return true;
  }

  int getAscensionCost(Card card) {
    int baseCost = 2000;
    int ascensionLevelCost = card.ascensionLevel * 500;
    int rarityCost = card.rarity == CardRarity.ULTRA_RARE ? 1000 : 0;
    return baseCost + ascensionLevelCost + rarityCost;
  }

  bool ascendCard(Card cardToAscend, String sacrificeEvo0CardId) {
    if (!canAscend(cardToAscend)) {
      _logMessage("Ascension conditions not met for ${cardToAscend.name}.");
      return false;
    }

    final sacrificeCardIndex = _userOwnedCards.indexWhere(
      (c) => c.id == sacrificeEvo0CardId,
    );
    if (sacrificeCardIndex == -1) {
      _logMessage(
        "Sacrifice Evo 0 card (ID: $sacrificeEvo0CardId) for ascension not found.",
      );
      return false;
    }
    final sacrificeCard = _userOwnedCards[sacrificeCardIndex];

    if (sacrificeCard.originalTemplateId != cardToAscend.originalTemplateId ||
        sacrificeCard.rarity != cardToAscend.rarity ||
        sacrificeCard.evolutionLevel != 0 ||
        sacrificeCard.id == cardToAscend.id) {
      _logMessage(
        "Invalid Evo 0 sacrifice card selected for ${cardToAscend.name}.",
      );
      return false;
    }

    ShardType? elementalShardType = getElementalShardTypeFromCardType(
      cardToAscend.type,
    );
    int elementalShardCost = 30 + (cardToAscend.ascensionLevel * 15);
    if (elementalShardType != null) {
      int elementalShardsOwned = _playerShards[elementalShardType] ?? 0;
      int shardsToUseFromInventory = min(
        elementalShardsOwned,
        elementalShardCost,
      );

      if (shardsToUseFromInventory > 0) {
        useShards(elementalShardType, shardsToUseFromInventory);
      }
      int remainingShardCost = elementalShardCost - shardsToUseFromInventory;
      if (remainingShardCost > 0) {
        if (!useSouls(remainingShardCost)) {
          _logMessage(
            "Ascension failed for ${cardToAscend.name}: Insufficient souls for remaining cost. This should have been caught by canAscend.",
          );
          return false;
        }
      }
    } else {
      _logMessage(
        "Cannot determine elemental shard type for ascension cost of ${cardToAscend.name}.",
      );
      return false;
    }

    _userOwnedCards.removeAt(sacrificeCardIndex);
    cardToAscend.ascensionLevel++;

    cardToAscend.maxHp = (cardToAscend.maxHp * 1.05).round();
    cardToAscend.attack = (cardToAscend.attack * 1.05).round();
    cardToAscend.defense = (cardToAscend.defense * 1.05).round();
    cardToAscend.speed = (cardToAscend.speed * 1.05).round();
    cardToAscend.currentHp = cardToAscend.maxHp;

    _logMessage(
      "${cardToAscend.name} ascended to Ascension Level ${cardToAscend.ascensionLevel} by sacrificing ${sacrificeCard.name}!",
    );
    notifyListeners();
    saveGameState();
    return true;
  }

  void addShards(ShardType shardType, int amount) {
    if (amount <= 0) return;
    _playerShards[shardType] = (_playerShards[shardType] ?? 0) + amount;
    _logMessage(
      "Gained $amount ${shardType.toString().split('.').last.replaceAll('_', ' ')}.",
    );
    notifyListeners();
  }

  bool useShards(ShardType shardType, int amount) {
    if (amount <= 0) return true;
    if ((_playerShards[shardType] ?? 0) >= amount) {
      _playerShards[shardType] = (_playerShards[shardType]!) - amount;
      _logMessage(
        "Used $amount ${shardType.toString().split('.').last.replaceAll('_', ' ')}.",
      );
      notifyListeners();
      return true;
    }
    _logMessage(
      "Not enough ${shardType.toString().split('.').last.replaceAll('_', ' ')}. Required: $amount, Have: ${_playerShards[shardType] ?? 0}",
    );
    notifyListeners();
    return false;
  }

  bool useSouls(int amount) {
    if (amount <= 0) return true;
    if (_playerSouls >= amount) {
      _playerSouls -= amount;
      _logMessage("Used $amount Souls.");
      notifyListeners();
      return true;
    }
    _logMessage("Not enough Souls. Required: $amount, Have: $_playerSouls");
    notifyListeners();
    return false;
  }

  int _getXpValueForFodder(Card fodderCard) {
    int rarityBonus = (fodderCard.rarity.index + 1) * 20;
    int levelBonus = fodderCard.level * 10;
    int evolutionBonus = fodderCard.evolutionLevel * 50;
    return rarityBonus + levelBonus + evolutionBonus;
  }

  bool enhanceCard(
    Card cardToEnhance, {
    List<String>? fodderCardIds,
    int soulsToUse = 0,
  }) {
    if (cardToEnhance.level >= cardToEnhance.maxCardLevel) {
      _logMessage(
        "${cardToEnhance.name} is already at max level for its current evolution.",
      );
      return false;
    }

    int totalXpGained = 0;
    List<Card> actualFodderCards = [];

    if (fodderCardIds != null && fodderCardIds.isNotEmpty) {
      for (String fodderId in fodderCardIds) {
        final fodderIndex = _userOwnedCards.indexWhere(
          (c) => c.id == fodderId && c.id != cardToEnhance.id,
        );
        if (fodderIndex != -1) {
          actualFodderCards.add(_userOwnedCards[fodderIndex]);
          totalXpGained += _getXpValueForFodder(_userOwnedCards[fodderIndex]);
        } else {
          _logMessage(
            "Warning: Fodder card ID $fodderId not found or is the card being enhanced.",
          );
        }
      }
    }

    if (soulsToUse > 0) {
      if (_playerSouls >= soulsToUse) {
        totalXpGained += soulsToUse;
        _playerSouls -= soulsToUse;
        _logMessage("Used $soulsToUse souls for enhancement.");
      } else {
        _logMessage(
          "Not enough souls. Tried to use $soulsToUse, but only have $_playerSouls.",
        );
        soulsToUse = 0;
      }
    }

    if (totalXpGained == 0) {
      _logMessage("No XP gained from enhancement for ${cardToEnhance.name}.");
      return false;
    }

    for (var fodder in actualFodderCards) {
      _userOwnedCards.removeWhere((c) => c.id == fodder.id);
    }

    cardToEnhance.xp += totalXpGained;
    _logMessage("${cardToEnhance.name} gained $totalXpGained XP.");

    bool leveledUp = false;
    while (cardToEnhance.level < cardToEnhance.maxCardLevel &&
        cardToEnhance.xp >= cardToEnhance.xpToNextLevel) {
      cardToEnhance.xp -= cardToEnhance.xpToNextLevel;
      cardToEnhance.level++;
      _applyLevelUpStatBoosts(cardToEnhance);
      cardToEnhance.xpToNextLevel = Card.calculateXpToNextLevel(
        cardToEnhance.level,
      );
      _logMessage(
        "${cardToEnhance.name} leveled up to Lvl ${cardToEnhance.level}!",
      );
      leveledUp = true;
    }
    if (cardToEnhance.level >= cardToEnhance.maxCardLevel) cardToEnhance.xp = 0;

    notifyListeners();
    saveGameState();
    return leveledUp;
  }

  Future<void> saveGameState() async {
    if (!_isUserLoggedIn || _currentPlayerId.isEmpty) {
      _logMessage(
        "Cannot save game state: User not logged in or player ID is empty.",
      );
      return;
    }

    _logMessage(
      "Attempting to save game state for user: $_currentPlayerId to Firestore.",
    );
    try {
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentPlayerId);

      Map<String, dynamic> userData = {
        'playerCurrency': _playerCurrency,
        'playerDiamonds': _playerDiamonds,
        'playerSouls': _playerSouls,
        'userOwnedCards': _userOwnedCards
            .map((card) => cardToJson(card))
            .whereType<String>()
            .toList(),
        'playerShards': _playerShards.map(
          (key, value) => MapEntry(key.index.toString(), value),
        ),
        'mintedCardCounts': _mintedCardCounts.map(
          (templateId, rarityMap) => MapEntry(
            templateId,
            rarityMap.map(
              (rarity, count) => MapEntry(rarity.index.toString(), count),
            ),
          ),
        ),
        'unlockedFloorIds': _unlockedFloorIds.toList(),
        'completedFloorIds': _completedFloorIds.toList(),
        'highestUnlockedLevelPerFloor': _highestUnlockedLevelPerFloor,
        'completedLevelsPerFloor': _completedLevelsPerFloor.map(
          (key, value) => MapEntry(key, value.toList()),
        ),
        'displayedCardJsonStrings': _displayedCardJsonStrings.toList(),
        'userStatusMessage': _userStatusMessage,
        'username': _currentAuthUsername,
        'lastSaveTimestamp': FieldValue.serverTimestamp(),
      };

      await userDocRef.set(userData, SetOptions(merge: true));
      _logMessage("Game state saved to Firestore for user: $_currentPlayerId");
    } catch (e) {
      _logMessage(
        "Error saving game state to Firestore for user $_currentPlayerId: $e",
      );
    }
  }

  Future<void> loadGameState() async {
    if (!_isUserLoggedIn || _currentPlayerId.isEmpty) {
      _logMessage(
        "Cannot load game state: User not logged in or player ID is empty.",
      );
      _initializeUserInventory();
      _initializePlayerShards();
      return;
    }

    _logMessage("Loading game state for user: $_currentPlayerId");
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentPlayerId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _logMessage("Firestore data found for user $_currentPlayerId: $data");

        _playerCurrency = data['playerCurrency'] ?? 500;
        _playerDiamonds = data['playerDiamonds'] ?? 10;
        _playerSouls = data['playerSouls'] ?? 1000;
        _currentAuthUsername = data['username'] ?? "";

        List<dynamic>? ownedCardsJson =
            data['userOwnedCards'] as List<dynamic>?;
        if (ownedCardsJson != null && ownedCardsJson.isNotEmpty) {
          _userOwnedCards.clear();
          _userOwnedCards.addAll(
            ownedCardsJson
                .map((json) => cardFromJson(json as String))
                .whereType<Card>()
                .toList(),
          );
          if (_userOwnedCards.isEmpty) {
            _initializeUserInventory();
          } else {
            _currentlySelectedPlayerCard = _userOwnedCards.isNotEmpty
                ? _userOwnedCards[0]
                : null;
          }
        } else {
          _initializeUserInventory();
        }

        Map<String, dynamic>? shardsData =
            data['playerShards'] as Map<String, dynamic>?;
        _playerShards.clear();
        _userStatusMessage = data['userStatusMessage'] ?? "";
        _initializePlayerShards();
        if (shardsData != null) {
          shardsData.forEach((key, value) {
            try {
              _playerShards[ShardType.values[int.parse(key)]] = value as int;
            } catch (e) {
              _logMessage(
                "Error parsing shard data from Firestore for user $_currentPlayerId: key $key. Error: $e",
              );
            }
          });
        }

        Map<String, dynamic>? mintedCountsData =
            data['mintedCardCounts'] as Map<String, dynamic>?;
        _mintedCardCounts.clear();
        if (mintedCountsData != null) {
          mintedCountsData.forEach((templateId, rarityMapDynamic) {
            final rarityMap = rarityMapDynamic as Map<String, dynamic>;
            Map<CardRarity, int> counts = {};
            rarityMap.forEach((rarityIndexStr, count) {
              try {
                counts[CardRarity.values[int.parse(rarityIndexStr)]] =
                    count as int;
              } catch (e) {
                _logMessage(
                  "Error parsing minted count rarity data for $templateId: $rarityIndexStr. Error: $e",
                );
              }
            });
            _mintedCardCounts[templateId] = counts;
          });
        }

        _unlockedFloorIds.clear();
        _unlockedFloorIds.addAll(
          List<String>.from(
            data['unlockedFloorIds'] ??
                (FloorDefinitions.floors.isNotEmpty
                    ? [FloorDefinitions.floors.first.id]
                    : []),
          ),
        );
        if (_unlockedFloorIds.isEmpty && FloorDefinitions.floors.isNotEmpty) {
          _unlockedFloorIds.add(FloorDefinitions.floors.first.id);
        }

        _completedFloorIds.clear();
        _completedFloorIds.addAll(
          List<String>.from(data['completedFloorIds'] ?? []),
        );

        _highestUnlockedLevelPerFloor.clear();
        Map<String, dynamic>? highestUnlockedData =
            data['highestUnlockedLevelPerFloor'] as Map<String, dynamic>?;
        if (highestUnlockedData != null) {
          highestUnlockedData.forEach((key, value) {
            _highestUnlockedLevelPerFloor[key] = value as int;
          });
        }
        if (_highestUnlockedLevelPerFloor.isEmpty &&
            FloorDefinitions.floors.isNotEmpty) {
          _highestUnlockedLevelPerFloor[FloorDefinitions.floors.first.id] = 1;
        }

        _completedLevelsPerFloor.clear();
        Map<String, dynamic>? completedLevelsData =
            data['completedLevelsPerFloor'] as Map<String, dynamic>?;
        if (completedLevelsData != null) {
          completedLevelsData.forEach((key, value) {
            _completedLevelsPerFloor[key] = Set<int>.from(
              value as List<dynamic>,
            );
          });
        }
        _displayedCardJsonStrings.clear();
        _displayedCardJsonStrings = List<String>.from(
          data['displayedCardJsonStrings'] ?? [],
        );
        if (_displayedCardJsonStrings.length > 5) {
          _displayedCardJsonStrings = _displayedCardJsonStrings.sublist(0, 5);
        }
        _logMessage(
          "Game state loaded from Firestore for user: $_currentPlayerId",
        );
      } else {
        _logMessage(
          "No Firestore document found for user $_currentPlayerId. Initializing new game state.",
        );
        _initializeUserInventory();
        _initializePlayerShards();
        _playerCurrency = 500;
        _playerDiamonds = 10;
        _playerSouls = 1000;
        if (gameFloors.isNotEmpty) {
          _unlockedFloorIds.add(gameFloors.first.id);
          _highestUnlockedLevelPerFloor[gameFloors.first.id] = 1;
          _displayedCardJsonStrings.clear();
        }
        await saveGameState();
      }
    } catch (e) {
      _logMessage(
        "Error loading game state from Firestore for user $_currentPlayerId: $e. Initializing local defaults.",
      );
      _initializeUserInventory();
      _currentAuthUsername = "";
      _initializePlayerShards();
      _playerCurrency = 500;
      _playerDiamonds = 10;
      _playerSouls = 1000;
      if (gameFloors.isNotEmpty) {
        _displayedCardJsonStrings.clear();
        _unlockedFloorIds.add(gameFloors.first.id);
        _highestUnlockedLevelPerFloor[gameFloors.first.id] = 1;
      }
    }
    notifyListeners();
  }

  Future<bool> registerUser(String username, String password) async {
    try {
      String email = "$username@anigame.app";
      fb_auth.UserCredential userCredential = await fb_auth
          .FirebaseAuth
          .instance
          .createUserWithEmailAndPassword(email: email, password: password);
      _currentAuthUsername = username;
      _logMessage(
        "User '$username' (email: $email) registered successfully with Firebase.",
      );
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _logMessage('Registration failed: The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        _logMessage(
          'Registration failed: The account already exists for that email/username.',
        );
      } else {
        _logMessage('Registration failed: ${e.message}');
      }
      return false;
    } catch (e) {
      _logMessage('Registration failed with unknown error: $e');
      return false;
    }
  }

  Future<bool> loginUser(String username, String password) async {
    try {
      String email = "$username@anigame.app";
      await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentAuthUsername = username;
      _logMessage(
        "User '$username' (email: $email) logged in successfully with Firebase.",
      );
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        _logMessage('Login failed: Invalid credentials for $username.');
      } else {
        _logMessage('Login failed: ${e.message}');
      }
      return false;
    } catch (e) {
      _logMessage('Login failed with unknown error: $e');
      return false;
    }
  }

  Future<void> logoutUser() async {
    if (!_isUserLoggedIn) return;
    await saveGameState();
    await fb_auth.FirebaseAuth.instance.signOut();
    _logMessage("User '$_currentPlayerId' logged out.");
  }

  Future<void> spawnNewRaidEvent({
    Card? specificBossCard,
    CardRarity? rarityOverride,
  }) async {
    if (_activeRaidEvents.length >= MAX_ACTIVE_RAIDS) {
      _logMessage(
        "Max active raids ($MAX_ACTIVE_RAIDS) reached. Cannot spawn new raid.",
      );
      return;
    }

    Card? bossToSpawn;
    if (specificBossCard != null) {
      CardRarity finalRarity = rarityOverride ?? specificBossCard.rarity;
      bossToSpawn = _copyCard(
        specificBossCard,
        finalRarity,
        specificBossCard.level,
      );
    } else {
      if (CardDefinitions.eventCards.isEmpty) {
        _logMessage("No event card definitions available to spawn a raid.");
        return;
      }
      if (CardDefinitions.eventCards.isEmpty) {
        _logMessage(
          "No event card definitions available at all to pick a template for a raid.",
        );
        return;
      }
      final bossTemplate = CardDefinitions
          .eventCards[_random.nextInt(CardDefinitions.eventCards.length)];
      CardRarity finalRarity = rarityOverride ?? bossTemplate.rarity;
      // Spawn raid bosses at a high level, max evolution, and high ascension
      int bossLevel = 50; // Default
      int bossAscension = 0; // Default
      switch (finalRarity) {
        case CardRarity.SUPER_RARE:
          bossLevel = 60; // Max level for SR (no change)
          bossAscension = 20; // Max ascension for SR
          break;
        case CardRarity.ULTRA_RARE:
          bossLevel = 75; // Max level for UR (no change)
          bossAscension = 25; // Max ascension for UR
          break;
        default: // For Common, Uncommon, Rare if they become raid bosses
          bossLevel = (Card(
            // Explicitly use app_card.Card
            id: '',
            originalTemplateId: '',
            name: '',
            imageUrl: '',
            maxHp: 1,
            attack: 1,
            defense: 1,
            speed: 1,
            rarity: finalRarity,
            level: 1,
          )).maxCardLevel;
      }
      bossToSpawn = _copyCard(bossTemplate, finalRarity, bossLevel);
      bossToSpawn.evolutionLevel = 3; // Max evolution
      bossToSpawn.ascensionLevel = bossAscension.clamp(
        0,
        bossToSpawn.maxAscensionLevel,
      );
    }
    applyEvolutionAscensionBattleStats(bossToSpawn); // Public call

    final newRaid = RaidEvent(bossCard: bossToSpawn);

    try {
      await FirebaseFirestore.instance
          .collection('activeRaids')
          .doc(newRaid.id)
          .set(newRaid.toJson());
      _activeRaidEvents.add(newRaid);
      _logMessage(
        "New Raid Event spawned and saved to Firestore: ${bossToSpawn.name} (Rarity: ${newRaid.rarity}, ID: ${newRaid.id}). Lobby expires at ${newRaid.lobbyExpiresAt}.",
      );
      notifyListeners();
    } catch (e) {
      _logMessage("Error saving new raid event ${newRaid.id} to Firestore: $e");
    }
  }

  Future<void> updateRaidEventStatuses() async {
    if (_activeRaidEvents.isEmpty) return;

    bool changed = false;
    List<String> raidsToRemoveFromFirestoreIds = [];
    List<RaidEvent> raidsToUpdateInFirestore = [];

    _activeRaidEvents.removeWhere((raid) {
      RaidEventStatus oldStatus = raid.status;
      raid.updateStatus();
      if (raid.status != oldStatus) {
        raidsToUpdateInFirestore.add(raid);
        _logMessage(
          "Raid ${raid.id} (${raid.bossCard.name}) status changed from $oldStatus to ${raid.status}",
        );
        changed = true;
      }

      if (raid.status == RaidEventStatus.expiredUnstarted ||
          raid.status == RaidEventStatus.completedSuccess ||
          raid.status == RaidEventStatus.completedFailure ||
          raid.status == RaidEventStatus.expiredInProgress) {
        _logMessage(
          "Raid Event ${raid.id} (${raid.bossCard.name}) ended. Removing from active list.",
        );
        changed = true;
        raidsToRemoveFromFirestoreIds.add(
          raid.id,
        ); // Mark for Firestore deletion
        return true;
      }
      return false;
    });

    for (var raid in raidsToUpdateInFirestore) {
      if (!raidsToRemoveFromFirestoreIds.contains(raid.id)) {
        // Only update if not also being removed
        try {
          await FirebaseFirestore.instance
              .collection('activeRaids')
              .doc(raid.id)
              .update(raid.toJson());
        } catch (e) {
          _logMessage("Error updating raid ${raid.id} status in Firestore: $e");
        }
      }
    }
    for (var raidId in raidsToRemoveFromFirestoreIds) {
      try {
        await FirebaseFirestore.instance
            .collection('activeRaids')
            .doc(raidId)
            .delete();
      } catch (e) {
        _logMessage("Error deleting raid $raidId from Firestore: $e");
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<bool> joinRaidLobby(String raidId, String playerId) async {
    final raid = _activeRaidEvents.firstWhereOrNull((r) => r.id == raidId);
    if (raid != null) {
      if (raid.addPlayer(playerId)) {
        try {
          await FirebaseFirestore.instance
              .collection('activeRaids')
              .doc(raidId)
              .update({
                'participants': raid.playersInLobby,
                'status': raid.status.toString(),
              });
          _logMessage(
            "$playerId joined lobby for raid: ${raid.bossCard.name} (ID: $raidId)",
          );
          notifyListeners();
          return true;
        } catch (e) {
          _logMessage(
            "Error updating raid $raidId in Firestore after player join: $e",
          );
          raid.removePlayer(playerId);
        }
      } else {
        _logMessage(
          "Failed to join lobby for $playerId (ID: $raidId). Lobby full or already joined.",
        );
      }
    } else {
      _logMessage("Could not find raid with ID: $raidId to join.");
    }
    return false;
  }

  Future<bool> leaveRaidLobby(String raidId, String playerId) async {
    final raid = _activeRaidEvents.firstWhereOrNull((r) => r.id == raidId);
    if (raid != null) {
      if (raid.removePlayer(playerId)) {
        try {
          await FirebaseFirestore.instance
              .collection('activeRaids')
              .doc(raidId)
              .update({
                'participants': raid.playersInLobby,
                'status': raid.status.toString(),
              });
          _logMessage(
            "$playerId left lobby for raid: ${raid.bossCard.name} (ID: $raidId)",
          );
          notifyListeners();
          return true;
        } catch (e) {
          _logMessage(
            "Error updating raid $raidId in Firestore after player leave: $e",
          );
          raid.addPlayer(playerId);
        }
      }
    }
    return false;
  }

  Future<bool> kickPlayerFromRaidLobby(
    String raidId,
    String kickerId,
    String playerIdToKick,
  ) async {
    final raid = _activeRaidEvents.firstWhereOrNull((r) => r.id == raidId);
    if (raid != null) {
      if (raid.removePlayer(playerIdToKick, kickerId: kickerId)) {
        try {
          await FirebaseFirestore.instance
              .collection('activeRaids')
              .doc(raidId)
              .update({
                'participants': raid.playersInLobby,
                'status': raid.status.toString(),
              });
          _logMessage(
            "$kickerId kicked $playerIdToKick from lobby: ${raid.bossCard.name} (ID: $raidId)",
          );
          notifyListeners();
          return true;
        } catch (e) {
          _logMessage(
            "Error updating raid $raidId in Firestore after player kick: $e",
          );
        }
      }
    }
    return false;
  }

  Future<bool> startRaidBattle(String raidId, String starterId) async {
    final raid = _activeRaidEvents.firstWhereOrNull((r) => r.id == raidId);
    if (raid != null && raid.startBattle(starterId)) {
      try {
        await FirebaseFirestore.instance
            .collection('activeRaids')
            .doc(raidId)
            .update({
              'status': raid.status.toString(),
              'battleStartedAt': raid.battleStartedAt,
              'battleEndsAt': raid.battleEndsAt,
            });
        _logMessage(
          "Raid battle ${raid.id} started by $starterId. Status: ${raid.status}",
        );
        notifyListeners();
        return true;
      } catch (e) {
        _logMessage(
          "Error updating raid $raidId in Firestore after battle start: $e",
        );
      }
    }
    return false;
  }

  Future<bool> dealDamageToRaidBoss(
    String raidId,
    String playerId,
    int damageAmount,
  ) async {
    final raid = _activeRaidEvents.firstWhereOrNull((r) => r.id == raidId);
    if (raid != null && raid.status == RaidEventStatus.battleInProgress) {
      if (raid.bossCard.currentHp <= 0) {
        _logMessage(
          "Boss ${raid.bossCard.name} (ID: $raidId) already defeated. No damage applied.",
        );
        return false;
      }
      int previousBossHp = raid.bossCard.currentHp;
      raid.bossCard.takeDamage(damageAmount);
      Map<String, dynamic> updates = {'bossCard': cardToJson(raid.bossCard)};

      if (raid.bossCard.currentHp <= 0) {
        raid.completeRaid(true);
        updates['status'] = raid.status.toString();
        _logMessage(
          "Raid boss ${raid.bossCard.name} (ID: $raidId) defeated by collective effort!",
        );
        _distributeRaidCompletionRewards(raid, playerId);
      }
      try {
        await FirebaseFirestore.instance
            .collection('activeRaids')
            .doc(raidId)
            .update(updates);
        _logMessage(
          "$playerId dealt $damageAmount damage to raid boss ${raid.bossCard.name} (ID: $raidId). Boss HP: ${raid.bossCard.currentHp}",
        );
        notifyListeners();
        return true;
      } catch (e) {
        _logMessage(
          "Error updating raid $raidId boss HP/status in Firestore: $e",
        );
        raid.bossCard.currentHp = previousBossHp;
      }
    }
    return false;
  }

  void _distributeRaidCompletionRewards(RaidEvent raid, String winnerPlayerId) {
    double srChance = 0.0;
    double urChance = 0.0;
    int minShards = 0, maxShards = 0;
    int minGold = 0, maxGold = 0;
    int minDiamonds = 0, maxDiamonds = 0;

    switch (raid.rarity) {
      case CardRarity.COMMON:
        srChance = 0.09;
        urChance = 0.03;
        minShards = 200;
        maxShards = 300;
        minGold = 500;
        maxGold = 500;
        minDiamonds = 10;
        maxDiamonds = 10;
        break;
      case CardRarity.UNCOMMON:
        srChance = 0.12;
        urChance = 0.04;
        minShards = 300;
        maxShards = 400;
        minGold = 500;
        maxGold = 650;
        minDiamonds = 10;
        maxDiamonds = 20;
        break;
      case CardRarity.RARE:
        srChance = 0.17;
        urChance = 0.05;
        minShards = 400;
        maxShards = 500;
        minGold = 600;
        maxGold = 750;
        minDiamonds = 10;
        maxDiamonds = 30;
        break;
      case CardRarity.SUPER_RARE:
        srChance = 0.23;
        urChance = 0.07;
        minShards = 500;
        maxShards = 700;
        minGold = 700;
        maxGold = 900;
        minDiamonds = 20;
        maxDiamonds = 40;
        break;
      case CardRarity.ULTRA_RARE:
        srChance = 0.30;
        urChance = 0.10;
        minShards = 600;
        maxShards = 900;
        minGold = 800;
        maxGold = 1100;
        minDiamonds = 25;
        maxDiamonds = 50;
        break;
    }

    Card? rewardCard;
    String bossTemplateId = raid.bossCard.originalTemplateId;

    if (_random.nextDouble() < urChance) {
      rewardCard = _mintCardInstanceByTemplateId(
        bossTemplateId,
        CardRarity.ULTRA_RARE,
        initialLevel: 1,
      );
      if (rewardCard != null) {
        _logMessage(
          "$winnerPlayerId received UR ${rewardCard.name} from defeating ${raid.rarity.name} raid!",
        );
      }
    } else if (_random.nextDouble() < srChance) {
      rewardCard = _mintCardInstanceByTemplateId(
        bossTemplateId,
        CardRarity.SUPER_RARE,
        initialLevel: 1,
      );
      if (rewardCard != null) {
        _logMessage(
          "$winnerPlayerId received SR ${rewardCard.name} from defeating ${raid.rarity.name} raid!",
        );
      }
    }

    if (rewardCard != null) {
      if (_currentPlayerId == winnerPlayerId) {
        _userOwnedCards.add(rewardCard);
      } else {
        _logMessage(
          "Reward card ${rewardCard.name} minted for $winnerPlayerId (not current GameState user).",
        );
      }
    }

    ShardType? bossElementType = getElementalShardTypeFromCardType(
      raid.bossCard.type,
    );
    if (bossElementType != null && maxShards > 0) {
      int shardsGained = minShards + _random.nextInt(maxShards - minShards + 1);
      addShards(bossElementType, shardsGained);
    }

    if (maxGold > 0) {
      int goldGained = minGold + _random.nextInt(maxGold - minGold + 1);
      _playerCurrency += goldGained;
      _logMessage("$winnerPlayerId gained $goldGained gold.");
    }

    if (maxDiamonds > 0) {
      int diamondsGained =
          minDiamonds + _random.nextInt(maxDiamonds - minDiamonds + 1);
      _playerDiamonds += diamondsGained;
      _logMessage("$winnerPlayerId gained $diamondsGained diamonds.");
    }
    notifyListeners();
  }

  Future<void> setDisplayedProfileCards(
    List<String> selectedInstanceCardIds,
  ) async {
    if (!_isUserLoggedIn) {
      _logMessage("Cannot set displayed cards: User not logged in.");
      return;
    }
    List<String> newDisplayedJsonStrings = [];
    List<String> validSelectedIds = List.from(selectedInstanceCardIds);

    validSelectedIds.removeWhere(
      (id) => !_userOwnedCards.any((ownedCard) => ownedCard.id == id),
    );

    if (validSelectedIds.length > 5) {
      _logMessage("Cannot display more than 5 cards. Truncating list.");
      validSelectedIds = validSelectedIds.sublist(0, 5);
    }

    for (String cardId in validSelectedIds) {
      Card? card = _userOwnedCards.firstWhereOrNull((c) => c.id == cardId);
      if (card != null) {
        newDisplayedJsonStrings.add(cardToJson(card));
      }
    }
    _displayedCardJsonStrings = newDisplayedJsonStrings;
    _logMessage(
      "User $_currentPlayerId updated displayed profile cards. Count: ${_displayedCardJsonStrings.length}",
    );
    notifyListeners();
    await saveGameState();
  }

  @override
  void dispose() {
    _raidEventStatusUpdaterTimer?.cancel();
    _raidPopulationMaintenanceTimer?.cancel();
    super.dispose();
  }

  Future<void> updateUserStatusMessage(String newMessage) async {
    if (!_isUserLoggedIn) return;
    _userStatusMessage = newMessage;
    _logMessage(
      "User $_currentPlayerId updated status message: $_userStatusMessage",
    );
    notifyListeners();
    await saveGameState();
  }
}
