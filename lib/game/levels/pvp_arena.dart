import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../components/manga_effects.dart';
import '../components/platform.dart';
import '../components/player.dart';
import '../components/remote_player.dart';
import '../manga_game.dart';
import '../services/audio_service.dart';
import '../services/lan_multiplayer_service.dart';

class PvPArenaLevel extends Component with HasGameReference<MangaGame> {
  static const double arenaWidth = 1200.0;
  static const double arenaHeight = 600.0;

  // Floating platform coordinates
  static const double platformX = 240.0;
  static const double platformY = 440.0;
  static const double platformWidth = 720.0;
  static const double platformHeight = 55.0;

  static const double voidDeathY = 560.0;

  final Map<String, RemotePlayer> remotePlayers = {};
  bool localPlayerEliminated = false;

  PvPArenaLevel() {
    final net = LanMultiplayerService.instance;
    final players = net.roomPlayers.values.toList();
    final total = max(2, players.length);

    for (final p in players) {
      if (p.id != net.myPlayerId) {
        final spawnX = getSpawnX(p.slot, total);
        final facing = p.slot < (total / 2) ? 1 : -1;
        final remote = RemotePlayer(
          id: p.id,
          position: Vector2(spawnX, platformY),
          nickname: p.nickname,
          playerColor: p.color,
          slot: p.slot,
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

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Illustrated Panoramic Arena Background
    add(SpriteComponent(
      sprite: await game.loadSprite('illustrations/bg_level5_sanctum.png'),
      size: Vector2(arenaWidth, arenaHeight),
      position: Vector2.zero(),
      priority: 10,
    ));

    // 2. Central Floating Stone Platform (Safe Zone)
    add(ComicPlatform(
      position: Vector2(platformX, platformY),
      size: Vector2(platformWidth, platformHeight),
    ));

    // 3. Setup Local Player on platform based on assigned slot
    final net = LanMultiplayerService.instance;
    final total = max(2, net.roomPlayers.length);
    final localSpawnX = getSpawnX(net.mySlot, total);
    final localFacing = net.mySlot < (total / 2) ? 1 : -1;

    game.player.position = Vector2(localSpawnX, platformY);
    game.player.velocity = Vector2.zero();
    game.player.facingDirection = localFacing;
    game.player.hp = 100;
    game.player.maxHp = 100;
    game.player.spirit = 0.0;
    game.player.isOnGround = true;
    game.player.isDying = false;
    game.player.action = PlayerAction.idle;
    game.player.touchMoveInput = 0.0;
    game.player.keyboardMoveInput = 0.0;

    // 4. Add all Remote Opponents into the arena
    for (final remote in remotePlayers.values) {
      add(remote);
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
    if (localPlayerEliminated) return;

    final player = game.player;

    // Fall to Void / Ring Out detection for Local Player
    if (player.position.y > voidDeathY) {
      localPlayerEliminated = true;
      player.isDying = true;
      AudioService.playSfx(AudioService.sfxPlayerDeath);

      game.add(MangaTextEffect(
        position: Vector2(
          player.position.x.clamp(platformX, platformX + platformWidth),
          380,
        ),
        text: 'RING OUT!!',
        fillColor: Colors.redAccent,
        targetScale: 2.4,
      ));

      LanMultiplayerService.instance.sendLocalPlayerEliminated();
      game.onLocalPlayerEliminated();
    }
  }
}
