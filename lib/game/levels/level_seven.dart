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
import '../components/enemies/enemy_kitsune_mage.dart';
import '../components/bosses/boss_inari_kyubi.dart';
import 'level_one.dart';

class LevelSeven extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 380);
  static const double levelWidth = 6680.0;
  static const double bossArenaTriggerX = 5680.0;
  static const double arenaCenterX = 6170.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Phantom Kitsune Shrine Woods Backdrop
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level7_kitsune.png',
      tintColor: const Color(0x241B052C),
    ));

    // =========================================================================
    // ZONE 1: Vermilion Torii Trail & Foxfire Glade (x: 0 .. 1220)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(0, 390),
      size: Vector2(360, 150),
    ));
    add(BreakableCrate(position: Vector2(170, 390)));
    add(EnemyGrunt(
      position: Vector2(265, 390),
      minXBound: 180,
      maxXBound: 335,
      maxHp: 65,
    ));

    add(ComicPlatform(
      position: Vector2(415, 315),
      size: Vector2(210, 26),
    ));
    add(EnemyKitsuneMage(
      position: Vector2(530, 315),
      patrolRange: 95,
      maxHp: 75,
    ));

    add(ComicPlatform(
      position: Vector2(680, 250),
      size: Vector2(260, 26),
    ));
    add(InkScroll(position: Vector2(780, 200))); // Scroll #1
    add(BreakableCrate(position: Vector2(860, 250), dropsRamen: true));

    add(ComicPlatform(
      position: Vector2(990, 365),
      size: Vector2(240, 50),
    ));
    add(CheckpointLantern(position: Vector2(1110, 365)));

    // =========================================================================
    // ZONE 2: Illusion Warp Portals & Crumbling Spirit Bridges (x: 1260 .. 2540)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(1270, 460),
      size: Vector2(520, 60),
    ));
    add(PoisonSporeGeyser(
      position: Vector2(1430, 460),
      cloudHeight: 150,
      cyclePeriod: 2.7,
    ));
    add(EnemySamuraiShield(
      position: Vector2(1610, 460),
      minXBound: 1490,
      maxXBound: 1740,
      maxHp: 95,
    ));

    // Upper Spirit Canopy Vault accessed via Warp Portal
    add(ComicPlatform(
      position: Vector2(1380, 205),
      size: Vector2(380, 24),
    ));
    add(InkScroll(position: Vector2(1470, 155))); // Scroll #2
    add(RamenBowl(position: Vector2(1560, 160)));

    final shrineGate = GateBarrier(
      position: Vector2(1755, 460),
      size: Vector2(28, 130),
    );
    add(shrineGate);
    add(SwitchOrb(
      position: Vector2(1690, 205),
      targetGate: shrineGate,
    ));

    add(EclipseWarpPortal(
      position: Vector2(1330, 460),
      targetDestination: Vector2(1420, 195),
      portalColor: const Color(0xFFE040FB),
    ));

    // Phantom Crumbling Stepping Stones over Miasma Abyss
    add(ComicPlatform(
      position: Vector2(1840, 400),
      size: Vector2(110, 24),
      isCrumbling: true,
    ));
    add(ComicPlatform(
      position: Vector2(2005, 345),
      size: Vector2(110, 24),
      isCrumbling: true,
    ));
    add(EnemyKitsuneMage(
      position: Vector2(2080, 345),
      patrolRange: 105,
      maxHp: 80,
    ));
    add(ComicPlatform(
      position: Vector2(2170, 295),
      size: Vector2(110, 24),
      isCrumbling: true,
    ));

    add(ComicPlatform(
      position: Vector2(2330, 360),
      size: Vector2(240, 55),
    ));
    add(CheckpointLantern(position: Vector2(2460, 360)));

    // =========================================================================
    // ZONE 3: Haunted Taiko Canopy & Kitsune Coven (x: 2600 .. 3840)
    // =========================================================================
    add(TaikoBounceDrum(position: Vector2(2650, 340)));
    add(ComicPlatform(
      position: Vector2(2740, 240),
      size: Vector2(280, 26),
    ));
    add(EnemyOniArcher(position: Vector2(2890, 240)));
    add(InkScroll(position: Vector2(2810, 190))); // Scroll #3

    add(ZipLineLanternRail(
      startX: 3020,
      endX: 3560,
      railY: 190,
      glideSpeed: 390.0,
    ));
    add(EnemyKitsuneMage(
      position: Vector2(3280, 240),
      patrolRange: 115,
      maxHp: 80,
    ));

    add(ComicPlatform(
      position: Vector2(3580, 365),
      size: Vector2(310, 55),
    ));
    add(BreakableCrate(position: Vector2(3680, 365), dropsRamen: true));
    add(CheckpointLantern(position: Vector2(3790, 365)));

    // =========================================================================
    // ZONE 4: Twin Foxfire Sanctum & Moving Floating Altars (x: 3920 .. 4820)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(3940, 370),
      size: Vector2(140, 24),
      isMoving: true,
      moveRange: Vector2(120, -60),
      moveSpeed: 2.3,
    ));
    add(EnemyDrone(
      position: Vector2(4160, 240),
      flyRange: 110,
      flySpeed: 2.1,
    ));
    add(ComicPlatform(
      position: Vector2(4240, 320),
      size: Vector2(140, 24),
      isMoving: true,
      moveRange: Vector2(0, 95),
      moveSpeed: 2.4,
    ));
    add(InkScroll(position: Vector2(4310, 200))); // Scroll #4

    add(ComicPlatform(
      position: Vector2(4450, 380),
      size: Vector2(360, 55),
    ));
    add(EnemySamuraiShield(
      position: Vector2(4620, 380),
      minXBound: 4480,
      maxXBound: 4770,
      maxHp: 100,
    ));

    // =========================================================================
    // ZONE 5: Nine-Tail Shrine Approach (x: 4860 .. 5680)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(4860, 450),
      size: Vector2(810, 65),
    ));
    add(PoisonSporeGeyser(
      position: Vector2(5000, 450),
      cloudHeight: 155,
      cyclePeriod: 2.5,
    ));
    add(EnemyKitsuneMage(
      position: Vector2(5160, 450),
      patrolRange: 100,
      maxHp: 85,
    ));
    add(EnemyOniArcher(position: Vector2(5340, 450)));
    add(InkScroll(position: Vector2(5250, 360))); // Scroll #5
    add(RamenBowl(position: Vector2(5480, 405)));
    add(CheckpointLantern(position: Vector2(5550, 450)));

    add(ToriiGateExit(
      position: Vector2(5620, 450),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 6: Nine-Tail Shrine Boss Arena (x: 5690 .. 6650)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(5690, 485),
      size: Vector2(940, 60),
    ));
    add(ComicPlatform(
      position: Vector2(5820, 355),
      size: Vector2(145, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6320, 355),
      size: Vector2(145, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6070, 245),
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

    if (game.player.position.x < 5750) {
      game.player.position = Vector2(5770, 460);
    }
    game.currentSpawnPoint = Vector2(5770, 460);
    game.lockToBossArena(minX: 5720, maxX: 6590);

    add(BossInariKyubi(
      position: Vector2(6370, 485),
      arenaMinX: 5730,
      arenaMaxX: 6570,
    ));

    game.triggerBossCutIn(
      bossName: 'INARI-KYUBI',
      quote:
          'DANCE WITHIN MY NINE-TAILED FOXFIRE ILLUSIONS UNTIL YOUR SOUL TURNS TO ASH!!',
      portraitColor: const Color(0xFFE040FB),
      portraitAsset: CartoonAssets.portraitInariKyubi,
    );
  }
}
