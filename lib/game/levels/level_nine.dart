import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../components/platform.dart';
import '../components/traps.dart';
import '../components/collectibles.dart';
import '../components/enemies/enemy_drone.dart';
import '../components/enemies/enemy_oni_archer.dart';
import '../components/enemies/enemy_samurai_shield.dart';
import '../components/enemies/enemy_kitsune_mage.dart';
import '../components/enemies/enemy_karakuri_automaton.dart';
import '../components/bosses/boss_raijin_tei.dart';
import 'level_one.dart';

class LevelNine extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 380);
  static const double levelWidth = 6980.0;
  static const double bossArenaTriggerX = 5960.0;
  static const double arenaCenterX = 6450.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Thunderstorm Sky Pagoda Backdrop
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level9_raijin.png',
      tintColor: const Color(0x24140A30),
    ));

    // =========================================================================
    // ZONE 1: Floating Cloud Shrine & Thunder Drums (x: 0 .. 1280)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(0, 390),
      size: Vector2(360, 150),
    ));
    add(BreakableCrate(position: Vector2(165, 390)));
    add(EnemySamuraiShield(
      position: Vector2(265, 390),
      minXBound: 175,
      maxXBound: 340,
      maxHp: 100,
    ));

    add(TaikoBounceDrum(position: Vector2(430, 360)));
    add(ComicPlatform(
      position: Vector2(510, 260),
      size: Vector2(240, 26),
    ));
    add(EnemyKitsuneMage(
      position: Vector2(640, 260),
      patrolRange: 95,
      maxHp: 85,
    ));
    add(InkScroll(position: Vector2(630, 210))); // Scroll #1

    add(TaikoBounceDrum(position: Vector2(815, 280)));
    add(ComicPlatform(
      position: Vector2(900, 355),
      size: Vector2(340, 55),
    ));
    add(EnemyKarakuriAutomaton(
      position: Vector2(1060, 355),
      minXBound: 930,
      maxXBound: 1190,
      maxHp: 90,
    ));
    add(CheckpointLantern(position: Vector2(1195, 355)));

    // =========================================================================
    // ZONE 2: Gale-Force Lightning Bridge & Warp Sanctum (x: 1320 .. 2720)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(1330, 455),
      size: Vector2(580, 65),
    ));
    add(BlizzardWindZone(
      position: Vector2(1380, 225),
      size: Vector2(500, 230),
      windSpeedX: -135.0,
    ));
    add(InkSawBlade(
      position: Vector2(1540, 410),
      patrolOffset: Vector2(100, 0),
      patrolSpeed: 3.1,
    ));
    add(EnemyOniArcher(position: Vector2(1740, 455)));

    // High Cloud Vault unlocked via Warp Portal
    add(ComicPlatform(
      position: Vector2(1440, 200),
      size: Vector2(380, 24),
    ));
    add(InkScroll(position: Vector2(1540, 150))); // Scroll #2
    add(RamenBowl(position: Vector2(1630, 155)));

    final stormGate = GateBarrier(
      position: Vector2(1865, 455),
      size: Vector2(28, 130),
    );
    add(stormGate);
    add(SwitchOrb(
      position: Vector2(1760, 200),
      targetGate: stormGate,
    ));
    add(EclipseWarpPortal(
      position: Vector2(1390, 455),
      targetDestination: Vector2(1480, 190),
      portalColor: const Color(0xFFFFD600),
    ));

    add(ComicPlatform(
      position: Vector2(1960, 370),
      size: Vector2(135, 24),
      isMoving: true,
      moveRange: Vector2(120, -70),
      moveSpeed: 2.5,
    ));
    add(ComicPlatform(
      position: Vector2(2230, 290),
      size: Vector2(135, 24),
      isMoving: true,
      moveRange: Vector2(0, 90),
      moveSpeed: 2.6,
    ));
    add(ComicPlatform(
      position: Vector2(2440, 365),
      size: Vector2(260, 55),
    ));
    add(CheckpointLantern(position: Vector2(2610, 365)));

    // =========================================================================
    // ZONE 3: High-Altitude Raijin Taiko Chain & Zipline (x: 2760 .. 4120)
    // =========================================================================
    add(TaikoBounceDrum(position: Vector2(2790, 340)));
    add(TaikoBounceDrum(position: Vector2(2960, 270)));
    add(InkScroll(position: Vector2(2960, 140))); // Scroll #3

    add(ZipLineLanternRail(
      startX: 3060,
      endX: 3680,
      railY: 195,
      glideSpeed: 425.0,
    ));
    add(EnemyDrone(
      position: Vector2(3280, 190),
      flyRange: 120,
      flySpeed: 2.2,
    ));
    add(EnemyKitsuneMage(
      position: Vector2(3510, 240),
      patrolRange: 110,
      maxHp: 90,
    ));

    add(ComicPlatform(
      position: Vector2(3700, 360),
      size: Vector2(400, 60),
    ));
    add(EnemySamuraiShield(
      position: Vector2(3880, 360),
      minXBound: 3740,
      maxXBound: 4040,
      maxHp: 105,
    ));
    add(BreakableCrate(position: Vector2(3980, 360), dropsRamen: true));
    add(CheckpointLantern(position: Vector2(4050, 360)));

    // =========================================================================
    // ZONE 4: Tempest Sawblade & Crumbling Cloud Spires (x: 4160 .. 5080)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(4180, 320),
      size: Vector2(115, 24),
      isCrumbling: true,
    ));
    add(InkSawBlade(
      position: Vector2(4360, 270),
      patrolOffset: Vector2(0, 100),
      patrolSpeed: 3.2,
    ));
    add(ComicPlatform(
      position: Vector2(4430, 275),
      size: Vector2(115, 24),
      isCrumbling: true,
    ));
    add(InkScroll(position: Vector2(4485, 215))); // Scroll #4

    add(ComicPlatform(
      position: Vector2(4610, 330),
      size: Vector2(115, 24),
      isCrumbling: true,
    ));
    add(ComicPlatform(
      position: Vector2(4790, 370),
      size: Vector2(280, 55),
    ));
    add(EnemyKarakuriAutomaton(
      position: Vector2(4930, 370),
      minXBound: 4820,
      maxXBound: 5040,
      maxHp: 95,
    ));

    // =========================================================================
    // ZONE 5: Thunder Emperor's Grand Bridge (x: 5120 .. 5960)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(5120, 450),
      size: Vector2(830, 65),
    ));
    add(InkSawBlade(
      position: Vector2(5260, 405),
      patrolOffset: Vector2(105, 0),
      patrolSpeed: 3.1,
    ));
    add(EnemySamuraiShield(
      position: Vector2(5480, 450),
      minXBound: 5370,
      maxXBound: 5620,
      maxHp: 110,
    ));
    add(EnemyKitsuneMage(
      position: Vector2(5670, 450),
      patrolRange: 95,
      maxHp: 90,
    ));
    add(InkScroll(position: Vector2(5560, 355))); // Scroll #5
    add(RamenBowl(position: Vector2(5790, 405)));
    add(CheckpointLantern(position: Vector2(5850, 450)));

    add(ToriiGateExit(
      position: Vector2(5910, 450),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 6: Thunder Emperor Sky Arena (x: 5970 .. 6940)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(5970, 485),
      size: Vector2(950, 60),
    ));
    add(ComicPlatform(
      position: Vector2(6100, 355),
      size: Vector2(145, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6600, 355),
      size: Vector2(145, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6350, 245),
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

    if (game.player.position.x < 6030) {
      game.player.position = Vector2(6050, 460);
    }
    game.currentSpawnPoint = Vector2(6050, 460);
    game.lockToBossArena(minX: 6000, maxX: 6870);

    add(BossRaijinTei(
      position: Vector2(6650, 485),
      arenaMinX: 6010,
      arenaMaxX: 6850,
    ));

    game.triggerBossCutIn(
      bossName: 'RAIJIN-TEI',
      quote:
          'KNEEL BEFORE THE THUNDER EMPEROR! TEN THOUSAND VOLTS SHALL VAPORIZE YOU!!',
      portraitColor: const Color(0xFFFFD600),
      portraitAsset: CartoonAssets.portraitRaijinTei,
    );
  }
}
