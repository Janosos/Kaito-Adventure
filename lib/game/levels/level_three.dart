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
import '../components/bosses/boss_hebi_hime.dart';
import 'level_one.dart';

class LevelThree extends Component with HasGameReference<MangaGame> {
  static final Vector2 spawnPosition = Vector2(80, 380);
  static const double levelWidth = 5420.0;
  static const double bossArenaTriggerX = 4450.0;
  static const double arenaCenterX = 4940.0;

  bool _bossSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 2D Cartoon Emerald Bamboo Forest Backdrop
    add(MangaTiledBackdrop(
      assetPath: 'illustrations/bg_level3_bamboo.png',
      tintColor: const Color(0x22041E12),
    ));

    // =========================================================================
    // ZONE 1: Whispering Bamboo Shrine Entrance (x: 0 .. 1040)
    // Raised starting platform (y: 390) so Kaito is clearly visible above mobile thumb/joystick!
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(0, 390),
      size: Vector2(360, 150),
    ));
    add(BreakableCrate(position: Vector2(170, 390)));
    add(EnemyGrunt(
      position: Vector2(265, 390),
      minXBound: 185,
      maxXBound: 335,
      maxHp: 50,
    ));

    // First Wind Updraft Vent into the Bamboo Treetops
    add(WindUpdraftVent(
      position: Vector2(320, 390),
      liftHeight: 220,
    ));

    add(ComicPlatform(
      position: Vector2(390, 300),
      size: Vector2(230, 26),
    ));
    add(EnemyOniArcher(
      position: Vector2(515, 300),
      patrolRange: 45,
    ));
    add(InkScroll(position: Vector2(440, 255)));

    add(TaikoBounceDrum(position: Vector2(680, 340)));
    add(ComicPlatform(
      position: Vector2(745, 250),
      size: Vector2(240, 26),
    ));
    add(BreakableCrate(position: Vector2(860, 250), dropsRamen: true));
    add(CheckpointLantern(position: Vector2(935, 250)));

    // =========================================================================
    // ZONE 2: High-Altitude Wind Canopy Surfing (x: 1020 .. 2260) — LEVEL 3 EXCLUSIVE!
    // =========================================================================
    // Small suspended bamboo perches with powerful Updraft Vents carrying Kaito across the sky!
    add(ComicPlatform(
      position: Vector2(1050, 430),
      size: Vector2(110, 24),
    ));
    add(WindUpdraftVent(
      position: Vector2(1105, 430),
      liftHeight: 235,
      liftSpeed: -420,
    ));
    add(InkScroll(position: Vector2(1105, 260)));

    add(ComicPlatform(
      position: Vector2(1240, 240),
      size: Vector2(180, 24),
    ));
    add(EnemyDrone(position: Vector2(1330, 165), flyRange: 75));

    add(ComicPlatform(
      position: Vector2(1480, 420),
      size: Vector2(110, 24),
    ));
    add(WindUpdraftVent(
      position: Vector2(1535, 420),
      liftHeight: 245,
      liftSpeed: -430,
    ));
    add(InkScroll(position: Vector2(1535, 240)));

    add(ComicPlatform(
      position: Vector2(1660, 220),
      size: Vector2(210, 24),
    ));
    add(EnemyOniArcher(position: Vector2(1790, 220)));
    add(RamenBowl(position: Vector2(1710, 175)));

    add(ComicPlatform(
      position: Vector2(1940, 390),
      size: Vector2(110, 24),
    ));
    add(WindUpdraftVent(
      position: Vector2(1995, 390),
      liftHeight: 220,
      liftSpeed: -410,
    ));
    add(EnemyDrone(position: Vector2(2110, 200), flyRange: 85));

    // =========================================================================
    // ZONE 3: Venom Spore Hollow & Shrine Gate (x: 2220 .. 3400) — LEVEL 3 EXCLUSIVE!
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(2220, 460),
      size: Vector2(980, 65),
    ));
    add(CheckpointLantern(position: Vector2(2275, 460)));

    // Alternating Toxic Poison Spore Geysers along the Bamboo Shrine Floor!
    add(PoisonSporeGeyser(
      position: Vector2(2400, 460),
      cyclePeriod: 2.9,
      activeDuration: 1.15,
      initialPhase: 0.0,
    ));
    add(EnemyGrunt(
      position: Vector2(2530, 460),
      minXBound: 2450,
      maxXBound: 2630,
      maxHp: 55,
    ));
    add(PoisonSporeGeyser(
      position: Vector2(2680, 460),
      cyclePeriod: 2.9,
      activeDuration: 1.15,
      initialPhase: 1.45,
    ));
    add(EnemyGrunt(
      position: Vector2(2820, 460),
      minXBound: 2730,
      maxXBound: 2920,
      maxHp: 55,
    ));
    add(PoisonSporeGeyser(
      position: Vector2(2970, 460),
      cyclePeriod: 2.9,
      activeDuration: 1.15,
      initialPhase: 0.7,
    ));

    // Locked Bamboo Shrine Gate + Upper Canopy Switch Orb
    final gate3 = GateBarrier(position: Vector2(3130, 460));
    add(gate3);

    add(MangaSpringPad(position: Vector2(2560, 460), launchPower: 610));
    add(ComicPlatform(
      position: Vector2(2640, 250),
      size: Vector2(360, 24),
    ));
    add(PoisonSporeGeyser(
      position: Vector2(2810, 250),
      cyclePeriod: 2.7,
      activeDuration: 1.0,
      cloudHeight: 95,
    ));
    add(SwitchOrb(
      position: Vector2(2940, 250),
      targetGate: gate3,
    ));
    add(InkScroll(position: Vector2(2720, 205)));

    // =========================================================================
    // ZONE 4: Swinging Serpent Rafts & Pre-Boss Grove (x: 3250 .. 4460)
    // =========================================================================
    // Diagonal Oscillating Bamboo Rafts over a Giant Venom-Spike Pit!
    add(ComicPlatform(
      position: Vector2(3260, 410),
      size: Vector2(130, 24),
      isMoving: true,
      moveRange: Vector2(130, -75),
      moveSpeed: 1.85,
    ));
    add(TaikoBounceDrum(position: Vector2(3560, 330)));
    add(ComicPlatform(
      position: Vector2(3630, 350),
      size: Vector2(130, 24),
      isMoving: true,
      moveRange: Vector2(130, 65),
      moveSpeed: 1.95,
    ));

    // Spiked Pit Floor under the Swinging Rafts
    add(ComicPlatform(
      position: Vector2(3240, 515),
      size: Vector2(650, 30),
    ));
    add(SpikeTrap(position: Vector2(3255, 515), spikeCount: 38));

    // Final Pre-Boss Bamboo Sanctuary Approach
    add(ComicPlatform(
      position: Vector2(3910, 455),
      size: Vector2(570, 65),
    ));
    add(InkSawBlade(
      position: Vector2(4020, 400),
      patrolOffset: Vector2(0, -70),
      patrolSpeed: 2.6,
    ));
    add(EnemyOniArcher(position: Vector2(4160, 455)));
    add(EnemyGrunt(
      position: Vector2(4290, 455),
      minXBound: 4210,
      maxXBound: 4365,
      maxHp: 55,
    ));
    add(RamenBowl(position: Vector2(4360, 410)));
    add(CheckpointLantern(position: Vector2(4395, 455)));

    add(ToriiGateExit(
      position: Vector2(4445, 455),
      onEnter: _enterBossArena,
    ));

    // =========================================================================
    // ZONE 5: Viper Empress Boss Arena (x: 4500 .. 5400)
    // =========================================================================
    add(ComicPlatform(
      position: Vector2(4500, 485),
      size: Vector2(900, 60),
    ));
    add(ComicPlatform(
      position: Vector2(4630, 355),
      size: Vector2(140, 22),
    ));
    add(ComicPlatform(
      position: Vector2(5110, 355),
      size: Vector2(140, 22),
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

    if (game.player.position.x < 4560) {
      game.player.position = Vector2(4580, 460);
    }
    game.currentSpawnPoint = Vector2(4580, 460);
    game.lockToBossArena(minX: 4530, maxX: 5360);

    add(BossHebiHime(
      position: Vector2(5140, 485),
      arenaMinX: 4540,
      arenaMaxX: 5340,
    ));

    game.triggerBossCutIn(
      bossName: 'HEBI-HIME',
      quote: 'WELCOME TO MY VENOMOUS BAMBOO LABYRINTH, LITTLE SHINOBI!',
      portraitColor: const Color(0xFF00C853),
      portraitAsset: CartoonAssets.portraitHebiHime,
    );
  }
}
