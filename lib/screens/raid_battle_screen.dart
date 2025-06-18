import 'dart:async';
import 'dart:math'; // Import for Random
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../game_state.dart';
import '../event_logic.dart';
import '../card_model.dart' as app_card;
import '../widgets/themed_scaffold.dart';
import '../elemental_system.dart';
import '../talent_system.dart';
import '../widgets/framed_card_image_widget.dart';

class RaidBattleScreen extends StatefulWidget {
  final String raidId;
  final List<String> playerTeamCardIds;

  const RaidBattleScreen({
    super.key,
    required this.raidId,
    required this.playerTeamCardIds,
  });

  @override
  State<RaidBattleScreen> createState() => _RaidBattleScreenState();
}

class _RaidBattleScreenState extends State<RaidBattleScreen> {
  Timer? _uiRefreshTimer;
  final List<app_card.Card?> _playerTeamCards = List.filled(
    3,
    null,
    growable: false,
  );
  int _activePlayerCardIndex = 0;

  app_card.Card? _bossBattleInstance;

  final List<String> _battleLog = [];
  final Random _random = Random();
  bool _playerTeamWiped = false;
  bool _battleOverForThisAttempt = false; // Is the current attempt over?
  int _currentRound = 1;
  final int _maxRoundsPerAttempt = 20; // Max rounds for one attempt
  String? _attemptOutcomeMessage;

  int _playerSpecialAttacksRemaining = 3; // Player gets 3 special attacks

  @override
  void initState() {
    super.initState();
    final gameState = Provider.of<GameState>(context, listen: false);
    final raidEvent = gameState.activeRaidEvents.firstWhereOrNull(
      (r) => r.id == widget.raidId,
    );

    if (raidEvent != null) {
      // Create local battle instances for the player's team
      if (widget.playerTeamCardIds.isNotEmpty) {
        for (int i = 0; i < widget.playerTeamCardIds.length && i < 3; i++) {
          final cardId = widget.playerTeamCardIds[i];
          final cardFromInventory = gameState.userOwnedCards.firstWhereOrNull(
            (c) => c.id == cardId,
          );
          if (cardFromInventory != null) {
            _playerTeamCards[i] = gameState.copyCardForBattle(
              cardFromInventory,
            );
            gameState.applyPermanentTalentEffects(_playerTeamCards[i]!);
            gameState.applyEvolutionAscensionBattleStats(_playerTeamCards[i]!);
            gameState.resetCardBattleFlags(_playerTeamCards[i]!);
            _playerTeamCards[i]!.reset();
          }
        }
        _activePlayerCardIndex = _playerTeamCards.indexWhere(
          (card) => card != null && card.currentHp > 0,
        );
        if (_activePlayerCardIndex == -1 &&
            _playerTeamCards.firstOrNull != null) {
          _activePlayerCardIndex = 0;
        } else if (_playerTeamCards.firstOrNull == null) {
          _battleOverForThisAttempt = true;
          _attemptOutcomeMessage = "No team cards selected for battle.";
        }
      } else {
        _battleOverForThisAttempt = true;
        _attemptOutcomeMessage = "No team cards provided for battle.";
      }

      _bossBattleInstance = gameState.copyCardForBattle(raidEvent.bossCard);
      gameState.applyPermanentTalentEffects(_bossBattleInstance!);
      gameState.applyEvolutionAscensionBattleStats(_bossBattleInstance!);
      gameState.resetCardBattleFlags(_bossBattleInstance!);
      _bossBattleInstance!.currentHp = raidEvent.bossCard.currentHp;
      _bossBattleInstance!.maxHp = raidEvent.bossCard.maxHp;

      if (!_battleOverForThisAttempt) {
        _logBattle("Battle started against ${raidEvent.bossCard.name}!");
        final activePlayerCard = _getActivePlayerCard();
        if (activePlayerCard != null && _bossBattleInstance != null) {
          TalentSystem.applyOffensiveStartOfBattleTalents(
            activePlayerCard,
            _bossBattleInstance!,
            _logBattle,
          );
          TalentSystem.applyOffensiveStartOfBattleTalents(
            _bossBattleInstance!,
            activePlayerCard,
            _logBattle,
          );
        }
        _startAutomatedBattleSequence(); // Start the auto battle
      }
    } else {
      _battleOverForThisAttempt = true;
      _attemptOutcomeMessage = "Raid event not found.";
    }

    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    // The async battle loop will self-terminate due to `!mounted` checks
    super.dispose();
  }

