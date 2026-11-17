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
import '../components/bosses/boss_genji_karakuri.dart';
import 'level_one.dart';

class LevelSix extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 380);
  static const double levelWidth = 6520.0;
  static const double bossArenaTriggerX = 5530.0;
  static const double arenaCenterX = 6020.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Clockwork Karakuri Fortress Backdrop
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level6_karakuri.png',
      tintColor: const Color(0x24281404),
    ));

    // =========================================================================
    // ZONE 1: Brass Gear Gateways & Automaton Patrols (x: 0 .. 1180)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(0, 390),
      size: Vector2(360, 150),
    ));
    add(BreakableCrate(position: Vector2(160, 390)));
    add(EnemyKarakuriAutomaton(
      position: Vector2(265, 390),
      minXBound: 175,
      maxXBound: 340,
      maxHp: 75,
    ));

    add(ComicPlatform(
      position: Vector2(410, 340),
      size: Vector2(150, 24),
      isMoving: true,
      moveRange: Vector2(0, -85),
      moveSpeed: 2.1,
    ));
    add(InkSawBlade(
      position: Vector2(485, 420),
      patrolOffset: Vector2(65, 0),
      patrolSpeed: 2.5,
    ));

    add(ComicPlatform(
      position: Vector2(610, 265),
      size: Vector2(320, 28),
    ));
    add(EnemySamuraiShield(
      position: Vector2(760, 265),
      minXBound: 640,
      maxXBound: 890,
      maxHp: 90,
    ));
    add(InkScroll(position: Vector2(880, 215))); // Scroll #1

    add(ComicPlatform(
      position: Vector2(970, 370),
      size: Vector2(220, 45),
    ));
    add(CheckpointLantern(position: Vector2(1080, 370)));

    // =========================================================================
    // ZONE 2: Synchronized Sawblade Foundry & Switch Gate (x: 1220 .. 2420)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(1230, 450),
      size: Vector2(460, 65),
    ));
    add(EnemyKarakuriAutomaton(
      position: Vector2(1380, 450),
      minXBound: 1260,
      maxXBound: 1520,
      maxHp: 80,
    ));
    add(InkSawBlade(
      position: Vector2(1560, 405),
      patrolOffset: Vector2(90, 0),
      patrolSpeed: 2.8,
    ));

    // Upper Switch Vault to unlock Foundry Gate
    add(MangaSpringPad(position: Vector2(1310, 450), launchPower: 630));
    add(ComicPlatform(
      position: Vector2(1380, 240),
      size: Vector2(260, 24),
    ));
    add(EnemyOniArcher(position: Vector2(1510, 240)));
    add(BreakableCrate(position: Vector2(1430, 240), dropsRamen: true));

    final foundryGate = GateBarrier(
      position: Vector2(1660, 450),
      size: Vector2(28, 130),
    );
    add(foundryGate);
    add(SwitchOrb(
      position: Vector2(1595, 240),
      targetGate: foundryGate,
    ));

    // Moving Gear Conveyor Bridge over Molten Furnace
    add(ComicPlatform(
      position: Vector2(1740, 395),
      size: Vector2(135, 24),
      isMoving: true,
      moveRange: Vector2(115, 0),
      moveSpeed: 2.3,
    ));
    add(MagmaGeyserVent(
      position: Vector2(1930, 520),
      geyserHeight: 195,
      cyclePeriod: 2.6,
      activeDuration: 1.0,
    ));
    add(ComicPlatform(
      position: Vector2(2010, 330),
      size: Vector2(135, 24),
      isMoving: true,
      moveRange: Vector2(0, 85),
      moveSpeed: 2.4,
    ));
    add(InkScroll(position: Vector2(2075, 210))); // Scroll #2

    add(ComicPlatform(
      position: Vector2(2200, 380),
      size: Vector2(240, 55),
    ));
    add(CheckpointLantern(position: Vector2(2320, 380)));

    // =========================================================================
    // ZONE 3: High-Speed Steam Zipline & Ronin Bastion (x: 2460 .. 3680)
    // =========================================================================
    add(ZipLineLanternRail(
      startX: 2420,
      endX: 3040,
      railY: 220,
      glideSpeed: 400.0,
    ));
    add(EnemyDrone(
      position: Vector2(2660, 210),
      flyRange: 100,
      flySpeed: 2.0,
    ));
    add(EnemyDrone(
      position: Vector2(2880, 195),
      flyRange: 110,
      flySpeed: 2.1,
    ));
    add(InkScroll(position: Vector2(2760, 165))); // Scroll #3

    // Lower alternative route with spike pits & Karakuri
    add(ComicPlatform(
      position: Vector2(2520, 480),
      size: Vector2(460, 40),
    ));
    add(SpikeTrap(position: Vector2(2560, 480), spikeCount: 10));
    add(EnemyKarakuriAutomaton(
      position: Vector2(2820, 480),
      minXBound: 2730,
      maxXBound: 2950,
    ));

    add(ComicPlatform(
      position: Vector2(3060, 360),
      size: Vector2(580, 65),
    ));
    add(EnemySamuraiShield(
      position: Vector2(3230, 360),
      minXBound: 3110,
      maxXBound: 3360,
      maxHp: 95,
    ));
    add(EnemyOniArcher(position: Vector2(3440, 360)));
    add(RamenBowl(position: Vector2(3520, 315)));
    add(CheckpointLantern(position: Vector2(3590, 360)));

    // =========================================================================
    // ZONE 4: Clockwork Pendulum & Taiko Ascent (x: 3700 .. 4620)
    // =========================================================================
    add(TaikoBounceDrum(position: Vector2(3730, 340)));
    add(ComicPlatform(
      position: Vector2(3810, 250),
      size: Vector2(120, 24),
      isCrumbling: true,
    ));
    add(InkSawBlade(
      position: Vector2(3980, 230),
      patrolOffset: Vector2(0, 95),
      patrolSpeed: 3.0,
    ));
    add(TaikoBounceDrum(position: Vector2(4060, 310)));
    add(InkScroll(position: Vector2(4060, 165))); // Scroll #4

    add(ComicPlatform(
      position: Vector2(4150, 240),
      size: Vector2(120, 24),
      isCrumbling: true,
    ));
    add(ComicPlatform(
      position: Vector2(4320, 350),
      size: Vector2(310, 55),
    ));
    add(EnemyKarakuriAutomaton(
      position: Vector2(4460, 350),
      minXBound: 4350,
      maxXBound: 4590,
      maxHp: 85,
    ));

    // =========================================================================
    // ZONE 5: Shogun's Iron Guard Gauntlet (x: 4660 .. 5530)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(4680, 445),
      size: Vector2(820, 65),
    ));
    add(InkSawBlade(
      position: Vector2(4810, 400),
      patrolOffset: Vector2(95, 0),
      patrolSpeed: 2.9,
    ));
    add(EnemySamuraiShield(
      position: Vector2(5030, 445),
      minXBound: 4920,
      maxXBound: 5160,
      maxHp: 100,
    ));
    add(EnemyGrunt(
      position: Vector2(5220, 445),
      minXBound: 5140,
      maxXBound: 5330,
      maxHp: 70,
    ));
    add(InkScroll(position: Vector2(5120, 355))); // Scroll #5
    add(RamenBowl(position: Vector2(5360, 400)));
    add(CheckpointLantern(position: Vector2(5415, 445)));

    add(ToriiGateExit(
      position: Vector2(5475, 445),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 6: Clockwork Foundry Boss Arena (x: 5540 .. 6500)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(5540, 485),
      size: Vector2(940, 60),
    ));
    add(ComicPlatform(
      position: Vector2(5670, 355),
      size: Vector2(145, 22),
    ));
    add(ComicPlatform(
      position: Vector2(6170, 355),
      size: Vector2(145, 22),
    ));
    add(ComicPlatform(
      position: Vector2(5920, 245),
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

    if (game.player.position.x < 5600) {
      game.player.position = Vector2(5620, 460);
    }
    game.currentSpawnPoint = Vector2(5620, 460);
    game.lockToBossArena(minX: 5570, maxX: 6440);

    add(BossGenjiKarakuri(
      position: Vector2(6220, 485),
      arenaMinX: 5580,
      arenaMaxX: 6420,
    ));

    game.triggerBossCutIn(
      bossName: 'GENJI-KARAKURI',
      quote:
          'MY CLOCKWORK GEARS NEVER REST! YOUR FLESH AND INK WILL BE CRUSHED!!',
      portraitColor: const Color(0xFFFF8F00),
      portraitAsset: CartoonAssets.portraitGenjiKarakuri,
    );
  }
}
