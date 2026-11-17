import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../cartoon_assets.dart';
import '../manga_game.dart';
import '../../ui/comic_theme.dart';
import '../components/platform.dart';
import '../components/traps.dart';
import '../components/collectibles.dart';
import '../components/enemies/enemy_grunt.dart';
import '../components/enemies/enemy_drone.dart';
import '../components/enemies/enemy_oni_archer.dart';
import '../components/enemies/enemy_samurai_shield.dart';
import '../components/enemies/enemy_kitsune_mage.dart';
import '../components/enemies/enemy_karakuri_automaton.dart';
import '../components/bosses/boss_akuma_shin.dart';
import 'level_one.dart';

class LevelTen extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 380);
  static const double levelWidth = 7240.0;
  static const double bossArenaTriggerX = 6200.0;
  static const double arenaCenterX = 6700.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Primordial Ink Dimension Void Throne Backdrop
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level10_void.png',
      tintColor: const Color(0x2812021C),
    ));

    // =========================================================================
    // ZONE 1: Shattered Manga Panels & Void Entry (x: 0 .. 1300)
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
      maxHp: 105,
    ));

    add(MangaSpringPad(position: Vector2(325, 390), launchPower: 635));
    add(ComicPlatform(
      position: Vector2(410, 265),
      size: Vector2(260, 26),
    ));
    add(EnemyKitsuneMage(
      position: Vector2(540, 265),
      patrolRange: 100,
      maxHp: 90,
    ));
    add(InkScroll(position: Vector2(520, 215))); // Scroll #1

    add(TaikoBounceDrum(position: Vector2(735, 320)));
    add(ComicPlatform(
      position: Vector2(815, 250),
      size: Vector2(240, 26),
    ));
    add(EnemyOniArcher(position: Vector2(960, 250)));

    add(ComicPlatform(
      position: Vector2(1090, 365),
      size: Vector2(230, 50),
    ));
    add(CheckpointLantern(position: Vector2(1210, 365)));

    // =========================================================================
    // ZONE 2: Dual Dimensional Warp Sanctum & Gate Puzzle (x: 1350 .. 2780)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(1360, 460),
      size: Vector2(640, 65),
    ));
    add(EnemyKarakuriAutomaton(
      position: Vector2(1540, 460),
      minXBound: 1390,
      maxXBound: 1720,
      maxHp: 95,
    ));
    add(InkSawBlade(
      position: Vector2(1780, 415),
      patrolOffset: Vector2(95, 0),
      patrolSpeed: 3.2,
    ));

    // Upper Void Vault accessed via Dimensional Warp Portal
    add(ComicPlatform(
      position: Vector2(1460, 195),
      size: Vector2(430, 24),
    ));
    add(EnemySamuraiShield(
      position: Vector2(1660, 195),
      minXBound: 1500,
      maxXBound: 1810,
      maxHp: 100,
    ));
    add(InkScroll(position: Vector2(1550, 145))); // Scroll #2
    add(RamenBowl(position: Vector2(1740, 150)));

    final voidGate = GateBarrier(
      position: Vector2(1955, 460),
      size: Vector2(28, 130),
    );
    add(voidGate);
    add(SwitchOrb(
      position: Vector2(1845, 195),
      targetGate: voidGate,
    ));
    add(EclipseWarpPortal(
      position: Vector2(1415, 460),
      targetDestination: Vector2(1500, 185),
      portalColor: const Color(0xFFFF1744),
    ));

    // Moving Astral Monoliths over Erupting Void Geysers
    add(ComicPlatform(
      position: Vector2(2045, 385),
      size: Vector2(130, 24),
      isMoving: true,
      moveRange: Vector2(120, -65),
      moveSpeed: 2.5,
    ));
    add(MagmaGeyserVent(
      position: Vector2(2260, 520),
      geyserHeight: 215,
      cyclePeriod: 2.3,
      activeDuration: 1.0,
    ));
    add(ComicPlatform(
      position: Vector2(2330, 315),
      size: Vector2(130, 24),
      isMoving: true,
      moveRange: Vector2(0, 95),
      moveSpeed: 2.6,
    ));

    add(ComicPlatform(
      position: Vector2(2530, 365),
      size: Vector2(250, 55),
    ));
    add(CheckpointLantern(position: Vector2(2670, 365)));

    // =========================================================================
    // ZONE 3: Astral Zipline Canyon & All-Enemy Squadron (x: 2820 .. 4260)
    // =========================================================================
    add(ZipLineLanternRail(
      startX: 2780,
      endX: 3460,
      railY: 210,
      glideSpeed: 430.0,
    ));
    add(EnemyDrone(
      position: Vector2(3020, 195),
      flyRange: 120,
      flySpeed: 2.2,
    ));
    add(EnemyKitsuneMage(
      position: Vector2(3280, 250),
      patrolRange: 115,
      maxHp: 95,
    ));
    add(InkScroll(position: Vector2(3140, 150))); // Scroll #3

    add(ComicPlatform(
      position: Vector2(3480, 365),
      size: Vector2(740, 65),
    ));
    add(EnemySamuraiShield(
      position: Vector2(3660, 365),
      minXBound: 3520,
      maxXBound: 3820,
      maxHp: 110,
    ));
    add(EnemyKarakuriAutomaton(
      position: Vector2(3940, 365),
      minXBound: 3830,
      maxXBound: 4090,
      maxHp: 95,
    ));
    add(RamenBowl(position: Vector2(4110, 320)));
    add(CheckpointLantern(position: Vector2(4170, 365)));

    // =========================================================================
    // ZONE 4: Dimensional Taiko & Sawblade Labyrinth (x: 4300 .. 5280)
    // =========================================================================
    add(TaikoBounceDrum(position: Vector2(4330, 340)));
    add(ComicPlatform(
      position: Vector2(4420, 250),
      size: Vector2(115, 24),
      isCrumbling: true,
    ));
    add(InkSawBlade(
      position: Vector2(4600, 240),
      patrolOffset: Vector2(0, 105),
      patrolSpeed: 3.3,
    ));
    add(TaikoBounceDrum(position: Vector2(4685, 310)));
    add(InkScroll(position: Vector2(4685, 160))); // Scroll #4

    add(ComicPlatform(
      position: Vector2(4780, 250),
      size: Vector2(115, 24),
      isCrumbling: true,
    ));
    add(ComicPlatform(
      position: Vector2(4950, 355),
      size: Vector2(310, 55),
    ));
    add(EnemyOniArcher(position: Vector2(5120, 355)));
    add(BreakableCrate(position: Vector2(5200, 355), dropsRamen: true));

    // =========================================================================
    // ZONE 5: Primordial God's Royal Citadel Gauntlet (x: 5320 .. 6200)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(5320, 450),
      size: Vector2(870, 65),
    ));
    add(InkSawBlade(
      position: Vector2(5460, 405),
      patrolOffset: Vector2(110, 0),
      patrolSpeed: 3.3,
    ));
    add(EnemySamuraiShield(
      position: Vector2(5690, 450),
      minXBound: 5580,
      maxXBound: 5830,
      maxHp: 115,
    ));
    add(EnemyKitsuneMage(
      position: Vector2(5860, 450),
      patrolRange: 105,
      maxHp: 95,
    ));
    add(EnemyGrunt(
      position: Vector2(5970, 450),
      minXBound: 5880,
      maxXBound: 6060,
      maxHp: 85,
    ));
    add(InkScroll(position: Vector2(5780, 355))); // Scroll #5
    add(RamenBowl(position: Vector2(6060, 405)));
    add(CheckpointLantern(position: Vector2(6110, 450)));

    add(ToriiGateExit(
      position: Vector2(6165, 450),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 6: Primordial Ink God Final Boss Arena (x: 6220 .. 7200)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(6220, 485),
      size: Vector2(960, 60),
    ));
    add(ComicPlatform(
      position: Vector2(6350, 355),
      size: Vector2(150, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6860, 355),
      size: Vector2(150, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6605, 245),
      size: Vector2(150, 22),
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

    if (game.player.position.x < 6280) {
      game.player.position = Vector2(6300, 460);
    }
    game.currentSpawnPoint = Vector2(6300, 460);
    game.lockToBossArena(minX: 6250, maxX: 7130);

    add(BossAkumaShin(
      position: Vector2(6910, 485),
      arenaMinX: 6260,
      arenaMaxX: 7110,
    ));

    game.triggerBossCutIn(
      bossName: 'AKUMA-SHIN',
      quote:
          'I AM THE PRIMORDial INK GOD WHO PENNED THIS WORLD! NOW I ERASE YOUR FINAL PAGE, KAITO!!',
      portraitColor: ComicTheme.actionRed,
      portraitAsset: CartoonAssets.portraitAkumaShin,
    );
  }
}