  app_card.Card? _getActivePlayerCard() {
    if (_playerTeamCards.isNotEmpty &&
        _activePlayerCardIndex >= 0 &&
        _activePlayerCardIndex < _playerTeamCards.length) {
      return _playerTeamCards[_activePlayerCardIndex];
    }
    return null;
  }

  void _logBattle(String message) {
    if (mounted) {
      setState(() {
        _battleLog.insert(0, message);
        if (_battleLog.length > 50) {
          _battleLog.removeLast();
        }
      });
    } else {
      // ignore: avoid_print
      print("Log (not mounted): $message");
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

  Future<void> _startAutomatedBattleSequence() async {
    if (_battleOverForThisAttempt) return;

    while (_currentRound <= _maxRoundsPerAttempt &&
        !_battleOverForThisAttempt) {
      if (!mounted) return;

      _logBattle("--- Round $_currentRound ---");
      if (mounted) setState(() {});

      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Brief pause at round start
      if (!mounted || _battleOverForThisAttempt) return;

      final app_card.Card? currentPlayerCard = _getActivePlayerCard();
      final app_card.Card? currentBossCard = _bossBattleInstance;

      // Determine action order for automated attacks this round
      bool playerAutoAttacksFirst = false;
      if (currentPlayerCard != null && currentBossCard != null) {
        playerAutoAttacksFirst =
            currentPlayerCard.speed >= currentBossCard.speed;
      }

      if (playerAutoAttacksFirst) {
        // 1. Player's Active Card Automated Attack
        if (currentPlayerCard != null &&
            currentPlayerCard.currentHp > 0 &&
            currentBossCard != null &&
            currentBossCard.currentHp > 0) {
          _logBattle("${currentPlayerCard.name} (Auto) attacks!");
          _executeSingleAttack(
            currentPlayerCard,
            currentBossCard,
            isPlayerAttackingBoss: true,
          );
          if (_checkBattleEndConditions()) break;
        }
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted || _battleOverForThisAttempt) return;

        // 2. Boss's Automated Attack
        if (currentBossCard != null &&
            currentBossCard.currentHp > 0 &&
            currentPlayerCard != null &&
            currentPlayerCard.currentHp > 0) {
          _logBattle("${currentBossCard.name} (Auto) attacks!");
          _executeSingleAttack(
            currentBossCard,
            currentPlayerCard,
            isPlayerAttackingBoss: false,
          );
          if (_handlePlayerCardKO(currentPlayerCard)) break;
          if (_checkBattleEndConditions()) break;
        }
      } else {
        // 1. Boss's Automated Attack
        if (currentBossCard != null &&
            currentBossCard.currentHp > 0 &&
            currentPlayerCard != null &&
            currentPlayerCard.currentHp > 0) {
          _logBattle("${currentBossCard.name} (Auto) attacks!");
          _executeSingleAttack(
            currentBossCard,
            currentPlayerCard,
            isPlayerAttackingBoss: false,
          );
          if (_handlePlayerCardKO(currentPlayerCard)) break;
          if (_checkBattleEndConditions()) break;
        }
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted || _battleOverForThisAttempt) return;

        // 2. Player's Active Card Automated Attack
        if (currentPlayerCard != null &&
            currentPlayerCard.currentHp > 0 &&
            currentBossCard != null &&
            currentBossCard.currentHp > 0) {
          _logBattle("${currentPlayerCard.name} (Auto) attacks!");
          _executeSingleAttack(
            currentPlayerCard,
            currentBossCard,
            isPlayerAttackingBoss: true,
          );
          if (_checkBattleEndConditions()) break;
        }
      }

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted || _battleOverForThisAttempt) return;

      _applyEndOfRoundEffects();
      if (_checkBattleEndConditions()) break;

      if (mounted) {
        setState(() {
          _currentRound++;
        });
      }

      if (_currentRound > _maxRoundsPerAttempt && !_battleOverForThisAttempt) {
        _logBattle("Max rounds reached for this attempt!");
        if (mounted) {
          setState(() {
            _battleOverForThisAttempt = true;
            _attemptOutcomeMessage = "Attempt ended: Max rounds reached.";
          });
        }
        break;
      }
      await Future.delayed(
        const Duration(milliseconds: 1500),
      ); // Longer delay between full rounds
    }

