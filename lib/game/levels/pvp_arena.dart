import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/manga_effects.dart';
import '../components/platform.dart';
import '../components/remote_player.dart';
import '../manga_game.dart';
import '../services/audio_service.dart';
import '../services/lan_multiplayer_service.dart';

class PvPArenaLevel extends Component with HasGameReference<MangaGame> {
  static const double arenaWidth = 1200.0;
  static const double arenaHeight = 600.0;

  // Base platform coordinates
  static const double platformX = 240.0;
  static const double platformY = 440.0;
  static const double platformWidth = 720.0;
  static const double platformHeight = 55.0;

  static const double voidDeathY = 560.0;

  final Map<String, RemotePlayer> remotePlayers = {};
  final List<ComicPlatform> arenaPlatforms = [];
  bool localPlayerEliminated = false;
  late final int stageIndex;
  double? _remainingTime;
  bool _timeUpTriggered = false;

  PvPArenaLevel() {
    final net = LanMultiplayerService.instance;
    stageIndex = net.matchConfig.stageIndex.clamp(0, kPvpStages.length - 1);
    final players = net.roomPlayers.values.toList();
    final total = max(2, players.length);
    final maxHp = net.configuredMaxHp;
    final maxLives = net.configuredLives;

    for (final p in players) {
      if (p.id != net.myPlayerId) {
        final spawnPos = getSpawnPosition(p.slot, total, stageIndex: stageIndex);
        final facing = p.slot < (total / 2) ? 1 : -1;
        final remote = RemotePlayer(
          id: p.id,
          position: spawnPos,
          nickname: p.nickname,
          playerColor: p.color,
          colorIndex: p.colorIndex,
          slot: p.slot,
          initialHp: maxHp,
          initialLives: maxLives,
        )..facingDirection = facing;
        remotePlayers[p.id] = remote;
      }
    }
  }

  static double getSpawnX(int slot, int totalPlayers) {
    if (totalPlayers <= 1) return platformX + platformWidth * 0.5;
    final usableWidth = platformWidth - 160.0;
    final step = usableWidth / (max(2, totalPlayers) - 1);
    return platformX + 80.0 + (slot.clamp(0, totalPlayers - 1)) * step;
  }

  static Vector2 getSpawnPosition(
    int slot,
    int totalPlayers, {
    int stageIndex = 0,
  }) {
    if (stageIndex == 2) {
      // Twin Islands + Center Bridge + High Ledges (avoid central pit at x=530..670)
      const islandSpawns = < List<double> >[
        [310.0, 448.0],
        [890.0, 448.0],
        [600.0, 342.0],
        [305.0, 240.0],
        [895.0, 240.0],
      ];
      final pair = islandSpawns[slot.clamp(0, islandSpawns.length - 1)];
      return Vector2(pair[0], pair[1]);
    }
    final baseY = stageIndex == 1 ? 450.0 : platformY;
    return Vector2(getSpawnX(slot, totalPlayers), baseY);
  }

  Vector2 getSafeRespawnPoint() {
    final net = LanMultiplayerService.instance;
    final total = max(2, net.roomPlayers.length);
    final groundPos =
        getSpawnPosition(net.mySlot, total, stageIndex: stageIndex);
    return Vector2(groundPos.x, groundPos.y - 75.0);
  }

