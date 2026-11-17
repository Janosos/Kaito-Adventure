import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../components/platform.dart';
import '../components/traps.dart';
import '../components/collectibles.dart';
import '../components/enemies/enemy_grunt.dart';
import '../components/enemies/enemy_drone.dart';
import '../components/enemies/enemy_oni_archer.dart';
import '../components/enemies/enemy_samurai_shield.dart';
import '../components/enemies/enemy_karakuri_automaton.dart';
import '../components/bosses/boss_wadatsumi.dart';
import 'level_one.dart';

class LevelEight extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 380);
  static const double levelWidth = 6840.0;
  static const double bossArenaTriggerX = 5820.0;
  static const double arenaCenterX = 6310.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Abyssal Kraken Shipwreck Sea Backdrop
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level8_abyss.png',
      tintColor: const Color(0x24021E2A),
    ));

    // =========================================================================
    // ZONE 1: Shattered Galleon Decks & Tidal Geysers (x: 0 .. 1250)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(0, 390),
      size: Vector2(360, 150),
    ));
    add(BreakableCrate(position: Vector2(165, 390)));
    add(EnemySamuraiShield(
      position: Vector2(265, 390),
      minXBound: 170,
      maxXBound: 340,
      maxHp: 95,
    ));

    add(ComicPlatform(
      position: Vector2(420, 360),
      size: Vector2(140, 24),
      isMoving: true,
      moveRange: Vector2(0, -80),
      moveSpeed: 2.2,
    ));
    add(MagmaGeyserVent(
      position: Vector2(610, 520),
      geyserHeight: 205,
      cyclePeriod: 2.5,
      activeDuration: 1.0,
    ));

    add(ComicPlatform(
      position: Vector2(680, 280),
      size: Vector2(320, 28),
      isSlipperyIce: true,
    ));
    add(EnemyOniArcher(position: Vector2(840, 280)));
    add(InkScroll(position: Vector2(760, 230))); // Scroll #1

    add(ComicPlatform(
      position: Vector2(1045, 375),
      size: Vector2(220, 50),
    ));
    add(CheckpointLantern(position: Vector2(1155, 375)));

    // =========================================================================
    // ZONE 2: Maelstrom Wind Squalls & Sunken Hull Gauntlet (x: 1300 .. 2640)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(1310, 455),
      size: Vector2(560, 65),
    ));
    add(BlizzardWindZone(
      position: Vector2(1360, 235),
      size: Vector2(480, 220),
      windSpeedX: -120.0,
    ));
    add(EnemyKarakuriAutomaton(
      position: Vector2(1540, 455),
      minXBound: 1380,
      maxXBound: 1720,
      maxHp: 85,
    ));
    add(InkSawBlade(
      position: Vector2(1740, 410),
      patrolOffset: Vector2(85, 0),
      patrolSpeed: 2.9,
    ));

    add(MangaSpringPad(position: Vector2(1820, 455), launchPower: 635));
    add(ComicPlatform(
      position: Vector2(1910, 250),
      size: Vector2(260, 26),
    ));
    add(InkScroll(position: Vector2(2020, 200))); // Scroll #2
    add(BreakableCrate(position: Vector2(2100, 250), dropsRamen: true));

    add(ComicPlatform(
      position: Vector2(2230, 340),
      size: Vector2(135, 24),
      isMoving: true,
      moveRange: Vector2(115, 0),
      moveSpeed: 2.4,
    ));
    add(ComicPlatform(
      position: Vector2(2460, 370),
      size: Vector2(220, 50),
    ));
    add(CheckpointLantern(position: Vector2(2570, 370)));

    // =========================================================================
    // ZONE 3: Shipwreck Rigging Ziplines & Abyssal Flyers (x: 2700 .. 3980)
    // =========================================================================
    add(ZipLineLanternRail(
      startX: 2650,
      endX: 3280,
      railY: 210,
      glideSpeed: 410.0,
    ));
    add(EnemyDrone(
      position: Vector2(2900, 200),
      flyRange: 115,
      flySpeed: 2.1,
    ));
    add(EnemyDrone(
      position: Vector2(3140, 185),
      flyRange: 115,
      flySpeed: 2.2,
    ));
    add(InkScroll(position: Vector2(3010, 155))); // Scroll #3

    add(ComicPlatform(
      position: Vector2(3310, 365),
      size: Vector2(640, 65),
      isSlipperyIce: true,
    ));
    add(EnemySamuraiShield(
      position: Vector2(3510, 365),
      minXBound: 3360,
      maxXBound: 3660,
      maxHp: 100,
    ));
    add(EnemyOniArcher(position: Vector2(3760, 365)));
    add(RamenBowl(position: Vector2(3840, 320)));
    add(CheckpointLantern(position: Vector2(3900, 365)));

    // =========================================================================
    // ZONE 4: Whirlpool Geyser Trench & Taiko Drums (x: 4020 .. 4940)
    // =========================================================================
    add(TaikoBounceDrum(position: Vector2(4050, 345)));
    add(MagmaGeyserVent(
      position: Vector2(4170, 520),
      geyserHeight: 215,
      cyclePeriod: 2.3,
      activeDuration: 1.0,
    ));
    add(ComicPlatform(
      position: Vector2(4240, 265),
      size: Vector2(115, 24),
      isCrumbling: true,
    ));
    add(TaikoBounceDrum(position: Vector2(4420, 320)));
    add(InkScroll(position: Vector2(4420, 175))); // Scroll #4

    add(ComicPlatform(
      position: Vector2(4520, 260),
      size: Vector2(115, 24),
      isCrumbling: true,
    ));
    add(ComicPlatform(
      position: Vector2(4690, 360),
      size: Vector2(260, 55),
    ));
    add(EnemyKarakuriAutomaton(
      position: Vector2(4810, 360),
      minXBound: 4710,
      maxXBound: 4920,
      maxHp: 90,
    ));

    // =========================================================================
    // ZONE 5: Leviathan's Dreadnought Bridge (x: 4980 .. 5820)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(4990, 450),
      size: Vector2(820, 65),
    ));
    add(InkSawBlade(
      position: Vector2(5120, 405),
      patrolOffset: Vector2(100, 0),
      patrolSpeed: 3.0,
    ));
    add(EnemySamuraiShield(
      position: Vector2(5340, 450),
      minXBound: 5230,
      maxXBound: 5470,
      maxHp: 105,
    ));
    add(EnemyGrunt(
      position: Vector2(5530, 450),
      minXBound: 5450,
      maxXBound: 5640,
      maxHp: 75,
    ));
    add(InkScroll(position: Vector2(5420, 360))); // Scroll #5
    add(RamenBowl(position: Vector2(5660, 405)));
    add(CheckpointLantern(position: Vector2(5715, 450)));

    add(ToriiGateExit(
      position: Vector2(5775, 450),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 6: Abyssal Leviathan Boss Arena (x: 5830 .. 6800)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(5830, 485),
      size: Vector2(950, 60),
    ));
    add(ComicPlatform(
      position: Vector2(5960, 355),
      size: Vector2(145, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6460, 355),
      size: Vector2(145, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6210, 245),
      size: Vector2(145, 22),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_bossSpawned && game.player.position.x >= bossArenaTriggerX) {
      _enterBossArena();
    }
  }

  void _enterBossArena() {
    if (_bossSpawned) return;
    _bossSpawned = true;

    if (game.player.position.x < 5890) {
      game.player.position = Vector2(5910, 460);
    }
    game.currentSpawnPoint = Vector2(5910, 460);
    game.lockToBossArena(minX: 5860, maxX: 6730);

    add(BossWadatsumi(
      position: Vector2(6510, 485),
      arenaMinX: 5870,
      arenaMaxX: 6710,
    ));

    game.triggerBossCutIn(
      bossName: 'WADATSUMI',
      quote:
          'THE ABYSSAL MAELSTROM DEVOURS ALL! DROWN Beneath MY TIDAL FURY!!',
      portraitColor: const Color(0xFF00E5FF),
      portraitAsset: CartoonAssets.portraitWadatsumi,
    );
  }
}