    if (mounted && !_battleOverForThisAttempt) {
      _logBattle("Battle sequence completed.");
      setState(() {
        _battleOverForThisAttempt = true;
        _attemptOutcomeMessage =
            _attemptOutcomeMessage ??
            "Battle ended after $_maxRoundsPerAttempt rounds.";
      });
    }
  }

  bool _checkBattleEndConditions() {
    if (!mounted) {
      return true; // If not mounted, consider battle ended for this screen
    }

    final gameState = Provider.of<GameState>(context, listen: false);
    final raidEvent = gameState.activeRaidEvents.firstWhereOrNull(
      (r) => r.id == widget.raidId,
    );

    if (raidEvent == null || _bossBattleInstance == null) {
      if (mounted) {
        setState(() {
          _battleOverForThisAttempt = true;
          _attemptOutcomeMessage =
              _attemptOutcomeMessage ?? "Raid is no longer active.";
        });
      }
      return true;
    }
    if (raidEvent.bossCard.currentHp <= 0) {
      _logBattle("${raidEvent.bossCard.name} has been defeated globally!");
      if (mounted) {
        setState(() {
          _battleOverForThisAttempt = true;
          _attemptOutcomeMessage = "Raid Boss Defeated!";
        });
      }
      return true;
    }

    if (_playerTeamCards.every((card) => card == null || card.currentHp <= 0)) {
      _logBattle("All your cards have been defeated in this attempt!");
      if (mounted) {
        setState(() {
          _playerTeamWiped = true;
          _battleOverForThisAttempt = true;
          _attemptOutcomeMessage = "Your team was wiped out in this attempt!";
        });
      }
      return true;
    }
    return false;
  }

  bool _handlePlayerCardKO(app_card.Card koCard) {
    if (koCard.currentHp <= 0) {
      _logBattle("${koCard.name} has been defeated!");
      if (_playerTeamCards.every(
        (card) => card == null || card.currentHp <= 0,
      )) {
        if (mounted) {
          setState(() {
            _playerTeamWiped = true;
            _battleOverForThisAttempt = true;
            _attemptOutcomeMessage = "Your team was wiped out!";
          });
        }
        return true;
      }
      int nextActive = _playerTeamCards.indexWhere(
        (c) => c != null && c.currentHp > 0,
      );
      if (nextActive != -1) {
        if (mounted) {
          setState(() {
            _activePlayerCardIndex = nextActive;
          });
        }
        _logBattle("Switched to ${_playerTeamCards[nextActive]!.name}.");
      } else {
        if (mounted) {
          setState(() {
            _playerTeamWiped = true;
            _battleOverForThisAttempt = true;
            _attemptOutcomeMessage = "Team wiped (fallback)!";
          });
        }
        return true;
      }
    }
    return false;
  }

  void _applyEndOfRoundEffects() {
    if (!mounted || _battleOverForThisAttempt) return;

    final activePlayerCard = _getActivePlayerCard();

    if (activePlayerCard != null &&
        activePlayerCard.currentHp > 0 &&
        activePlayerCard.maxMana > 0) {
      int manaGained =
          (GameState.MANA_GAIN_PER_ROUND *
                  (1.0 + activePlayerCard.manaRegenBonus))
              .round();
      activePlayerCard.currentMana = (activePlayerCard.currentMana + manaGained)
          .clamp(0, activePlayerCard.maxMana);
      _logBattle(
        "${activePlayerCard.name} gained $manaGained mana. Current: ${activePlayerCard.currentMana}/${activePlayerCard.maxMana}",
      );
    }
    if (_bossBattleInstance != null &&
        _bossBattleInstance!.currentHp > 0 &&
        _bossBattleInstance!.maxMana > 0) {
      int manaGained =
          (GameState.MANA_GAIN_PER_ROUND *
                  (1.0 + _bossBattleInstance!.manaRegenBonus))
              .round();
      _bossBattleInstance!.currentMana =
          (_bossBattleInstance!.currentMana + manaGained).clamp(
            0,
            _bossBattleInstance!.maxMana,
          );
      _logBattle(
        "${_bossBattleInstance!.name} gained $manaGained mana. Current: ${_bossBattleInstance!.currentMana}/${_bossBattleInstance!.maxMana}",
      );
    }

    if (activePlayerCard != null &&
        activePlayerCard.currentHp > 0 &&
        _bossBattleInstance != null &&
        _bossBattleInstance!.currentHp > 0) {
      TalentSystem.rotateYinYangBuff(activePlayerCard, _logBattle);
      TalentSystem.checkAndApplyBerserker(activePlayerCard, _logBattle);
      TalentSystem.checkAndApplyBloodSurgeLifesteal(
        activePlayerCard,
        _logBattle,
      );
      TalentSystem.checkAndApplyDominance(
        activePlayerCard,
        _bossBattleInstance!,
        _logBattle,
      );
      TalentSystem.checkAndApplyExecutioner(
        activePlayerCard,
        _bossBattleInstance!,
        _logBattle,
      );
      TalentSystem.checkAndApplyUnderdog(
        activePlayerCard,
        _bossBattleInstance!,
        _logBattle,
      );
      TalentSystem.applyRoundEndTalentEffects(
        activePlayerCard,
        _bossBattleInstance!,
        _currentRound,
        _logBattle,
      );

      TalentSystem.rotateYinYangBuff(_bossBattleInstance!, _logBattle);
      TalentSystem.checkAndApplyBerserker(_bossBattleInstance!, _logBattle);
      TalentSystem.checkAndApplyBloodSurgeLifesteal(
        _bossBattleInstance!,
        _logBattle,
      );
      TalentSystem.checkAndApplyDominance(
        _bossBattleInstance!,
        activePlayerCard,
        _logBattle,
      );
      TalentSystem.checkAndApplyExecutioner(
        _bossBattleInstance!,
        activePlayerCard,
        _logBattle,
      );
      TalentSystem.checkAndApplyUnderdog(
        _bossBattleInstance!,
        activePlayerCard,
        _logBattle,
      );
      TalentSystem.applyRoundEndTalentEffects(
        _bossBattleInstance!,
        activePlayerCard,
        _currentRound,
        _logBattle,
      );

      if (_handlePlayerCardKO(activePlayerCard)) return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _executeSingleAttack(
    app_card.Card attacker,
    app_card.Card defender, {
    required bool isPlayerAttackingBoss,
  }) {
    final gameState = Provider.of<GameState>(context, listen: false);
    if (attacker.currentHp <= 0 || defender.currentHp <= 0) return;

    if (attacker.isStunned) {
      _logBattle("${attacker.name} is Stunned and misses their turn!");
      attacker.isStunned = false;
      return;
    }
    // For auto-attacks, silence doesn't prevent them.
    // Only player-initiated special talents are blocked by silence.
    // if (attacker.isSilenced && isPlayerAttackingBoss) {
    //   _logBattle("${attacker.name} is Silenced and cannot attack!");
    //   return;
    // }

    if (defender.currentEvasionChance > 0 &&
        _random.nextDouble() < defender.currentEvasionChance) {
      _logBattle("${defender.name} EVADED ${attacker.name}'s attack!");
      return;
    }

    double baseDamage = (attacker.attack - defender.defense).toDouble();
    if (baseDamage < 1.0) baseDamage = 1.0;

    double finalDamage = baseDamage;
    String attackLog =
        "${attacker.name} (Lvl ${attacker.level}) attacks ${defender.name} (Lvl ${defender.level})";

    double typeMultiplier = ElementalSystem.getTypeEffectivenessMultiplier(
      attacker.type,
      defender.type,
    );
    if (typeMultiplier > 1.0) {
      attackLog += " (Super Effective!)";
    } else if (typeMultiplier < 1.0)
      attackLog += " (Not Very Effective...)";
    finalDamage *= typeMultiplier;

    double critChance =
        0.05 +
        (attacker.isPrecisionBuffActive
            ? attacker.precisionCritChanceBonus
            : 0.0);
    double critDamageMultiplier =
        1.5 +
        (attacker.isPrecisionBuffActive
            ? attacker.precisionCritDamageBonus
            : 0.0);
    if (_random.nextDouble() < critChance.clamp(0.0, 1.0)) {
      finalDamage *= critDamageMultiplier;
      attackLog += " (CRITICAL HIT!)";
    }

    if (defender.isEnduranceBuffActive) {
      double reduction = finalDamage * defender.enduranceDamageReductionPercent;
      finalDamage -= reduction;
      attackLog += " (Endurance reduces damage by ${reduction.round()}!)";
    }

    int damageToDeal = finalDamage.round().clamp(1, 99999);

    if (isPlayerAttackingBoss) {
      // Apply to local boss instance for simulation
      _bossBattleInstance?.takeDamage(damageToDeal);
      // Report to global boss HP
      gameState.dealDamageToRaidBoss(
        widget.raidId,
        gameState.currentPlayerId,
        damageToDeal,
      );
    } else {
      defender.takeDamage(damageToDeal);
    }
    _logBattle(
      "$attackLog for $damageToDeal damage. ${defender.name} HP: ${defender.currentHp}",
    );

    TalentSystem.activateOnDealDamageTalents(
      attacker,
      damageToDeal,
      _logBattle,
    );

    if (defender.currentHp > 0 &&
        defender.talent?.type == TalentType.REVERSION &&
        !defender.hasReversionActivatedThisBattle) {
      if (TalentSystem.checkReversionCondition(defender, _logBattle)) {
        _logBattle(
          "${defender.name}'s Reversion might trigger (logic to be fully implemented here).",
        );
        // Consider calling GameState's _executeReversionEffect or a similar local one if needed
      }
    }
    if (mounted) {
      setState(() {}); // Update UI after attack
    }
  }

  void _performPlayerSpecialAttack() {
    if (_battleOverForThisAttempt || _playerSpecialAttacksRemaining <= 0) {
      return;
    }

    final app_card.Card? attackingPlayerCard = _getActivePlayerCard();
    if (attackingPlayerCard != null &&
        attackingPlayerCard.currentHp > 0 &&
        _bossBattleInstance != null &&
        _bossBattleInstance!.currentHp > 0) {
      _logBattle(
        "${attackingPlayerCard.name} uses a Special Attack! (${_playerSpecialAttacksRemaining - 1} remaining)",
      );
      _executeSingleAttack(
        attackingPlayerCard,
        _bossBattleInstance!,
        isPlayerAttackingBoss: true,
      );

      if (mounted) {
        setState(() {
          _playerSpecialAttacksRemaining--;
        });
      }
      _checkBattleEndConditions();
    } else {
      _logBattle(
        "Cannot perform special attack: No active card or boss is KO'd.",
      );
    }
  }

  void _activatePlayerTalent() {
    if (_battleOverForThisAttempt) return;

    final app_card.Card? activePlayerCard = _getActivePlayerCard();
    if (activePlayerCard == null ||
        activePlayerCard.currentHp <= 0 ||
        _bossBattleInstance == null) {
      return;
    }
    if (activePlayerCard.talent == null) {
      _logBattle("${activePlayerCard.name} has no talent.");
      return;
    }
    if (activePlayerCard.isSilenced) {
      _logBattle("${activePlayerCard.name} is Silenced and cannot use talent!");
      return;
    }
    if (activePlayerCard.currentMana < activePlayerCard.talent!.manaCost) {
      _logBattle(
        "${activePlayerCard.name} needs ${activePlayerCard.talent!.manaCost} mana, has ${activePlayerCard.currentMana}.",
      );
      return;
    }

    activePlayerCard.currentMana -= activePlayerCard.talent!.manaCost;
    _logBattle(
      "${activePlayerCard.name} uses ${activePlayerCard.talent!.name}!",
    );

    final talentType = activePlayerCard.talent!.type;
    bool talentUsedSuccessfully = false;
    int damageDealtByTalent = 0;
    final gameState = Provider.of<GameState>(context, listen: false);

    switch (talentType) {
      case TalentType.REGENERATION:
        talentUsedSuccessfully = TalentSystem.activateRegenerationBuff(
          activePlayerCard,
          _logBattle,
        );
        break;
      case TalentType.REJUVENATION:
        talentUsedSuccessfully = TalentSystem.activateRejuvenation(
          activePlayerCard,
          _logBattle,
        );
        break;
      case TalentType.PRECISION:
        talentUsedSuccessfully = TalentSystem.activatePrecision(
          activePlayerCard,
          _logBattle,
        );
        break;
      case TalentType.BLAZE:
        talentUsedSuccessfully = TalentSystem.activateBlaze(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        break;
      case TalentType.TIME_BOMB:
        talentUsedSuccessfully = TalentSystem.activateTimeBomb(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        break;
      case TalentType.TIME_ATTACK:
        damageDealtByTalent = TalentSystem.activateTimeAttack(
          activePlayerCard,
          _bossBattleInstance!,
          _currentRound,
          _logBattle,
        );
        talentUsedSuccessfully = damageDealtByTalent >= 0;
        break;
      case TalentType.AMPLIFIER:
        talentUsedSuccessfully = TalentSystem.activateAmplifier(
          activePlayerCard,
          _logBattle,
        );
        break;
      case TalentType.BALANCING_STRIKE:
        damageDealtByTalent = TalentSystem.activateBalancingStrike(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        talentUsedSuccessfully = damageDealtByTalent >= 0;
        break;
      case TalentType.BREAKER_ATK:
        talentUsedSuccessfully = TalentSystem.activateBreakerAtk(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        break;
      case TalentType.BREAKER_DEF:
        talentUsedSuccessfully = TalentSystem.activateBreakerDef(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        break;
      case TalentType.DEXTERITY_DRIVE:
        damageDealtByTalent = TalentSystem.activateDexterityDrive(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        talentUsedSuccessfully = damageDealtByTalent >= 0;
        break;
      case TalentType.DOUBLE_EDGED_STRIKE:
        damageDealtByTalent = TalentSystem.activateDoubleEdgedStrike(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        talentUsedSuccessfully = damageDealtByTalent >= 0;
        break;
      case TalentType.ELEMENTAL_STRIKE:
        damageDealtByTalent = TalentSystem.activateElementalStrike(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        talentUsedSuccessfully = damageDealtByTalent >= 0;
        break;
      case TalentType.ENDURANCE:
        talentUsedSuccessfully = TalentSystem.activateEndurance(
          activePlayerCard,
          _logBattle,
        );
        break;
      case TalentType.EVASION:
        talentUsedSuccessfully = TalentSystem.activateEvasion(
          activePlayerCard,
          _logBattle,
        );
        break;
      case TalentType.FREEZE:
        talentUsedSuccessfully = TalentSystem.activateFreeze(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        break;
      case TalentType.LUCKY_COIN:
        talentUsedSuccessfully = TalentSystem.activateLuckyCoin(
          activePlayerCard,
          _logBattle,
        );
        break;
      case TalentType.MANA_REAVER:
        damageDealtByTalent = TalentSystem.activateManaReaver(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        talentUsedSuccessfully = damageDealtByTalent >= 0;
        break;
      case TalentType.OFFENSIVE_STANCE:
        talentUsedSuccessfully = TalentSystem.activateOffensiveStance(
          activePlayerCard,
          _logBattle,
        );
        break;
      case TalentType.PARALYSIS:
        talentUsedSuccessfully = TalentSystem.activateParalysis(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        break;
      case TalentType.PAIN_FOR_POWER:
        talentUsedSuccessfully = TalentSystem.activatePainForPower(
          activePlayerCard,
          _logBattle,
        );
        break;
      case TalentType.POISON:
        talentUsedSuccessfully = TalentSystem.activatePoison(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        break;
      case TalentType.RESTRICTED_INSTINCT:
        talentUsedSuccessfully = TalentSystem.activateRestrictedInstinct(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        break;
      case TalentType.TRICK_ROOM_ATK:
        damageDealtByTalent = TalentSystem.activateTrickRoomAtk(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        talentUsedSuccessfully = damageDealtByTalent >= 0;
        break;
      case TalentType.TRICK_ROOM_DEF:
        talentUsedSuccessfully = TalentSystem.activateTrickRoomDef(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        break;
      case TalentType.ULTIMATE_COMBO:
        damageDealtByTalent = TalentSystem.activateUltimateCombo(
          activePlayerCard,
          _bossBattleInstance!,
          _playerTeamCards.whereNotNull().toList(),
          _logBattle,
        );
        talentUsedSuccessfully = damageDealtByTalent >= 0;
        break;
      case TalentType.VENGEANCE:
        damageDealtByTalent = TalentSystem.activateVengeance(
          activePlayerCard,
          _bossBattleInstance!,
          _logBattle,
        );
        talentUsedSuccessfully = damageDealtByTalent >= 0;
        break;
      case TalentType.TEMPORAL_REWIND:
        talentUsedSuccessfully = TalentSystem.activateTemporalRewind(
          activePlayerCard,
          _logBattle,
        );
        break;
      default:
        _logBattle(
          "Talent ${activePlayerCard.talent!.name} has no specific activation logic in RaidBattleScreen yet.",
        );
        talentUsedSuccessfully = false;
    }

    if (damageDealtByTalent > 0) {
      gameState.dealDamageToRaidBoss(
        widget.raidId,
        gameState.currentPlayerId,
        damageDealtByTalent,
      );
    }

    if (!talentUsedSuccessfully) {
      activePlayerCard.currentMana += activePlayerCard.talent!.manaCost;
      _logBattle(
        "Talent activation for ${activePlayerCard.talent!.name} was not fully successful, mana refunded.",
      );
    }

    if (mounted) {
      setState(() {}); // Update UI after talent use
    }
    _checkBattleEndConditions(); // Check if talent ended the battle
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final RaidEvent? raidEvent = gameState.activeRaidEvents.firstWhereOrNull(
      (r) => r.id == widget.raidId,
    );

    if (raidEvent == null ||
        _bossBattleInstance == null ||
        (raidEvent.status != RaidEventStatus.battleInProgress &&
            raidEvent.status != RaidEventStatus.lobbyOpen) ||
        (_playerTeamCards.every((card) => card == null) &&
            raidEvent.status == RaidEventStatus.battleInProgress)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Raid battle is no longer active.")),
            );
          } else {
            // ignore: avoid_print
            print(
              "RaidBattleScreen: Raid ended but cannot pop. Screen might have already been removed or is top-level.",
            );
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/event_screen', (route) => false);
          }
        }
      });
      return ThemedScaffold(
        appBar: AppBar(title: const Text("Battle Ended")),
        body: const Center(
          child: Text("This raid battle has concluded or is not available."),
        ),
      );
    }

    final app_card.Card globalBossState = raidEvent.bossCard;
    final app_card.Card localBossDisplay = _bossBattleInstance!;
    final app_card.Card? activePlayerCard = _getActivePlayerCard();

    return ThemedScaffold(
      appBar: AppBar(title: Text("Raid Battle: ${globalBossState.name}")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Round: $_currentRound / $_maxRoundsPerAttempt",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                "Boss: ${localBossDisplay.name}",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              FramedCardImageWidget(
                card: localBossDisplay,
                width: 120,
                height: 180,
              ),
              Text(
                "HP: ${globalBossState.currentHp} / ${globalBossState.maxHp}",
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                "ATK: ${localBossDisplay.attack} DEF: ${localBossDisplay.defense} SPD: ${localBossDisplay.speed}",
                style: const TextStyle(fontSize: 12),
              ),
              if (localBossDisplay.maxMana > 0)
                Text(
                  "Mana: ${localBossDisplay.currentMana}/${localBossDisplay.maxMana}",
                  style: const TextStyle(fontSize: 12),
                ),
              Text(
                "Time Remaining: ${_formatDuration(raidEvent.battleTimeRemaining)}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              const Divider(),
              Text(
                "Your Team:",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  final playerCard = _playerTeamCards[index];
                  if (playerCard == null) {
                    return const SizedBox(
                      width: 100,
                      child: Center(child: Text("Empty Slot")),
                    );
                  }
                  bool isActive =
                      index == _activePlayerCardIndex &&
                      playerCard.currentHp > 0;
                  return GestureDetector(
                    onTap: playerCard.currentHp > 0
                        ? () => setState(() => _activePlayerCardIndex = index)
                        : null,
                    child: Opacity(
                      opacity: playerCard.currentHp > 0 ? 1.0 : 0.5,
                      child: Column(
                        children: [
                          FramedCardImageWidget(
                            card: playerCard,
                            width: 80,
                            height: 120,
                            frameColorOverride: isActive
                                ? Colors.greenAccent.withOpacity(0.7)
                                : null,
                          ),
                          Text(
                            playerCard.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "HP: ${playerCard.currentHp}/${playerCard.maxHp}",
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            "ATK: ${playerCard.attack} DEF: ${playerCard.defense} SPD: ${playerCard.speed}",
                            style: const TextStyle(fontSize: 10),
                          ),
                          if (playerCard.maxMana > 0)
                            Text(
                              "Mana: ${playerCard.currentMana}/${playerCard.maxMana}",
                              style: const TextStyle(fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              if (!_battleOverForThisAttempt &&
                  raidEvent.status == RaidEventStatus.battleInProgress) ...[
                if (activePlayerCard != null &&
                    activePlayerCard.currentHp > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on),
                        label: Text(
                          "Special Attack ($_playerSpecialAttacksRemaining left)",
                        ),
                        onPressed: (_playerSpecialAttacksRemaining > 0)
                            ? _performPlayerSpecialAttack
                            : null,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.star),
                        label: Text(
                          activePlayerCard.talent?.name ?? "No Talent",
                        ),
                        onPressed:
                            (activePlayerCard.talent != null &&
                                !activePlayerCard.isSilenced &&
                                activePlayerCard.currentMana >=
                                    activePlayerCard.talent!.manaCost)
                            ? _activatePlayerTalent
                            : null,
                      ),
                    ],
                  ),
                ] else if (activePlayerCard == null ||
                    activePlayerCard.currentHp <= 0) ...[
                  const Text(
                    "All your active cards are KO'd for this attempt.",
                  ),
                ],
                const SizedBox(height: 10),
                const Text(
                  "Battle in Progress...",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ] else if (_attemptOutcomeMessage != null) ...[
                Text(
                  _attemptOutcomeMessage!,
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text("Back to Lobby"),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/event_screen',
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
              const SizedBox(height: 20),
              Text(
                "Battle Log:",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.black.withOpacity(0.1),
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: _battleLog.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    child: Text(
                      _battleLog[index],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
