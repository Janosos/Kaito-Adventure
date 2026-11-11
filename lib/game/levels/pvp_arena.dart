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

  // Floating platform coordinates
  static const double platformX = 240.0;
  static const double platformY = 440.0;
  static const double platformWidth = 720.0;
  static const double platformHeight = 55.0;

  static const double voidDeathY = 560.0;

  late final RemotePlayer remotePlayer;
  bool matchEnded = false;

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

    // 3. Spawn Local Player on the platform
    final isHost = LanMultiplayerService.instance.role == MatchRole.host;
    final localSpawnX = isHost ? platformX + 120.0 : platformX + platformWidth - 120.0;
    final remoteSpawnX = isHost ? platformX + platformWidth - 120.0 : platformX + 120.0;

    game.player.position = Vector2(localSpawnX, platformY - 50.0);
    game.player.velocity = Vector2.zero();
    game.player.facingDirection = isHost ? 1 : -1;
    game.player.hp = 100;
    game.player.maxHp = 100;
    game.player.spirit = 0.0;

    // 4. Spawn Remote Opponent on opposite side of the platform
    remotePlayer = RemotePlayer(
      position: Vector2(remoteSpawnX, platformY),
      nickname: LanMultiplayerService.instance.opponentNickname,
      playerColor: LanMultiplayerService.instance.opponentColor,
    );
    remotePlayer.facingDirection = isHost ? -1 : 1;
    add(remotePlayer);

    // Initial Battle Cry Effect
    add(MangaTextEffect(
      position: Vector2(arenaWidth / 2, 280),
      text: 'SHINOBI DUEL • FIGHT!!',
      fillColor: Colors.amberAccent,
      targetScale: 2.2,
      maxLifetime: 1.8,
    ));
    AudioService.playSfx(AudioService.sfxBossRoar);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (matchEnded) return;

    final player = game.player;

    // Fall to Void / Ring Out detection for Local Player
    if (player.position.y > voidDeathY) {
      matchEnded = true;
      AudioService.playSfx(AudioService.sfxPlayerDeath);
      game.add(MangaTextEffect(
        position: Vector2(player.position.x, 380),
        text: 'RING OUT!!',
        fillColor: Colors.redAccent,
        targetScale: 2.4,
      ));
      LanMultiplayerService.instance.sendRingOut(
        defeatedNickname: LanMultiplayerService.instance.myNickname,
      );
      game.onMultiplayerMatchOver(
        winnerName: LanMultiplayerService.instance.opponentNickname,
        didLocalWin: false,
      );
    }
  }
}

