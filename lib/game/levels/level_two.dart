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
import '../components/bosses/boss_ryu_kotei.dart';
import 'level_one.dart';

class LevelTwo extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 470);
  static const double levelWidth = 5020.0;
  static const double bossArenaTriggerX = 4050.0;
  static const double arenaCenterX = 4540.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Crimson Citadel Backdrop
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level2_citadel.jpg',
      tintColor: const Color(0x241B0808),
    ));

    // =========================================================================
    // ZONE 1: Outer Fortress Ramparts & Watchtowers (x: 0 .. 950)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(0, 480),
      size: Vector2(360, 60),
    ));
    add(EnemyGrunt(
      position: Vector2(220, 480),
      minXBound: 140,
      maxXBound: 330,
    ));
    add(BreakableCrate(position: Vector2(315, 480)));

    add(ComicPlatform(
      position: Vector2(400, 405),
      size: Vector2(150, 26),
    ));
    add(MangaSpringPad(
      position: Vector2(495, 405),
      launchPower: 590,
    ));

    add(ComicPlatform(
      position: Vector2(570, 275),
      size: Vector2(290, 26),
    ));
    add(EnemyOniArcher(
      position: Vector2(760, 275),
      patrolRange: 45,
    ));
    add(InkScroll(position: Vector2(630, 230)));
    add(BreakableCrate(position: Vector2(825, 275), dropsRamen: true));

    // =========================================================================
    // ZONE 2: Molten Magma Geyser Foundry (x: 900 .. 1960) — LEVEL 2 EXCLUSIVE!
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(900, 465),
      size: Vector2(240, 60),
    ));
    add(CheckpointLantern(position: Vector2(950, 465)));

    // Stepping Anvil Blocks with Erupting Magma Geyser Vents in the gaps!
    add(ComicPlatform(
      position: Vector2(1210, 440),
      size: Vector2(130, 30),
    ));
    add(MagmaGeyserVent(
      position: Vector2(1175, 520),
      cyclePeriod: 2.8,
      activeDuration: 1.05,
      geyserHeight: 165,
      initialPhase: 0.0,
    ));
    add(InkScroll(position: Vector2(1275, 390)));

    add(ComicPlatform(
      position: Vector2(1420, 415),
      size: Vector2(140, 30),
    ));
    add(MagmaGeyserVent(
      position: Vector2(1380, 520),
      cyclePeriod: 2.8,
      activeDuration: 1.05,
      geyserHeight: 175,
      initialPhase: 1.4,
    ));
    add(EnemyDrone(position: Vector2(1490, 260), flyRange: 80));

    add(ComicPlatform(
      position: Vector2(1640, 440),
      size: Vector2(290, 65),
    ));
    add(MagmaGeyserVent(
      position: Vector2(1600, 520),
      cyclePeriod: 2.8,
      activeDuration: 1.05,
      geyserHeight: 165,
      initialPhase: 0.7,
    ));
    add(EnemyGrunt(
      position: Vector2(1790, 440),
      minXBound: 1675,
      maxXBound: 1895,
      maxHp: 50,
    ));

    // =========================================================================
    // ZONE 3: Vertical Forge Elevator Tower & Twin-Orb Portcullis (x: 1960 .. 3000)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(1980, 460),
      size: Vector2(920, 65),
    ));
    add(CheckpointLantern(position: Vector2(2030, 460)));

    // Vertical Forge Elevator #1 (rides vertically from y=420 up to y=240!)
    add(ComicPlatform(
      position: Vector2(2110, 420),
      size: Vector2(115, 24),
      isMoving: true,
      moveRange: Vector2(0, -175),
      moveSpeed: 1.8,
    ));

    // Upper Forge Catwalk #1
    add(ComicPlatform(
      position: Vector2(2260, 240),
      size: Vector2(220, 24),
    ));
    add(EnemyOniArcher(position: Vector2(2380, 240)));
    add(RamenBowl(position: Vector2(2310, 195)));

    // Lower Forge Patrol & Magma Vent
    add(MagmaGeyserVent(
      position: Vector2(2360, 460),
      cyclePeriod: 3.1,
      activeDuration: 1.1,
      geyserHeight: 145,
    ));
    add(EnemyGrunt(
      position: Vector2(2540, 460),
      minXBound: 2430,
      maxXBound: 2680,
      maxHp: 50,
    ));

    // Twin-Sealed Iron Portcullis Gates!
    final gate2A = GateBarrier(position: Vector2(2780, 460));
    final gate2B = GateBarrier(position: Vector2(2830, 460));
    add(gate2A);
    add(gate2B);

    // Switch Orb #1 on Upper Catwalk #1
    add(SwitchOrb(
      position: Vector2(2440, 240),
      targetGate: gate2A,
    ));

    // Vertical Forge Elevator #2 to Upper Catwalk #2
    add(ComicPlatform(
      position: Vector2(2520, 390),
      size: Vector2(110, 24),
      isMoving: true,
      moveRange: Vector2(0, -150),
      moveSpeed: 2.0,
    ));
    add(ComicPlatform(
      position: Vector2(2660, 235),
      size: Vector2(180, 24),
    ));
    // Switch Orb #2 on Upper Catwalk #2
    add(SwitchOrb(
      position: Vector2(2760, 235),
      targetGate: gate2B,
    ));
    add(InkScroll(position: Vector2(2700, 190)));

    // =========================================================================
    // ZONE 4: Crumbling Magma Viaduct & Saw Gauntlet (x: 2940 .. 4060)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(2950, 420),
      size: Vector2(105, 24),
      isCrumbling: true,
    ));
    add(ComicPlatform(
      position: Vector2(3100, 395),
      size: Vector2(105, 24),
      isCrumbling: true,
    ));
    add(TaikoBounceDrum(position: Vector2(3265, 355)));
    add(ComicPlatform(
      position: Vector2(3335, 410),
      size: Vector2(105, 24),
      isCrumbling: true,
    ));

    // Spiked Magma Trench below the Viaduct
    add(ComicPlatform(
      position: Vector2(2930, 515),
      size: Vector2(540, 30),
    ));
    add(SpikeTrap(position: Vector2(2945, 515), spikeCount: 30));

    // Final Pre-Boss Citadel Courtyard
    add(ComicPlatform(
      position: Vector2(3480, 455),
      size: Vector2(600, 65),
    ));
    add(InkSawBlade(
      position: Vector2(3600, 405),
      radius: 26,
      patrolOffset: Vector2(90, 0),
      patrolSpeed: 2.4,
    ));
    add(EnemyOniArcher(position: Vector2(3810, 455)));
    add(BreakableCrate(position: Vector2(3900, 455), dropsRamen: true));
    add(CheckpointLantern(position: Vector2(3980, 455)));

    add(ToriiGateExit(
      position: Vector2(4045, 455),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 5: Dragon Shogun Boss Arena (x: 4100 .. 5000)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(4100, 485),
      size: Vector2(900, 60),
    ));
    add(ComicPlatform(
      position: Vector2(4220, 355),
      size: Vector2(135, 22),
    ));
    add(ComicPlatform(
      position: Vector2(4720, 355),
      size: Vector2(135, 22),
    ));
    add(ComicPlatform(
      position: Vector2(4470, 250),
      size: Vector2(130, 22),
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

    if (game.player.position.x < 4160) {
      game.player.position = Vector2(4180, 460);
    }
    game.currentSpawnPoint = Vector2(4180, 460);
    game.lockToBossArena(minX: 4130, maxX: 4960);

    add(BossRyuKotei(
      position: Vector2(4750, 485),
      arenaMinX: 4140,
      arenaMaxX: 4940,
    ));

    game.triggerBossCutIn(
      bossName: 'RYU-KOTEI',
      quote: 'WHO DARES TREAD UPON THE DRAGON THRONE?!',
      portraitColor: ComicTheme.actionRed,
      portraitAsset: CartoonAssets.portraitRyuKotei,
    );
  }
}