  void spawnRingOutBlast(double x, Color blastColor) {
    final clampedX = x.clamp(90.0, arenaWidth - 90.0);
    game.world.add(SmashRingOutBlastEffect(
      position: Vector2(clampedX, 540.0),
      playerColor: blastColor,
      arenaCenterX: arenaWidth * 0.5,
    ));
    game.camera.viewfinder.position += Vector2(0, -14);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final net = LanMultiplayerService.instance;
    final stageInfo = kPvpStages[stageIndex];

    // 1. Illustrated Panoramic Arena Background (Per Selected Stage)
    add(SpriteComponent(
      sprite: await game.loadSprite(stageInfo.flameBgAsset),
      size: Vector2(arenaWidth, arenaHeight),
      position: Vector2.zero(),
      priority: 10,
    ));

    // 2. Stage-Specific Floating Platforms Layout
    arenaPlatforms.clear();
    void addArenaPlatform(Vector2 pos, Vector2 sz) {
      final plat = ComicPlatform(position: pos, size: sz);
      arenaPlatforms.add(plat);
      add(plat);
    }

    if (stageIndex == 0) {
      // Stage 0 (Original Base): Single Central Floating Stone Platform
      addArenaPlatform(
        Vector2(platformX, platformY),
        Vector2(platformWidth, platformHeight),
      );
    } else if (stageIndex == 1) {
      // Stage 1 (Azoteas Neo-Tokyo): Tri-Platform Battlefield Layout
      addArenaPlatform(Vector2(220, 450), Vector2(760, 52));
      addArenaPlatform(Vector2(265, 336), Vector2(195, 24));
      addArenaPlatform(Vector2(740, 336), Vector2(195, 24));
      addArenaPlatform(Vector2(490, 226), Vector2(220, 24));
    } else {
      // Stage 2 (Fortaleza Carmesí): Twin Floating Islands + High Ledges
      addArenaPlatform(Vector2(170, 448), Vector2(360, 50));
      addArenaPlatform(Vector2(670, 448), Vector2(360, 50));
      addArenaPlatform(Vector2(480, 342), Vector2(240, 24));
      addArenaPlatform(Vector2(220, 240), Vector2(170, 24));
      addArenaPlatform(Vector2(810, 240), Vector2(170, 24));
    }

    // 3. Setup Local Player on platform based on assigned slot & full match stats
    final total = max(2, net.roomPlayers.length);
    final localSpawn =
        getSpawnPosition(net.mySlot, total, stageIndex: stageIndex);
    final localFacing = net.mySlot < (total / 2) ? 1 : -1;

    game.player.resetForMatch(
      maxHealth: net.configuredMaxHpInt,
      lives: net.configuredLives,
    );
    game.player.position = localSpawn.clone();
    game.player.facingDirection = localFacing;
    game.player.isOnGround = true;

    final timeLimit = net.matchConfig.timeLimitSeconds;
    if (timeLimit > 0) {
      _remainingTime = timeLimit.toDouble();
      net.remainingSecondsNotifier.value = timeLimit;
    } else {
      _remainingTime = null;
      net.remainingSecondsNotifier.value = null;
    }

    // 4. Add all Remote Opponents directly into game.world for identical camera & render pipeline
    for (final remote in remotePlayers.values) {
      if (!game.world.children.contains(remote)) {
        await game.world.add(remote);
      }
    }

    // Initial Battle Cry Effect
    final battleText = total > 2
        ? 'BATTLE ROYALE • $total SHINOBIS!!'
        : 'SHINOBI DUEL • FIGHT!!';
    add(MangaTextEffect(
      position: Vector2(arenaWidth / 2, 280),
      text: battleText,
      fillColor: Colors.amberAccent,
      targetScale: 2.2,
      maxLifetime: 1.8,
    ));
    AudioService.playSfx(AudioService.sfxBossRoar);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final net = LanMultiplayerService.instance;
    if (net.victoryCelebrationNotifier.value != null ||
        net.resultsPodiumNotifier.value != null) {
      return;
    }

    // Update Battle Countdown Timer if enabled
    if (_remainingTime != null && !_timeUpTriggered) {
      _remainingTime = (_remainingTime! - dt).clamp(0.0, 99999.0);
      final ceilSec = _remainingTime!.ceil();
      if (net.remainingSecondsNotifier.value != ceilSec) {
        net.remainingSecondsNotifier.value = ceilSec;
      }
      if (_remainingTime! <= 0) {
        _timeUpTriggered = true;
        game.add(MangaTextEffect(
          position: Vector2(arenaWidth / 2, 250),
          text: '¡TIEMPO AGOTADO!',
          fillColor: Colors.amberAccent,
          targetScale: 2.3,
          maxLifetime: 2.0,
        ));
        AudioService.playSfx(AudioService.sfxBossRoar);
        if (net.role == MatchRole.host) {
          net.hostTriggerTimeUp();
        }
        return;
      }
    }

    if (localPlayerEliminated) {
      return;
    }

    final player = game.player;

    // Anti-tunneling platform floor clamp: prevents players from ever clipping through
    // arena platforms on initial spawn, respawn landing, or frame hitches.
    if (!player.isDying && player.velocity.y >= 0) {
      for (final plat in arenaPlatforms) {
        final left = plat.position.x - 10.0;
        final right = plat.position.x + plat.size.x + 10.0;
        final top = plat.position.y;
        final maxDepth = (plat.size.y * 0.85).clamp(24.0, 48.0);
        if (player.position.x >= left &&
            player.position.x <= right &&
            player.position.y >= top - 2.0 &&
            player.position.y <= top + maxDepth) {
          player.position.y = top;
          player.velocity.y = 0;
          player.isOnGround = true;
          player.isTouchingWall = false;
          break;
        }
      }
    }

    // Fall to Void / Ring Out detection for Local Player
    if (player.position.y > voidDeathY) {
      final blastX = player.position.x.clamp(90.0, arenaWidth - 90.0);
      spawnRingOutBlast(blastX, net.myColor);
      net.sendRingOutBlast(x: blastX, colorIndex: net.myColorIndex);

      AudioService.playSfx(AudioService.sfxPlayerDeath);
      AudioService.heavyHaptic();

      game.add(MangaTextEffect(
        position: Vector2(
          blastX.clamp(220.0, arenaWidth - 220.0),
          360,
        ),
        text: 'RING OUT!!',
        fillColor: Colors.redAccent,
        targetScale: 2.4,
      ));

      final eliminated =
          player.consumeMultiplayerLifeOrEliminate(isRingOut: true);
      if (eliminated) {
        localPlayerEliminated = true;
      }
    }
  }

  @override
  void onRemove() {
    for (final remote in remotePlayers.values) {
      if (remote.isMounted) {
        remote.removeFromParent();
      }
    }
    super.onRemove();
  }
}
